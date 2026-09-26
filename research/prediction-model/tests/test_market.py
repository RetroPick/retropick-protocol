"""Prediction reference-model tests."""

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from adversarial import run_sequences  # noqa: E402
from domain import MarketState, Outcome, PredictionError, ResolutionResult  # noqa: E402
from exhaustive_search import explore  # noqa: E402
from fixed_point import compare_scales, dust_bound, half_up_both_sides  # noqa: E402
from fixtures_build import build  # noqa: E402
from invariants import check_market  # noqa: E402
from market import activate_binary, create_market  # noqa: E402
from theorems import all_theorems  # noqa: E402


class TheoremTests(unittest.TestCase):
    def test_theorem_labels(self):
        labels = all_theorems()
        self.assertEqual(labels["P-THEOREM-1"], "PROVEN")
        self.assertEqual(labels["P-THEOREM-2"], "PROVEN")
        self.assertEqual(labels["P-THEOREM-3"], "PROVEN")
        self.assertEqual(labels["P-THEOREM-4"], "PROVEN")
        self.assertEqual(labels["P-THEOREM-5"], "PROVEN")
        self.assertEqual(labels["P-THEOREM-6"], "PROVEN")
        self.assertEqual(labels["P-THEOREM-6-half-up"], "COUNTEREXAMPLE_FOUND")
        self.assertEqual(labels["P-THEOREM-6-fragmentation"], "COUNTEREXAMPLE_FOUND")
        self.assertEqual(labels["P-THEOREM-7"], "PROVEN")
        self.assertEqual(labels["CX-PRED-FEE-NAIVE"], "COUNTEREXAMPLE_FOUND")
        self.assertEqual(labels["CX-PRED-UNQUALIFIED-COLLATERAL"], "PROVEN")

    def test_half_up_counterexample_is_concrete(self):
        self.assertGreater(half_up_both_sides(1), 1)


class AdversarialTests(unittest.TestCase):
    def test_sequences(self):
        report = run_sequences()
        failed = {key: value for key, value in report.items() if value == "FAIL"}
        self.assertEqual(failed, {})
        self.assertEqual(report["redeem_loser"], "PAYS_ZERO")
        self.assertEqual(report["invalid_dust_yes_side"], "BOUNDED")


class LifecycleTests(unittest.TestCase):
    def test_full_yes_path_and_archive(self):
        market = create_market(integer=True, collateral="COLL", dust_sink="SINK")
        activate_binary(market, market_id="m", resolver="resolver", spec_hash="h")
        market.split("alice", 4, 4)
        market.close_mint()
        market.begin_resolution()
        market.resolve("resolver", ResolutionResult.YES_WIN)
        self.assertEqual(market.state, MarketState.RESOLVED)
        with self.assertRaises(PredictionError):
            market.redeem("alice", Outcome.YES, 1)
        market.open_redemption()
        self.assertEqual(market.redeem("alice", Outcome.YES, 4), 4)
        market.burn_worthless("alice", Outcome.NO, 4)
        residual = market.archive()
        self.assertEqual(residual, 0)
        self.assertEqual(market.state, MarketState.ARCHIVED)
        check_market(market)

    def test_cancel_draft(self):
        market = create_market(integer=True, collateral="COLL", dust_sink="SINK")
        market.cancel_draft()
        check_market(market)
        self.assertEqual(market.state, MarketState.ARCHIVED)

    def test_merge_allowed_while_locked(self):
        market = create_market(integer=True, collateral="COLL", dust_sink="SINK")
        activate_binary(market, market_id="m", resolver="resolver", spec_hash="h")
        market.split("alice", 5, 5)
        market.close_mint()
        released = market.merge("alice", 2)
        self.assertEqual(released, 2)
        self.assertEqual(market.collateral_locked, 3)


class IntegerPolicyTests(unittest.TestCase):
    def test_invalid_dust_is_modulus_two(self):
        for amount in range(1, 33):
            self.assertEqual(dust_bound(amount), amount % 2)
            market = create_market(integer=True, collateral="COLL", dust_sink="SINK")
            activate_binary(market, market_id="m", resolver="resolver", spec_hash="h")
            market.split("alice", amount, amount)
            market.close_mint()
            market.begin_resolution()
            market.resolve("resolver", ResolutionResult.INVALID)
            market.open_redemption()
            market.redeem("alice", Outcome.YES, amount)
            market.redeem("alice", Outcome.NO, amount)
            self.assertEqual(market.collateral_locked, amount % 2)
            self.assertEqual(market.liability(), 0)

    def test_scale_conversion_matches_native_floor(self):
        report = compare_scales(48)
        self.assertTrue(report["identity"])
        self.assertEqual(report["mismatches"], 0)


class ExhaustiveTests(unittest.TestCase):
    def test_small_domain(self):
        report = explore(max_unit=3)
        self.assertEqual(report["failures"], 0)
        self.assertEqual(report["result"], "EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN")
        self.assertGreater(report["states"], 10)
        out = ROOT / "outputs"
        out.mkdir(exist_ok=True)
        (out / "exhaustive_summary.json").write_text(
            json.dumps(report, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )


class FixtureTests(unittest.TestCase):
    def test_fixture_numbers(self):
        payload = build()
        split = payload["prediction_split"]["steps"][0]
        self.assertEqual(split["yes_supply"], "100")
        self.assertEqual(split["no_supply"], "100")
        self.assertEqual(split["collateral_locked"], "100")
        merge = payload["prediction_merge"]["steps"][0]
        self.assertEqual(merge["collateral_locked"], "60")
        resolved = payload["prediction_resolve_yes"]["steps"][0]
        self.assertEqual(resolved["state"], "REDEEMABLE")
        self.assertEqual(resolved["result"], "YES_WIN")
        self.assertEqual(payload["prediction_redeem_yes"]["payout"], "25")
        self.assertEqual(payload["prediction_redeem_yes"]["no_payout"], "0")
        self.assertEqual(payload["prediction_invalid_rounding"]["residual"], "1")
        self.assertEqual(payload["prediction_close_mint"]["state"], "2")
        self.assertEqual(payload["prediction_begin_resolution"]["state"], "3")
        self.assertEqual(payload["prediction_resolve_yes_state"]["state"], "4")
        self.assertEqual(payload["prediction_resolve_yes_state"]["yes_numerator"], "2")
        self.assertEqual(payload["prediction_resolve_no"]["result"], "2")
        self.assertEqual(payload["prediction_resolve_no"]["no_numerator"], "2")
        self.assertEqual(payload["prediction_resolve_invalid"]["liability"], "4")
        self.assertEqual(payload["prediction_redeem_no"]["payout"], "25")
        self.assertEqual(payload["prediction_burn_worthless"]["after_burn"]["no_supply"], "0")
        self.assertEqual(payload["prediction_archive_invalid"]["after_archive"]["residual"], "1")
        self.assertEqual(payload["prediction_merge_locked"]["released"], "2")
        self.assertEqual(payload["prediction_rejections"]["split_after_close"]["status"], "REJECTED")
        self.assertEqual(payload["prediction_rejections"]["invalid_burn"]["status"], "REJECTED")
        directory = ROOT / "fixtures"
        directory.mkdir(exist_ok=True)
        for name, body in payload.items():
            (directory / f"{name}.json").write_text(
                json.dumps(body, indent=2, sort_keys=True) + "\n",
                encoding="utf-8",
            )


if __name__ == "__main__":
    unittest.main()
