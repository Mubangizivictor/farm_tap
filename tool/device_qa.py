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
# `flutter run` reads its keys from this file via `tail -f` (hot restart = "R").
FIFO = Path(os.environ.get("TMPDIR", "/tmp")) / "flutter_keys"


def idb(*args):
    return subprocess.run([IDB, *args, "--udid", UDID], capture_output=True, text=True, timeout=60)


def elements():
    out = idb("ui", "describe-all").stdout
    try:
        return json.loads(out)
    except json.JSONDecodeError:
        return []


def find(label):
    """Exact label first, then a button containing it, then any element."""
    els = elements()
    for test in (
        lambda e: (e.get("AXLabel") or "").strip() == label,
        lambda e: e.get("type") == "Button" and label in (e.get("AXLabel") or ""),
        lambda e: label in (e.get("AXLabel") or ""),
    ):
        for e in els:
            if test(e):
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
        if f and (f.get("width", 0) == 0 or f.get("height", 0) == 0):
            continue  # off screen
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
            with open(os.environ.get("FLUTTER_IN", str(FIFO)), "a") as keys:
                keys.write("R\n")
            time.sleep(6)
        elif cmd == "scroll":
            # Swipe up in the middle of the screen (arg: "down" is default).
            idb("ui", "swipe", "220", "760", "220", "300", "--duration", "0.4")
            time.sleep(1.0)
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
    "B": [
        "restart",
        "tap Continue with Google",
        "tap Add another farm",
        "expect Choose your language",
        "shot B01",
        "tap Continue",
        "expect What do you do?",
        "shot B02",
        "tap Poultry",
        "expect Poultry is coming soon",
        "tap Your name",
        "type Kyomugisha Annet",
        "tap WhatsApp number",
        "type 772451908",
        "shot B03",
        "tap Join the waitlist",
        "expect You're on the list!",
        "shot B04",
        "tap Done",
        "expect What do you do?",
        "tap Continue",
        "expect What kind of dairy?",
        "shot B05",
        "swipeback",
        "expect What do you do?",
        "tap Continue",
        "tap Continue",
        "expect About your farm",
        "tap Farm name",
        "type Rwemera Dairy Farm",
        "tap 31–100",
        "shot B06",
        "tap Continue",
        "expect Where should we send reports?",
        "tap WhatsApp number",
        "type 772451908",
        "shot B07",
        "tap Continue",
        "expect What is your role?",
        "shot B08",
        "tap Continue",
        "expect Add your first worker",
        "shot B09",
        "tap Skip",
        "expect Your farm is ready!",
        "shot B10",
        "tap Start using FarmTap",
    ],
    "CD": [
        "restart",
        "tap Continue with Google",
        "tap Rwemera Dairy Farm",
        "expect Rwemera Dairy Farm",
        "shot D01",
        "tap All records synced",
        "expect Sync status",
        "shot D04",
        "tapxy 220 120",
        "scroll",
        "tap See all",
        "expect Alerts",
        "shot D03",
        "swipeback",
        "expect Quick actions",
        "tap Tap card",
        "wait 1",
        "tap Home",
        "tapxy 215 330",
        "wait 1",
    ],
    "E": [
        "restart",
        "tap Continue with Google",
        "tap Rwemera Dairy Farm",
        "tap Herd",
        "expect Search by name or tag number",
        "shot E01",
        "tap Filter",
        "expect Filter animals",
        "shot E02",
        "tap Show",
        "tap Kasheshe",
        "expect Milk not for sale",
        "shot E03",
        "tap Record",
        "expect What happened?",
        "shot E06",
        "tap Died",
        "expect Record Kasheshe as dead?",
        "shot E08",
        "tap Cancel",
        "swipeback",
        "expect Add animal",
        "tap Add animal",
        "expect Tag number",
        "shot E04",
        "back",
        "tap Scan ear tag",
        "expect Point at the QR code",
        "shot E05",
        "swipeback",
        "expect Search by name or tag number",
    ],
    "H": [
        "restart",
        "tap Continue with Google",
        "tap Rwemera Dairy Farm",
        "tap Health",
        "expect Sick list",
        "shot H01",
        "tap Health calendar",
        "expect Add to calendar",
        "shot H05",
        "back",
        "tap Drugs low",
        "expect Drug stock",
        "shot H04",
        "swipeback",
        "tap See all",
        "expect Why this matters",
        "shot H06",
        "back",
        "tap Treatment",
        "expect What is the problem?",
        "tap Mastitis",
        "shot H02",
        "scroll",
        "tap Save",
        "expect Is this correct?",
        "tap Yes, save",
        "wait 4",
        "expect Treatment saved",
        "shot H03",
        "tap Done",
        "expect Sick list",
    ],
    "I": [
        "restart",
        "tap Continue with Google",
        "tap Rwemera Dairy Farm",
        "tap More",
        "expect Lock phone",
        "shot N01",
        "tap Feeding",
        "expect Feed cost this month",
        "shot I01",
        "tap Buy feed",
        "expect Save purchase",
        "shot I03",
        "tap Save purchase",
        "expect Is this correct?",
        "tap Yes, save",
        "wait 4",
        "shot I01_after_buy",
        "tap Record feeding",
        "expect Which group?",
        "tap 1",
        "tap Decimal point",
        "tap 5",
        "shot I02",
        "back",
        "expect Discard changes?",
        "tap Discard",
        "expect Feed cost this month",
        "back",
        "expect More",
    ],
    "J": [
        "restart",
        "tap Continue with Google",
        "tap Rwemera Dairy Farm",
        "tap More",
        "tap Breeding",
        "expect Expected calvings",
        "shot J01",
        "scroll",
        "tap Rwemera",
        "expect Heat & service — Rwemera",
        "shot J02",
        "tap Save",
        "expect Is this correct?",
        "tap Yes, save",
        "wait 1",
        "tap Kasheshe",
        "expect Is Kasheshe pregnant?",
        "tap Yes, pregnant",
        "wait 2",
        "expect Kasheshe is pregnant!",
        "shot J03",
        "tap Done",
        "expect Expected calvings",
        "shot J01_after",
        "back",
        "expect More",
    ],
    "G": [
        "restart",
        "tap Continue with Google",
        "tap Kashari Milk Centre",
        "expect Tap farmer card",
        "shot G01",
        "tap Close session",
        "expect Keep open",
        "shot G08",
        "tap Keep open",
        "tap Tap farmer card",
        "expect Tap the farmer's card",
        "shot G02",
        "tap Simulate tap (debug)",
        "expect Card OK",
        "tap 4",
        "tap 2",
        "tap Decimal point",
        "tap 5",
        "shot G03",
        "tap Quality test",
        "expect Alcohol test",
        "tap Failed",
        "tap Added water",
        "shot G12",
        "tapxy 215 120",
        "wait 0.5",
        "tap Next",
        "expect 42.5 litres",
        "shot G04",
        "tap Yes, save",
        "wait 0.5",
        "expect Tap the next card",
        "shot G05",
        "tap Farmers",
        "expect suppliers",
        "shot G06",
        "tapxy 215 330",
        "expect SMS receipts on",
        "shot G07",
        "swipeback",
        "tap Pay",
        "expect Send SMS statements",
        "shot G09",
        "tap Payment sheet",
        "expect Confirm and pay",
        "shot G10",
        "back",
        "tap Send SMS statements",
        "expect Extra SMS needed",
        "shot G11",
        "back",
        "tap Home",
        "tap Dispatch",
        "expect Save reconciliation",
        "shot G13",
        "back",
    ],
    "F": [
        "restart",
        "tap Continue with Google",
        "tap Rwemera Dairy Farm",
        "tap Milk",
        "expect Cows recorded",
        "shot F01",
        "tap Record milk",
        "expect Search cow or scan tag",
        "shot F02",
        "tap Kasheshe",
        "expect Kasheshe is under treatment",
        "shot F06",
        "tap Cancel",
        "tap Kahara",
        "expect How many litres?",
        "tap 9",
        "tap Decimal point",
        "tap 5",
        "shot F03",
        "tap Next",
        "expect 9.5 litres",
        "shot F04",
        "tap Yes, save",
        "wait 0.5",
        "shot F05",
        "wait 3",
        "expect How many litres?",
        "back",
        "expect Search cow or scan tag",
        "swipeback",
        "expect Cows recorded",
        "scroll",
        "tap Quick total",
        "expect Quick mode",
        "shot F07",
        "back",
        "tap Milk use",
        "expect Accounted for",
        "shot F08",
        "back",
        "tap Milk sales",
        "expect Sold this week",
        "shot F09",
        "back",
        "tap Milk trends",
        "expect Top cows",
        "shot F10",
        "swipeback",
    ],
    "C": [
        "expect Tap your card",
        "shot C01",
        "tap Enter card number instead",
        "expect Enter your card number",
        "tap 0",
        "tap 1",
        "tap 4",
        "tap 2",
        "shot C02",
        "tap Next",
        "expect Hello, Amos",
        "tap 1",
        "tap 2",
        "shot C03",
        "tap 1",
        "tap 1",
        "expect Wrong PIN",
        "shot C04",
        "tap 1",
        "tap 2",
        "tap 3",
        "tap 4",
        "expect Hello, Amos",
        "shot D02",
    ],
}

if __name__ == "__main__":
    name = sys.argv[1]
    mode = sys.argv[sys.argv.index("--mode") + 1] if "--mode" in sys.argv else "light"
    run(SCRIPTS[name], mode)
