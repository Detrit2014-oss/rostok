#!/usr/bin/env python3
"""Правит aspect в kCartoon под габариты мультяшного рисовальщика."""
import re
from pathlib import Path

P = Path('/home/z/my-project/time_to_grow/lib/data/cartoon.dart')
src = P.read_text(encoding='utf-8')

new_aspect = {
    'fox': 1.12, 'cat': 1.12, 'dragon': 1.4, 'bunny': 0.78, 'hedgehog': 1.25,
    'panda': 1.1, 'bear': 1.1, 'dog': 1.15, 'deer': 1.2, 'squirrel': 1.2,
    'raccoon': 1.2, 'koala': 1.05, 'pig': 1.15, 'unicorn': 1.2,
    'owl': 0.65, 'duck': 0.65, 'chick': 0.6, 'penguin': 0.65,
    'frog': 1.43,
    'seal': 2.4, 'whale': 2.8, 'turtle': 2.2, 'octopus': 1.35, 'crab': 1.75,
    'cactus': 0.55, 'bonsai': 0.9, 'succulent': 0.6, 'sunflower': 0.57,
    'clover': 0.74, 'sprout': 0.53,
}

# Разбиваем на записи по "PetType.<имя>: CartoonSpec("
parts = re.split(r'(?m)(?=  PetType\.\w+: CartoonSpec\()', src)
out = []
for chunk in parts:
    m = re.match(r'  PetType\.(\w+): CartoonSpec\(', chunk)
    if m and m.group(1) in new_aspect:
        chunk = re.sub(r'aspect: [\d.]+', f'aspect: {new_aspect[m.group(1)]}', chunk, count=1)
    out.append(chunk)
P.write_text(''.join(out), encoding='utf-8')

# Проверка
src2 = P.read_text(encoding='utf-8')
found = dict(re.findall(r'PetType\.(\w+): CartoonSpec\([^;]*?aspect: ([\d.]+)', src2))
bad = {k: (found.get(k), v) for k, v in new_aspect.items() if found.get(k) != str(v)}
print('OK' if not bad else f'MISMATCH: {bad}')
print('entries:', len(found))
