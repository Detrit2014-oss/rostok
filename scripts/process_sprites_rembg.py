#!/usr/bin/env python3
"""Спрайты «Ростка» v2.1.0: удаление фона через rembg (U2Net).

Генерации дали студийные фоны (серые градиенты, вода у кита, трава) —
простая заливка по белизне их не берёт. rembg выделяет объект по
нейросетевой маске. После matte: обрезка по содержимому, лимит 512px,
WebP (assets + public) и PNG-мастер, контактный лист для контроля.
"""
import io
import os
import sys

from PIL import Image, ImageDraw, ImageFont

RAW = '/home/z/my-project/scripts/sprites_raw'
OUT_PNG = '/home/z/my-project/scripts/sprites_out'
APP = '/home/z/my-project/time_to_grow/assets/sprites'
WEB = '/home/z/my-project/public/sprites'

_model = None


def get_session():
    global _model
    if _model is None:
        from rembg import remove, new_session
        _model = (remove, new_session('u2net'))
    return _model


def cutout(img: Image.Image) -> Image.Image:
    remove, session = get_session()
    buf = io.BytesIO()
    img.convert('RGBA').save(buf, 'PNG')
    out = remove(buf.getvalue(), session=session,
                 alpha_matting=False, post_process_mask=True)
    return Image.open(io.BytesIO(out)).convert('RGBA')


def process(name: str):
    img = Image.open(os.path.join(RAW, name + '.png'))
    img = cutout(img)

    bbox = img.getchannel('A').point(lambda a: 255 if a > 8 else 0).getbbox()
    if bbox:
        img = img.crop(bbox)

    w, h = img.size
    scale = 512.0 / max(w, h)
    if scale < 1.0:
        img = img.resize((round(w * scale), round(h * scale)), Image.LANCZOS)

    # Чётные размеры + свежая копия (обход бага кодировщика WebP).
    w, h = img.size
    if w % 2 or h % 2:
        img = img.crop((0, 0, w - w % 2, h - h % 2))
    img = img.copy()

    os.makedirs(OUT_PNG, exist_ok=True)
    os.makedirs(APP, exist_ok=True)
    os.makedirs(WEB, exist_ok=True)
    img.save(os.path.join(OUT_PNG, name + '.png'), optimize=True)
    img.save(os.path.join(APP, name + '.webp'), 'WEBP', quality=88)
    img.save(os.path.join(WEB, name + '.webp'), 'WEBP', quality=88)
    return name, img.width, img.height


def contact_sheet(done):
    if not done:
        return
    cols = 8
    cell = 150
    rows = (len(done) + cols - 1) // cols
    sheet = Image.new('RGB', (cols * cell, rows * (cell + 16)), (245, 245, 245))
    d = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 11)
    except OSError:
        font = ImageFont.load_default()
    for i, name in enumerate(sorted(done)):
        img = Image.open(os.path.join(OUT_PNG, name + '.png'))
        img.thumbnail((cell - 8, cell - 8))
        cx = (i % cols) * cell
        cy = (i // cols) * (cell + 16)
        for ty in range(2):
            for tx in range(2):
                if (tx + ty) % 2 == 0:
                    d.rectangle([cx + tx * cell // 2, cy + ty * cell // 2,
                                 cx + tx * cell // 2 + cell // 2 - 1,
                                 cy + ty * cell // 2 + cell // 2 - 1],
                                fill=(230, 230, 230))
        sheet.paste(img, (cx + (cell - img.width) // 2,
                          cy + (cell - 8 - img.height) // 2 + 4), img)
        d.text((cx + 4, cy + cell - 6), name, fill=(30, 30, 30), font=font)
    sheet.save(os.path.join(OUT_PNG, '_contact.png'))


def main():
    names = sorted(f[:-4] for f in os.listdir(RAW)
                   if f.endswith('.png') and not f.startswith('_'))
    if len(sys.argv) > 1:
        names = [n for n in names if n in sys.argv[1:]]
    done = []
    for n in names:
        try:
            name, w, h = process(n)
            done.append(name)
            print(f'ok {name} {w}x{h}', flush=True)
        except Exception as e:  # noqa: BLE001
            print(f'FAIL {n}: {e}', flush=True)
    contact_sheet(done)
    print('contact sheet:', len(done))


if __name__ == '__main__':
    main()
