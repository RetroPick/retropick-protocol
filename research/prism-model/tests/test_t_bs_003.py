"""SymPy and Z3 discharge of written T-BS-003 for every finite component count."""

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from t_bs_003 import discharge_t_bs_003  # noqa: E402


EVIDENCE = Path(__file__).resolve().parents[3] / "evidence" / "research" / "prism"


class TBs003Tests(unittest.TestCase):
    def test_component_backing_implies_terminal_solvency(self):
        report = discharge_t_bs_003()
        path = EVIDENCE / "t-bs-003-2026-09-26.json"
        path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")
        self.assertEqual(report["id"], "T-BS-003")
        self.assertEqual(report["classification"], "PROVEN_UNDER_ASSUMPTIONS")
        self.assertIsNone(report["counterexample"])
        self.assertEqual(report["component_counts"], "every finite n >= 1")
        self.assertTrue(report["gap_is_margin_dot_payoff"])
        self.assertEqual(report["inductive_step"], "unsat")
        outside = report["negative_payoff_outside_assumption"]
        self.assertTrue(outside["breaks_inequality"])
        self.assertEqual(outside["backing_value"], -2)
        self.assertEqual(outside["liability"], -1)
        model = report["model_check"]
        self.assertEqual(model["components"], 3)
        self.assertEqual(model["states"], 4)
        self.assertTrue(model["all_solvent"])
        self.assertEqual(len(model["rows"]), 4)
        self.assertEqual(report["canonical_math1"], "FAIL")
        self.assertGreater(report["runtime_seconds"], 0)


if __name__ == "__main__":
    unittest.main()
