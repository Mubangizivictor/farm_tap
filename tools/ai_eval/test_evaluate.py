"""Self-test: a tiny ONNX model that calls bright photos "positive", on made-up photos.
Run: python -I -m unittest discover tools/ai_eval  (from the repo root)."""

import json
import sys
import tempfile
import unittest
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import evaluate  # noqa: E402


def bright_model(path: Path) -> None:
    import onnx
    from onnx import TensorProto, helper

    x = helper.make_tensor_value_info("x", TensorProto.FLOAT, [1, 3, 32, 32])
    y = helper.make_tensor_value_info("y", TensorProto.FLOAT, [1, 1])
    mean = helper.make_node("ReduceMean", ["x"], ["m"], keepdims=1, axes=[1, 2, 3])
    shift = helper.make_tensor("half", TensorProto.FLOAT, [], [0.5])
    gain = helper.make_tensor("gain", TensorProto.FLOAT, [], [20.0])
    sub = helper.make_node("Sub", ["m", "half"], ["c"])
    mul = helper.make_node("Mul", ["c", "gain"], ["g"])
    sig = helper.make_node("Sigmoid", ["g"], ["s"])
    rs = helper.make_tensor("shape", TensorProto.INT64, [2], [1, 1])
    out = helper.make_node("Reshape", ["s", "shape"], ["y"])
    g = helper.make_graph([mean, sub, mul, sig, out], "bright", [x], [y], [shift, gain, rs])
    m = helper.make_model(g, opset_imports=[helper.make_opsetid("", 13)])
    m.ir_version = 8
    onnx.save(m, str(path))


class EvaluateTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        bright_model(self.tmp / "m.onnx")
        rng = np.random.default_rng(1)
        for label, level, n in (("positive", 220, 120), ("negative", 30, 120)):
            (self.tmp / label).mkdir()
            for i in range(n):
                px = np.clip(rng.normal(level, 10, (32, 32, 3)), 0, 255).astype(np.uint8)
                Image.fromarray(px).save(self.tmp / label / f"{i}.png")

    def test_a_good_model_passes(self):
        r = evaluate.evaluate("eye", self.tmp / "m.onnx", self.tmp, size=32, normalise=False)
        self.assertEqual(r["counts"], {"tp": 120, "fn": 0, "tn": 120, "fp": 0})
        self.assertTrue(r["passed"], r["problems"])

    def test_too_few_photos_never_pass(self):
        for f in list((self.tmp / "negative").glob("*"))[20:]:
            f.unlink()
        r = evaluate.evaluate("eye", self.tmp / "m.onnx", self.tmp, size=32, normalise=False)
        self.assertFalse(r["passed"])
        self.assertIn("needs at least", r["problems"][0])

    def test_wilson_interval(self):
        lo, hi = evaluate.wilson(90, 100)
        self.assertAlmostEqual(lo, 0.826, places=2)
        self.assertAlmostEqual(hi, 0.945, places=2)

    def test_thresholds_match_the_app(self):
        shared = (Path(__file__).resolve().parents[2] / "shared" / "aiScreening.ts").read_text()
        for k, v in json.loads((Path(__file__).resolve().parent / "thresholds.json").read_text()).items():
            if k.startswith("_"):
                continue
            self.assertIn(f"key: '{k}'", shared)
            self.assertIn(f"minSensitivity: {v['minSensitivity']}", shared)


if __name__ == "__main__":
    unittest.main()
