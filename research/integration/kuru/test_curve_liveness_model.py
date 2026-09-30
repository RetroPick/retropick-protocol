"""Bounded adversarial sequences for a proposed generic completion ceiling."""

import unittest
import json
from pathlib import Path

from curve_liveness_campaign import run_campaign
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
        self.assertEqual(len(result["rows"]), 6)
        self.assertGreater(result["totals"]["accepted"], 100)
        self.assertGreater(result["totals"]["ceiling_rejected"], 0)
        self.assertGreater(result["totals"]["invalid_calls"], 0)
        for row in result["rows"]:
            self.assertEqual(row["prelude_accepted_calls"], 8)
            self.assertEqual(row["random_attempts"], 300)
            self.assertLessEqual(row["final_immediate_terminal_quote_raw"],
                                 row["ceiling_raw"])

    def test_stateful_campaign_artifact_matches_generator(self):
        root = Path(__file__).resolve().parents[3]
        artifact = root / "evidence/launchpad/kuru/curve-liveness-campaign-2026-09-30.json"
        self.assertEqual(json.loads(artifact.read_text()), run_campaign())


if __name__ == "__main__":
    unittest.main()
