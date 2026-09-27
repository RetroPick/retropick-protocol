"""SymPy and Z3 discharge of written T-FP-004, the minimum mint/redeem cycle."""

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from t_fp_004 import discharge_t_fp_004  # noqa: E402


EVIDENCE = Path(__file__).resolve().parents[3] / "evidence" / "research" / "prism"


class TFp004Tests(unittest.TestCase):
    def test_minimum_mint_redeem_cycle_extracts_nothing(self):
        report = discharge_t_fp_004()
        path = EVIDENCE / "t-fp-004-2026-09-26.json"
        path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")
        self.assertEqual(report["id"], "T-FP-004")
        self.assertEqual(report["classification"], "PROVEN_UNDER_ASSUMPTIONS")
        self.assertIsNone(report["counterexample"])
        self.assertTrue(report["delta_identity"])
        self.assertEqual(report["cycle_shortfall"], "unsat")
        cycle = report["closed_cycle"]
        self.assertEqual(cycle["deposited"], [3, 3])
        self.assertEqual(cycle["released"], [3, 3])
        self.assertEqual(cycle["net_extraction"], [0, 0])
        self.assertEqual(cycle["supply_after"], 0)
        self.assertEqual(cycle["backing_after"], [0, 0])
        surplus = report["surplus_preserved"]
        self.assertEqual(surplus["deposited"], [3, 3])
        self.assertEqual(surplus["released"], [3, 3])
        self.assertEqual(surplus["backing_after"], [1, 1])
        self.assertTrue(surplus["surplus_unchanged"])
        self.assertEqual(report["settlement_redemption"], "not_this_statement")
        self.assertEqual(report["canonical_math1"], "FAIL")
        self.assertGreater(report["runtime_seconds"], 0)


if __name__ == "__main__":
    unittest.main()
