"""SymPy and Z3 discharge of written T-FP-002, the requirement-delta redemption."""

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from t_fp_002 import discharge_t_fp_002  # noqa: E402


EVIDENCE = Path(__file__).resolve().parents[3] / "evidence" / "research" / "prism"


class TFp002Tests(unittest.TestCase):
    def test_requirement_delta_keeps_remaining_supply_backed(self):
        report = discharge_t_fp_002()
        path = EVIDENCE / "t-fp-002-2026-09-26.json"
        path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")
        self.assertEqual(report["id"], "T-FP-002")
        self.assertEqual(report["classification"], "PROVEN_UNDER_ASSUMPTIONS")
        self.assertIsNone(report["counterexample"])
        self.assertTrue(report["margin_identity"])
        self.assertEqual(report["remaining_shortfall"], "unsat")
        model = report["model_check"]
        self.assertEqual(model["supply_before"], 5)
        self.assertEqual(model["redeemed"], 2)
        self.assertEqual(model["supply_after"], 3)
        self.assertEqual(model["requirement_before"], [3, 3])
        self.assertEqual(model["backing_before"], [3, 3])
        self.assertEqual(model["released"], [1, 1])
        self.assertEqual(model["requirement_after"], [2, 2])
        self.assertEqual(model["backing_after"], [2, 2])
        self.assertTrue(model["still_backed"])
        self.assertTrue(model["margin_unchanged"])
        self.assertEqual(report["settlement_redemption"], "not_this_statement")
        self.assertEqual(report["canonical_math1"], "FAIL")
        self.assertGreater(report["runtime_seconds"], 0)


if __name__ == "__main__":
    unittest.main()
