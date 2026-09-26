"""Z3 discharge of written T-FP-003, the guarded settlement-funding claim."""

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from fixed_point import WAD  # noqa: E402
from t_fp_003 import discharge_t_fp_003  # noqa: E402


EVIDENCE = Path(__file__).resolve().parents[3] / "evidence" / "research" / "prism"


class TFp003Tests(unittest.TestCase):
    def test_guarded_floor_redemption_preserves_funding(self):
        report = discharge_t_fp_003()
        path = EVIDENCE / "t-fp-003-2026-09-26.json"
        path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")
        self.assertEqual(report["id"], "T-FP-003")
        self.assertEqual(report["classification"], "PROVEN_UNDER_ASSUMPTIONS")
        self.assertIsNone(report["counterexample"])
        self.assertEqual(report["funded_shortfall"], "unsat")
        witness = report["fragmentation_witness"]
        self.assertEqual(witness["supply"], 2)
        self.assertEqual(witness["payout_wad"], WAD - 1)
        self.assertEqual(witness["required_raw"], 2)
        self.assertEqual(witness["first_payout"], 0)
        self.assertEqual(witness["second_payout"], 0)
        self.assertEqual(witness["one_shot_floor"], 1)
        self.assertEqual(witness["sweepable_dust"], 2)
        self.assertEqual(witness["after_first_balance"], 2)
        self.assertEqual(witness["after_first_required"], 1)
        self.assertTrue(witness["funding_held"])
        self.assertFalse(witness["holders_receive_one_shot"])
        rejected = report["rejected_underfunded_call"]
        self.assertTrue(rejected["rejected"])
        self.assertTrue(rejected["unchanged"])
        self.assertEqual(report["holder_sum_claim"], "not_this_statement")
        self.assertEqual(report["cx_fp_settlement_001"], "COUNTEREXAMPLE_FOUND")
        self.assertEqual(report["canonical_math1"], "FAIL")
        self.assertGreater(report["runtime_seconds"], 0)


if __name__ == "__main__":
    unittest.main()
