# -*- coding: utf-8 -*-
"""
TGA / DDS 文件清理工具（GUI）
功能：扫描并删除指定文件夹（可选含子文件夹）中所有 .tga 和 .dds 文件。
依赖：仅 Python 标准库（tkinter）
"""

import os
import tkinter as tk
from tkinter import ttk, filedialog, messagebox

TARGET_EXTS = (".tga", ".dds")   # 要删除的后缀（小写比较）


class CleanerApp:
    def __init__(self, root: tk.Tk):
        self.root = root
        self.root.title("TGA / DDS 文件清理工具")
        self.root.geometry("760x520")
        self.root.minsize(600, 400)

        self.found_files = []                      # 保存待删除文件的绝对路径
        self.folder_var = tk.StringVar()
        self.recursive_var = tk.BooleanVar(value=True)
        self.status_var = tk.StringVar(value="请选择文件夹后点击“扫描”")

        self._build_ui()

    # ---------------- 界面 ----------------
    def _build_ui(self):
        # 顶部：文件夹选择
        top = ttk.Frame(self.root, padding=10)
        top.pack(fill=tk.X)
        ttk.Label(top, text="目标文件夹：").pack(side=tk.LEFT)
        ttk.Entry(top, textvariable=self.folder_var).pack(
            side=tk.LEFT, fill=tk.X, expand=True, padx=(0, 6))
        ttk.Button(top, text="浏览…", command=self.choose_folder).pack(side=tk.LEFT)

        # 选项
        opt = ttk.Frame(self.root, padding=(10, 0))
        opt.pack(fill=tk.X)
        ttk.Checkbutton(opt, text="包含子文件夹（递归扫描）",
                        variable=self.recursive_var).pack(side=tk.LEFT)

        # 按钮区
        btns = ttk.Frame(self.root, padding=10)
        btns.pack(fill=tk.X)
        ttk.Button(btns, text="扫描", command=self.scan).pack(side=tk.LEFT)
        ttk.Button(btns, text="删除全部", command=self.delete_all).pack(side=tk.LEFT, padx=6)
        ttk.Button(btns, text="清空列表", command=self.clear_list).pack(side=tk.LEFT)

        # 文件列表
        mid = ttk.Frame(self.root, padding=(10, 0))
        mid.pack(fill=tk.BOTH, expand=True)
        ttk.Label(mid, text="匹配到的文件：").pack(anchor=tk.W)

        list_frame = ttk.Frame(mid)
        list_frame.pack(fill=tk.BOTH, expand=True, pady=(4, 0))
        scrollbar = ttk.Scrollbar(list_frame, orient=tk.VERTICAL)
        self.listbox = tk.Listbox(list_frame, yscrollcommand=scrollbar.set,
                                  selectmode=tk.EXTENDED, activestyle="none")
        scrollbar.config(command=self.listbox.yview)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        self.listbox.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)

        # 状态栏
        status = ttk.Frame(self.root, padding=(10, 6))
        status.pack(fill=tk.X)
        ttk.Label(status, textvariable=self.status_var, foreground="#555").pack(anchor=tk.W)

    # ---------------- 逻辑 ----------------
    def choose_folder(self):
        folder = filedialog.askdirectory(title="选择要清理的文件夹")
        if folder:
            self.folder_var.set(folder)

    def _iter_target_files(self, folder):
        """生成所有符合后缀条件的文件绝对路径"""
        if self.recursive_var.get():
            for dirpath, _dirnames, filenames in os.walk(folder):
                for name in filenames:
                    if name.lower().endswith(TARGET_EXTS):
                        yield os.path.join(dirpath, name)
        else:
            try:
                names = os.listdir(folder)
            except OSError as e:
                messagebox.showerror("错误", f"无法读取文件夹：\n{e}")
                return
            for name in names:
                path = os.path.join(folder, name)
                if os.path.isfile(path) and name.lower().endswith(TARGET_EXTS):
                    yield path

    def scan(self):
        folder = self.folder_var.get().strip()
        if not folder:
            messagebox.showwarning("提示", "请先选择目标文件夹。")
            return
        if not os.path.isdir(folder):
            messagebox.showerror("错误", f"文件夹不存在：\n{folder}")
            return

        self.clear_list()
        self.status_var.set("正在扫描…")
        self.root.update_idletasks()

        count = 0
        for path in self._iter_target_files(folder):
            self.found_files.append(path)
            try:
                shown = os.path.relpath(path, folder)
            except ValueError:
                shown = path
            self.listbox.insert(tk.END, shown)
            count += 1

        if count:
            self.status_var.set(
                f"共找到 {count} 个 .tga / .dds 文件，点击“删除全部”执行删除。")
        else:
            self.status_var.set("未找到 .tga / .dds 文件。")

    def delete_all(self):
        if not self.found_files:
            messagebox.showinfo("提示", "列表为空，请先点击“扫描”。")
            return

        total = len(self.found_files)
        if not messagebox.askyesno(
                "确认删除",
                f"确定要永久删除这 {total} 个文件吗？\n\n此操作不可撤销！"):
            return

        deleted = 0
        failed = []
        for path in self.found_files:
            try:
                os.remove(path)
                deleted += 1
            except OSError as e:
                failed.append((path, str(e)))

        self.clear_list()
        msg = f"删除完成：成功 {deleted} 个"
        if failed:
            msg += f"，失败 {len(failed)} 个"
        self.status_var.set(msg)

        if failed:
            detail = "\n".join(f"{p}\n    → {err}" for p, err in failed[:20])
            if len(failed) > 20:
                detail += f"\n… 另有 {len(failed) - 20} 个未显示"
            messagebox.showwarning("部分文件删除失败", f"{msg}\n\n{detail}")
        else:
            messagebox.showinfo("完成", msg)

    def clear_list(self):
        self.found_files.clear()
        self.listbox.delete(0, tk.END)


def main():
    # Windows 下开启高 DPI 支持，界面更清晰
    try:
        from ctypes import windll
        windll.shcore.SetProcessDpiAwareness(1)
    except Exception:
        pass

    root = tk.Tk()
    CleanerApp(root)
    root.mainloop()


if __name__ == "__main__":
    main()