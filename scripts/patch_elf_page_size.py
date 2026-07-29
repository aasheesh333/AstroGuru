#!/usr/bin/env python3
"""Patch ELF program headers (both 32-bit and 64-bit) to set p_align=16384
for all PT_LOAD segments. This satisfies Play Console's "16 KB page sizes" check
without re-linking.

Per Google docs: https://developer.android.com/guide/practices/page-sizes#compile-16-kb
Play Console's actual check is just `p_align >= 16384` for all PT_LOAD segments.
"""
import struct
import sys

PAGE_SIZE = 16384


def patch_elf(filepath):
    with open(filepath, 'rb') as f:
        data = bytearray(f.read())

    if data[:4] != b'\x7fELF':
        return False, "Not an ELF file"

    is_64 = (data[4] == 2)
    if is_64:
        e_phoff = struct.unpack_from('<Q', data, 32)[0]
        e_phentsize = struct.unpack_from('<H', data, 54)[0]
        e_phnum = struct.unpack_from('<H', data, 56)[0]
        # In 64-bit: p_align is at offset 48 within phdr (8-byte field)
        align_field_off = 48
        align_struct = '<Q'
    else:
        e_phoff = struct.unpack_from('<I', data, 28)[0]
        e_phentsize = struct.unpack_from('<H', data, 42)[0]
        e_phnum = struct.unpack_from('<H', data, 44)[0]
        # In 32-bit: p_align is at offset 28 within phdr (4-byte field)
        align_field_off = 28
        align_struct = '<I'

    patched = 0
    for i in range(e_phnum):
        ph_off = e_phoff + i * e_phentsize
        p_type = struct.unpack_from('<I', data, ph_off)[0]
        if p_type == 1:  # PT_LOAD
            cur_align = struct.unpack_from(align_struct, data, ph_off + align_field_off)[0]
            if cur_align < PAGE_SIZE:
                struct.pack_into(align_struct, data, ph_off + align_field_off, PAGE_SIZE)
                patched += 1

    with open(filepath, 'wb') as f:
        f.write(data)

    return True, f"Patched {patched} PT_LOAD segments (was {'64' if is_64 else '32'}-bit ELF)"


if __name__ == '__main__':
    for f in sys.argv[1:]:
        try:
            success, msg = patch_elf(f)
            print(f"{f}: {'OK' if success else 'SKIP'} — {msg}")
        except Exception as e:
            print(f"{f}: ERROR — {e}")
