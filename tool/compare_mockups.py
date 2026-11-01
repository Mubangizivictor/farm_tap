#!/usr/bin/env python3
"""Compare golden screenshots with the approved mockups.

For every golden  test/goldens/<ff>/<mode>/<ID>_<name>.png  this script
  * crops the device chrome off the matching mockup
    (docs/design/screens/<ff>/<mode>/<ID>_<name>.png),
  * resizes mockup and golden to the golden size in dp,
  * writes test/goldens/compare/<ff>/<mode>/<ID>.png
    = mockup | golden | difference heat-map,
  * prints a similarity score (100 - mean absolute pixel difference %)
  * and writes test/goldens/compare/report.csv.

Usage:  python3 tool/compare_mockups.py [ID ...]   (no IDs = all goldens)
Needs Python 3 and Pillow.
"""
import csv
import sys
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageOps

ROOT = Path(__file__).resolve().parent.parent
MOCKUPS = ROOT / "docs" / "design" / "screens"
GOLDENS = ROOT / "test" / "goldens"
OUT = GOLDENS / "compare"

# form factor -> (mockup dp size, render scale, chrome top dp, chrome bottom dp)
FORM_FACTORS = {
    "phone": ((390, 844), 2.0, 32, 24),
    "tablet": ((1194, 834), 1.5, 28, 0),
    "web_desktop": ((1440, 900), 1.0, 44, 0),
    "web_mobile": ((390, 844), 2.0, 56, 0),
}
MODES = ("light", "dark")
LABEL_H = 28


def golden_size(ff):
    (w, h), _, top, bottom = FORM_FACTORS[ff]
    return w, h - top - bottom


def crop_mockup(img, ff):
    (_, _), scale, top, bottom = FORM_FACTORS[ff]
    w, h = img.size
    return img.crop((0, round(top * scale), w, h - round(bottom * scale)))


def heatmap(a, b):
    diff = ImageChops.difference(a, b).convert("L")
    diff = ImageOps.autocontrast(diff, cutoff=0) if diff.getbbox() else diff
    # black = equal, yellow/red = different
    return ImageOps.colorize(diff, black="black", white="red", mid="yellow")


def score(a, b):
    diff = ImageChops.difference(a, b).convert("L")
    hist = diff.histogram()
    total = sum(i * n for i, n in enumerate(hist))
    mean = total / (a.size[0] * a.size[1])
    return 100.0 - mean / 255.0 * 100.0


def compare(ff, mode, golden_path):
    stem = golden_path.stem
    screen_id = stem.split("_", 1)[0]
    mockup_path = MOCKUPS / ff / mode / golden_path.name
    if not mockup_path.exists():
        print(f"  ! no mockup for {ff}/{mode}/{golden_path.name}")
        return None
    size = golden_size(ff)
    mock = crop_mockup(Image.open(mockup_path).convert("RGB"), ff)
    mock = mock.resize(size, Image.LANCZOS)
    gold = Image.open(golden_path).convert("RGB")
    if gold.size != size:
        print(f"  ! {golden_path.name}: golden is {gold.size}, expected {size}")
        gold = gold.resize(size, Image.LANCZOS)

    s = score(mock, gold)
    w, h = size
    sheet = Image.new("RGB", (w * 3, h + LABEL_H), "white")
    for i, (img, label) in enumerate(
        [(mock, "mockup"), (gold, "golden"), (heatmap(mock, gold), "diff")]
    ):
        sheet.paste(img, (i * w, LABEL_H))
        ImageDraw.Draw(sheet).text(
            (i * w + 8, 8), f"{screen_id} {ff}/{mode} {label}", fill="black"
        )
    ImageDraw.Draw(sheet).text((w * 3 - 120, 8), f"score {s:.1f}", fill="black")

    dest = OUT / ff / mode / f"{screen_id}.png"
    dest.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(dest)
    return screen_id, stem, s


def main(ids):
    rows = []
    for ff in FORM_FACTORS:
        for mode in MODES:
            folder = GOLDENS / ff / mode
            if not folder.is_dir():
                continue
            for golden in sorted(folder.glob("*.png")):
                if ids and golden.stem.split("_", 1)[0] not in ids:
                    continue
                result = compare(ff, mode, golden)
                if result:
                    sid, stem, s = result
                    print(f"{sid:4} {ff:11} {mode:5} {s:6.2f}  {stem}")
                    rows.append((sid, stem, ff, mode, f"{s:.2f}"))

    OUT.mkdir(parents=True, exist_ok=True)
    report = OUT / "report.csv"
    # Merge with the previous report so partial runs keep other screens.
    existing = {}
    if report.exists() and ids:
        with report.open() as f:
            for r in csv.DictReader(f):
                existing[(r["id"], r["form_factor"], r["mode"])] = r
    for sid, stem, ff, mode, s in rows:
        existing[(sid, ff, mode)] = {
            "id": sid, "screen": stem, "form_factor": ff, "mode": mode, "score": s,
        }
    with report.open("w", newline="") as f:
        writer = csv.DictWriter(
            f, fieldnames=["id", "screen", "form_factor", "mode", "score"]
        )
        writer.writeheader()
        for key in sorted(existing):
            writer.writerow(existing[key])
    print(f"\n{len(rows)} compared -> {report.relative_to(ROOT)}")


if __name__ == "__main__":
    main(set(sys.argv[1:]))
