"""Evaluate a photo-screening model before FarmTap may switch it on (decision 0025).

Usage:
    python -I evaluate.py --target skin --model model.onnx --data photos/ [--out report.json]

`photos/` holds two folders of labelled photos taken on real farms, checked by
a vet: `positive/` (has the problem) and `negative/` (does not). The model is
an ONNX image classifier taking 1x3xSIZExSIZE floats (ImageNet-normalised by
default) and returning one score per photo (or two class scores; the last is
"positive"). The report gives sensitivity, specificity and their 95% Wilson
intervals, and PASSES only when the lower ends meet thresholds.json and each
class has enough photos. Nothing is uploaded anywhere: it runs on this computer.
"""

from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent
EXTS = {".jpg", ".jpeg", ".png", ".webp"}
MEAN = np.array([0.485, 0.456, 0.406], dtype=np.float32)
STD = np.array([0.229, 0.224, 0.225], dtype=np.float32)


def wilson(k: int, n: int, z: float = 1.96) -> tuple[float, float]:
    """95% Wilson score interval for k successes out of n."""
    if n == 0:
        return (0.0, 0.0)
    p = k / n
    d = 1 + z * z / n
    c = (p + z * z / (2 * n)) / d
    h = z * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n)) / d
    return (max(0.0, c - h), min(1.0, c + h))


def load(path: Path, size: int, normalise: bool) -> np.ndarray:
    img = Image.open(path).convert("RGB").resize((size, size))
    x = np.asarray(img, dtype=np.float32) / 255.0
    if normalise:
        x = (x - MEAN) / STD
    return x.transpose(2, 0, 1)[None]


def score(session, x: np.ndarray) -> float:
    name = session.get_inputs()[0].name
    out = np.asarray(session.run(None, {name: x})[0]).reshape(-1)
    if out.size == 1:
        v = float(out[0])
        return v if 0.0 <= v <= 1.0 else 1 / (1 + math.exp(-v))
    e = np.exp(out - out.max())
    return float(e[-1] / e.sum())


def evaluate(target: str, model: Path, data: Path, size: int = 224, cutoff: float = 0.5, normalise: bool = True) -> dict:
    import onnxruntime as ort

    limits = json.loads((HERE / "thresholds.json").read_text())[target]
    session = ort.InferenceSession(str(model), providers=["CPUExecutionProvider"])
    counts = {"tp": 0, "fn": 0, "tn": 0, "fp": 0}
    for label in ("positive", "negative"):
        files = sorted(p for p in (data / label).glob("*") if p.suffix.lower() in EXTS)
        for f in files:
            hit = score(session, load(f, size, normalise)) >= cutoff
            if label == "positive":
                counts["tp" if hit else "fn"] += 1
            else:
                counts["fp" if hit else "tn"] += 1
    pos = counts["tp"] + counts["fn"]
    neg = counts["tn"] + counts["fp"]
    sens_ci = wilson(counts["tp"], pos)
    spec_ci = wilson(counts["tn"], neg)
    problems = []
    if pos < limits["minPerClass"] or neg < limits["minPerClass"]:
        problems.append(f"needs at least {limits['minPerClass']} photos in each folder (has {pos} positive, {neg} negative)")
    if sens_ci[0] < limits["minSensitivity"]:
        problems.append(f"sensitivity lower bound {sens_ci[0]:.2f} is below {limits['minSensitivity']}")
    if spec_ci[0] < limits["minSpecificity"]:
        problems.append(f"specificity lower bound {spec_ci[0]:.2f} is below {limits['minSpecificity']}")
    return {
        "target": target,
        "model": model.name,
        "cutoff": cutoff,
        "counts": counts,
        "sensitivity": counts["tp"] / pos if pos else None,
        "sensitivity95": sens_ci,
        "specificity": counts["tn"] / neg if neg else None,
        "specificity95": spec_ci,
        "accuracy": (counts["tp"] + counts["tn"]) / (pos + neg) if pos + neg else None,
        "passed": not problems,
        "problems": problems,
    }


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--target", required=True, choices=sorted(k for k in json.loads((HERE / "thresholds.json").read_text()) if not k.startswith("_")))
    ap.add_argument("--model", required=True, type=Path)
    ap.add_argument("--data", required=True, type=Path)
    ap.add_argument("--size", type=int, default=224)
    ap.add_argument("--cutoff", type=float, default=0.5)
    ap.add_argument("--no-normalise", action="store_true")
    ap.add_argument("--out", type=Path)
    a = ap.parse_args(argv)
    r = evaluate(a.target, a.model, a.data, a.size, a.cutoff, not a.no_normalise)
    text = json.dumps(r, indent=2)
    if a.out:
        a.out.write_text(text + "\n")
    print(text)
    print("PASSED: may be switched on (after the owner agrees)" if r["passed"] else "NOT PASSED: stays off", file=sys.stderr)
    return 0 if r["passed"] else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
