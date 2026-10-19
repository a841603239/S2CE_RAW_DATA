# -*- coding: utf-8 -*-
"""
luac_float_convert_gui.py — Lua 5.1 字节码转换器 (GUI)  v1.4

功能：
· 仅支持输入 .lua 源文件，自动编译并转换（需 luac5.1.exe）
· 批量处理、文件夹扫描、实时日志、进度条
· 可选 S2CE 模式（默认勾选）：
    - S2CE: size_t 4→8, lua_Number 8→4（重写所有字符串长度前缀）
    - S2TW: size_t 不变(4), lua_Number 8→4
· 命名规则：
    .lua → <name>.luac
"""

import os
import queue
import struct
import subprocess
import tempfile
import threading
import time
import tkinter as tk
from tkinter import ttk, filedialog, messagebox
from tkinter.scrolledtext import ScrolledText

APP_TITLE = "S2TW .luac编译工具"
APP_VER = "v1.4"

SZ_INT = 4
SZ_INSTR = 4


# ============================================================
# 核心转换逻辑（泛型化：支持 size_t / lua_Number 4↔8 组合）
# ============================================================
class Reader:
    def __init__(self, data, endian, sz_width=4, num_width=8):
        self.d = data
        self.off = 0
        self.e = endian      # '<' 或 '>'
        self.sw = sz_width   # 输入 size_t 宽度
        self.nw = num_width  # 输入 lua_Number 宽度

    def u8(self):
        v = self.d[self.off]
        self.off += 1
        return v

    def i32(self):
        v = struct.unpack_from(self.e + 'i', self.d, self.off)[0]
        self.off += 4
        return v

    def sz(self):
        if self.sw == 4:
            v = struct.unpack_from(self.e + 'I', self.d, self.off)[0]
            self.off += 4
        else:
            v = struct.unpack_from(self.e + 'Q', self.d, self.off)[0]
            self.off += 8
        return v

    def raw(self, n):
        v = self.d[self.off:self.off + n]
        self.off += n
        return v


class Writer:
    def __init__(self, endian, sz_width=4, num_width=4):
        self.b = bytearray()
        self.e = endian
        self.sw = sz_width   # 输出 size_t 宽度
        self.nw = num_width  # 输出 lua_Number 宽度

    def u8(self, v):
        self.b.append(v)

    def raw(self, v):
        self.b += v

    def i32(self, v):
        self.b += struct.pack(self.e + 'i', v)

    def sz(self, v):
        if self.sw == 4:
            self.b += struct.pack(self.e + 'I', v)
        else:
            self.b += struct.pack(self.e + 'Q', v)


def convert_proto(r, w):
    """递归转换一个 Proto 结构。"""
    # source 字符串（长度前缀按各自 size_t 宽度重写）
    n = r.sz()
    w.sz(n)
    w.raw(r.raw(n))

    # linedefined, lastlinedefined
    w.i32(r.i32())
    w.i32(r.i32())

    # nups, numparams, is_vararg, maxstacksize（各 1 字节，顺序不能错）
    w.u8(r.u8())   # nups
    w.u8(r.u8())   # numparams
    w.u8(r.u8())   # is_vararg
    w.u8(r.u8())   # maxstacksize

    # code
    sizecode = r.sz()
    w.sz(sizecode)
    w.raw(r.raw(sizecode * SZ_INSTR))

    # constants
    sizek = r.sz()
    w.sz(sizek)
    for _ in range(sizek):
        t = r.u8()
        w.u8(t)
        if t == 0:      # NIL
            pass
        elif t == 1:    # BOOLEAN
            w.u8(r.u8())
        elif t == 3:    # NUMBER：按输入/输出宽度转换
            if r.nw == w.nw:
                w.raw(r.raw(r.nw))
            else:
                fmt_in = 'd' if r.nw == 8 else 'f'
                v = struct.unpack_from(r.e + fmt_in, r.d, r.off)[0]
                r.off += r.nw
                fmt_out = 'd' if w.nw == 8 else 'f'
                w.raw(struct.pack(w.e + fmt_out, v))
        elif t == 4:    # STRING
            n = r.sz()
            w.sz(n)
            w.raw(r.raw(n))
        else:
            raise ValueError("未知常量类型 %d (偏移 %d)" % (t, r.off))

    # 子 Proto
    sizep = r.sz()
    w.sz(sizep)
    for _ in range(sizep):
        convert_proto(r, w)

    # lineinfo
    n = r.sz()
    w.sz(n)
    w.raw(r.raw(n * SZ_INT))

    # locvars
    n = r.sz()
    w.sz(n)
    for _ in range(n):
        ln = r.sz()
        w.sz(ln)
        w.raw(r.raw(ln))
        w.i32(r.i32())  # startpc
        w.i32(r.i32())  # endpc

    # upvalues
    n = r.sz()
    w.sz(n)
    for _ in range(n):
        un = r.sz()
        w.sz(un)
        w.raw(r.raw(un))


def verify_roundtrip(out_bytes, endian, sz_width):
    """自验证：按目标 ABI 再解析一遍，结果必须与输出逐字节一致。"""
    try:
        r = Reader(out_bytes, endian, sz_width, 4)
        w = Writer(endian, sz_width, 4)
        w.raw(out_bytes[0:12])
        r.off = 12
        convert_proto(r, w)
        if r.off != len(out_bytes):
            return False, "未完全解析 (%d/%d)" % (r.off, len(out_bytes))
        if bytes(w.b) != out_bytes:
            return False, "二次序列化结果不一致"
        return True, ""
    except Exception as e:
        return False, "%s: %s" % (type(e).__name__, e)


def convert_one(src_path, dst_path, log, s2ce=True):
    """
    转换单个 .luac 文件。
      s2ce=True : 目标 size_t=8, lua_Number=4（重写字符串长度前缀）
      s2ce=False: 目标 size_t=4（保持不变）, lua_Number=4
    成功返回 True。
    """
    try:
        with open(src_path, 'rb') as f:
            data = f.read()
    except OSError as e:
        log("  错误: 无法读取文件: %s" % e, "err")
        return False

    # ---- 头部校验 ----
    if len(data) < 12 or data[0] != 0x1b or data[1:4] != b'Lua':
        log("  跳过: 不是 Lua 字节码文件", "warn")
        return False
    if data[4] != 0x51:
        log("  跳过: 版本字节 0x%02x 不是 Lua 5.1 (0x51)" % data[4], "warn")
        return False
    if data[6] != 1:
        log("  跳过: 仅支持小端字节序", "warn")
        return False
    if data[7] != 4 or data[9] != 4:
        log("  跳过: int/Instruction 宽度非 4 字节，属其他平台", "warn")
        return False
    if data[11] != 0:
        log("  跳过: lua_Number 为整型模式(integral)，不支持", "warn")
        return False

    in_sz = data[8]
    in_num = data[10]
    if in_sz not in (4, 8) or in_num not in (4, 8):
        log("  跳过: size_t(0x%02x)/lua_Number(0x%02x) 宽度不支持"
            % (in_sz, in_num), "warn")
        return False

    tgt_sz = 8 if s2ce else 4
    if not s2ce and in_sz != 4:
        log("  跳过: S2TW 模式要求输入 size_t=4，该文件 size_t=%d" % in_sz, "warn")
        return False
    if in_sz == tgt_sz and in_num == 4:
        log("  跳过: 已是目标格式 (size_t=%d, float)，无需转换" % tgt_sz, "warn")
        return False

    endian = '<' if data[6] == 1 else '>'
    r = Reader(data, endian, in_sz, in_num)
    w = Writer(endian, tgt_sz, 4)

    # ---- 头部：拷贝 12 字节并修补 size_t / lua_Number 字段 ----
    head = bytearray(data[0:12])
    head[8] = tgt_sz
    head[10] = 4
    w.raw(bytes(head))
    r.off = 12

    # ---- 顶层 Proto ----
    try:
        convert_proto(r, w)
    except Exception as e:
        log("  失败: 解析出错 %s: %s" % (type(e).__name__, e), "err")
        return False
    if r.off != len(data):
        log("  警告: 未完全解析 (%d/%d)，剩余 %d 字节，已放弃写出"
            % (r.off, len(data), len(data) - r.off), "warn")
        return False

    out = bytes(w.b)

    # ---- 自验证（round-trip）----
    ok, msg = verify_roundtrip(out, endian, tgt_sz)
    if not ok:
        log("  失败: 生成结果自验证未通过: %s，已放弃写出" % msg, "err")
        return False

    try:
        with open(dst_path, 'wb') as f:
            f.write(out)
    except OSError as e:
        log("  错误: 无法写出文件: %s" % e, "err")
        return False

    log("  OK: size_t %d→%d, lua_Number %d→4; %d 字节 → %d 字节"
        % (in_sz, tgt_sz, in_num, len(data), len(out)), "ok")
    log("  输出: %s" % dst_path, "path")
    return True


# ============================================================
# GUI
# ============================================================
class App:
    def __init__(self, root):
        self.root = root
        self.q = queue.Queue()
        self.files = []
        self.running = False
        self.cancel = threading.Event()

        # luac5.1.exe 默认位于脚本同目录的 lua-5.1.5_Win32_bin 文件夹中
        _script_dir = os.path.dirname(os.path.abspath(__file__))
        _candidates = [
            os.path.join(_script_dir, "lua-5.1.5_Win32_bin", "luac5.1.exe"),
            os.path.join(_script_dir, "luac5.1.exe"),
            os.path.join(os.path.dirname(_script_dir), "lua-5.1.5_Win32_bin", "luac5.1.exe"),
            os.path.join(os.path.dirname(_script_dir), "luac5.1.exe"),
        ]
        _default_luac = ""
        for _p in _candidates:
            if os.path.isfile(_p):
                _default_luac = _p
                break
        self.luac_path = tk.StringVar(value=_default_luac)

        # S2CE 模式开关（默认勾选）
        self.s2ce_mode = tk.BooleanVar(value=True)

        root.title(APP_TITLE + " " + APP_VER)
        root.geometry("920x760")
        root.minsize(780, 620)

        self._build_ui()
        self._bind_keys()
        root.protocol("WM_DELETE_WINDOW", self.on_close)
        root.after(80, self._drain)

    # ---------- 界面 ----------
    def _build_ui(self):
        pad = dict(padx=8, pady=4)

        # 状态栏
        self.status_var = tk.StringVar(value="就绪 — 请添加 .lua 文件")
        tk.Label(self.root, textvariable=self.status_var, anchor='w',
                 relief='sunken', bd=1).pack(side='bottom', fill='x')

        # ---- 工具栏 ----
        bar = ttk.Frame(self.root)
        bar.pack(fill='x', **pad)
        ttk.Button(bar, text="添加文件…", command=self.add_files).pack(side='left')
        ttk.Button(bar, text="添加文件夹…", command=self.add_folder).pack(side='left', padx=(6, 0))
        ttk.Button(bar, text="移除选中", command=self.remove_selected).pack(side='left', padx=(6, 0))
        ttk.Button(bar, text="清空列表", command=self.clear_files).pack(side='left', padx=(6, 0))
        tk.Label(bar, text="说明：本工具用于将.lua编译为ShogunII使用的.luac格式",
         fg='blue').pack(side='left', padx=(12, 0))
        ttk.Label(bar, text="(Ctrl+O 添加 / Delete 移除)").pack(side='right')

        # ---- 文件列表 ----
        lf = ttk.LabelFrame(self.root, text="待转换文件（仅支持 .lua）")
        lf.pack(fill='both', expand=True, padx=8, pady=4)
        self.tree = ttk.Treeview(lf, columns=('file', 'type', 'status'),
                                 show='headings', selectmode='extended')
        self.tree.heading('file', text='文件')
        self.tree.heading('type', text='类型')
        self.tree.heading('status', text='状态')
        self.tree.column('file', width=560, anchor='w')
        self.tree.column('type', width=70, anchor='center', stretch=False)
        self.tree.column('status', width=120, anchor='center', stretch=False)
        self.tree.tag_configure('run', foreground='#0066cc')
        self.tree.tag_configure('ok', foreground='#0a7d0a')
        self.tree.tag_configure('fail', foreground='#c00000')
        self.tree.tag_configure('skip', foreground='#b07000')
        vs = ttk.Scrollbar(lf, orient='vertical', command=self.tree.yview)
        self.tree.configure(yscrollcommand=vs.set)
        vs.pack(side='right', fill='y')
        self.tree.pack(side='left', fill='both', expand=True)
        self.tree.bind('<Delete>', lambda e: self.remove_selected())
        self.tree.bind('<<TreeviewSelect>>', self._on_select)

        # ---- 编译与输出设置 ----
        opt = ttk.LabelFrame(self.root, text="编译与输出设置")
        opt.pack(fill='x', padx=8, pady=4)

        # luac 路径
        ttk.Label(opt, text="luac5.1.exe（必填）：").grid(row=0, column=0, sticky='w', padx=6, pady=3)
        self.e_luac = ttk.Entry(opt, textvariable=self.luac_path)
        self.e_luac.grid(row=0, column=1, sticky='ew', padx=6, pady=3)
        ttk.Button(opt, text="浏览…", command=self.choose_luac).grid(row=0, column=2, padx=6, pady=3)

        # S2CE 模式开关
        self.chk_s2ce = tk.Checkbutton(
            opt,
            text="S2CE(完全版)支持"
                 "　 注：不勾选则为 S2TW 原版格式（size_t=4，lua_Number 8→4）",
            variable=self.s2ce_mode,
            fg='red', font=('', 12, 'bold'),
            activeforeground='red',
            selectcolor='white')
        self.chk_s2ce.grid(row=1, column=0, columnspan=4, sticky='w', padx=6, pady=3)

        # 输出模式
        self.out_mode = tk.StringVar(value='same')
        ttk.Radiobutton(opt, text="与源文件同目录（输出 <name>.luac）",
                        variable=self.out_mode, value='same',
                        command=self._sync_out).grid(row=2, column=0, columnspan=4,
                                                     sticky='w', padx=6, pady=3)
        ttk.Radiobutton(opt, text="指定输出目录：", variable=self.out_mode, value='dir',
                        command=self._sync_out).grid(row=3, column=0, sticky='w', padx=6, pady=3)
        self.out_dir = tk.StringVar()
        self.e_outdir = ttk.Entry(opt, textvariable=self.out_dir)
        self.e_outdir.grid(row=3, column=1, sticky='ew', padx=6, pady=3)
        self.b_outdir = ttk.Button(opt, text="浏览…", command=self.choose_outdir)
        self.b_outdir.grid(row=3, column=2, padx=6, pady=3)
        opt.columnconfigure(1, weight=1)
        self._sync_out()

        # ---- 进度 & 按钮 ----
        bottom = ttk.Frame(self.root)
        bottom.pack(fill='x', padx=8, pady=(2, 4))
        self.progress = ttk.Progressbar(bottom, mode='determinate')
        self.progress.pack(side='left', fill='x', expand=True)
        self.btn_start = ttk.Button(bottom, text="开始转换", command=self.start)
        self.btn_start.pack(side='left', padx=(8, 0))
        self.btn_stop = ttk.Button(bottom, text="停止", command=self.stop, state='disabled')
        self.btn_stop.pack(side='left', padx=(6, 0))

        # ---- 日志 ----
        logf = ttk.LabelFrame(self.root, text="日志")
        logf.pack(fill='both', expand=True, padx=8, pady=(0, 6))
        self.logview = ScrolledText(logf, height=12, wrap='word', state='disabled',
                                    font=('Consolas', 9))
        self.logview.pack(fill='both', expand=True)
        self.logview.tag_config('info', foreground='#333333')
        self.logview.tag_config('ok', foreground='#0a7d0a')
        self.logview.tag_config('warn', foreground='#b07000')
        self.logview.tag_config('err', foreground='#c00000')
        self.logview.tag_config('head', foreground='#0066cc', font=('Consolas', 9, 'bold'))
        self.logview.tag_config('path', foreground='#777777')

    def _bind_keys(self):
        self.root.bind('<Control-o>', lambda e: self.add_files())
        self.root.bind('<Control-O>', lambda e: self.add_files())
        self.root.bind('<Control-Return>', lambda e: self.start())

    def _sync_out(self):
        st = 'normal' if self.out_mode.get() == 'dir' else 'disabled'
        self.e_outdir.configure(state=st)
        self.b_outdir.configure(state=st)

    def _on_select(self, _evt=None):
        sel = self.tree.selection()
        if sel:
            self.status_var.set(sel[0])

    # ---------- 列表操作 ----------
    def add_files(self):
        if self.running:
            return
        paths = filedialog.askopenfilenames(
            title="选择 .lua 源文件",
            filetypes=[("Lua 源文件", "*.lua"),
                       ("所有文件", "*.*")])
        if paths:
            self._add_paths(paths)

    def add_folder(self):
        if self.running:
            return
        d = filedialog.askdirectory(title="选择包含 .lua 的文件夹")
        if not d:
            return
        found = []
        for root_, _dirs, fs in os.walk(d):
            for f in fs:
                if f.lower().endswith('.lua'):
                    found.append(os.path.join(root_, f))
        if not found:
            messagebox.showinfo("提示", "该文件夹下未找到 .lua 文件")
            return
        self._add_paths(found)

    def _add_paths(self, paths):
        added = 0
        for p in paths:
            p = os.path.abspath(p)
            if p in self.files or self.tree.exists(p):
                continue
            ext = os.path.splitext(p)[1].lower()
            if ext != '.lua':
                continue
            ftype = "Lua源"
            self.files.append(p)
            self.tree.insert('', 'end', iid=p,
                             values=(os.path.basename(p), ftype, '待转换'))
            added += 1
        self.status_var.set("已添加 %d 个，共 %d 个文件" % (added, len(self.files)))

    def remove_selected(self):
        if self.running:
            return
        for iid in self.tree.selection():
            self.tree.delete(iid)
            if iid in self.files:
                self.files.remove(iid)
        self.status_var.set("共 %d 个文件" % len(self.files))

    def clear_files(self):
        if self.running:
            return
        self.tree.delete(*self.tree.get_children())
        self.files.clear()
        self.status_var.set("列表已清空")

    def choose_outdir(self):
        d = filedialog.askdirectory(title="选择输出目录")
        if d:
            self.out_dir.set(d)

    def choose_luac(self):
        p = filedialog.askopenfilename(
            title="选择 luac5.1.exe (Lua 5.1 编译器)",
            filetypes=[("可执行文件", "*.exe"), ("所有文件", "*.*")])
        if p:
            self.luac_path.set(p)

    # ---------- 队列 / 日志 ----------
    def log(self, msg, tag='info'):
        self.q.put(('log', msg, tag))

    def _append(self, msg, tag='info'):
        lv = self.logview
        lv.configure(state='normal')
        lv.insert('end', msg + '\n', tag)
        lv.see('end')
        lv.configure(state='disabled')

    def _clear_log(self):
        lv = self.logview
        lv.configure(state='normal')
        lv.delete('1.0', 'end')
        lv.configure(state='disabled')

    def _drain(self):
        try:
            while True:
                item = self.q.get_nowait()
                self._handle(item)
        except queue.Empty:
            pass
        self.root.after(80, self._drain)

    def _handle(self, item):
        kind = item[0]
        if kind == 'log':
            self._append(item[1], item[2])
        elif kind == 'status':
            _, path, text, tag = item
            if self.tree.exists(path):
                self.tree.set(path, 'status', text)
                self.tree.item(path, tags=(tag,) if tag else ())
                self.tree.see(path)
        elif kind == 'progress':
            self.progress['value'] = item[1]
        elif kind == 'done':
            _, ok, total, elapsed, cancelled = item
            self.running = False
            self.btn_start.configure(state='normal')
            self.btn_stop.configure(state='disabled')
            self._append('-' * 64, 'path')
            if cancelled:
                self._append("已中止: %d / %d 个文件转换成功，用时 %.2f 秒"
                             % (ok, total, elapsed), 'warn')
                self.status_var.set("已中止")
            else:
                self._append("完成: %d / %d 个文件转换成功，用时 %.2f 秒"
                             % (ok, total, elapsed), 'ok' if ok == total else 'warn')
                self.status_var.set("完成: %d / %d 成功" % (ok, total))
            if total > 0 and ok == total:
                messagebox.showinfo("完成", "全部 %d 个文件转换成功！" % total)
            elif total > 0:
                messagebox.showwarning("完成", "成功 %d / %d 个文件。\n请查看日志了解详情。"
                                       % (ok, total))

    # ---------- 转换流程 ----------
    def start(self):
        if self.running:
            return
        if not self.files:
            messagebox.showinfo("提示", "请先添加要转换的 .lua 文件")
            return

        luac_exe = self.luac_path.get().strip()
        if not luac_exe:
            messagebox.showwarning("提示", "请先指定 luac5.1.exe 路径。")
            return
        if not os.path.isfile(luac_exe):
            messagebox.showerror("错误", "指定的 luac5.1.exe 不存在：\n%s" % luac_exe)
            return

        s2ce = bool(self.s2ce_mode.get())

        mode = self.out_mode.get()
        outdir = self.out_dir.get().strip()
        if mode == 'dir':
            if not outdir:
                messagebox.showwarning("提示", "请选择输出目录")
                return
            if not os.path.isdir(outdir):
                try:
                    os.makedirs(outdir)
                except OSError as e:
                    messagebox.showerror("错误", "无法创建输出目录:\n%s" % e)
                    return

        self.running = True
        self.cancel.clear()
        self.btn_start.configure(state='disabled')
        self.btn_stop.configure(state='normal')
        self.progress.configure(maximum=len(self.files), value=0)
        for p in self.files:
            if self.tree.exists(p):
                self.tree.set(p, 'status', '等待中')
                self.tree.item(p, tags=())

        self._clear_log()
        self._append("开始处理 %d 个 .lua 文件" % len(self.files), 'head')
        self._append("转换模式: %s"
                     % ("S2CE (size_t 4→8, lua_Number 8→4)" if s2ce
                        else "S2TW (size_t=4, lua_Number 8→4)"), 'info')
        self._append("使用 luac：%s" % luac_exe, 'info')
        self._append("输出模式: %s"
                     % ("与源文件同目录" if mode == 'same' else outdir), 'info')
        self.status_var.set("处理中…")

        t = threading.Thread(target=self._worker,
                             args=(list(self.files), mode, outdir, luac_exe, s2ce),
                             daemon=True)
        t.start()

    def stop(self):
        if self.running:
            self.cancel.set()
            self.btn_stop.configure(state='disabled')
            self.status_var.set("正在中止…")

    def _worker(self, files, mode, outdir, luac_exe, s2ce):
        t0 = time.time()
        ok = 0
        total = len(files)
        cancelled = False

        for i, src in enumerate(files):
            if self.cancel.is_set():
                cancelled = True
                self.log("已取消，剩余 %d 个文件未处理" % (total - i), 'warn')
                break

            self.q.put(('status', src, '处理中…', 'run'))
            self.log("", 'info')
            self.log("[%d/%d] %s" % (i + 1, total, src), 'head')

            base, _ = os.path.splitext(src)
            out_name = os.path.basename(base) + '.luac'

            if mode == 'same':
                dst = os.path.join(os.path.dirname(src), out_name)
            else:
                dst = os.path.join(outdir, out_name)

            # 所有输入都是 .lua，必须先编译成临时 .luac
            fd, tmp_luac = tempfile.mkstemp(suffix='.luac', prefix='luac_double_')
            os.close(fd)
            self.log("  编译: %s → 临时 .luac" % os.path.basename(src), 'info')
            try:
                proc = subprocess.run([luac_exe, '-o', tmp_luac, src],
                                      capture_output=True, text=True, timeout=30)
                if proc.returncode != 0:
                    self.log("  编译失败 (返回码 %d): %s"
                             % (proc.returncode,
                                proc.stderr.strip() or proc.stdout.strip()), 'err')
                    os.unlink(tmp_luac)
                    self.q.put(('status', src, '编译失败', 'fail'))
                    self.q.put(('progress', i + 1))
                    continue
            except subprocess.TimeoutExpired:
                self.log("  编译超时", 'err')
                os.unlink(tmp_luac)
                self.q.put(('status', src, '编译超时', 'fail'))
                self.q.put(('progress', i + 1))
                continue
            except Exception as e:
                self.log("  编译异常: %s" % e, 'err')
                if os.path.exists(tmp_luac):
                    os.unlink(tmp_luac)
                self.q.put(('status', src, '编译异常', 'fail'))
                self.q.put(('progress', i + 1))
                continue

            luac_input = tmp_luac

            # 调用核心转换
            good = convert_one(luac_input, dst, self.log, s2ce=s2ce)

            # 清理临时文件
            if tmp_luac and os.path.exists(tmp_luac):
                try:
                    os.unlink(tmp_luac)
                except OSError:
                    pass

            if good:
                ok += 1
                self.q.put(('status', src, '成功', 'ok'))
            else:
                self.q.put(('status', src, '失败/跳过', 'fail'))
            self.q.put(('progress', i + 1))

        self.q.put(('done', ok, total, time.time() - t0, cancelled))

    # ---------- 关闭 ----------
    def on_close(self):
        if self.running:
            if not messagebox.askyesno("确认", "任务仍在进行中，确定要退出吗？"):
                return
            self.cancel.set()
        self.root.destroy()


def main():
    root = tk.Tk()
    try:
        from ctypes import windll
        windll.shcore.SetProcessDpiAwareness(1)
    except Exception:
        pass
    App(root)
    root.mainloop()


if __name__ == '__main__':
    main()