"""SymPy and Z3 discharge of written R-THEOREM-5, which is T-BS-004."""

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from r_theorems import discharge_r_theorem_5  # noqa: E402


EVIDENCE = Path(__file__).resolve().parents[3] / "evidence" / "research" / "prism"


class RTheorem5Tests(unittest.TestCase):
    def test_funded_redemption_preserves_remaining_funding(self):
        report = discharge_r_theorem_5()
        self.assertEqual(report["canonical_id"], "T-BS-004")
        self.assertEqual(report["classification"], "PROVEN_UNDER_ASSUMPTIONS")
        self.assertIsNone(report["counterexample"])
        self.assertTrue(report["residual_equals_initial_surplus"])
        self.assertEqual(report["negation"], "unsat")
        self.assertTrue(report["overpayment_can_break_funding"])
        per_call = report["per_call_rule"]
        self.assertEqual(per_call["paid_raw"], 0)
        self.assertFalse(per_call["pays_exact_qr"])
        self.assertTrue(per_call["funding_still_holds"])
        self.assertEqual(per_call["remaining_supply"], 0)
        self.assertEqual(per_call["remaining_balance"], 2)
        self.assertEqual(report["reservation_negative_control"], "not_run")
        self.assertEqual(report["canonical_math1"], "FAIL")
        self.assertGreater(report["runtime_seconds"], 0)
        path = EVIDENCE / "r-theorem-5-2026-09-26.json"
        path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")


if __name__ == "__main__":
    unittest.main()
