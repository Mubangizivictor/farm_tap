#!/usr/bin/env python3
"""Drive the app on the iPhone 16 Pro Max simulator with idb for device QA.

    python3 tool/device_qa.py <script> [--mode light|dark]

<script> is a section name from SCRIPTS below (e.g. "A"). Each step is one
of:  shot ID | tap LABEL | tapxy X Y | type TEXT | back | swipeback | wait S |
expect LABEL | restart ROUTE.  Screenshots go to
test/device/iphone16promax/<mode>/<ID>.png. Prints every accessibility
element without a label that is tappable (buttons) as a warning.

Needs: idb (pip3 install fb-idb), idb_companion, a booted simulator and the
app running (flutter run -d <udid>).
"""
import json
import os
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
UDID = os.environ.get("SIM_UDID", "29FA47F4-DB31-4273-ADAA-C1E71FCAE948")
IDB = os.path.expanduser("~/Library/Python/3.9/bin/idb")
OUT = ROOT / "test" / "device" / "iphone16promax"
# `flutter run` reads its keys from this pipe (see docs/design/PROGRESS.md, device QA).
FIFO = Path(os.environ.get("TMPDIR", "/tmp")) / "flutter_in"


def idb(*args):
    return subprocess.run([IDB, *args, "--udid", UDID], capture_output=True, text=True, timeout=60)


def elements():
    out = idb("ui", "describe-all").stdout
    try:
        return json.loads(out)
    except json.JSONDecodeError:
        return []


def find(label):
    """First element whose AXLabel contains [label]."""
    for e in elements():
        if label in (e.get("AXLabel") or ""):
            return e
    return None


def centre(e):
    f = e["frame"]
    return f["x"] + f["width"] / 2, f["y"] + f["height"] / 2


def appearance(mode):
    subprocess.run(["xcrun", "simctl", "ui", UDID, "appearance", mode], check=False)


def text_size(size):
    subprocess.run(["xcrun", "simctl", "ui", UDID, "content_size", size], check=False)


def audit(screen):
    """Warn about buttons without a label and tap targets under 44 pt."""
    issues = []
    for e in elements():
        kind = e.get("type")
        label = (e.get("AXLabel") or "").strip()
        f = e.get("frame") or {}
        if kind == "Button" and not label:
            issues.append(f"unlabelled button at {f}")
        if kind == "Button" and f and min(f.get("width", 99), f.get("height", 99)) < 44:
            issues.append(f"small target '{label}' {f.get('width'):.0f}x{f.get('height'):.0f}")
    for i in issues:
        print(f"  ! {screen}: {i}")
    return issues


def run(steps, mode):
    folder = OUT / mode
    folder.mkdir(parents=True, exist_ok=True)
    appearance(mode)
    time.sleep(1)
    for step in steps:
        cmd, _, arg = step.partition(" ")
        if cmd == "shot":
            time.sleep(0.8)
            idb("screenshot", str(folder / f"{arg}.png"))
            audit(arg)
            print(f"shot {arg}")
        elif cmd == "tap":
            e = find(arg)
            if not e:
                print(f"  ! tap: '{arg}' not found")
                continue
            x, y = centre(e)
            idb("ui", "tap", str(int(x)), str(int(y)))
            time.sleep(0.9)
        elif cmd == "tapxy":
            x, y = arg.split()
            idb("ui", "tap", x, y)
            time.sleep(0.9)
        elif cmd == "type":
            idb("ui", "text", arg)
            time.sleep(0.4)
        elif cmd == "back":
            e = find("Back")
            if e:
                x, y = centre(e)
                idb("ui", "tap", str(int(x)), str(int(y)))
            else:
                print("  ! back: no Back button")
            time.sleep(0.9)
        elif cmd == "swipeback":
            idb("ui", "swipe", "2", "480", "360", "480", "--duration", "0.3")
            time.sleep(1.0)
        elif cmd == "restart":
            # Hot restart through the `flutter run` input pipe: fresh state.
            Path(os.environ.get("FLUTTER_IN", str(FIFO))).write_text("R\n")
            time.sleep(6)
        elif cmd == "wait":
            time.sleep(float(arg))
        elif cmd == "expect":
            ok = find(arg) is not None
            print(f"  {'ok' if ok else '!! MISSING'}: {arg}")
        else:
            raise SystemExit(f"unknown step {step}")


SCRIPTS = {
    "A": [
        "restart",
        "shot A02",
        "tap Continue with email",
        "expect Sign in with email",
        "shot A03",
        "swipeback",
        "expect Welcome to FarmTap",
        "tap Continue with email",
        "tap New to FarmTap",
        "expect Create your account",
        "shot A04",
        "back",
        "expect Sign in with email",
        "tap Forgot password",
        "expect Reset your password",
        "shot A05",
        "swipeback",
        "back",
        "expect Welcome to FarmTap",
        "tap Continue with Google",
        "expect Choose a farm",
        "shot A07",
    ],
}

if __name__ == "__main__":
    name = sys.argv[1]
    mode = sys.argv[sys.argv.index("--mode") + 1] if "--mode" in sys.argv else "light"
    run(SCRIPTS[name], mode)
