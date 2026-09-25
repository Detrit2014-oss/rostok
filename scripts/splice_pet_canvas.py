#!/usr/bin/env python3
"""Splice the new anatomy block into pet_canvas.dart, replacing the old
_bel + _paintPet implementation (lines 202-590) with the v2 port."""
import io, sys

SRC = '/home/z/my-project/time_to_grow/lib/widgets/pet_canvas.dart'
BLOCK = '/home/z/my-project/scripts/pet_canvas_v2_block.dart'

with io.open(SRC, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Verify boundaries (1-based): 202 = "  /// Особый цвет животика...", 590 = "  }"
start = 202 - 1
end = 590 - 1
assert '/// Особый цвет животика' in lines[start], lines[start]
assert lines[end].rstrip() == '  }', repr(lines[end])
assert 'void _paintPet' in ''.join(lines[start:end])
tail = ''.join(lines[end + 1:end + 5])
assert '_paintEgg' in tail, tail

with io.open(BLOCK, 'r', encoding='utf-8') as f:
    block = f.readlines()
if block and not block[-1].endswith('\n'):
    block[-1] += '\n'

new = lines[:start] + block + ['\n'] + lines[end + 1:]
with io.open(SRC, 'w', encoding='utf-8') as f:
    f.writelines(new)
print('OK: replaced lines 202-590 with', len(block), 'new lines; total now', len(new))
