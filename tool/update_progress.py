#!/usr/bin/env python3
"""Write scores from test/goldens/compare/report.csv into docs/design/PROGRESS.md.

    python3 tool/update_progress.py B01 B02 ... [--done] [--note ID "text"]...

--done ticks Nav, Device, Small and A11y (--no-device leaves Device open) for the given screens (only after
they passed: route tests, tool/device_qa.py light + dark, small-screen
goldens). Notes replace the screen's note text.
"""
import csv
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PROGRESS = ROOT / "docs" / "design" / "PROGRESS.md"
REPORT = ROOT / "test" / "goldens" / "compare" / "report.csv"
ORDER = [(f, m) for f in ("phone", "tablet", "web_desktop", "web_mobile") for m in ("light", "dark")]


def main(argv):
    done = "--done" in argv
    no_device = "--no-device" in argv
    notes = {}
    ids = []
    i = 0
    while i < len(argv):
        a = argv[i]
        if a == "--note":
            notes[argv[i + 1]] = argv[i + 2]
            i += 3
            continue
        if not a.startswith("--"):
            ids.append(a)
        i += 1
    scores = {}
    with REPORT.open() as f:
        for r in csv.DictReader(f):
            scores[(r["id"], r["form_factor"], r["mode"])] = float(r["score"])
    text = PROGRESS.read_text()
    for sid in ids:
        m = re.search(r"^\| " + sid + r" \|.*$", text, re.M)
        if not m:
            print(f"! {sid} not in PROGRESS.md")
            continue
        parts = [p.strip() for p in m.group(0).strip().strip("|").split("|")]
        vals = [scores.get((sid, f, md)) for f, md in ORDER]
        cells = ["%.1f" % v if v is not None else "—" for v in vals]
        got = [v for v in vals if v is not None]
        tick = "✓" if done else parts[13] if len(parts) > 13 else "—"
        note = notes.get(sid, parts[16] if len(parts) > 16 else "")
        if done and not note.startswith("done"):
            note = ("done. " + note).strip()
        ticks = [tick] * 4
        if no_device:
            ticks[1] = "—"
        row = parts[:3] + cells + ["min %.1f" % min(got) if got else "—"] + ticks + [note]
        text = text.replace(m.group(0), "| " + " | ".join(row) + " |")
    PROGRESS.write_text(text)
    print(f"updated {len(ids)} rows")


if __name__ == "__main__":
    main(sys.argv[1:])
