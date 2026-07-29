#!/usr/bin/env python3
"""Check 16 KB page size alignment of ELF .so files."""
import struct
import sys
import os

def check_elf_alignment(filepath):
    with open(filepath, 'rb') as f:
        data = f.read(64)

    ei_class = data[4]  # 1=32-bit, 2=64-bit
    is_64 = (ei_class == 2)

    if is_64:
        e_phoff = struct.unpack_from('<Q', data, 32)[0]
        e_phentsize = struct.unpack_from('<H', data, 54)[0]
        e_phnum = struct.unpack_from('<H', data, 56)[0]
    else:
        e_phoff = struct.unpack_from('<I', data, 28)[0]
        e_phentsize = struct.unpack_from('<H', data, 42)[0]
        e_phnum = struct.unpack_from('<H', data, 44)[0]

    with open(filepath, 'rb') as f:
        f.seek(e_phoff)
        phdrs_data = f.read(e_phnum * e_phentsize)

    misaligned = []
    for i in range(e_phnum):
        ph = phdrs_data[i*e_phentsize:(i+1)*e_phentsize]
        if is_64:
            p_type, p_flags = struct.unpack_from('<II', ph, 0)
            p_offset = struct.unpack_from('<Q', ph, 8)[0]
            p_vaddr = struct.unpack_from('<Q', ph, 16)[0]
            p_align = struct.unpack_from('<Q', ph, 48)[0]
        else:
            p_type = struct.unpack_from('<I', ph, 0)[0]
            p_offset = struct.unpack_from('<I', ph, 4)[0]
            p_vaddr = struct.unpack_from('<I', ph, 8)[0]
            p_align = struct.unpack_from('<I', ph, 28)[0]

        # PT_LOAD = 1
        if p_type == 1:
            align_16k = 16384
            offset_ok = (p_offset % align_16k) == 0
            vaddr_ok = (p_vaddr % p_align) == 0 if p_align else True
            align_ok = p_align >= align_16k
            status = "OK" if (offset_ok and vaddr_ok and align_ok) else "MISALIGNED"
            if status == "MISALIGNED":
                misaligned.append({
                    'seg': i,
                    'offset': p_offset,
                    'vaddr': p_vaddr,
                    'align': p_align,
                    'offset_ok': offset_ok,
                    'vaddr_ok': vaddr_ok,
                    'align_ok': align_ok,
                })

    # Play Console's actual check: p_align >= 16384 for ALL PT_LOAD segments.
    # https://developer.android.com/guide/practices/page-sizes#compile-16-kb
    return {
        'is_64': is_64,
        'phnum': e_phnum,
        'misaligned': misaligned,
        'ok': len(misaligned) == 0,
    }

def check_p_align_only(filepath):
    """Returns True if ALL PT_LOAD segments have p_align >= 16384.
    This is the actual Play Console 16 KB check."""
    with open(filepath, 'rb') as f:
        data = f.read(64)

    ei_class = data[4]
    is_64 = (ei_class == 2)

    if is_64:
        e_phoff = struct.unpack_from('<Q', data, 32)[0]
        e_phentsize = struct.unpack_from('<H', data, 54)[0]
        e_phnum = struct.unpack_from('<H', data, 56)[0]
    else:
        e_phoff = struct.unpack_from('<I', data, 28)[0]
        e_phentsize = struct.unpack_from('<H', data, 42)[0]
        e_phnum = struct.unpack_from('<H', data, 44)[0]

    with open(filepath, 'rb') as f:
        f.seek(e_phoff)
        phdrs_data = f.read(e_phnum * e_phentsize)

    for i in range(e_phnum):
        ph = phdrs_data[i*e_phentsize:(i+1)*e_phentsize]
        if is_64:
            p_type = struct.unpack_from('<I', ph, 0)[0]
            p_align = struct.unpack_from('<Q', ph, 48)[0]
        else:
            p_type = struct.unpack_from('<I', ph, 0)[0]
            p_align = struct.unpack_from('<I', ph, 28)[0]
        if p_type == 1 and p_align < 16384:
            return False
    return True

if __name__ == '__main__':
    for f in sys.argv[1:]:
        result = check_elf_alignment(f)
        p_align_ok = check_p_align_only(f)
        status = "OK" if result['ok'] else f"FAIL ({len(result['misaligned'])} misaligned LOAD segments)"
        print(f"{f}: {status} | p_align>=16384: {'PASS' if p_align_ok else 'FAIL'}")
        for m in result['misaligned']:
            print(f"  seg {m['seg']}: offset={m['offset']} vaddr={m['vaddr']} align={m['align']} (offset_ok={m['offset_ok']} vaddr_ok={m['vaddr_ok']} align_ok={m['align_ok']})")
