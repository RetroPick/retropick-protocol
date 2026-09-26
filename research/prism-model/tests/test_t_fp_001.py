"""Z3 discharge of written T-FP-001, the ceil component-mint requirement."""

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from t_fp_001 import discharge_t_fp_001  # noqa: E402


EVIDENCE = Path(__file__).resolve().parents[3] / "evidence" / "research" / "prism"


class TFp001Tests(unittest.TestCase):
    def test_ceil_requirement_prevents_mint_underreservation(self):
        report = discharge_t_fp_001()
        path = EVIDENCE / "t-fp-001-2026-09-26.json"
        path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")
        self.assertEqual(report["id"], "T-FP-001")
        self.assertEqual(report["classification"], "PROVEN_UNDER_ASSUMPTIONS")
        self.assertIsNone(report["counterexample"])
        self.assertEqual(report["ceil_shortfall"], "unsat")
        self.assertEqual(report["backed_raw_shortfall"], "unsat")
        floor = report["floor_control"]
        self.assertEqual(floor["floor_raw"], 0)
        self.assertEqual(floor["ceil_raw"], 1)
        self.assertFalse(floor["floor_covers_exact"])
        self.assertTrue(floor["ceil_covers_exact"])
        rejected = report["rejected_mint"]
        self.assertTrue(rejected["rejected"])
        self.assertTrue(rejected["unchanged"])
        self.assertEqual(rejected["supply"], 0)
        self.assertEqual(rejected["backing"], [1, 0])
        accepted = report["accepted_mint"]
        self.assertEqual(accepted["supply"], 1)
        self.assertEqual(accepted["backing"], [1, 1])
        self.assertTrue(accepted["covers_exact"])
        self.assertTrue(accepted["equals_requirement"])
        self.assertEqual(report["settlement_redemption"], "not_this_statement")
        self.assertEqual(report["canonical_math1"], "FAIL")
        self.assertGreater(report["runtime_seconds"], 0)


if __name__ == "__main__":
    unittest.main()
