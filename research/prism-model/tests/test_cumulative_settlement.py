"""Candidate cumulative floor. The per-call rule stays a permanent failure."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from cumulative_settlement import CumulativeFloorSettlement  # noqa: E402
from cumulative_settlement_attack import (  # noqa: E402
    canonical_counterexample_still_fails,
    original_case_on_candidate,
    per_call_mint_then_oneshot_redeem,
    run_attack,
)
from fixed_point import WAD  # noqa: E402
from fixed_point_model import FixedPointSettlement  # noqa: E402


class CumulativeSettlementTests(unittest.TestCase):
    def test_per_call_rule_remains_the_counterexample(self):
        row = canonical_counterexample_still_fails()
        self.assertEqual(row["classification"], "COUNTEREXAMPLE_FOUND")
        self.assertEqual(row["fragmented_paid_raw"], 0)
        self.assertEqual(row["one_shot_floor_raw"], 1)
        self.assertEqual(row["swept_dust_raw"], 2)
        book = FixedPointSettlement(2, WAD - 1, 18, 2)
        book.make_redeemable()
        self.assertEqual(book.redeem(1) + book.redeem(1), 0)

    def test_candidate_pays_the_original_case_without_replacing_the_oracle(self):
        row = original_case_on_candidate()
        self.assertEqual(row["candidate_paid"], 1)
        self.assertEqual(row["candidate_residual"], 1)
        self.assertEqual(row["per_holder_cursor_paid"], 0)
        self.assertEqual(row["orders"]["AB"]["paid"], row["orders"]["BA"]["paid"])
        self.assertFalse(hasattr(CumulativeFloorSettlement, "mint"))
        self.assertFalse(hasattr(FixedPointSettlement, "cumulative_redeem"))

    def test_attack_holds_on_the_searched_domain(self):
        report = run_attack()
        self.assertEqual(report["failures"], [])
        self.assertIsNone(report["new_counterexample"])
        self.assertEqual(report["leakage_bound"]["classification"], "PROVEN_UNDER_ASSUMPTIONS")
        self.assertEqual(report["leakage_bound"]["domain_check"], "EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN")
        self.assertEqual(report["canonical_math1"], "FAIL")
        self.assertEqual(report["per_call_mint_extraction_raw"], 1)
        self.assertEqual(per_call_mint_then_oneshot_redeem(2, WAD - 1, 18), 1)
        self.assertEqual(report["shared_cursor_cycle_mismatches"], 0)
        self.assertEqual(report["single_call_max_shortfall_vs_isolated_floor"], 0)
        self.assertLessEqual(report["single_call_max_surplus_vs_isolated_floor"], 1)
        self.assertGreater(report["states"], 0)
        self.assertGreater(report["transitions"], 0)
        self.assertGreater(report["runtime_seconds"], 0)
        self.assertFalse(report["rejection"]["mutated"])
        fragment = report["self_fragmentation"]
        self.assertEqual(fragment["paid"], fragment["one_shot"])
        self.assertTrue(fragment["holder_a_below_isolated_floor"])
        self.assertTrue(fragment["shortfall_received_by_other"])
        self.assertLessEqual(fragment["residual"], 1)


if __name__ == "__main__":
    unittest.main()
