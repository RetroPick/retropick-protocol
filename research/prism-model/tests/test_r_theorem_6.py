"""Z3 and ledger discharge of written R-THEOREM-6, which is T-ALLOC-001."""

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from r_theorems import discharge_r_theorem_6  # noqa: E402


EVIDENCE = Path(__file__).resolve().parents[3] / "evidence" / "research" / "prism"


class RTheorem6Tests(unittest.TestCase):
    def test_reservations_cannot_double_use_physical_balance(self):
        report = discharge_r_theorem_6()
        self.assertEqual(report["canonical_id"], "T-ALLOC-001")
        self.assertEqual(report["classification"], "PROVEN_UNDER_ASSUMPTIONS")
        self.assertIsNone(report["counterexample"])
        self.assertTrue(report["double_use_rejected"])
        control = report["negative_control"]
        self.assertEqual(control["balance"], 100)
        self.assertEqual(control["first"], 60)
        self.assertEqual(control["second"], 50)
        self.assertTrue(control["rejected"])
        self.assertTrue(control["unchanged"])
        self.assertEqual(control["available_after_reject"], "40")
        fitting = report["fitting_reservations"]
        self.assertEqual(fitting["available"], "15")
        self.assertEqual(fitting["first"], 60)
        self.assertEqual(fitting["second"], 25)
        self.assertEqual(fitting["balance"], 100)
        self.assertEqual(
            report["negation"],
            {"deposit": "unsat", "reserve": "unsat", "release": "unsat", "withdraw": "unsat"},
        )
        self.assertEqual(report["canonical_math1"], "FAIL")
        self.assertGreater(report["runtime_seconds"], 0)
        path = EVIDENCE / "r-theorem-6-2026-09-26.json"
        path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")


if __name__ == "__main__":
    unittest.main()
