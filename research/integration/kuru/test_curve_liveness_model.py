"""Bounded adversarial sequences for a proposed generic completion ceiling."""

import unittest
import json
from pathlib import Path

from curve_liveness_campaign import run_campaign, run_legacy_campaign
from curve_liveness_model import (
    CompletionCeilingRejected, CurveState, TradeRejected, admit_transition,
)


class CurveLivenessModelTest(unittest.TestCase):
    @staticmethod
    def launch(decimals: int, buyback_enabled: bool = False) -> CurveState:
        return CurveState(
            phantom_quote=100 * 10**decimals,
            reserved_tokens=500_000 * 10**18,
            tracked_tokens=1_000_000 * 10**18,
            buyback_enabled=buyback_enabled,
        )

    def test_two_raw_cycle_is_minimal_and_repeatedly_pumps(self):
        for decimals in (18, 6):
            with self.subTest(decimals=decimals):
                state = self.launch(decimals)
                one_raw, tokens, spent = state.buy(1)
                self.assertEqual(spent, 1)
                with self.assertRaisesRegex(TradeRejected, "zero gross quote"):
                    one_raw.sell(tokens)
                for i in range(16):
                    after_buy, tokens, spent = state.buy(2)
                    self.assertEqual(spent, 2)
                    state, payout = after_buy.sell(tokens)
                    self.assertEqual(payout, 1)
                    self.assertEqual(state.tracked_tokens, 1_000_000 * 10**18)
                    self.assertEqual(state.real_quote, i + 1)
                    self.assertEqual(state.completion(), state.phantom_quote + 2 + 2 * (i + 1))

    def test_guard_preserves_completion_at_fifth_cycle_boundary(self):
        for decimals in (18, 6):
            with self.subTest(decimals=decimals):
                state = self.launch(decimals)
                ceiling = state.phantom_quote + 10
                for i in range(5):
                    after_buy, tokens, _ = state.buy(2)
                    after_buy = admit_transition(after_buy, ceiling)
                    after_sell, _ = after_buy.sell(tokens)
                    if i < 4:
                        state = admit_transition(after_sell, ceiling)
                    else:
                        self.assertEqual(after_buy.completion(), ceiling)
                        self.assertEqual(after_sell.real_quote, 5)
                        self.assertLess(after_sell.real_quote, ceiling)
                        self.assertEqual(after_sell.completion(), ceiling + 2)
                        with self.assertRaises(CompletionCeilingRejected):
                            admit_transition(after_sell, ceiling)
                        self.assertEqual(after_buy.completion(), ceiling)

    def test_sweep_and_buyback_transitions_are_checked_not_exempted(self):
        for decimals in (18, 6):
            with self.subTest(decimals=decimals):
                state = self.launch(decimals, buyback_enabled=True)
                after_buy, _, _ = state.buy(20 * 10**decimals)
                self.assertGreater(after_buy.buyback_quote_balance, 0)
                swept = after_buy.sweep(min_buyback_tokens_out=1)
                self.assertEqual(swept.quote_fee_balance, 0)
                self.assertLessEqual(swept.tracked_tokens, after_buy.tracked_tokens)
                # The guard applies even if the trusted sweep executes an
                # internal token buyback and changes both reserve axes.
                ceiling = max(after_buy.completion(), swept.completion())
                self.assertEqual(admit_transition(swept, ceiling), swept)
                if swept.completion() > after_buy.completion():
                    with self.assertRaises(CompletionCeilingRejected):
                        admit_transition(swept, after_buy.completion())

    def test_authorized_fee_rescue_preserves_tradeable_reserve_and_completion(self):
        for decimals in (18, 6):
            with self.subTest(decimals=decimals):
                state = self.launch(decimals, buyback_enabled=True)
                bought, _, _ = state.buy(20 * 10**decimals)
                self.assertGreater(bought.quote_fee_balance, 0)
                self.assertGreater(bought.buyback_quote_balance, 0)
                rescued = bought.rescue_fees()
                self.assertEqual(rescued.real_quote, bought.real_quote)
                self.assertEqual(rescued.reserve_product, bought.reserve_product)
                self.assertEqual(rescued.completion(), bought.completion())
                self.assertEqual(rescued.buyback_quote_balance, 0)
                self.assertEqual(admit_transition(rescued, bought.completion()), rescued)
                with self.assertRaisesRegex(TradeRejected, "no fees"):
                    rescued.rescue_fees()

    def test_deterministic_stateful_campaign_keeps_every_accepted_state_completable(self):
        result = run_campaign()
        self.assertEqual(result["schema_version"], 2)
        self.assertEqual(
            result["classification"],
            "BOUNDED_MULTI_PROFILE_MODEL_CAMPAIGN_NOT_PRODUCTION_GUARD_PROOF",
        )
        self.assertEqual(len(result["rows"]), 48)
        self.assertEqual(
            {row["profile"] for row in result["rows"]},
            {
                "BASELINE",
                "MINIMUM_VALID",
                "SMALL",
                "MEDIUM_NONDIVISIBLE",
                "HIGH_COMBINED_FEE",
                "ZERO_FEE",
                "LARGE",
                "MAXIMUM_CANDIDATE",
            },
        )
        self.assertEqual({row["quote_decimals"] for row in result["rows"]}, {18, 6})
        self.assertEqual(result["seeds"], [20260930, 20261001, 20261002])
        self.assertEqual(result["random_steps_per_history"], 220)
        self.assertEqual(
            result["totals"],
            {"histories": 48, "accepted": 4954, "ceiling_rejected": 48,
             "invalid_calls": 6176},
        )
        for row in result["rows"]:
            self.assertIn(row["quote_decimals"], (18, 6))
            self.assertEqual(row["random_attempts"], 220)
            self.assertEqual(row["prelude"]["pump_cycles_accepted"], 4)
            self.assertEqual(row["prelude"]["fresh_pump"]["accepted"], 8)
            self.assertGreater(row["prelude"]["fresh_pump"]["quote_gain_raw"], 0)
            self.assertTrue(row["prelude"]["boundary_sell_probe"]["attempted"])
            self.assertTrue(row["prelude"]["boundary_sell_probe"]["ceiling_rejected"])
            self.assertTrue(row["prelude"]["near_crossing_one_token_sell"]["attempted"])
            self.assertEqual(
                row["prelude"]["near_crossing_one_token_sell"]["invalid_reason"],
                "zero gross quote output",
            )
            self.assertLessEqual(row["final_immediate_terminal_quote_raw"],
                                 row["ceiling_raw"])
        self.assertGreater(result["totals"]["accepted"], 0)
        self.assertEqual(
            sum(row["prelude"]["boundary_sell_probe"]["ceiling_rejected"]
                for row in result["rows"]),
            48,
        )
        self.assertEqual(
            {action for row in result["rows"] for action in row["action_attempts"]},
            {"buy", "sell", "sweep", "rescue_fees", "model_buyback_toggle"},
        )

    def test_stateful_campaign_artifact_matches_generator(self):
        root = Path(__file__).resolve().parents[3]
        artifact = root / "evidence/launchpad/kuru/curve-liveness-campaign-2026-10-01.json"
        self.assertEqual(json.loads(artifact.read_text()), run_campaign())

    def test_legacy_stateful_campaign_artifact_remains_reproducible(self):
        root = Path(__file__).resolve().parents[3]
        artifact = root / "evidence/launchpad/kuru/curve-liveness-campaign-2026-09-30.json"
        self.assertEqual(json.loads(artifact.read_text()), run_legacy_campaign())


if __name__ == "__main__":
    unittest.main()
