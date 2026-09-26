"""SymPy and Z3 discharge of written T-BS-002, the exact in-kind redemption."""

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from t_bs_002 import discharge_t_bs_002  # noqa: E402


EVIDENCE = Path(__file__).resolve().parents[3] / "evidence" / "research" / "prism"


class TBs002Tests(unittest.TestCase):
    def test_in_kind_redemption_preserves_margin(self):
        report = discharge_t_bs_002()
        path = EVIDENCE / "t-bs-002-2026-09-26.json"
        path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")
        self.assertEqual(report["id"], "T-BS-002")
        self.assertEqual(report["classification"], "PROVEN_UNDER_ASSUMPTIONS")
        self.assertIsNone(report["counterexample"])
        self.assertTrue(report["margin_identity"])
        self.assertEqual(report["backing_shortfall"], "unsat")
        exact = report["exact_redeem"]
        self.assertEqual(exact["released"], ["150", "100"])
        self.assertEqual(exact["margin_before"], ["0", "0"])
        self.assertEqual(exact["margin_after"], ["0", "0"])
        self.assertEqual(exact["backing_after"], ["450", "300"])
        self.assertEqual(exact["supply_after"], "750")
        surplus = report["surplus_redeem"]
        self.assertEqual(surplus["margin_before"], ["1", "0"])
        self.assertEqual(surplus["margin_after"], ["1", "0"])
        self.assertEqual(report["canonical_math1"], "FAIL")
        self.assertGreater(report["runtime_seconds"], 0)


if __name__ == "__main__":
    unittest.main()
