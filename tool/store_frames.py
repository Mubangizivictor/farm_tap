#!/usr/bin/env python3
"""Store screenshots with a caption (decision 0024).

Reads docs/store/screenshots/raw/<size>/<n>_<name>.png (made by
`STORE_SHOTS=1 flutter test --update-goldens test/store`) and writes
docs/store/screenshots/<size>/<n>_<name>.png at the same pixel size, with the
FarmTap green, a short caption and the screen in a rounded frame.
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / 'docs/store/screenshots/raw'
OUT = ROOT / 'docs/store/screenshots'
FONT = ROOT / 'assets/fonts/Outfit/Outfit-Bold.ttf'
FONT_SUB = ROOT / 'assets/fonts/Outfit/Outfit-Medium.ttf'
GREEN = (31, 94, 74)
GOLD = (238, 184, 60)
CREAM = (247, 245, 240)

CAPTIONS = {
    '1_home': ('Your whole farm, one tap away', 'Milk, cows, treatments and workers today'),
    '2_milk': ('Record milk in seconds', 'Every cow, every milking, even offline'),
    '3_herd': ('Know every animal', 'Tags, health, breeding and history'),
    '4_roster': ('Duties with stand-ins', 'Everyone knows who does what today'),
    '5_feeds': ('Never run out of feed', 'See what is left and how long it lasts'),
    '6_plan': ('Pay with Mobile Money', 'Free trial, then MTN, Airtel or card'),
}


def frame(src: Path, dst: Path) -> None:
    shot = Image.open(src).convert('RGB')
    w, h = shot.size
    canvas = Image.new('RGB', (w, h), GREEN)
    draw = ImageDraw.Draw(canvas)
    title, sub = CAPTIONS.get(src.stem, (src.stem, ''))
    big = ImageFont.truetype(str(FONT), int(w * 0.068))
    small = ImageFont.truetype(str(FONT_SUB), int(w * 0.038))
    top = int(h * 0.045)
    for text, font, color in ((title, big, CREAM), (sub, small, GOLD)):
        box = draw.textbbox((0, 0), text, font=font)
        draw.text(((w - (box[2] - box[0])) / 2, top), text, font=font, fill=color)
        top += (box[3] - box[1]) + int(h * 0.018)
    top += int(h * 0.02)
    scale = min((h - top - int(h * 0.03)) / h, 0.86)
    sw, sh = int(w * scale), int(h * scale)
    inner = shot.resize((sw, sh), Image.LANCZOS)
    radius = int(sw * 0.06)
    mask = Image.new('L', (sw, sh), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, sw, sh), radius=radius, fill=255)
    x = (w - sw) // 2
    border = max(4, int(w * 0.008))
    draw.rounded_rectangle((x - border, top - border, x + sw + border, top + sh + border), radius=radius + border, fill=(20, 60, 48))
    canvas.paste(inner, (x, top), mask)
    dst.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(dst, optimize=True)


def main() -> None:
    for src in sorted(RAW.glob('*/*.png')):
        dst = OUT / src.parent.name / src.name
        frame(src, dst)
        print(dst.relative_to(ROOT))


if __name__ == '__main__':
    main()
