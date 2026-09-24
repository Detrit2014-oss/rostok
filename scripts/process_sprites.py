#!/usr/bin/env python3
"""Спрайты «Ростка» v2.1.0: обработка сгенерированных картинок.

1. Удаляет белый фон: заливка от краёв (BFS) по порогу белизны.
2. Снимает белую кайму с антиалиасных краёв (erode+feather+unpremultiply).
3. Обрезает по содержимому, ужимает до 512px по длинной стороне.
4. Сохраняет: WebP q=88 (assets приложения + public демо) и PNG-мастер.
5. Собирает контактный лист scripts/sprites_out/_contact.png для контроля.
"""
import os
import sys
from collections import deque

from PIL import Image, ImageFilter, ImageDraw, ImageFont

RAW = '/home/z/my-project/scripts/sprites_raw'
OUT_PNG = '/home/z/my-project/scripts/sprites_out'
APP = '/home/z/my-project/time_to_grow/assets/sprites'
WEB = '/home/z/my-project/public/sprites'

WHITE_T = 238  # порог белизны фона


def key_out_white(img: Image.Image) -> Image.Image:
    img = img.convert('RGBA')
    w, h = img.size
    px = img.load()

    # BFS от всех краёв по «почти белым» пикселям.
    bg = bytearray(w * h)
    q = deque()

    def is_whiteish(x, y):
        r, g, b, _ = px[x, y]
        return r >= WHITE_T and g >= WHITE_T and b >= WHITE_T

    for x in range(w):
        for y in (0, h - 1):
            if is_whiteish(x, y) and not bg[y * w + x]:
                bg[y * w + x] = 1
                q.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            if is_whiteish(x, y) and not bg[y * w + x]:
                bg[y * w + x] = 1
                q.append((x, y))
    while q:
        x, y = q.popleft()
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h and not bg[ny * w + nx] \
                    and is_whiteish(nx, ny):
                bg[ny * w + nx] = 1
                q.append((nx, ny))

    alpha = Image.new('L', (w, h), 255)
    ap = alpha.load()
    for y in range(h):
        row = y * w
        for x in range(w):
            if bg[row + x]:
                ap[x, y] = 0

    # Снять белую кайму: 1px эрозия + лёгкое размытие альфы.
    alpha = alpha.filter(ImageFilter.MinFilter(3))
    alpha = alpha.filter(ImageFilter.GaussianBlur(1.1))
    img.putalpha(alpha)

    # Убрать белую подложку из полупрозрачных краёв (unpremultiply по белому).
    px = img.load()
    ap = alpha.load()
    for y in range(h):
        for x in range(w):
            a = ap[x, y]
            if 0 < a < 250:
                r, g, b, _ = px[x, y]
                af = a / 255.0
                r = int(max(0, min(255, (r - (1 - af) * 255) / af)))
                g = int(max(0, min(255, (g - (1 - af) * 255) / af)))
                b = int(max(0, min(255, (b - (1 - af) * 255) / af)))
                px[x, y] = (r, g, b, a)
    return img


def process(name: str) -> tuple[str, int, int]:
    src_path = os.path.join(RAW, name + '.png')
    img = Image.open(src_path)
    img = key_out_white(img)

    bbox = img.getchannel('A').point(lambda a: 255 if a > 8 else 0).getbbox()
    if bbox:
        img = img.crop(bbox)

    w, h = img.size
    scale = 512.0 / max(w, h)
    if scale < 1.0:
        img = img.resize((round(w * scale), round(h * scale)),
                         Image.LANCZOS)

    os.makedirs(OUT_PNG, exist_ok=True)
    os.makedirs(APP, exist_ok=True)
    os.makedirs(WEB, exist_ok=True)
    img.save(os.path.join(OUT_PNG, name + '.png'), optimize=True)
    img.save(os.path.join(APP, name + '.webp'), 'WEBP', quality=88)
    img.save(os.path.join(WEB, name + '.webp'), 'WEBP', quality=88)
    return name, img.width, img.height


def contact_sheet(done: list[str]) -> None:
    cols = 8
    cell = 150
    rows = (len(done) + cols - 1) // cols
    sheet = Image.new('RGB', (cols * cell, rows * (cell + 16)), (245, 245, 245))
    d = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.truetype(
            '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 11)
    except OSError:
        font = ImageFont.load_default()
    for i, name in enumerate(sorted(done)):
        img = Image.open(os.path.join(OUT_PNG, name + '.png'))
        img.thumbnail((cell - 8, cell - 8))
        cx = (i % cols) * cell
        cy = (i // cols) * (cell + 16)
        # шахматка для прозрачности
        for ty in range(2):
            for tx in range(2):
                if (tx + ty) % 2 == 0:
                    d.rectangle(
                        [cx + tx * cell // 2, cy + ty * cell // 2,
                         cx + tx * cell // 2 + cell // 2 - 1,
                         cy + ty * cell // 2 + cell // 2 - 1],
                        fill=(230, 230, 230))
        sheet.paste(img, (cx + (cell - img.width) // 2,
                          cy + (cell - 8 - img.height) // 2 + 4), img)
        d.text((cx + 4, cy + cell - 6), name, fill=(30, 30, 30), font=font)
    sheet.save(os.path.join(OUT_PNG, '_contact.png'))
    print('contact sheet:', len(done), 'sprites')


def main() -> None:
    names = sorted(
        f[:-4] for f in os.listdir(RAW)
        if f.endswith('.png') and not f.startswith('_'))
    if len(sys.argv) > 1:
        names = [n for n in names if n in sys.argv[1:]]
    done = []
    for n in names:
        try:
            name, w, h = process(n)
            done.append(name)
            print(f'ok {name} {w}x{h}')
        except Exception as e:  # noqa: BLE001
            print(f'FAIL {n}: {e}')
    contact_sheet(done)


if __name__ == '__main__':
    main()
