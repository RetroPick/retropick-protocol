"""SymPy and Z3 discharge of written T-BS-001, the exact-backed mint."""

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from t_bs_001 import discharge_t_bs_001  # noqa: E402


EVIDENCE = Path(__file__).resolve().parents[3] / "evidence" / "research" / "prism"


class TBs001Tests(unittest.TestCase):
    def test_exact_backed_mint_preserves_margin(self):
        report = discharge_t_bs_001()
        path = EVIDENCE / "t-bs-001-2026-09-26.json"
        path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")
        self.assertEqual(report["id"], "T-BS-001")
        self.assertEqual(report["classification"], "PROVEN_UNDER_ASSUMPTIONS")
        self.assertIsNone(report["counterexample"])
        self.assertTrue(report["margin_identity"])
        self.assertEqual(report["backing_shortfall"], "unsat")
        exact = report["exact_mint"]
        self.assertEqual(exact["margin_before"], ["0", "0"])
        self.assertEqual(exact["margin_after"], ["0", "0"])
        self.assertEqual(exact["backing_after"], ["600", "400"])
        self.assertEqual(exact["supply_after"], "1000")
        surplus = report["surplus_mint"]
        self.assertEqual(surplus["margin_before"], ["1", "0"])
        self.assertEqual(surplus["margin_after"], ["1", "0"])
        self.assertEqual(report["canonical_math1"], "FAIL")
        self.assertGreater(report["runtime_seconds"], 0)


if __name__ == "__main__":
    unittest.main()
