"""Observed zero-supply settlement residual. No new sweep."""

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from zero_supply_dust import discharge_zero_supply_dust  # noqa: E402


EVIDENCE = Path(__file__).resolve().parents[3] / "evidence" / "research" / "prism"


class ZeroSupplyDustTests(unittest.TestCase):
    def test_residual_sits_unwithdrawn(self):
        report = discharge_zero_supply_dust()
        path = EVIDENCE / "zero-supply-dust-2026-09-26.json"
        path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")
        self.assertEqual(report["id"], "ZERO-SUPPLY-DUST")
        self.assertEqual(report["ceil_floor_gap"], "unsat")
        self.assertEqual(report["residual_bound"], "PROVEN_UNDER_ASSUMPTIONS")
        self.assertEqual(report["sweep_policy"], "NOT_YET_VALIDATED")
        self.assertIsNone(report["extraction_witness"])
        self.assertEqual(report["canonical_math1"], "FAIL")
        self.assertEqual(report["kernel_status"], "differential_research_kernel")
        self.assertEqual(report["cx_fp_settlement_001"], "COUNTEREXAMPLE_FOUND")
        self.assertEqual(report["zero_supply_python_cells"], 24)

        constructed = report["cases"]["constructed_at_supply_0"]
        self.assertTrue(constructed["all_cells_match"])
        self.assertEqual(constructed["residual"], 0)
        self.assertEqual(constructed["solidity_candidate"], "constructor reverts ZeroSupply; the object is not created")

        redeemed = report["cases"]["supply_reaches_0_after_full_redemption"]
        self.assertTrue(redeemed["exact_ceil_observed"])
        sitting = redeemed["candidate_residual_one"]
        self.assertEqual(sitting["first_payout"], 0)
        self.assertEqual(sitting["second_payout"], 1)
        self.assertEqual(sitting["residual"], 1)
        self.assertEqual(sitting["one_shot_floor"], 1)
        self.assertFalse(sitting["post_zero"]["withdrew"])
        self.assertTrue(sitting["post_zero"]["state_unchanged"])
        self.assertEqual(redeemed["candidate_residual_zero"]["residual"], 0)
        self.assertFalse(redeemed["candidate_residual_zero"]["post_zero"]["withdrew"])
        self.assertEqual(redeemed["surplus_above_ceil"]["residual"], 4)
        self.assertFalse(redeemed["surplus_above_ceil"]["withdrawn"])
        per_call = redeemed["canonical_per_call_read"]
        self.assertEqual(per_call["first_payout"], 0)
        self.assertEqual(per_call["second_payout"], 0)
        self.assertEqual(per_call["sweepable_dust_read"], 2)
        self.assertEqual(per_call["balance_after_read"], 2)
        self.assertFalse(per_call["read_moved_balance"])

        one_unit = report["cases"]["one_unit_redemption_at_supply_0"]
        self.assertTrue(one_unit["rejected_and_unchanged"])
        self.assertEqual(one_unit["constructed"]["redeem_errors"]["A"], "unknown holder")
        self.assertEqual(one_unit["after_depletion"]["redeem_errors"]["A"], "invalid candidate redemption quantity")
        self.assertEqual(one_unit["after_depletion"]["balance_after"], 1)

        exact = report["exact_rational_series"]
        self.assertEqual(exact["constructed_redeem_error"], "invalid final redemption quantity")
        self.assertEqual(exact["constructed_balance_after_archive"], "0")
        self.assertEqual(exact["full_redemption_paid"], "2")
        self.assertEqual(exact["full_redemption_balance_before_archive"], "3")
        self.assertEqual(exact["full_redemption_balance_after_archive"], "3")
        self.assertFalse(exact["archive_moved_settlement_balance"])

        self.assertEqual(report["component_backing_sweep"]["returned"], [2])
        self.assertEqual(report["component_backing_sweep"]["backing_after"], [0])
        self.assertNotIn("sweep_dust", report["cumulative_public_methods"])
        self.assertNotIn("sweep_dust", report["canonical_settlement_public_methods"])
        self.assertIn("sweepable_dust", report["canonical_settlement_public_methods"])
        solidity = report["solidity"]
        self.assertEqual(solidity["safe_transfer_count"], 1)
        self.assertFalse(solidity["sweep_function"])
        self.assertTrue(solidity["reverts_zero_supply"])
        self.assertTrue(solidity["redeem_transfers_only_nonzero_payout"])
        self.assertGreater(report["runtime_seconds"], 0)


if __name__ == "__main__":
    unittest.main()
