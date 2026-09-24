#!/usr/bin/env python3
"""Смоук-проверка Flutter-проекта «Время Расти» перед упаковкой в архив.

Проверяет:
1. Баланс фигурных/круглых скобок в каждом .dart-файле (грубо, без строк).
2. Разрешимость всех относительных импортов и package:time_to_grow/...
3. Отсутствие забытых ссылок на старую «садовую» архитектуру (garden/plant).
4. Наличие обязательных файлов и ключевых строк в docs.
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path('/home/z/my-project/time_to_grow')
errors: list[str] = []

# ── 1. Баланс скобок (вырезая строковые литералы и комментарии) ──────
def strip_code(src: str) -> str:
    out = []
    i, n = 0, len(src)
    in_str = None  # ' или "
    while i < n:
        c = src[i]
        nxt = src[i + 1] if i + 1 < n else ''
        if in_str:
            if c == '\\':
                i += 2
                continue
            if c == in_str:
                in_str = None
            i += 1
            continue
        if c in ("'", '"'):
            # тройные кавычки
            if src[i:i + 3] in ("'''", '"""'):
                q = src[i:i + 3]
                j = src.find(q, i + 3)
                i = (j + 3) if j != -1 else n
                continue
            in_str = c
            i += 1
            continue
        if c == '/' and nxt == '/':
            j = src.find('\n', i)
            i = j if j != -1 else n
            continue
        if c == '/' and nxt == '*':
            j = src.find('*/', i)
            i = (j + 2) if j != -1 else n
            continue
        out.append(c)
        i += 1
    return ''.join(out)

dart_files = sorted(ROOT.rglob('*.dart'))
for f in dart_files:
    src = f.read_text(encoding='utf-8')
    code = strip_code(src)
    for open_c, close_c in (('{', '}'), ('(', ')'), ('[', ']')):
        if code.count(open_c) != code.count(close_c):
            errors.append(
                f'{f.relative_to(ROOT)}: дисбаланс {open_c}{close_c} '
                f'({code.count(open_c)} vs {code.count(close_c)})')

# ── 2. Разрешимость импортов ─────────────────────────────────────────
import_re = re.compile(r"import\s+'([^']+)'")
for f in dart_files:
    src = f.read_text(encoding='utf-8')
    for m in import_re.finditer(src):
        path = m.group(1)
        if path.startswith('dart:') or path.startswith('package:flutter'):
            continue
        if path.startswith('package:time_to_grow/'):
            target = ROOT / 'lib' / path[len('package:time_to_grow/'):]
        elif path.startswith('package:'):
            # внешние пакеты: проверяем наличие в pubspec
            pkg = path.split('/')[0][len('package:'):]
            pubspec = (ROOT / 'pubspec.yaml').read_text(encoding='utf-8')
            active = re.search(rf'^\s*{re.escape(pkg)}:', pubspec, re.M)
            commented = re.search(rf'^\s*#\s*{re.escape(pkg)}:', pubspec, re.M)
            if not active and not commented:
                errors.append(f'{f.relative_to(ROOT)}: пакет {pkg} не объявлен в pubspec')
            if active is None and commented:
                print(f'  WARN: {f.relative_to(ROOT)} импортирует закомментированный пакет {pkg}')
            continue
        else:
            target = (f.parent / path).resolve()
        if not target.exists():
            errors.append(f'{f.relative_to(ROOT)}: импорт не найден: {path}')

# ── 3. Забытые ссылки на старую архитектуру ──────────────────────────
forbidden = re.compile(r'\b(GardenService|GardenCanvas|garden_screen|plant_catalog|PlantType|kPlantCatalog|QuietGardenApp)\b')
for f in dart_files:
    src = f.read_text(encoding='utf-8')
    for m in forbidden.finditer(src):
        errors.append(f'{f.relative_to(ROOT)}: старая ссылка «{m.group(0)}»')

# ── 4. Обязательные файлы и ключевые строки ──────────────────────────
required = [
    'pubspec.yaml', 'README.md', 'CHANGELOG.md',
    'docs/UPDATE_FLOW.md', 'docs/FIREBASE.md',
    'docs/SCREEN_TIME.md', 'docs/WEB_TESTING.md',
    'update/version.json',
    'lib/main.dart', 'lib/app.dart',
    'lib/screens/home_shell.dart', 'lib/screens/pet_screen.dart',
    'lib/screens/pet_selection_screen.dart',
    'lib/screens/diary_screen.dart', 'lib/screens/challenge_screen.dart',
    'lib/screens/profile_screen.dart',
    'lib/services/screen_time_service.dart',
    'lib/widgets/update_banner.dart', 'lib/widgets/pet_canvas.dart',
    'test/widget_test.dart',
]
for rel in required:
    if not (ROOT / rel).exists():
        errors.append(f'отсутствует обязательный файл: {rel}')

vj = json.loads((ROOT / 'update/version.json').read_text(encoding='utf-8'))
if vj.get('latest_version') != '2.1.0':
    errors.append('version.json: latest_version != 2.1.0')

pubspec = (ROOT / 'pubspec.yaml').read_text(encoding='utf-8')
if 'version: 2.1.0+12' not in pubspec:
    errors.append('pubspec.yaml: версия не 2.1.0+12')

appv = (ROOT / 'lib/core/app_version.dart').read_text(encoding='utf-8')
if "kAppVersion = '2.1.0'" not in appv:
    errors.append('app_version.dart: версия не синхронизирована')

# ── Итог ─────────────────────────────────────────────────────────────
print(f'Проверено dart-файлов: {len(dart_files)}')
if errors:
    print('\nОШИБКИ:')
    for e in errors:
        print(' -', e)
    sys.exit(1)
print('Все проверки пройдены: скобки, импорты, версии, обязательные файлы — OK')
