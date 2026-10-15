#!/usr/bin/env python3
"""往返校验：UI -> XML -> UI 必须与原文件字节级完全一致。

用法： python roundtrip_test.py            （扫描默认目录 Desktop\\ui）
      python roundtrip_test.py D:\\path    （扫描指定目录）
"""
import os, sys, collections, traceback

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import convert_ui

SRC = sys.argv[1] if len(sys.argv) > 1 else r"C:\Users\Administrator\Desktop\ui"
TMP = os.path.join(os.path.dirname(os.path.abspath(__file__)), "_rt_tmp")
os.makedirs(TMP, exist_ok=True)


def first_diff(a, b):
    for i, (x, y) in enumerate(zip(a, b)):
        if x != y:
            return i
    return min(len(a), len(b))


stats = {}
fails = []
total = 0
for root, dirs, files in os.walk(SRC):
    for fn in files:
        p = os.path.join(root, fn)
        if os.path.splitext(fn)[1]:
            continue
        try:
            with open(p, "rb") as f:
                hdr = f.read(10)
        except OSError:
            continue
        if not hdr.startswith(b"Version"):
            continue
        ver = hdr[7:10].decode()
        total += 1
        ok, err = False, ""
        try:
            xmlf = os.path.join(TMP, "t.xml")
            uif = os.path.join(TMP, "t.ui")
            convert_ui.convertUIToXML(p, xmlf)
            convert_ui.convertXMLToUI(xmlf, uif)
            orig = open(p, "rb").read()
            new = open(uif, "rb").read()
            if orig == new:
                ok = True
            else:
                d = first_diff(orig, new)
                err = ("字节不一致 @%#x (原 %s / 新 %s, 长度 %d/%d)"
                       % (d, orig[d:d + 8].hex(), new[d:d + 8].hex(), len(orig), len(new)))
        except Exception as e:
            err = "%s: %s" % (type(e).__name__, e)
            if os.environ.get("RT_VERBOSE"):
                traceback.print_exc()
        s = stats.setdefault(ver, [0, 0])
        s[1] += 1
        if ok:
            s[0] += 1
        else:
            fails.append((ver, p, err))

print("%-6s%6s%8s" % ("版本", "通过", "总数"))
for ver in sorted(stats):
    print("%-8s%5d%8d" % (ver, stats[ver][0], stats[ver][1]))
print("\n合计: %d/%d 字节级完全一致" % (sum(s[0] for s in stats.values()), total))
if fails:
    print("\n失败清单:")
    for ver, p, err in fails:
        print("  [%s] %s\n         %s" % (ver, p, err))
