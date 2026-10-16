#!/usr/bin/env python3
"""Convert Lua 5.1 chunks to the S2CE ABI (size_t=8, lua_Number=float32).

Compile Lua source with luac5.1 first, then run:
    python convert_luac.py input.luac output.luac

This rewrites string lengths in every function, constant, local and upvalue;
changing the chunk header alone does not convert a 32-bit chunk to 64-bit.
The converter accepts little-endian Lua 5.1 with 32-bit int/instructions.
"""

import argparse
from pathlib import Path
import struct


class ChunkConverter:
    def __init__(self, data, size_t=8, number=4):
        if (len(data) < 12 or data[:8] != b'\x1bLua\x51\x00\x01\x04'
                or data[8] not in (4, 8) or data[9] != 4
                or data[10] not in (4, 8) or data[11] != 0):
            raise ValueError('Expected a little-endian Lua 5.1 floating-point chunk')
        if size_t not in (4, 8) or number not in (4, 8):
            raise ValueError('size_t and lua_Number widths must be 4 or 8')
        self.data = data
        self.pos = 12
        self.input_size_t = data[8]
        self.input_number = data[10]
        self.output_size_t = size_t
        self.output_number = number
        self.output = bytearray(data[:12])
        self.output[8] = size_t
        self.output[10] = number

    def read(self, count):
        if count < 0 or count > len(self.data) - self.pos:
            raise ValueError('Truncated chunk at offset 0x%x' % self.pos)
        result = self.data[self.pos:self.pos + count]
        self.pos += count
        return result

    def copy(self, count):
        self.output.extend(self.read(count))

    def count(self):
        raw = self.read(4)
        value, = struct.unpack('<i', raw)
        if value < 0 or value > len(self.data) - self.pos:
            raise ValueError('Invalid count at offset 0x%x' % (self.pos - 4))
        self.output.extend(raw)
        return value

    def string(self):
        raw_size = self.read(self.input_size_t)
        size = int.from_bytes(raw_size, 'little')
        value = self.read(size)
        if value and value[-1] != 0:
            raise ValueError('Lua string is missing its terminating NUL')
        self.output.extend(size.to_bytes(self.output_size_t, 'little'))
        self.output.extend(value)

    def function(self, depth=0):
        if depth > 200:
            raise ValueError('Function nesting exceeds Lua 5.1 limits')
        self.string()                  # source
        self.copy(12)                  # line range, upvalues/parameters/flags/stack
        self.copy(self.count() * 4)     # instructions; counts stay int32
        for _ in range(self.count()):   # constants
            kind = self.read(1)
            self.output.extend(kind)
            if kind == b'\x00':
                continue
            if kind == b'\x01':
                self.copy(1)
            elif kind == b'\x03':
                raw = self.read(self.input_number)
                if self.input_number == self.output_number:
                    self.output.extend(raw)
                else:
                    value, = struct.unpack('<f' if self.input_number == 4 else '<d', raw)
                    self.output.extend(struct.pack('<f' if self.output_number == 4 else '<d', value))
            elif kind == b'\x04':
                self.string()
            else:
                raise ValueError('Unknown constant type %d' % kind[0])
        for _ in range(self.count()):   # child functions
            self.function(depth + 1)
        self.copy(self.count() * 4)     # line numbers
        for _ in range(self.count()):   # local variable debug data
            self.string()
            self.copy(8)
        for _ in range(self.count()):   # upvalue debug names
            self.string()

    def convert(self):
        self.function()
        if self.pos != len(self.data):
            raise ValueError('Unparsed trailing data at offset 0x%x' % self.pos)
        return bytes(self.output)


def convert(data, size_t=8, number=4):
    return ChunkConverter(data, size_t, number).convert()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('input', type=Path)
    parser.add_argument('output', type=Path)
    parser.add_argument('--size-t', type=int, choices=(4, 8), default=8)
    parser.add_argument('--number', type=int, choices=(4, 8), default=4)
    args = parser.parse_args()
    source = args.input.read_bytes()
    result = convert(source, args.size_t, args.number)
    # Parse the generated chunk independently from its emitted header.
    if convert(result, args.size_t, args.number) != result:
        raise ValueError('Generated chunk failed verification')
    args.output.write_bytes(result)
    print('Lua 5.1: size_t %d -> %d, lua_Number %d -> %d; %d -> %d bytes'
          % (source[8], args.size_t, source[10], args.number, len(source), len(result)))


if __name__ == '__main__':
    main()
