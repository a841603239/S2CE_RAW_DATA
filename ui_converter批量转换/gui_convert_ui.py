#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Total War UI 批量转换器 GUI

依赖同目录下的 convert_ui.py（需已加入 __main__ 保护）。

功能：
  - 选择输入 / 输出文件夹
  - 两种方向：UI  -> XML   /   XML -> UI
  - 可选递归子文件夹
  - 可选保持原目录结构
  - 后台线程转换，带进度条和实时日志
"""

import os
import queue
import threading
import traceback
import tkinter as tk
from tkinter import ttk, filedialog, messagebox
from xml.dom.minidom import parse

import convert_ui
from convert_ui import TypeCastReader, TypeCastWriter, UiEntry


SUPPORTED_VERSIONS = {29, 32, 33, 39, 43, 44, 46, 47, 49, 50, 51, 52, 54,
                      55, 56, 57, 58, 60, 61, 62, 63}


# --------------------------------------------------------------------------
# 核心转换函数（在 convert_ui.py 基础上做了健壮性增强）
# --------------------------------------------------------------------------

def convert_ui_to_xml(src, dst):
    """把 .ui 二进制文件转换成 XML。"""
    with open(src, "rb", buffering=0) as raw:
        uiFile = TypeCastReader(raw)

        versionString = uiFile.read(10)
        if len(versionString) < 10 or versionString[0:7] != b"Version":
            raise ValueError("不是 UI 布局文件或未知文件版本")

        try:
            versionNumber = int(versionString[7:10])
        except ValueError:
            raise ValueError("无法解析版本号：%r" % versionString)

        if versionNumber not in SUPPORTED_VERSIONS:
            raise ValueError("不支持的版本 Version%03d" % versionNumber)

        # Version058+ 每个 tgaUse 结尾的附加字节数不固定，自动探测后记录到 XML
        fileSize = os.path.getsize(src)
        chosen = None
        for count in convert_ui.extra_byte_counts(versionNumber):
            uiFile.seek(10)
            convert_ui.TGAUSE_EXTRA_BYTES_SET(count)
            try:
                probe = UiEntry(versionNumber, 1)
                probe.readFrom(uiFile)
                if uiFile.tell() == fileSize:
                    chosen = count
                    break
            except Exception:
                continue
        if chosen is None:
            raise ValueError("无法识别该文件结构（解析未精确到达文件末尾）")

        with open(dst, "w", encoding="utf-8", newline="") as outFile:
            outFile.write("<ui>\n  <version>%03d</version>\n  <tgaUseExtraBytes>%d</tgaUseExtraBytes>\n"
                          % (versionNumber, chosen))
            uiFile.seek(10)
            convert_ui.TGAUSE_EXTRA_BYTES_SET(chosen)
            uiE = UiEntry(versionNumber, 1)
            uiE.readFrom(uiFile)
            uiE.writeToXML(outFile)
            outFile.write("</ui>\n")


def convert_xml_to_ui(src, dst):
    """把 XML 转换回 .ui 二进制文件。"""
    dom = parse(src)

    versionNodes = dom.getElementsByTagName("version")
    if not versionNodes:
        raise ValueError("XML 中缺少 <version> 节点")

    versionNode = versionNodes[0]
    if not versionNode.firstChild:
        raise ValueError("<version> 节点为空")

    versionStr = versionNode.firstChild.nodeValue.strip()
    try:
        versionInt = int(versionStr)
    except ValueError:
        raise ValueError("非法版本号：%r" % versionStr)

    # 找到 <uiEntry> 元素节点（跳过空白文本节点和附加的元数据节点）
    rootNode = versionNode.nextSibling
    while rootNode is not None and (rootNode.nodeType != rootNode.ELEMENT_NODE
                                    or rootNode.nodeName != "uiEntry"):
        rootNode = rootNode.nextSibling

    if rootNode is None:
        raise ValueError("XML 中找不到 uiEntry 节点")
    if rootNode.nodeName != "uiEntry":
        raise ValueError("期望 uiEntry 节点，实际为 %s" % rootNode.nodeName)

    root = UiEntry(versionInt, 0)
    root.constructFromNode(rootNode)

    extraNodes = dom.getElementsByTagName("tgaUseExtraBytes")
    if extraNodes:
        convert_ui.TGAUSE_EXTRA_BYTES_SET(int(extraNodes[0].firstChild.nodeValue))
    else:
        convert_ui.TGAUSE_EXTRA_BYTES_SET(convert_ui.DEFAULT_EXTRA_BYTES.get(versionInt, 0))

    versionBytes = ("%03d" % versionInt).encode("ascii")

    with open(dst, "wb", buffering=0) as raw:
        outFile = TypeCastWriter(raw)
        outFile.write(b"Version" + versionBytes)
        root.writeTo(outFile)
        outFile.flush()


# --------------------------------------------------------------------------
# GUI
# --------------------------------------------------------------------------

class ConverterApp:

    def __init__(self, root):
        self.root = root
        self.queue = queue.Queue()
        self.worker = None
        self.stop_flag = threading.Event()

        self._build_ui()
        self.root.after(80, self._drain_queue)

    # -------------------------- 界面构建 --------------------------

    def _build_ui(self):
        self.root.title("Total War UI 批量转换器")
        self.root.geometry("760x600")
        self.root.minsize(660, 480)

        main = ttk.Frame(self.root, padding=10)
        main.pack(fill="both", expand=True)

        # --- 输入文件夹 ---
        frm_in = ttk.LabelFrame(main, text="输入文件夹", padding=8)
        frm_in.pack(fill="x", pady=(0, 6))
        self.var_in = tk.StringVar()
        ttk.Entry(frm_in, textvariable=self.var_in).pack(
            side="left", fill="x", expand=True)
        ttk.Button(frm_in, text="浏览...", width=10,
                   command=self._choose_in).pack(side="left", padx=(6, 0))

        # --- 输出文件夹 ---
        frm_out = ttk.LabelFrame(main, text="输出文件夹", padding=8)
        frm_out.pack(fill="x", pady=(0, 6))
        self.var_out = tk.StringVar()
        ttk.Entry(frm_out, textvariable=self.var_out).pack(
            side="left", fill="x", expand=True)
        ttk.Button(frm_out, text="浏览...", width=10,
                   command=self._choose_out).pack(side="left", padx=(6, 0))

        # --- 选项 ---
        frm_opt = ttk.LabelFrame(main, text="转换选项", padding=8)
        frm_opt.pack(fill="x", pady=(0, 6))

        self.var_mode = tk.StringVar(value="u2x")
        ttk.Radiobutton(frm_opt, text="UI  →  XML",
                        variable=self.var_mode, value="u2x").pack(side="left")
        ttk.Radiobutton(frm_opt, text="XML →  UI",
                        variable=self.var_mode, value="x2u").pack(
                            side="left", padx=(18, 0))

        self.var_recurse = tk.BooleanVar(value=False)
        ttk.Checkbutton(frm_opt, text="包含子文件夹",
                        variable=self.var_recurse).pack(side="left", padx=(28, 0))

        self.var_keepstruct = tk.BooleanVar(value=True)
        ttk.Checkbutton(frm_opt, text="保持目录结构",
                        variable=self.var_keepstruct).pack(side="left", padx=(18, 0))

        # --- 按钮 + 进度条 ---
        frm_btn = ttk.Frame(main)
        frm_btn.pack(fill="x", pady=(0, 6))

        self.btn_start = ttk.Button(frm_btn, text="开始转换",
                                    width=12, command=self._start)
        self.btn_start.pack(side="left")

        self.btn_stop = ttk.Button(frm_btn, text="停止",
                                   width=8, command=self._stop,
                                   state="disabled")
        self.btn_stop.pack(side="left", padx=(6, 0))

        ttk.Button(frm_btn, text="打开输出目录", width=14,
                   command=self._open_output).pack(side="left", padx=(6, 0))

        self.progress = ttk.Progressbar(frm_btn, mode="determinate")
        self.progress.pack(side="left", fill="x", expand=True, padx=(12, 0))

        self.var_status = tk.StringVar(value="就绪")
        ttk.Label(main, textvariable=self.var_status,
                  anchor="w").pack(fill="x", pady=(0, 4))

        # --- 日志 ---
        frm_log = ttk.LabelFrame(main, text="日志", padding=4)
        frm_log.pack(fill="both", expand=True)

        self.txt = tk.Text(frm_log, wrap="word", height=16,
                           state="disabled", font=("Consolas", 9))
        sb = ttk.Scrollbar(frm_log, command=self.txt.yview)
        self.txt.configure(yscrollcommand=sb.set)
        sb.pack(side="right", fill="y")
        self.txt.pack(side="left", fill="both", expand=True)

        # 关闭窗口时尝试停止线程
        self.root.protocol("WM_DELETE_WINDOW", self._on_close)

    # -------------------------- 辅助 --------------------------

    def _log(self, msg):
        self.txt.configure(state="normal")
        self.txt.insert("end", msg + "\n")
        self.txt.see("end")
        self.txt.configure(state="disabled")

    def _set_status(self, msg):
        self.var_status.set(msg)

    def _choose_in(self):
        d = filedialog.askdirectory(title="选择输入文件夹")
        if d:
            self.var_in.set(d)
            if not self.var_out.get().strip():
                self.var_out.set(os.path.join(d, "output"))

    def _choose_out(self):
        d = filedialog.askdirectory(title="选择输出文件夹")
        if d:
            self.var_out.set(d)

    def _open_output(self):
        d = self.var_out.get().strip()
        if not d or not os.path.isdir(d):
            messagebox.showinfo("提示", "输出目录还不存在")
            return
        try:
            if os.name == "nt":
                os.startfile(d)          # noqa: S606 (Windows)
            elif sys_platform() == "darwin":
                os.system('open "%s"' % d)
            else:
                os.system('xdg-open "%s"' % d)
        except Exception as e:
            messagebox.showerror("错误", "无法打开目录：%s" % e)

    # -------------------------- 启动 / 停止 --------------------------

    def _start(self):
        if self.worker and self.worker.is_alive():
            return

        src_dir = self.var_in.get().strip()
        dst_dir = self.var_out.get().strip()

        if not src_dir or not os.path.isdir(src_dir):
            messagebox.showerror("错误", "请选择有效的输入文件夹")
            return
        if not dst_dir:
            messagebox.showerror("错误", "请选择输出文件夹")
            return

        # 避免输出到输入目录里再被扫描到（尤其递归时）
        try:
            if os.path.abspath(dst_dir).startswith(os.path.abspath(src_dir) + os.sep) \
               and self.var_recurse.get():
                if not messagebox.askyesno(
                        "确认",
                        "输出文件夹位于输入文件夹内部且启用了递归扫描，\n"
                        "可能会把上一次的输出再转换一遍。是否继续？"):
                    return
        except Exception:
            pass

        if not os.path.isdir(dst_dir):
            try:
                os.makedirs(dst_dir, exist_ok=True)
            except OSError as e:
                messagebox.showerror("错误", "无法创建输出文件夹：%s" % e)
                return

        mode = self.var_mode.get()
        recurse = self.var_recurse.get()
        keepstruct = self.var_keepstruct.get()

        files = self._collect_files(src_dir, recurse, mode)
        if not files:
            messagebox.showinfo("提示", "没有找到可转换的文件")
            return

        self.stop_flag.clear()
        self.progress.configure(maximum=len(files), value=0)
        self._log("=" * 66)
        self._log("输入目录：%s" % src_dir)
        self._log("输出目录：%s" % dst_dir)
        self._log("方向：%s   递归：%s   保持结构：%s   文件数：%d"
                  % ("UI -> XML" if mode == "u2x" else "XML -> UI",
                     "是" if recurse else "否",
                     "是" if keepstruct else "否",
                     len(files)))

        self.btn_start.configure(state="disabled")
        self.btn_stop.configure(state="normal")
        self._set_status("正在转换 ...")

        self.worker = threading.Thread(
            target=self._run_batch,
            args=(files, src_dir, dst_dir, mode, keepstruct),
            daemon=True,
        )
        self.worker.start()

    def _collect_files(self, src_dir, recurse, mode):
        files = []
        if recurse:
            for dirpath, _dirnames, filenames in os.walk(src_dir):
                for fn in filenames:
                    files.append(os.path.join(dirpath, fn))
        else:
            for fn in os.listdir(src_dir):
                p = os.path.join(src_dir, fn)
                if os.path.isfile(p):
                    files.append(p)

        if mode == "u2x":
            # UI -> XML：排除已经是 xml 的文件
            files = [f for f in files
                     if not f.lower().endswith(".xml")
                     and not os.path.basename(f).startswith(".")]
        else:
            # XML -> UI：只处理 .xml
            files = [f for f in files
                     if f.lower().endswith(".xml")
                     and not os.path.basename(f).startswith(".")]

        files.sort()
        return files

    def _stop(self):
        if self.worker and self.worker.is_alive():
            self.stop_flag.set()
            self._set_status("正在停止 ...")
            self._log(">> 收到停止请求，将在当前文件完成后中止")

    def _on_close(self):
        if self.worker and self.worker.is_alive():
            if not messagebox.askyesno("退出", "转换仍在进行，确定要退出吗？"):
                return
            self.stop_flag.set()
        self.root.destroy()

    # -------------------------- 工作线程 --------------------------

    def _run_batch(self, files, src_dir, dst_dir, mode, keepstruct):
        ok = 0
        fail = 0
        total = len(files)

        for idx, src in enumerate(files, 1):
            if self.stop_flag.is_set():
                self.queue.put(("log", ">> 已停止，剩余 %d 个文件未处理"
                                       % (total - idx + 1)))
                break

            rel = os.path.relpath(src, src_dir)

            if mode == "u2x":
                out_rel = rel + ".xml"
            else:
                out_rel = rel[:-4] if rel.lower().endswith(".xml") else rel

            if keepstruct:
                dst = os.path.join(dst_dir, out_rel)
            else:
                dst = os.path.join(dst_dir, os.path.basename(out_rel))

            try:
                parent = os.path.dirname(dst)
                if parent:
                    os.makedirs(parent, exist_ok=True)

                if mode == "u2x":
                    convert_ui_to_xml(src, dst)
                else:
                    convert_xml_to_ui(src, dst)

                ok += 1
                self.queue.put(("log", "[ OK ] %s" % rel))
            except Exception as e:
                fail += 1
                self.queue.put(("log", "[FAIL] %s  ->  %s: %s"
                                       % (rel, type(e).__name__, e)))
                if os.environ.get("GUI_CONVERT_DEBUG"):
                    self.queue.put(("log", traceback.format_exc()))

            self.queue.put(("progress", idx))
            self.queue.put(("status",
                            "进度 %d / %d   成功 %d  失败 %d"
                            % (idx, total, ok, fail)))

        self.queue.put(("done", (ok, fail)))

    # -------------------------- 消息泵 --------------------------

    def _drain_queue(self):
        try:
            while True:
                kind, payload = self.queue.get_nowait()

                if kind == "log":
                    self._log(payload)
                elif kind == "progress":
                    self.progress.configure(value=payload)
                elif kind == "status":
                    self._set_status(payload)
                elif kind == "done":
                    ok, fail = payload
                    self._log("-" * 66)
                    self._log("完成：成功 %d 个，失败 %d 个" % (ok, fail))
                    self._set_status("完成：成功 %d 个，失败 %d 个" % (ok, fail))
                    self.btn_start.configure(state="normal")
                    self.btn_stop.configure(state="disabled")
                    self.worker = None
        except queue.Empty:
            pass

        self.root.after(80, self._drain_queue)


def sys_platform():
    import sys
    return sys.platform


def main():
    root = tk.Tk()
    try:
        # 高 DPI（Windows）
        if os.name == "nt":
            from ctypes import windll
            windll.shcore.SetProcessDpiAwareness(1)
    except Exception:
        pass

    try:
        style = ttk.Style()
        if "vista" in style.theme_names():
            style.theme_use("vista")
        elif "clam" in style.theme_names():
            style.theme_use("clam")
    except Exception:
        pass

    ConverterApp(root)
    root.mainloop()


if __name__ == "__main__":
    main()