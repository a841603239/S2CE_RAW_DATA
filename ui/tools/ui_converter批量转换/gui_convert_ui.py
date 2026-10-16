#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Total War UI 转换器（单文件版）

命令行：
  python convert_ui.py -u  uifile      uifile.xml
  python convert_ui.py -x  uifile.xml  uifile
  python convert_ui.py -ua             (批量：当前目录 -> ./output)
  python convert_ui.py -xa             (批量：当前目录 -> ./uiOutput)
  python convert_ui.py -uar            (递归：当前目录树 -> ./output)
  python convert_ui.py -xar            (递归：当前目录树 -> ./uiOutput)

无参数运行 → GUI（默认：单文件模式 / XML → UI）

说明：
  - UI 文件是二进制，约定没有扩展名。
  - XML 文件带 .xml 后缀。
  - XML -> UI 时输出文件名 = 去掉 .xml；
    UI -> XML 时输出文件名 = 原文件名 + .xml。

P0 修复要点：
  - 解析 XML 时统一走 _node_text / _node_int / _node_num，
    空节点或缺失属性不再崩溃。
  - 移除全局 TGAUSE_EXTRA_BYTES；extra_bytes 随对象树传递，线程安全。
  - 二进制写出 / XML 中的 num 属性均用 len(list)，不再与 numXxx 失配。
  - CLI 递归扫描用 with open；-ua / -xa 增加单文件错误隔离。

GUI 增强：
  - 单文件模式为默认模式。
  - 默认转换方向为 XML → UI。
  - 文件选择器返回后立刻校对后缀：
      * UI → XML：源必须非 .xml，目标自动补 .xml。
      * XML → UI：源必须 .xml，目标去掉 .xml（询问）。
  - 切换方向时自动重新校对已选源文件。
"""

import io
import os
import sys
import base64
import struct
import queue
import threading
import traceback
from xml.dom.minidom import parse

# ==========================================================================
# 常量
# ==========================================================================

RAW_STRING_MARKER = "\x01base64:"

DEFAULT_EXTRA_BYTES = {58: 2, 60: 2, 61: 3, 62: 3, 63: 3}

SUPPORTED_VERSIONS = {29, 32, 33, 39, 43, 44, 46, 47, 49, 50, 51, 52,
                      54, 55, 56, 57, 58, 60, 61, 62, 63}


def _default_extra_bytes(version):
    """按版本推导 TGAUses.extraFlags 的字节数。"""
    return DEFAULT_EXTRA_BYTES.get(version, 0 if version < 58 else 3)


def extra_byte_counts(version):
    """返回该版本下尝试解析的 extra bytes 候选（默认值优先）。"""
    default = _default_extra_bytes(version)
    others = [n for n in (3, 2, 1, 0) if n != default]
    return [default] + others


# ==========================================================================
# 字符串编解码
# ==========================================================================

def _raw_to_xml(raw):
    if any(c < 0x20 and c not in (9, 10, 13) for c in raw):
        return RAW_STRING_MARKER + base64.b64encode(raw).decode("ascii")
    string = raw.decode("latin-1")
    out = []
    for ch in string:
        if ch == "&":
            out.append("&amp;")
        elif ch == "<":
            out.append("&lt;")
        elif ch == ">":
            out.append("&gt;")
        elif ch == "\r":
            out.append("&#x0D;")
        else:
            out.append(ch)
    return "".join(out)


def _xml_to_raw(string):
    if string.startswith(RAW_STRING_MARKER):
        return base64.b64decode(string[len(RAW_STRING_MARKER):])
    return string.encode("latin-1", "replace")


def _utf16_to_xml(raw):
    string = raw.decode("utf-16-le", "replace")
    if any(ord(c) < 0x20 and c not in ("\t", "\n", "\r") for c in string):
        return RAW_STRING_MARKER + base64.b64encode(raw).decode("ascii")
    return (string.replace("&", "&amp;")
                  .replace("<", "&lt;")
                  .replace(">", "&gt;")
                  .replace("\r", "&#x0D;"))


def _xml_to_utf16(string):
    if string.startswith(RAW_STRING_MARKER):
        return base64.b64decode(string[len(RAW_STRING_MARKER):])
    return string.encode("utf-16-le")


# ==========================================================================
# XML 辅助
# ==========================================================================

def _node_text(node, default=""):
    """安全读取节点的文本内容；空节点返回 default。"""
    return node.firstChild.data if node.firstChild else default


def _node_int(node, default=0):
    """安全地把节点文本转 int；空节点返回 default。"""
    if node.firstChild is None:
        return default
    text = node.firstChild.data.strip()
    return int(text) if text else default


def _attr_text(node, name, default=""):
    """安全读取节点属性文本。"""
    if not node.attributes:
        return default
    attr = node.attributes.getNamedItem(name)
    if attr is None or attr.firstChild is None:
        return default
    return attr.firstChild.data


def _attr_int(node, name, default=0):
    text = _attr_text(node, name, "").strip()
    return int(text) if text else default


def _node_num(node, default=0):
    """安全读取节点上的 num 属性。"""
    return _attr_int(node, "num", default)


# ==========================================================================
# 读写器
# ==========================================================================

class TypeCastReader(io.BufferedReader):
    def readByte(self):
        return struct.unpack("B", self.read(1))[0]

    def readInt(self):
        return struct.unpack("i", self.read(4))[0]

    def readUInt(self):
        return struct.unpack("I", self.read(4))[0]

    def readShort(self):
        return struct.unpack("h", self.read(2))[0]

    def readUShort(self):
        return struct.unpack("H", self.read(2))[0]

    def readFloat(self):
        return struct.unpack("f", self.read(4))[0]

    def readDouble(self):
        return struct.unpack("d", self.read(8))[0]

    def readBool(self):
        return self.read(1) != b"\x00"

    def readUTF16(self):
        length = self.readUShort()
        return _utf16_to_xml(self.read(length * 2))

    def readASCII(self):
        length = self.readUShort()
        return _raw_to_xml(self.read(length))


class TypeCastWriter(io.BufferedWriter):
    def writeByte(self, arg):
        self.write(struct.pack("B", arg))

    def writeInt(self, arg):
        self.write(struct.pack("i", arg))

    def writeUInt(self, arg):
        self.write(struct.pack("I", arg))

    def writeShort(self, arg):
        self.write(struct.pack("h", arg))

    def writeUShort(self, arg):
        self.write(struct.pack("H", arg))

    def writeFloat(self, arg):
        self.write(struct.pack("f", arg))

    def writeDouble(self, arg):
        self.write(struct.pack("d", arg))

    def writeBool(self, arg):
        self.write(b"\x01" if arg else b"\x00")

    def writeUTF16(self, arg):
        self.writeUShort(len(arg))
        self.write(_xml_to_utf16(arg))

    def writeASCII(self, arg):
        data = _xml_to_raw(arg)
        self.writeUShort(len(data))
        self.write(data)


class DebuggableConverter:
    def indented_print(self, s, handle):
        print("%s%s (%x)" % (" " * self.indent, s, handle.tell()))

    def debug(self, name, handle):
        print("%s%s.%s=%s (%x)" % (" " * self.indent, type(self).__name__,
                                   name, self.__dict__[name], handle.tell()))


# ==========================================================================
# 数据结构
# ==========================================================================

class TgaEntry(DebuggableConverter):
    def __init__(self, version, indent):
        self.version = version
        self.indent = indent
        self.id = 0
        self.path = ""
        self.width = 0
        self.height = 0
        self.int1 = 0
        self.color1 = 0
        self.color2 = 0

    def readFrom(self, handle):
        self.id = handle.readInt()
        self.path = handle.readASCII()
        self.width = handle.readInt()
        self.height = handle.readInt()
        self.int1 = handle.readInt()
        if self.version >= 55:
            self.color1 = handle.readInt()
            self.color2 = handle.readInt()

    def writeTo(self, handle):
        handle.writeInt(self.id)
        handle.writeASCII(self.path)
        handle.writeInt(self.width)
        handle.writeInt(self.height)
        handle.writeInt(self.int1)
        if self.version >= 55:
            handle.writeInt(self.color1)
            handle.writeInt(self.color2)

    def writeToXML(self, handle):
        handle.write(
            "%(i)s<tga>\n"
            "%(i1)s<id>%(id)i</id>\n"
            "%(i1)s<path>%(path)s</path>\n"
            "%(i1)s<width>%(w)i</width>\n"
            "%(i1)s<height>%(h)i</height>\n"
            "%(i1)s<int1>%(int1)i</int1>\n"
            "%(i1)s<color1>%(c1)i</color1>\n"
            "%(i1)s<color2>%(c2)i</color2>\n"
            "%(i)s</tga>\n"
            % {"i": "  " * self.indent, "i1": "  " * (self.indent + 1),
               "id": self.id, "path": self.path, "w": self.width,
               "h": self.height, "int1": self.int1,
               "c1": self.color1, "c2": self.color2})

    def constructFromNode(self, node):
        if node.nodeName != "tga":
            raise Exception("Not a tga node")
        for child in node.childNodes:
            if child.nodeName == "id":
                self.id = _node_int(child)
            elif child.nodeName == "path":
                self.path = _node_text(child, self.path)
            elif child.nodeName == "width":
                self.width = _node_int(child)
            elif child.nodeName == "height":
                self.height = _node_int(child)
            elif child.nodeName == "int1":
                self.int1 = _node_int(child)
            elif child.nodeName == "color1":
                self.color1 = _node_int(child)
            elif child.nodeName == "color2":
                self.color2 = _node_int(child)


class TgaUse(DebuggableConverter):
    def __init__(self, version, indent, extra_bytes=None):
        self.version = version
        self.indent = indent
        if extra_bytes is None:
            extra_bytes = _default_extra_bytes(version)
        self.extra_bytes = extra_bytes

        self.id = 0
        self.xOff = 0
        self.yOff = 0
        self.width = 0
        self.height = 0
        self.redMultiply = 0
        self.greenMultiply = 0
        self.blueMultiply = 0
        self.alphaMultiply = 0
        self.flag1 = 0
        self.flag2 = 0
        self.flag3 = 0
        self.position = 0
        self.flag4 = 0
        self.flag5 = 0
        self.int1 = 0
        self.int2 = 0
        self.int3 = 0
        self.flag6 = 0
        self.extraFlags = []

    def readFrom(self, handle):
        self.id = handle.readInt()
        self.xOff = handle.readInt()
        self.yOff = handle.readInt()
        self.width = handle.readInt()
        self.height = handle.readInt()
        self.blueMultiply = handle.readByte()
        self.greenMultiply = handle.readByte()
        self.redMultiply = handle.readByte()
        self.alphaMultiply = handle.readByte()
        self.flag1 = handle.readByte()
        self.flag2 = handle.readByte()
        self.flag3 = handle.readByte()
        self.position = handle.readInt()
        self.flag4 = handle.readByte()
        self.flag5 = handle.readByte()
        self.int1 = handle.readInt()
        self.int2 = handle.readInt()
        self.int3 = handle.readInt()
        if self.version >= 51:
            self.flag6 = handle.readByte()
        if self.version >= 58:
            self.extraFlags = [handle.readByte() for _ in range(self.extra_bytes)]

    def writeTo(self, handle):
        handle.writeInt(self.id)
        handle.writeInt(self.xOff)
        handle.writeInt(self.yOff)
        handle.writeInt(self.width)
        handle.writeInt(self.height)
        handle.writeByte(self.blueMultiply)
        handle.writeByte(self.greenMultiply)
        handle.writeByte(self.redMultiply)
        handle.writeByte(self.alphaMultiply)
        handle.writeByte(self.flag1)
        handle.writeByte(self.flag2)
        handle.writeByte(self.flag3)
        handle.writeInt(self.position)
        handle.writeByte(self.flag4)
        handle.writeByte(self.flag5)
        handle.writeInt(self.int1)
        handle.writeInt(self.int2)
        handle.writeInt(self.int3)
        if self.version >= 51:
            handle.writeByte(self.flag6)
        if self.version >= 58:
            flags = list(self.extraFlags[:self.extra_bytes])
            flags += [0] * (self.extra_bytes - len(flags))
            for num in flags:
                handle.writeByte(num)

    def writeToXML(self, handle):
        handle.write(
            "%(i)s<tgaUse>\n"
            "%(i1)s<id>%(id)i</id>\n"
            "%(i1)s<xOff>%(x)i</xOff>\n"
            "%(i1)s<yOff>%(y)i</yOff>\n"
            "%(i1)s<width>%(w)i</width>\n"
            "%(i1)s<height>%(h)i</height>\n"
            "%(i1)s<blueMultiply>%(b)i</blueMultiply>\n"
            "%(i1)s<greenMultiply>%(g)i</greenMultiply>\n"
            "%(i1)s<redMultiply>%(r)i</redMultiply>\n"
            "%(i1)s<alphaMultiply>%(a)i</alphaMultiply>\n"
            "%(i1)s<flag1>%(f1)i</flag1>\n"
            "%(i1)s<mirror_horizontally>%(f2)i</mirror_horizontally>\n"
            "%(i1)s<mirror_vertically>%(f3)i</mirror_vertically>\n"
            "%(i1)s<position>%(pos)i</position>\n"
            "%(i1)s<stretches_horizontally>%(f4)i</stretches_horizontally>\n"
            "%(i1)s<stretches_vertically>%(f5)i</stretches_vertically>\n"
            "%(i1)s<int1>%(n1)i</int1>\n"
            "%(i1)s<int2>%(n2)i</int2>\n"
            "%(i1)s<int3>%(n3)i</int3>\n"
            "%(i1)s<flag6>%(f6)i</flag6>\n"
            "%(i1)s<extraFlags>%(ef)s</extraFlags>\n"
            "%(i)s</tgaUse>\n"
            % {"i": "  " * self.indent, "i1": "  " * (self.indent + 1),
               "id": self.id, "x": self.xOff, "y": self.yOff,
               "w": self.width, "h": self.height,
               "b": self.blueMultiply, "g": self.greenMultiply,
               "r": self.redMultiply, "a": self.alphaMultiply,
               "f1": self.flag1, "f2": self.flag2, "f3": self.flag3,
               "pos": self.position, "f4": self.flag4, "f5": self.flag5,
               "n1": self.int1, "n2": self.int2, "n3": self.int3,
               "f6": self.flag6,
               "ef": " ".join(map(str, self.extraFlags))})

    def constructFromNode(self, node):
        if node.nodeName != "tgaUse":
            raise Exception("Not a tgaUse node")
        for child in node.childNodes:
            if child.nodeName == "id":
                self.id = _node_int(child)
            elif child.nodeName == "xOff":
                self.xOff = _node_int(child)
            elif child.nodeName == "yOff":
                self.yOff = _node_int(child)
            elif child.nodeName == "width":
                self.width = _node_int(child)
            elif child.nodeName == "height":
                self.height = _node_int(child)
            elif child.nodeName == "blueMultiply":
                self.blueMultiply = _node_int(child)
            elif child.nodeName == "greenMultiply":
                self.greenMultiply = _node_int(child)
            elif child.nodeName == "redMultiply":
                self.redMultiply = _node_int(child)
            elif child.nodeName == "alphaMultiply":
                self.alphaMultiply = _node_int(child)
            elif child.nodeName == "flag1":
                self.flag1 = _node_int(child)
            elif child.nodeName == "mirror_horizontally":
                self.flag2 = _node_int(child)
            elif child.nodeName == "mirror_vertically":
                self.flag3 = _node_int(child)
            elif child.nodeName == "position":
                self.position = _node_int(child)
            elif child.nodeName == "stretches_horizontally":
                self.flag4 = _node_int(child)
            elif child.nodeName == "stretches_vertically":
                self.flag5 = _node_int(child)
            elif child.nodeName == "int1":
                self.int1 = _node_int(child)
            elif child.nodeName == "int2":
                self.int2 = _node_int(child)
            elif child.nodeName == "int3":
                self.int3 = _node_int(child)
            elif child.nodeName == "flag6":
                self.flag6 = _node_int(child)
            elif child.nodeName == "extraFlags":
                text = _node_text(child).strip()
                self.extraFlags = [int(x) for x in text.split()] if text else []


class Transition(DebuggableConverter):
    def __init__(self, version, indent):
        self.version = version
        self.indent = indent
        self.type = 0
        self.id = 0
        self.str1 = ""
        self.int1 = 0
        self.int2 = 0
        self.str2 = ""
        self.int3 = 0

    def readFrom(self, handle):
        self.type = handle.readInt()
        self.id = handle.readInt()
        if self.version >= 39:
            self.str1 = handle.readASCII()
            self.int1 = handle.readInt()
            self.int2 = handle.readInt()
        if self.version >= 43:
            self.str2 = handle.readASCII()
            self.int3 = handle.readInt()

    def writeTo(self, handle):
        handle.writeInt(self.type)
        handle.writeInt(self.id)
        if self.version >= 39:
            handle.writeASCII(self.str1)
            handle.writeInt(self.int1)
            handle.writeInt(self.int2)
        if self.version >= 43:
            handle.writeASCII(self.str2)
            handle.writeInt(self.int3)

    def writeToXML(self, handle):
        handle.write(
            "%(i)s<transition>\n"
            "%(i1)s<type>%(t)i</type>\n"
            "%(i1)s<stateIDRef>%(id)i</stateIDRef>\n"
            "%(i1)s<str1>%(s1)s</str1>\n"
            "%(i1)s<int1>%(n1)i</int1>\n"
            "%(i1)s<int2>%(n2)i</int2>\n"
            "%(i1)s<str2>%(s2)s</str2>\n"
            "%(i1)s<int3>%(n3)i</int3>\n"
            "%(i)s</transition>\n"
            % {"i": "  " * self.indent, "i1": "  " * (self.indent + 1),
               "t": self.type, "id": self.id,
               "s1": self.str1, "s2": self.str2,
               "n1": self.int1, "n2": self.int2, "n3": self.int3})

    def constructFromNode(self, node):
        if node.nodeName != "transition":
            raise Exception("Not a transition node")
        for child in node.childNodes:
            if child.nodeName == "type":
                self.type = _node_int(child)
            elif child.nodeName == "stateIDRef":
                self.id = _node_int(child)
            elif child.nodeName == "str1":
                self.str1 = _node_text(child, self.str1)
            elif child.nodeName == "str2":
                self.str2 = _node_text(child, self.str2)
            elif child.nodeName == "int1":
                self.int1 = _node_int(child)
            elif child.nodeName == "int2":
                self.int2 = _node_int(child)
            elif child.nodeName == "int3":
                self.int3 = _node_int(child)


class Effect(DebuggableConverter):
    def __init__(self, version, indent):
        self.version = version
        self.indent = indent
        self.name = None
        self.flag = 0
        self.phases = []

    def readFrom(self, handle):
        self.name = handle.readASCII()
        self.flag = handle.readShort()
        phase_count = handle.readInt()
        for _ in range(phase_count):
            phase = [handle.readFloat(), handle.readFloat()]
            if self.version >= 50:
                for _ in range(13):
                    phase.append(handle.readInt())
                if self.version >= 58:
                    phase.append(handle.readByte())
            else:
                for _ in range(10):
                    phase.append(handle.readInt())
            self.phases.append(phase)

    def writeTo(self, handle):
        handle.writeASCII(self.name)
        handle.writeShort(self.flag)
        handle.writeInt(len(self.phases))
        for phase in self.phases:
            handle.writeFloat(phase[0])
            handle.writeFloat(phase[1])
            if self.version >= 58:
                for num in phase[2:-1]:
                    handle.writeInt(num)
                handle.writeByte(phase[-1])
            else:
                for num in phase[2:]:
                    handle.writeInt(num)

    def writeToXML(self, handle):
        handle.write("%(i)s<effect>\n"
                     "%(i1)s<name>%(name)s</name>\n"
                     "%(i1)s<flag>%(flag)s</flag>\n"
                     % {"i": "  " * self.indent,
                        "i1": "  " * (self.indent + 1),
                        "name": self.name, "flag": self.flag})
        for phase in self.phases:
            handle.write("%(i1)s<phase>%(p)s</phase>\n"
                         % {"i1": "  " * (self.indent + 1),
                            "p": " ".join(map(str, phase))})
        handle.write("%(i)s</effect>\n" % {"i": "  " * self.indent})

    def constructFromNode(self, node):
        if node.nodeName != "effect":
            raise Exception("Not a effect node")
        for child in node.childNodes:
            if child.nodeName == "name":
                self.name = _node_text(child, self.name if self.name else "")
            elif child.nodeName == "flag":
                self.flag = _node_int(child)
            elif child.nodeName == "phase":
                data = _node_text(child).split()
                if len(data) < 2:
                    raise ValueError("phase 节点数据不足: %r" % (data,))
                phase = [float(data[0]), float(data[1])] + list(map(int, data[2:]))
                self.phases.append(phase)


class State(DebuggableConverter):
    def __init__(self, version, indent, extra_bytes=None):
        self.version = version
        self.indent = indent
        if extra_bytes is None:
            extra_bytes = _default_extra_bytes(version)
        self.extra_bytes = extra_bytes

        self.title = ""
        self.twui = ""
        self.TGAUses = []
        self.transitions = []
        self.stateText = ""
        self.tooltip = ""
        self.localisationID = ""
        self.tooltipID = ""
        self.stateDescription = ""
        self.eventText = ""
        self.fontColor = 0

        self.id = 0
        self.width = 0
        self.height = 0
        self.int7 = self.int8 = self.int9 = self.int10 = self.int11 = 0
        self.flag7 = 0
        self.font = ""
        self.int12 = self.int13 = self.int14 = 0
        self.int15 = self.int16 = self.int17 = 0
        self.flag8 = self.flag9 = self.flag10 = 0
        self.normalt0 = ""
        self.int18 = self.int19 = self.int20 = self.int21 = 0
        self.numTGAUses = 0
        self.int23 = self.int24 = 0
        self.numTransitions = 0

    def readFrom(self, handle):
        self.id = handle.readInt()
        self.title = handle.readASCII()
        self.width = handle.readInt()
        self.height = handle.readInt()
        self.stateText = handle.readUTF16()
        self.tooltip = handle.readUTF16()
        self.int7 = handle.readInt()
        self.int8 = handle.readInt()
        self.int9 = handle.readInt()
        self.int10 = handle.readInt()
        self.int11 = handle.readInt()
        self.flag7 = handle.readByte()
        self.localisationID = handle.readUTF16()
        self.tooltipID = handle.readUTF16()
        self.font = handle.readASCII()
        self.int12 = handle.readInt()
        self.int13 = handle.readInt()
        self.int14 = handle.readInt()
        if self.version >= 62:
            self.fontColor = handle.readInt()
        if self.version >= 43:
            self.twui = handle.readASCII()
        self.int15 = handle.readInt()
        self.int16 = handle.readInt()
        self.int17 = handle.readInt()
        self.flag8 = handle.readByte()
        self.flag9 = handle.readByte()
        self.flag10 = handle.readByte()
        self.normalt0 = handle.readASCII()
        self.int18 = handle.readInt()
        self.int19 = handle.readInt()
        self.int20 = handle.readInt()
        self.int21 = handle.readInt()
        self.stateDescription = handle.readASCII()
        self.eventText = handle.readASCII()

        self.numTGAUses = handle.readInt()
        for _ in range(self.numTGAUses):
            tu = TgaUse(self.version, self.indent + 2, self.extra_bytes)
            tu.readFrom(handle)
            self.TGAUses.append(tu)

        self.int23 = handle.readInt()
        self.int24 = handle.readInt()

        self.numTransitions = handle.readInt()
        for _ in range(self.numTransitions):
            tr = Transition(self.version, self.indent + 2)
            tr.readFrom(handle)
            self.transitions.append(tr)

    def writeTo(self, handle):
        handle.writeInt(self.id)
        handle.writeASCII(self.title)
        handle.writeInt(self.width)
        handle.writeInt(self.height)
        handle.writeUTF16(self.stateText)
        handle.writeUTF16(self.tooltip)
        handle.writeInt(self.int7)
        handle.writeInt(self.int8)
        handle.writeInt(self.int9)
        handle.writeInt(self.int10)
        handle.writeInt(self.int11)
        handle.writeByte(self.flag7)
        handle.writeUTF16(self.localisationID)
        handle.writeUTF16(self.tooltipID)
        handle.writeASCII(self.font)
        handle.writeInt(self.int12)
        handle.writeInt(self.int13)
        handle.writeInt(self.int14)
        if self.version >= 62:
            handle.writeInt(self.fontColor)
        if self.version >= 43:
            handle.writeASCII(self.twui)
        handle.writeInt(self.int15)
        handle.writeInt(self.int16)
        handle.writeInt(self.int17)
        handle.writeByte(self.flag8)
        handle.writeByte(self.flag9)
        handle.writeByte(self.flag10)
        handle.writeASCII(self.normalt0)
        handle.writeInt(self.int18)
        handle.writeInt(self.int19)
        handle.writeInt(self.int20)
        handle.writeInt(self.int21)
        handle.writeASCII(self.stateDescription)
        handle.writeASCII(self.eventText)

        # P0 修复：写出时用 len() 而非 self.numTGAUses
        handle.writeInt(len(self.TGAUses))
        for tu in self.TGAUses:
            tu.writeTo(handle)

        handle.writeInt(self.int23)
        handle.writeInt(self.int24)

        # P0 修复：同上
        handle.writeInt(len(self.transitions))
        for tr in self.transitions:
            tr.writeTo(handle)

    def writeToXML(self, handle):
        handle.write("""%(i)s<state>
%(i1)s<id>%(id)i</id>
%(i1)s<title>%(title)s</title>
%(i1)s<width>%(w)i</width>
%(i1)s<height>%(h)i</height>
%(i1)s<stateText>%(stateText)s</stateText>
%(i1)s<tooltip>%(tooltip)s</tooltip>
%(i1)s<int7>%(n7)i</int7>
%(i1)s<int8>%(n8)i</int8>
%(i1)s<int9>%(n9)i</int9>
%(i1)s<int10>%(n10)i</int10>
%(i1)s<int11>%(n11)i</int11>
%(i1)s<flag7>%(f7)i</flag7>
%(i1)s<localisationID>%(loc)s</localisationID>
%(i1)s<tooltipID>%(tid)s</tooltipID>
%(i1)s<font>%(font)s</font>
%(i1)s<int12>%(n12)i</int12>
%(i1)s<int13>%(n13)i</int13>
%(i1)s<textAlphaMultiply>%(n14)i</textAlphaMultiply>
%(i1)s<fontColor>%(fc)i</fontColor>
%(i1)s<twui>%(twui)s</twui>
%(i1)s<int15>%(n15)i</int15>
%(i1)s<int16>%(n16)i</int16>
%(i1)s<int17>%(n17)i</int17>
%(i1)s<flag8>%(f8)i</flag8>
%(i1)s<flag9>%(f9)i</flag9>
%(i1)s<flag10>%(f10)i</flag10>
%(i1)s<normalt0>%(normalt0)s</normalt0>
%(i1)s<int18>%(n18)i</int18>
%(i1)s<int19>%(n19)i</int19>
%(i1)s<int20>%(n20)i</int20>
%(i1)s<int21>%(n21)i</int21>
%(i1)s<stateDescription>%(sd)s</stateDescription>
%(i1)s<eventText>%(et)s</eventText>
%(i1)s<tgaUses num="%(numTU)i">
""" % {"i": "  " * self.indent, "i1": "  " * (self.indent + 1),
            "id": self.id, "title": self.title, "w": self.width, "h": self.height,
            "stateText": self.stateText, "tooltip": self.tooltip,
            "n7": self.int7, "n8": self.int8, "n9": self.int9,
            "n10": self.int10, "n11": self.int11, "f7": self.flag7,
            "loc": self.localisationID, "tid": self.tooltipID, "font": self.font,
            "n12": self.int12, "n13": self.int13, "n14": self.int14,
            "fc": self.fontColor, "twui": self.twui,
            "n15": self.int15, "n16": self.int16, "n17": self.int17,
            "f8": self.flag8, "f9": self.flag9, "f10": self.flag10,
            "normalt0": self.normalt0,
            "n18": self.int18, "n19": self.int19, "n20": self.int20, "n21": self.int21,
            "sd": self.stateDescription, "et": self.eventText,
            # P0：num 与列表长度对齐
            "numTU": len(self.TGAUses)})

        for tu in self.TGAUses:
            tu.writeToXML(handle)

        handle.write("""%(i1)s</tgaUses>
%(i1)s<int23>%(n23)i</int23>
%(i1)s<int24>%(n24)i</int24>
%(i1)s<transitions num="%(numTr)s">
""" % {"i1": "  " * (self.indent + 1),
            "n23": self.int23, "n24": self.int24,
            # P0：num 与列表长度对齐
            "numTr": len(self.transitions)})

        for tr in self.transitions:
            tr.writeToXML(handle)

        handle.write("%(i1)s</transitions>\n%(i)s</state>\n"
                     % {"i": "  " * self.indent,
                        "i1": "  " * (self.indent + 1)})

    def constructFromNode(self, node):
        if node.nodeName != "state":
            raise Exception("Not a state node")
        for child in node.childNodes:
            if child.nodeName == "id":
                self.id = _node_int(child)
            elif child.nodeName == "title":
                self.title = _node_text(child, self.title)
            elif child.nodeName == "width":
                self.width = _node_int(child)
            elif child.nodeName == "height":
                self.height = _node_int(child)
            elif child.nodeName == "stateText":
                self.stateText = _node_text(child, self.stateText)
            elif child.nodeName == "tooltip":
                self.tooltip = _node_text(child, self.tooltip)
            elif child.nodeName == "int7":
                self.int7 = _node_int(child)
            elif child.nodeName == "int8":
                self.int8 = _node_int(child)
            elif child.nodeName == "int9":
                self.int9 = _node_int(child)
            elif child.nodeName == "int10":
                self.int10 = _node_int(child)
            elif child.nodeName == "int11":
                self.int11 = _node_int(child)
            elif child.nodeName == "flag7":
                self.flag7 = _node_int(child)
            elif child.nodeName == "localisationID":
                self.localisationID = _node_text(child, self.localisationID)
            elif child.nodeName == "tooltipID":
                self.tooltipID = _node_text(child, self.tooltipID)
            elif child.nodeName == "font":
                self.font = _node_text(child, self.font)
            elif child.nodeName == "int12":
                self.int12 = _node_int(child)
            elif child.nodeName == "int13":
                self.int13 = _node_int(child)
            elif child.nodeName == "textAlphaMultiply":
                self.int14 = _node_int(child)
            elif child.nodeName == "fontColor":
                self.fontColor = _node_int(child)
            elif child.nodeName == "twui":
                self.twui = _node_text(child, self.twui)
            elif child.nodeName == "int15":
                self.int15 = _node_int(child)
            elif child.nodeName == "int16":
                self.int16 = _node_int(child)
            elif child.nodeName == "int17":
                self.int17 = _node_int(child)
            elif child.nodeName == "flag8":
                self.flag8 = _node_int(child)
            elif child.nodeName == "flag9":
                self.flag9 = _node_int(child)
            elif child.nodeName == "flag10":
                self.flag10 = _node_int(child)
            elif child.nodeName == "normalt0":
                self.normalt0 = _node_text(child, self.normalt0)
            elif child.nodeName == "int18":
                self.int18 = _node_int(child)
            elif child.nodeName == "int19":
                self.int19 = _node_int(child)
            elif child.nodeName == "int20":
                self.int20 = _node_int(child)
            elif child.nodeName == "int21":
                self.int21 = _node_int(child)
            elif child.nodeName == "stateDescription":
                self.stateDescription = _node_text(child, self.stateDescription)
            elif child.nodeName == "eventText":
                self.eventText = _node_text(child, self.eventText)
            elif child.nodeName == "tgaUses":
                # P0：num 属性缺失不再崩溃
                self.numTGAUses = _node_num(child)
                for tuNode in child.childNodes:
                    if tuNode.nodeName == "tgaUse":
                        tu = TgaUse(self.version, self.indent, self.extra_bytes)
                        tu.constructFromNode(tuNode)
                        self.TGAUses.append(tu)
            elif child.nodeName == "int23":
                self.int23 = _node_int(child)
            elif child.nodeName == "int24":
                self.int24 = _node_int(child)
            elif child.nodeName == "transitions":
                self.numTransitions = _node_num(child)
                for trNode in child.childNodes:
                    if trNode.nodeName == "transition":
                        tr = Transition(self.version, self.indent)
                        tr.constructFromNode(trNode)
                        self.transitions.append(tr)


class UiEntry(DebuggableConverter):
    def __init__(self, version, indent, extra_bytes=None):
        self.version = version
        self.indent = indent
        if extra_bytes is None:
            extra_bytes = _default_extra_bytes(version)
        self.extra_bytes = extra_bytes

        self.id = 0
        self.title = ""
        self.title2 = ""
        self.string10 = ""
        self.xOff = 0
        self.yOff = 0
        self.flag1 = self.flag2 = self.flag3 = 0
        self.flag11 = self.flag12 = self.flag13 = self.flag14 = 0
        self.flag6 = self.flag7 = self.flag8 = self.flag9 = 0
        self.flag16 = 0
        self.parentName = ""
        self.int1 = 0
        self.tooltip = ""
        self.tooltipText = ""
        self.int3 = 0
        self.int4 = 0
        self.flag4 = 0
        self.script = ""
        self.numTGAs = 0
        self.TGAs = []
        self.int5 = 0
        self.int6 = 0
        self.numStates = 0
        self.states = []
        self.int26 = 0
        self.events = []
        self.eventsEnd = ""
        self.int27 = 0
        self.numEffects = 0
        self.effects = []
        self.numChildren = 0
        self.children = []
        self.template = ""
        self.flag5 = 0
        self.flag5data = None
        self.flag15 = 0

    def readFrom(self, handle):
        self.id = handle.readInt()
        self.title = handle.readASCII()
        if self.version >= 43:
            self.title2 = handle.readASCII()
        self.xOff = handle.readInt()
        self.yOff = handle.readInt()
        self.flag1 = handle.readByte()
        self.flag2 = handle.readByte()
        self.flag3 = handle.readByte()
        self.flag11 = handle.readByte()
        self.flag12 = handle.readByte()
        self.flag13 = handle.readByte()
        self.flag14 = handle.readByte()
        if self.version >= 47:
            self.flag6 = handle.readByte()
        if self.version >= 50:
            self.flag7 = handle.readByte()
            self.flag8 = handle.readByte()
            self.flag9 = handle.readByte()
        if self.version >= 52:
            self.flag15 = handle.readByte()
        if self.version >= 59:
            self.flag16 = handle.readByte()
        self.parentName = handle.readASCII()
        self.int1 = handle.readInt()
        self.tooltip = handle.readUTF16()
        self.tooltipText = handle.readUTF16()
        self.int3 = handle.readInt()
        if self.version >= 33:
            self.flag4 = handle.readByte()
        if self.version >= 39:
            self.int4 = handle.readInt()
        self.script = handle.readASCII()

        self.numTGAs = handle.readInt()
        for _ in range(self.numTGAs):
            tga = TgaEntry(self.version, self.indent + 2)
            tga.readFrom(handle)
            self.TGAs.append(tga)

        self.int5 = handle.readInt()
        self.int6 = handle.readInt()

        self.numStates = handle.readInt()
        for _ in range(self.numStates):
            st = State(self.version, self.indent + 2, self.extra_bytes)
            st.readFrom(handle)
            self.states.append(st)

        self.int26 = handle.readInt()

        ev = handle.readASCII()
        while ev != "events_end":
            self.events.append(ev)
            ev = handle.readASCII()
        self.eventsEnd = ev

        self.int27 = handle.readInt()
        if self.version >= 39:
            self.numEffects = handle.readInt()
            for _ in range(self.numEffects):
                eff = Effect(self.version, self.indent + 2)
                eff.readFrom(handle)
                self.effects.append(eff)

        self.numChildren = handle.readInt()
        for _ in range(self.numChildren):
            child = UiEntry(self.version, self.indent + 2, self.extra_bytes)
            child.readFrom(handle)
            self.children.append(child)

        self.template = handle.readASCII()

        if self.version >= 44:
            self.flag5 = handle.readByte()
            if self.flag5 != 0:
                name = handle.readASCII()
                count = handle.readInt()
                self.flag5data = {
                    "name": name,
                    "data": [handle.readInt() for _ in range(count)],
                    "i1": handle.readInt(),
                    "i2": handle.readInt(),
                    "f1": handle.readByte(),
                    "i3": handle.readInt(),
                    "f2": handle.readByte(),
                }
        if self.version >= 49:
            self.string10 = handle.readASCII()

    def writeTo(self, handle):
        handle.writeInt(self.id)
        handle.writeASCII(self.title)
        if self.version >= 43:
            handle.writeASCII(self.title2)
        handle.writeInt(self.xOff)
        handle.writeInt(self.yOff)
        handle.writeByte(self.flag1)
        handle.writeByte(self.flag2)
        handle.writeByte(self.flag3)
        handle.writeByte(self.flag11)
        handle.writeByte(self.flag12)
        handle.writeByte(self.flag13)
        handle.writeByte(self.flag14)
        if self.version >= 47:
            handle.writeByte(self.flag6)
        if self.version >= 50:
            handle.writeByte(self.flag7)
            handle.writeByte(self.flag8)
            handle.writeByte(self.flag9)
        if self.version >= 52:
            handle.writeByte(self.flag15)
        if self.version >= 59:
            handle.writeByte(self.flag16)
        handle.writeASCII(self.parentName)
        handle.writeInt(self.int1)
        handle.writeUTF16(self.tooltip)
        handle.writeUTF16(self.tooltipText)
        handle.writeInt(self.int3)
        if self.version >= 33:
            handle.writeByte(self.flag4)
        if self.version >= 39:
            handle.writeInt(self.int4)
        handle.writeASCII(self.script)

        # P0 修复：计数一律用 len(list)
        handle.writeInt(len(self.TGAs))
        for tga in self.TGAs:
            tga.writeTo(handle)

        handle.writeInt(self.int5)
        handle.writeInt(self.int6)

        handle.writeInt(len(self.states))
        for st in self.states:
            st.writeTo(handle)

        handle.writeInt(self.int26)

        for ev in self.events:
            handle.writeASCII(ev)
        handle.writeASCII(self.eventsEnd)

        handle.writeInt(self.int27)
        if self.version >= 39:
            handle.writeInt(len(self.effects))
            for eff in self.effects:
                eff.writeTo(handle)

        handle.writeInt(len(self.children))
        for child in self.children:
            child.writeTo(handle)

        handle.writeASCII(self.template)

        if self.version >= 44:
            handle.writeByte(self.flag5)
            if self.flag5 != 0:
                d = self.flag5data
                handle.writeASCII(d["name"])
                handle.writeInt(len(d["data"]))
                for i in d["data"]:
                    handle.writeInt(i)
                handle.writeInt(d["i1"])
                handle.writeInt(d["i2"])
                handle.writeByte(d["f1"])
                handle.writeInt(d["i3"])
                handle.writeByte(d["f2"])

        if self.version >= 49:
            handle.writeASCII(self.string10)

    def writeToXML(self, handle):
        handle.write("""%(i)s<uiEntry>
%(i1)s<id>%(id)i</id>
%(i1)s<title>%(title)s</title>
%(i1)s<title2>%(title2)s</title2>
%(i1)s<string10>%(string10)s</string10>
%(i1)s<xOff>%(xOff)i</xOff>
%(i1)s<yOff>%(yOff)i</yOff>
%(i1)s<flag1>%(flag1)i</flag1>
%(i1)s<flag2>%(flag2)i</flag2>
%(i1)s<flag3>%(flag3)i</flag3>
%(i1)s<flag11>%(flag11)i</flag11>
%(i1)s<flag12>%(flag12)i</flag12>
%(i1)s<flag13>%(flag13)i</flag13>
%(i1)s<flag14>%(flag14)i</flag14>
%(i1)s<flag6>%(flag6)i</flag6>
%(i1)s<flag7>%(flag7)i</flag7>
%(i1)s<flag8>%(flag8)i</flag8>
%(i1)s<flag9>%(flag9)i</flag9>
%(i1)s<flag15>%(flag15)i</flag15>
%(i1)s<flag16>%(flag16)i</flag16>
%(i1)s<parentName>%(parentName)s</parentName>
%(i1)s<int1>%(int1)i</int1>
%(i1)s<tooltip>%(tooltip)s</tooltip>
%(i1)s<tooltipText>%(tooltipText)s</tooltipText>
%(i1)s<int3>%(int3)i</int3>
%(i1)s<int4>%(int4)i</int4>
%(i1)s<flag4>%(flag4)i</flag4>
%(i1)s<script>%(script)s</script>
%(i1)s<tgas num="%(numTGAs)i">
""" % {"i": "  " * self.indent, "i1": "  " * (self.indent + 1),
            "id": self.id, "title": self.title, "title2": self.title2,
            "string10": self.string10, "xOff": self.xOff, "yOff": self.yOff,
            "flag1": self.flag1, "flag2": self.flag2, "flag3": self.flag3,
            "flag11": self.flag11, "flag12": self.flag12,
            "flag13": self.flag13, "flag14": self.flag14,
            "flag6": self.flag6, "flag7": self.flag7,
            "flag8": self.flag8, "flag9": self.flag9,
            "flag15": self.flag15, "flag16": self.flag16,
            "parentName": self.parentName, "int1": self.int1,
            "tooltip": self.tooltip, "tooltipText": self.tooltipText,
            "int3": self.int3, "int4": self.int4, "flag4": self.flag4,
            "script": self.script,
            # P0：num 与列表长度对齐
            "numTGAs": len(self.TGAs)})

        for tga in self.TGAs:
            tga.writeToXML(handle)

        handle.write("""%(i1)s</tgas>
%(i1)s<int5>%(int5)i</int5>
%(i1)s<int6>%(int6)i</int6>
%(i1)s<states num="%(numStates)i">
""" % {"i1": "  " * (self.indent + 1),
            "int5": self.int5, "int6": self.int6,
            # P0：num 与列表长度对齐
            "numStates": len(self.states)})

        for st in self.states:
            st.writeToXML(handle)

        handle.write("""%(i1)s</states>
%(i1)s<int26>%(int26)i</int26>
%(i1)s<events>
""" % {"i1": "  " * (self.indent + 1), "int26": self.int26})

        for ev in self.events:
            handle.write("%(i2)s<event>%(ev)s</event>\n"
                         % {"i2": "  " * (self.indent + 2), "ev": ev})

        handle.write("""%(i1)s</events>
%(i1)s<eventsEnd>%(eventsEnd)s</eventsEnd>
%(i1)s<int27>%(int27)i</int27>
%(i1)s<effects num="%(numEffects)i">
""" % {"i1": "  " * (self.indent + 1), "eventsEnd": self.eventsEnd,
            "int27": self.int27,
            # P0：num 与列表长度对齐
            "numEffects": len(self.effects)})

        for eff in self.effects:
            eff.writeToXML(handle)

        handle.write("""%(i1)s</effects>
%(i1)s<children num="%(numChildren)i">
""" % {"i1": "  " * (self.indent + 1),
            # P0：num 与列表长度对齐
            "numChildren": len(self.children)})

        for child in self.children:
            child.writeToXML(handle)

        handle.write("%(i1)s</children>\n%(i1)s<template>%(template)s</template>"
                     % {"i1": "  " * (self.indent + 1),
                        "template": self.template})

        if self.flag5 == 0:
            handle.write("\n%(i1)s<flag5>%(flag5)i</flag5>\n"
                         % {"i1": "  " * (self.indent + 1), "flag5": self.flag5})
        else:
            d = self.flag5data
            handle.write("\n%(i1)s<flag5 name=\"%(name)s\" data=\"%(data)s\" "
                         "i1=\"%(i1v)s\" i2=\"%(i2v)s\" i3=\"%(i3v)s\" "
                         "f1=\"%(f1v)s\" f2=\"%(f2v)s\">%(flag5)i</flag5>\n"
                         % {"i1": "  " * (self.indent + 1),
                            "flag5": self.flag5, "name": d["name"],
                            "data": " ".join(map(str, d["data"])),
                            "i1v": d["i1"], "i2v": d["i2"], "i3v": d["i3"],
                            "f1v": d["f1"], "f2v": d["f2"]})

        handle.write("%(i)s</uiEntry>\n" % {"i": "  " * self.indent})

    def constructFromNode(self, node):
        if node.nodeName != "uiEntry":
            raise Exception("Not a ui node")
        for child in node.childNodes:
            if child.nodeName == "id":
                self.id = _node_int(child)
            elif child.nodeName == "title":
                self.title = _node_text(child, self.title)
            elif child.nodeName == "title2":
                self.title2 = _node_text(child, self.title2)
            elif child.nodeName == "string10":
                self.string10 = _node_text(child, self.string10)
            elif child.nodeName == "xOff":
                self.xOff = _node_int(child)
            elif child.nodeName == "yOff":
                self.yOff = _node_int(child)
            elif child.nodeName == "flag1":
                self.flag1 = _node_int(child)
            elif child.nodeName == "flag2":
                self.flag2 = _node_int(child)
            elif child.nodeName == "flag3":
                self.flag3 = _node_int(child)
            elif child.nodeName == "flag5":
                self.flag5 = _node_int(child)
                if self.flag5 != 0:
                    data_attr = _attr_text(child, "data", "")
                    self.flag5data = {
                        "name": _attr_text(child, "name", ""),
                        "data": [int(x) for x in data_attr.split()] if data_attr else [],
                        "i1": _attr_int(child, "i1", 0),
                        "i2": _attr_int(child, "i2", 0),
                        "i3": _attr_int(child, "i3", 0),
                        "f1": _attr_int(child, "f1", 0),
                        "f2": _attr_int(child, "f2", 0),
                    }
            elif child.nodeName == "flag11":
                self.flag11 = _node_int(child)
            elif child.nodeName == "flag12":
                self.flag12 = _node_int(child)
            elif child.nodeName == "flag13":
                self.flag13 = _node_int(child)
            elif child.nodeName == "flag14":
                self.flag14 = _node_int(child)
            elif child.nodeName == "flag15":
                self.flag15 = _node_int(child)
            elif child.nodeName == "flag16":
                self.flag16 = _node_int(child)
            elif child.nodeName == "flag6":
                self.flag6 = _node_int(child)
            elif child.nodeName == "flag7":
                self.flag7 = _node_int(child)
            elif child.nodeName == "flag8":
                self.flag8 = _node_int(child)
            elif child.nodeName == "flag9":
                self.flag9 = _node_int(child)
            elif child.nodeName == "parentName":
                self.parentName = _node_text(child, self.parentName)
            elif child.nodeName == "int1":
                self.int1 = _node_int(child)
            elif child.nodeName == "tooltip":
                self.tooltip = _node_text(child, self.tooltip)
            elif child.nodeName == "tooltipText":
                self.tooltipText = _node_text(child, self.tooltipText)
            elif child.nodeName == "int3":
                self.int3 = _node_int(child)
            elif child.nodeName == "flag4":
                self.flag4 = _node_int(child)
            elif child.nodeName == "int4":
                self.int4 = _node_int(child)
            elif child.nodeName == "script":
                self.script = _node_text(child, self.script)
            elif child.nodeName == "tgas":
                # P0：num 缺失不再崩溃
                self.numTGAs = _node_num(child)
                for tgaNode in child.childNodes:
                    if tgaNode.nodeName == "tga":
                        tga = TgaEntry(self.version, self.indent)
                        tga.constructFromNode(tgaNode)
                        self.TGAs.append(tga)
            elif child.nodeName == "int5":
                self.int5 = _node_int(child)
            elif child.nodeName == "int6":
                self.int6 = _node_int(child)
            elif child.nodeName == "states":
                self.numStates = _node_num(child)
                for stateNode in child.childNodes:
                    if stateNode.nodeName == "state":
                        st = State(self.version, self.indent, self.extra_bytes)
                        st.constructFromNode(stateNode)
                        self.states.append(st)
            elif child.nodeName == "int26":
                self.int26 = _node_int(child)
            elif child.nodeName == "events":
                for eventNode in child.childNodes:
                    if eventNode.nodeName == "event":
                        self.events.append(_node_text(eventNode, ""))
            elif child.nodeName == "eventsEnd":
                self.eventsEnd = _node_text(child, self.eventsEnd)
            elif child.nodeName == "int27":
                self.int27 = _node_int(child)
            elif child.nodeName == "effects":
                self.numEffects = _node_num(child)
                for effectNode in child.childNodes:
                    if effectNode.nodeName == "effect":
                        eff = Effect(self.version, self.indent)
                        eff.constructFromNode(effectNode)
                        self.effects.append(eff)
            elif child.nodeName == "children":
                self.numChildren = _node_num(child)
                for childNode in child.childNodes:
                    if childNode.nodeName == "uiEntry":
                        ui = UiEntry(self.version, self.indent, self.extra_bytes)
                        ui.constructFromNode(childNode)
                        self.children.append(ui)
            elif child.nodeName == "template":
                self.template = _node_text(child, self.template)


# ==========================================================================
# 转换函数
# ==========================================================================

def convert_ui_to_xml(src, dst):
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

        fileSize = os.path.getsize(src)
        chosen = None
        parsed = None
        for count in extra_byte_counts(versionNumber):
            uiFile.seek(10)
            try:
                probe = UiEntry(versionNumber, 1, extra_bytes=count)
                probe.readFrom(uiFile)
                if uiFile.tell() == fileSize:
                    chosen = count
                    parsed = probe
                    break
            except Exception:
                continue
        if chosen is None:
            raise ValueError("无法识别该文件结构（解析未精确到达文件末尾）")

        with open(dst, "w", encoding="utf-8", newline="") as outFile:
            outFile.write("<ui>\n  <version>%03d</version>\n"
                          "  <tgaUseExtraBytes>%d</tgaUseExtraBytes>\n"
                          % (versionNumber, chosen))
            # P0：复用已解析的实例，不再依赖全局状态重新解析
            parsed.writeToXML(outFile)
            outFile.write("</ui>\n")


def convert_xml_to_ui(src, dst):
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

    # P0：extra_bytes 从 XML 读取，回退到按版本推导；不再使用全局变量
    extra = _default_extra_bytes(versionInt)
    extraNodes = dom.getElementsByTagName("tgaUseExtraBytes")
    if extraNodes:
        extra = _node_int(extraNodes[0], extra)

    rootNodes = dom.getElementsByTagName("uiEntry")
    if not rootNodes:
        raise ValueError("XML 中找不到 uiEntry 节点")
    rootNode = rootNodes[0]

    root = UiEntry(versionInt, 0, extra_bytes=extra)
    root.constructFromNode(rootNode)

    versionBytes = ("%03d" % versionInt).encode("ascii")

    with open(dst, "wb", buffering=0) as raw:
        outFile = TypeCastWriter(raw)
        outFile.write(b"Version" + versionBytes)
        root.writeTo(outFile)
        outFile.flush()


# 兼容旧名字
convertUIToXML = convert_ui_to_xml
convertXMLToUI = convert_xml_to_ui


# ==========================================================================
# 命令行
# ==========================================================================

def cli_main():
    if len(sys.argv) < 2:
        return False
    if sys.argv[1] == "-x" and len(sys.argv) >= 4:
        convert_xml_to_ui(sys.argv[2], sys.argv[3])
    elif sys.argv[1] == "-u" and len(sys.argv) >= 4:
        convert_ui_to_xml(sys.argv[2], sys.argv[3])
    elif sys.argv[1] in ("-uar", "-xar"):
        to_ui = sys.argv[1] == "-xar"
        src = os.getcwd()
        out_root = os.path.join(src, "uiOutput" if to_ui else "output")
        pairs = []
        for root, dirs, files in os.walk(src):
            if os.path.abspath(root).startswith(os.path.abspath(out_root)):
                continue
            for fn in files:
                if fn.startswith("."):
                    continue
                p = os.path.join(root, fn)
                rel = os.path.relpath(p, src)
                if to_ui:
                    if fn.endswith(".xml"):
                        pairs.append((p, rel, os.path.join(out_root, rel[:-4])))
                else:
                    if os.path.splitext(fn)[1] == "":
                        # P0：用 with 显式关闭句柄
                        try:
                            with open(p, "rb") as fh:
                                if fh.read(7) == b"Version":
                                    pairs.append((p, rel,
                                                  os.path.join(out_root, rel + ".xml")))
                        except OSError:
                            pass
        ok = fail = 0
        for p, rel, out in pairs:
            os.makedirs(os.path.dirname(out), exist_ok=True)
            try:
                (convert_xml_to_ui if to_ui else convert_ui_to_xml)(p, out)
                ok += 1
            except Exception as e:
                fail += 1
                print("  FAILED %s: %s" % (rel, e))
        print("Recursive %s: %d converted, %d failed -> %s"
              % ("XML -> UI" if to_ui else "UI -> XML", ok, fail, out_root))
    elif sys.argv[1] == "-xa":
        filelist = os.listdir(os.getcwd())
        if not os.path.isdir("./uiOutput"):
            os.mkdir("./uiOutput")
        ok = fail = 0
        for filename in filelist:
            if filename.startswith(".") or os.path.isdir(filename):
                continue
            base = filename[:-4] if filename.lower().endswith(".xml") else filename
            try:
                convert_xml_to_ui(filename, "./uiOutput/" + base)
                ok += 1
            except Exception as e:
                fail += 1
                print("  FAILED %s: %s" % (filename, e))
        print("XML -> UI: %d converted, %d failed -> ./uiOutput" % (ok, fail))
    elif sys.argv[1] == "-ua":
        if not os.path.isdir("./output"):
            os.mkdir("./output")
        filelist = os.listdir(os.getcwd())
        ok = fail = 0
        for filename in filelist:
            if filename.startswith(".") or os.path.isdir(filename):
                continue
            try:
                convert_ui_to_xml(filename, "./output/" + filename + ".xml")
                ok += 1
            except Exception as e:
                fail += 1
                print("  FAILED %s: %s" % (filename, e))
        print("UI -> XML: %d converted, %d failed -> ./output" % (ok, fail))
    else:
        print("用法：")
        print("  python convert_ui.py -u  uifile      uifile.xml")
        print("  python convert_ui.py -x  uifile.xml  uifile")
        print("  python convert_ui.py -ua / -xa / -uar / -xar")
    return True


# ==========================================================================
# GUI
# ==========================================================================

def _run_gui():
    import tkinter as tk
    from tkinter import ttk, filedialog, messagebox

    class ConverterApp:
        def __init__(self, root):
            self.root = root
            self.queue = queue.Queue()
            self.worker = None
            self.stop_flag = threading.Event()
            self._build_ui()
            self.root.after(80, self._drain_queue)

        def _build_ui(self):
            self.root.title("Total War UI 转换器")
            self.root.geometry("750x640")
            self.root.minsize(750, 540)

            main = ttk.Frame(self.root, padding=10)
            main.pack(fill="both", expand=True)
            self._main = main

            self.frm_mode = ttk.LabelFrame(main, text="模式", padding=8)
            # 默认：单文件模式
            self.var_filemode = tk.StringVar(value="single")
            ttk.Radiobutton(self.frm_mode, text="批量模式（文件夹）",
                            variable=self.var_filemode, value="batch",
                            command=self._on_mode_change).pack(side="left")
            ttk.Radiobutton(self.frm_mode, text="单文件模式",
                            variable=self.var_filemode, value="single",
                            command=self._on_mode_change).pack(side="left", padx=(18, 0))

            self.frm_dir = ttk.LabelFrame(main, text="转换方向", padding=8)
            # 默认：XML → UI
            self.var_mode = tk.StringVar(value="x2u")
            ttk.Radiobutton(self.frm_dir, text="UI  →  XML",
                            variable=self.var_mode, value="u2x",
                            command=self._on_direction_change).pack(side="left")
            ttk.Radiobutton(self.frm_dir, text="XML →  UI（无扩展名）",
                            variable=self.var_mode, value="x2u",
                            command=self._on_direction_change).pack(
                                side="left", padx=(18, 0))

            self.frm_batch = ttk.Frame(main)

            frm_in = ttk.LabelFrame(self.frm_batch, text="输入文件夹", padding=8)
            frm_in.pack(fill="x", pady=(0, 6))
            self.var_in = tk.StringVar()
            ttk.Entry(frm_in, textvariable=self.var_in).pack(
                side="left", fill="x", expand=True)
            ttk.Button(frm_in, text="浏览...", width=10,
                       command=self._choose_in).pack(side="left", padx=(6, 0))

            frm_out = ttk.LabelFrame(self.frm_batch, text="输出文件夹", padding=8)
            frm_out.pack(fill="x", pady=(0, 6))
            self.var_out = tk.StringVar()
            ttk.Entry(frm_out, textvariable=self.var_out).pack(
                side="left", fill="x", expand=True)
            ttk.Button(frm_out, text="浏览...", width=10,
                       command=self._choose_out).pack(side="left", padx=(6, 0))

            frm_opt = ttk.Frame(self.frm_batch)
            frm_opt.pack(fill="x", pady=(0, 6))
            self.var_recurse = tk.BooleanVar(value=False)
            self.var_keepstruct = tk.BooleanVar(value=True)
            ttk.Checkbutton(frm_opt, text="包含子文件夹",
                            variable=self.var_recurse).pack(side="left", padx=(0, 18))
            ttk.Checkbutton(frm_opt, text="保持目录结构",
                            variable=self.var_keepstruct).pack(side="left")

            self.frm_single = ttk.Frame(main)

            frm_src = ttk.LabelFrame(self.frm_single, text="源文件", padding=8)
            frm_src.pack(fill="x", pady=(0, 6))
            self.var_src = tk.StringVar()
            ttk.Entry(frm_src, textvariable=self.var_src).pack(
                side="left", fill="x", expand=True)
            ttk.Button(frm_src, text="浏览...", width=10,
                       command=self._choose_src).pack(side="left", padx=(6, 0))

            frm_dst = ttk.LabelFrame(self.frm_single, text="目标文件", padding=8)
            frm_dst.pack(fill="x", pady=(0, 6))
            self.var_dst = tk.StringVar()
            ttk.Entry(frm_dst, textvariable=self.var_dst).pack(
                side="left", fill="x", expand=True)
            ttk.Button(frm_dst, text="浏览...", width=10,
                       command=self._choose_dst).pack(side="left", padx=(6, 0))

            ttk.Label(self.frm_single,
                      text="提示：UI 文件无扩展名；XML → UI 时目标文件会自动去掉 .xml。\n"
                           "目标留空则按源文件同名自动推导。",
                      foreground="#666", justify="left").pack(anchor="w", pady=(0, 4))

            self.var_src.trace_add("write", self._on_src_changed)

            self.frm_btn = ttk.Frame(main)
            self.btn_start = ttk.Button(self.frm_btn, text="开始转换", width=12,
                                        command=self._start)
            self.btn_start.pack(side="left")
            self.btn_stop = ttk.Button(self.frm_btn, text="停止", width=8,
                                       command=self._stop, state="disabled")
            self.btn_stop.pack(side="left", padx=(6, 0))
            ttk.Button(self.frm_btn, text="打开输出目录", width=14,
                       command=self._open_output).pack(side="left", padx=(6, 0))
            self.progress = ttk.Progressbar(self.frm_btn, mode="determinate")
            self.progress.pack(side="left", fill="x", expand=True, padx=(12, 0))

            self.var_status = tk.StringVar(value="就绪")
            self.lbl_status = ttk.Label(main, textvariable=self.var_status,
                                        anchor="w")

            self.frm_log = ttk.LabelFrame(main, text="日志", padding=4)
            self.txt = tk.Text(self.frm_log, wrap="word", height=14,
                               state="disabled", font=("Consolas", 12))
            sb = ttk.Scrollbar(self.frm_log, command=self.txt.yview)
            self.txt.configure(yscrollcommand=sb.set)
            sb.pack(side="right", fill="y")
            self.txt.pack(side="left", fill="both", expand=True)

            self.root.protocol("WM_DELETE_WINDOW", self._on_close)

            self._rebuild_layout()

        def _on_mode_change(self):
            self._rebuild_layout()
            if self.var_filemode.get() == "single":
                self._on_src_changed()

        def _rebuild_layout(self):
            for w in (self.frm_mode, self.frm_dir,
                      self.frm_batch, self.frm_single,
                      self.frm_btn, self.lbl_status, self.frm_log):
                try:
                    w.pack_forget()
                except Exception:
                    pass

            self.frm_mode.pack(fill="x", pady=(0, 6))
            self.frm_dir.pack(fill="x", pady=(0, 6))

            if self.var_filemode.get() == "single":
                self.frm_single.pack(fill="x", pady=(0, 6))
            else:
                self.frm_batch.pack(fill="x", pady=(0, 6))

            self.frm_btn.pack(fill="x", pady=(0, 6))
            self.lbl_status.pack(fill="x", pady=(0, 4))
            self.frm_log.pack(fill="both", expand=True)

        def _on_direction_change(self):
            # 方向切换后，源文件后缀可能与新方向不符，需要重新校对
            src = self.var_src.get().strip()
            if src:
                mode = self.var_mode.get()
                ext = os.path.splitext(src)[1].lower()
                mismatch = ((mode == "u2x" and ext == ".xml") or
                            (mode == "x2u" and ext != ".xml"))
                if mismatch:
                    self.var_src.set("")
                    self.var_dst.set("")
                    self._set_status("方向已切换，请重新选择源文件")
                    self._log(">> 方向已切换，原源文件后缀与新方向不符，已清空")
            self._on_src_changed()

        def _on_src_changed(self, *_):
            src = self.var_src.get().strip()
            if not src:
                return
            base, ext = os.path.splitext(src)
            ext = ext.lower()

            if self.var_mode.get() == "u2x":
                default_dst = base + ".xml"
            else:
                if ext == ".xml":
                    default_dst = base
                else:
                    default_dst = base if base else (src + "_out")

            cur = self.var_dst.get().strip()
            if not cur:
                self.var_dst.set(default_dst)

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

        def _choose_src(self):
            mode = self.var_mode.get()
            if mode == "u2x":
                ft = [("UI 文件（无扩展名）", "*"), ("所有文件", "*.*")]
                title = "选择要转换的 UI 文件（无扩展名）"
            else:
                ft = [("XML 文件", "*.xml"), ("所有文件", "*.*")]
                title = "选择要转换的 .xml 文件"
            p = filedialog.askopenfilename(title=title, filetypes=ft)
            if not p:
                return

            # ---- 立即校对后缀 ----
            ext = os.path.splitext(p)[1].lower()
            if mode == "u2x":
                if ext == ".xml":
                    messagebox.showwarning(
                        "后缀不符",
                        "当前方向为 UI → XML，源文件应为无扩展名的 UI 文件。\n\n"
                        "已选文件：%s\n\n请重新选择。" % os.path.basename(p))
                    return
            else:
                if ext != ".xml":
                    messagebox.showwarning(
                        "后缀不符",
                        "当前方向为 XML → UI，源文件应为 .xml 文件。\n\n"
                        "已选文件：%s\n\n请重新选择。" % os.path.basename(p))
                    return
            # ---- 校对结束 ----

            self.var_src.set(p)
            self._on_src_changed()

        def _choose_dst(self):
            src = self.var_src.get().strip()
            init_dir = os.path.dirname(src) if src else ""
            mode = self.var_mode.get()

            if mode == "u2x":
                ft = [("XML 文件", "*.xml"), ("所有文件", "*.*")]
                title = "保存为 XML"
                init_name = ""
                if src:
                    base, _ = os.path.splitext(os.path.basename(src))
                    init_name = base + ".xml"
                defext = ".xml"
            else:
                ft = [("所有文件", "*.*")]
                title = "保存为 UI（无扩展名）"
                init_name = ""
                if src:
                    base, _ = os.path.splitext(os.path.basename(src))
                    init_name = base
                defext = ""

            p = filedialog.asksaveasfilename(
                title=title, filetypes=ft, defaultextension=defext,
                initialdir=init_dir, initialfile=init_name)
            if not p:
                return

            # ---- 立即校对后缀 ----
            ext = os.path.splitext(p)[1].lower()
            if mode == "u2x":
                if ext != ".xml":
                    p = p + ".xml"
                    messagebox.showinfo(
                        "后缀已修正",
                        "当前方向为 UI → XML，目标文件应为 .xml。\n\n"
                        "已自动改为：%s" % os.path.basename(p))
            else:
                if ext == ".xml":
                    new_p = p[:-4]
                    if not messagebox.askyesno(
                            "后缀不符",
                            "当前方向为 XML → UI，UI 文件约定无扩展名。\n\n"
                            "是否去掉 .xml 后缀？\n\n原：%s\n新：%s"
                            % (os.path.basename(p), os.path.basename(new_p))):
                        return
                    p = new_p
            # ---- 校对结束 ----

            self.var_dst.set(p)

        def _open_output(self):
            if self.var_filemode.get() == "single":
                d = os.path.dirname(self.var_dst.get().strip()) or \
                    os.path.dirname(self.var_src.get().strip())
            else:
                d = self.var_out.get().strip()
            if not d or not os.path.isdir(d):
                messagebox.showinfo("提示", "输出目录还不存在")
                return
            try:
                if os.name == "nt":
                    os.startfile(d)  # noqa
                elif sys.platform == "darwin":
                    os.system('open "%s"' % d)
                else:
                    os.system('xdg-open "%s"' % d)
            except Exception as e:
                messagebox.showerror("错误", "无法打开目录：%s" % e)

        def _start(self):
            if self.worker and self.worker.is_alive():
                return
            if self.var_filemode.get() == "single":
                self._start_single()
            else:
                self._start_batch()

        def _start_single(self):
            src = self.var_src.get().strip()
            if not src or not os.path.isfile(src):
                messagebox.showerror("错误", "请选择有效的源文件")
                return

            mode = self.var_mode.get()
            ext = os.path.splitext(src)[1].lower()

            # 兜底校验（用户可能在输入框里手动输入路径）
            if mode == "u2x" and ext == ".xml":
                if not messagebox.askyesno(
                        "后缀不符",
                        "当前方向是 UI → XML，但源文件扩展名是 .xml。\n"
                        "仍要继续吗？"):
                    return
            if mode == "x2u" and ext and ext != ".xml":
                if not messagebox.askyesno(
                        "后缀不符",
                        "当前方向是 XML → UI，但源文件扩展名不是 .xml。\n"
                        "仍要继续吗？"):
                    return

            dst = self.var_dst.get().strip()
            if not dst:
                base, e = os.path.splitext(src)
                if mode == "u2x":
                    dst = base + ".xml"
                else:
                    dst = base if e.lower() == ".xml" else base + "_out"
                self.var_dst.set(dst)

            if os.path.abspath(dst) == os.path.abspath(src):
                messagebox.showerror("错误", "源文件和目标文件不能相同")
                return
            if os.path.exists(dst) and not messagebox.askyesno(
                    "确认", "目标文件已存在：\n%s\n\n是否覆盖？" % dst):
                return

            parent = os.path.dirname(dst)
            if parent and not os.path.isdir(parent):
                try:
                    os.makedirs(parent, exist_ok=True)
                except OSError as e:
                    messagebox.showerror("错误", "无法创建目标目录：%s" % e)
                    return

            self.stop_flag.clear()
            self.progress.configure(maximum=1, value=0)
            self._log("=" * 66)
            self._log("单文件模式")
            self._log("源文件：%s" % src)
            self._log("目标文件：%s" % dst)
            self._log("方向：%s" % ("UI -> XML" if mode == "u2x" else "XML -> UI"))

            self.btn_start.configure(state="disabled")
            self.btn_stop.configure(state="normal")
            self._set_status("正在转换 ...")

            self.worker = threading.Thread(
                target=self._run_single, args=(src, dst, mode), daemon=True)
            self.worker.start()

        def _run_single(self, src, dst, mode):
            ok = fail = 0
            try:
                if mode == "u2x":
                    convert_ui_to_xml(src, dst)
                else:
                    convert_xml_to_ui(src, dst)
                ok = 1
                self.queue.put(("log", "[ OK ] %s" % os.path.basename(src)))
            except Exception as e:
                fail = 1
                self.queue.put(("log", "[FAIL] %s  ->  %s: %s"
                                       % (os.path.basename(src),
                                          type(e).__name__, e)))
                if os.environ.get("GUI_CONVERT_DEBUG"):
                    self.queue.put(("log", traceback.format_exc()))

            self.queue.put(("progress", 1))
            self.queue.put(("status", "成功 %d  失败 %d" % (ok, fail)))
            self.queue.put(("done", (ok, fail)))

        def _start_batch(self):
            src_dir = self.var_in.get().strip()
            dst_dir = self.var_out.get().strip()

            if not src_dir or not os.path.isdir(src_dir):
                messagebox.showerror("错误", "请选择有效的输入文件夹")
                return
            if not dst_dir:
                messagebox.showerror("错误", "请选择输出文件夹")
                return

            if (os.path.abspath(dst_dir).startswith(os.path.abspath(src_dir) + os.sep)
                    and self.var_recurse.get()):
                if not messagebox.askyesno(
                        "确认",
                        "输出文件夹位于输入文件夹内部且启用了递归扫描，\n"
                        "可能会把上一次的输出再转换一遍。是否继续？"):
                    return

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
            self._log("批量模式")
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
                daemon=True)
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
                files = [f for f in files
                         if not f.lower().endswith(".xml")
                         and not os.path.basename(f).startswith(".")]
            else:
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

        def _run_batch(self, files, src_dir, dst_dir, mode, keepstruct):
            ok = fail = 0
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

                dst = os.path.join(dst_dir, out_rel if keepstruct
                                   else os.path.basename(out_rel))

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

    root = tk.Tk()
    try:
        if os.name == "nt":
            from ctypes import windll
            windll.shcore.SetProcessDpiAwareness(1)
    except Exception:
        pass
    try:
        style = ttk.Style()
        style.configure(".", font=("微软雅黑", 12))   # 全局默认字体，一行生效
        if "vista" in style.theme_names():
            style.theme_use("vista")
        elif "clam" in style.theme_names():
            style.theme_use("clam")
    except Exception:
        pass

    ConverterApp(root)
    root.mainloop()


# ==========================================================================
# 入口
# ==========================================================================

def main():
    if cli_main():
        return
    try:
        _run_gui()
    except ImportError:
        print("未检测到 tkinter，无法启动 GUI。")
        print("请改用命令行模式，例如：")
        print("  python convert_ui.py -u uifile uifile.xml")
        print("  python convert_ui.py -x uifile.xml uifile")


if __name__ == "__main__":
    main()