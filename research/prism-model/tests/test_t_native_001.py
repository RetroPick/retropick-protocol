"""SymPy and Z3 discharge of written T-NATIVE-001, complete-set conservation."""

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from t_native_001 import discharge_t_native_001  # noqa: E402


EVIDENCE = Path(__file__).resolve().parents[3] / "evidence" / "research" / "prism"


class TNative001Tests(unittest.TestCase):
    def test_split_merge_conserves_complete_set(self):
        report = discharge_t_native_001()
        path = EVIDENCE / "t-native-001-2026-09-26.json"
        path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")
        self.assertEqual(report["id"], "T-NATIVE-001")
        self.assertEqual(report["classification"], "PROVEN_UNDER_ASSUMPTIONS")
        self.assertIsNone(report["counterexample"])
        self.assertTrue(report["gap_identity"])
        self.assertEqual(report["split_breaks_equality"], "unsat")
        self.assertEqual(report["merge_breaks_equality"], "unsat")
        model = report["model_check"]
        self.assertEqual(model["yes"], "75")
        self.assertEqual(model["no"], "75")
        self.assertEqual(model["collateral"], "75")
        self.assertEqual(model["open_interest"], "75")
        rejected = report["rejected_merge"]
        self.assertTrue(rejected["rejected"])
        self.assertTrue(rejected["unchanged"])
        self.assertEqual(report["canonical_math1"], "FAIL")
        self.assertGreater(report["runtime_seconds"], 0)


if __name__ == "__main__":
    unittest.main()
