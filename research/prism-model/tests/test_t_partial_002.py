"""SymPy and Z3 discharge of written T-PARTIAL-002."""

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from t_partial_002 import discharge_t_partial_002  # noqa: E402


EVIDENCE = Path(__file__).resolve().parents[3] / "evidence" / "research" / "prism"


class TPartial002Tests(unittest.TestCase):
    def test_transform_preserves_backing_on_remaining_states(self):
        report = discharge_t_partial_002()
        path = EVIDENCE / "t-partial-002-2026-09-26.json"
        path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")
        self.assertEqual(report["id"], "T-PARTIAL-002")
        self.assertEqual(report["classification"], "PROVEN_UNDER_ASSUMPTIONS")
        self.assertIsNone(report["counterexample"])
        self.assertEqual(report["failed_shapes"], [])
        self.assertEqual(report["value_iff_component_payoff"], "unsat")
        self.assertEqual(report["remaining_state_negation"], "unsat")
        model = report["model_check"]
        self.assertEqual(model["cash_added"], "400")
        self.assertEqual(model["remaining"], [0, 2])
        self.assertTrue(model["preserves_remaining"])
        self.assertFalse(model["preserves_state_outside"])
        self.assertFalse(model["mismatched_portfolio_equivalent"])
        self.assertEqual(report["canonical_math1"], "FAIL")
        self.assertGreater(report["runtime_seconds"], 0)


if __name__ == "__main__":
    unittest.main()
