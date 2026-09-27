"""SymPy discharge of R-THEOREM-1. Does not re-run the later theorems."""

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from r_theorems import INVENTORY, discharge_r_theorem_1  # noqa: E402


EVIDENCE = Path(__file__).resolve().parents[3] / "evidence" / "research" / "prism"


class RTheorem1Tests(unittest.TestCase):
    def test_h_equals_gx_for_finite_shapes(self):
        report = discharge_r_theorem_1()
        self.assertEqual(report["classification"], "PROVEN_UNDER_ASSUMPTIONS")
        self.assertIsNone(report["counterexample"])
        self.assertEqual(report["failed_shapes"], [])
        self.assertTrue(report["oracle_matches_matrix_product"])
        self.assertEqual(report["oracle_payoff"], ["2/5", "0", "1", "3/5"])
        self.assertFalse(report["nonnegativity_required_for_equality"])
        self.assertEqual(report["canonical_math1"], "FAIL")
        self.assertGreater(report["runtime_seconds"], 0)
        self.assertEqual(INVENTORY["R-THEOREM-1"]["before"], "prose")
        self.assertEqual(INVENTORY["R-THEOREM-4"]["before"], "PARTIALLY_PROVEN")
        payload = {"inventory": INVENTORY, "check": report}
        path = EVIDENCE / "r-theorem-1-2026-09-26.json"
        path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n")


if __name__ == "__main__":
    unittest.main()
