"""Targeted exact-integer negative and representative controls for Kuru freeze."""

import json
import unittest
from pathlib import Path

from benchmark_launch_profiles import build_matrix
from prelaunch_quote_witness import build_witness
from prelaunch_round_trip_witness import build_witness as build_round_trip_witness
from completion_terminal_quote import (
    CurveCompletionState, completion_terminal_quote, terminal_quote_lower_bound,
)
from completion_liveness_witness import build_witness as build_liveness_witness
from launchpad_seed_model import (
    one_shot_crossing_quote, round_trip_crossing_quote, quote_first_seed, quote_opening_ticks,
    valid_router_parameters,
)


class KuruLaunchpadSeedModelTest(unittest.TestCase):
    def test_historical_zero_spread_is_invalid(self):
        params = dict(size_precision=10**8, price_precision=10**8, tick_size=1,
                      min_size=1, max_size=10**12, maker_fee_bps=0,
                      taker_fee_bps=0, amm_spread=0)
        self.assertFalse(valid_router_parameters(**params))
        params["amm_spread"] = 100
        self.assertTrue(valid_router_parameters(**params))

    def test_router_constraint_edges(self):
        base = dict(size_precision=10**8, price_precision=10**8, tick_size=1,
                    min_size=1, max_size=10**12, maker_fee_bps=0,
                    taker_fee_bps=0, amm_spread=100)
        invalid = [
            ("size_precision", 123), ("price_precision", 123),
            ("size_precision", 2**96), ("price_precision", 2**32),
            ("tick_size", 0), ("min_size", 0), ("max_size", 1),
            ("tick_size", 2**32), ("min_size", 2**96),
            ("max_size", 2**96),
            ("maker_fee_bps", 1), ("taker_fee_bps", 10_000),
            ("amm_spread", 9), ("amm_spread", 500),
        ]
        for key, value in invalid:
            with self.subTest(field=key, value=value):
                self.assertFalse(valid_router_parameters(**(base | {key: value})))

    def test_native_and_six_decimal_stable_quote(self):
        for quote_decimals in (6, 18):
            with self.subTest(quote_decimals=quote_decimals):
                result = quote_first_seed(
                    supply=1_000_000 * 10**18,
                    phantom_quote=100 * 10**quote_decimals,
                    secured_quote=100 * 10**quote_decimals,
                    base_decimals=18, quote_decimals=quote_decimals,
                    size_precision=10**8, amm_spread=100,
                )
                self.assertEqual(result.base_seed, 500_000 * 10**18)
                self.assertEqual(result.excess_base, 500_000 * 10**18)
                self.assertEqual(result.price_difference, 0)
                self.assertTrue(result.seedable_in_reduced_model)

    def test_rounding_bound_for_nondivisible_terminal_reserves(self):
        result = quote_first_seed(
            supply=10_000 * 10**18 + 123,
            phantom_quote=3_000_001,
            secured_quote=3_000_003,
            base_decimals=18, quote_decimals=6,
            size_precision=10**8, amm_spread=100,
        )
        self.assertGreaterEqual(result.price_difference, 0)
        self.assertLessEqual(result.price_difference,
                             result.scaled_price_error_upper_bound)
        self.assertGreater(result.price_error_numerator, 0)
        self.assertLess(result.price_error_numerator * result.base_seed,
                        result.price_error_denominator)
        # B=floor(T*Q/(P+Q)); the relative upward drift is < 1/B.
        self.assertLessEqual(
            result.kuru_first_ask_price_scaled * result.base_seed,
            result.terminal_price_scaled * (result.base_seed + 1)
            + result.base_seed,
        )
        self.assertTrue(result.seedable_in_reduced_model)

    def test_exhaustive_small_terminal_price_continuity_domain(self):
        checked = 0
        for supply in range(2, 26):
            for phantom in range(1, 26):
                for secured in range(1, 26):
                    base = supply * secured // (phantom + secured)
                    if base == 0:
                        continue
                    quote = quote_first_seed(
                        supply=supply, phantom_quote=phantom, secured_quote=secured,
                        base_decimals=0, quote_decimals=0,
                        size_precision=10**8, amm_spread=100,
                    )
                    self.assertEqual(quote.base_seed, base)
                    self.assertEqual(quote.price_error_numerator,
                                     supply * secured - base * (phantom + secured))
                    self.assertEqual(quote.price_error_denominator,
                                     base * (phantom + secured))
                    self.assertGreaterEqual(quote.price_error_numerator, 0)
                    self.assertLess(quote.price_error_numerator, phantom + secured)
                    self.assertGreaterEqual(quote.price_difference, 0)
                    self.assertLessEqual(quote.price_difference,
                                         quote.scaled_price_error_upper_bound)
                    checked += 1
        self.assertEqual(checked, 14_096)

    def test_uint256_input_and_quote_sum_bounds(self):
        with self.assertRaisesRegex(ValueError, "terminal reserve input exceeds uint256"):
            quote_first_seed(supply=2**256, phantom_quote=1, secured_quote=1,
                             base_decimals=18, quote_decimals=18,
                             size_precision=10**8, amm_spread=100)
        with self.assertRaisesRegex(ValueError, "virtual plus secured quote exceeds uint256"):
            quote_first_seed(supply=10**18, phantom_quote=2**256 - 1, secured_quote=1,
                             base_decimals=18, quote_decimals=18,
                             size_precision=10**8, amm_spread=100)

    def test_tiny_quote_fails_minimum_liquidity_and_vault_size(self):
        result = quote_first_seed(
            supply=10**6, phantom_quote=1, secured_quote=1,
            base_decimals=6, quote_decimals=6,
            size_precision=10**4, amm_spread=10,
        )
        self.assertFalse(result.seedable_in_reduced_model)

    def test_zero_base_seed_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "base seed rounds to zero"):
            quote_first_seed(
                supply=1, phantom_quote=10**9, secured_quote=1,
                base_decimals=18, quote_decimals=6,
                size_precision=10**8, amm_spread=100,
            )

    def test_vault_first_ask_intermediate_overflow_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "first-ask numerator exceeds uint256"):
            quote_first_seed(
                supply=10**18, phantom_quote=10**55, secured_quote=10**55,
                base_decimals=18, quote_decimals=18,
                size_precision=10**8, amm_spread=100,
            )

    def test_first_bid_matches_pinned_kuru_half_up_rounding(self):
        opening = quote_opening_ticks(
            first_ask_price_scaled=10**18, price_precision=10**8,
            tick_size=1, amm_spread=100,
        )
        self.assertEqual(opening.first_bid_price_scaled,
                         (10**18 * 10_000 + 10_100 // 2) // 10_100)
        # Preserve the false 20,000-bps bid denominator caught by the fork.
        self.assertNotEqual(opening.first_bid_price_scaled,
                            (10**18 * 20_000 + 20_100 // 2) // 20_100)
        self.assertTrue(opening.usable_limit_ticks)
        self.assertGreater(opening.ask_tick_floor, opening.bid_tick_floor)

    def test_tick_grid_rejects_unrepresentable_opening(self):
        opening = quote_opening_ticks(
            first_ask_price_scaled=1, price_precision=10**8,
            tick_size=1, amm_spread=100,
        )
        self.assertFalse(opening.usable_limit_ticks)
        self.assertEqual(opening.ask_tick_floor, 0)

    def test_tick_grid_rejects_coarse_tick_that_collapses_spread(self):
        opening = quote_opening_ticks(
            first_ask_price_scaled=10**18, price_precision=10**8,
            tick_size=10**8, amm_spread=100,
        )
        self.assertFalse(opening.usable_limit_ticks)

    def test_candidate_profile_matrix_uses_terminal_not_initial_supply(self):
        matrix = build_matrix()
        self.assertEqual(len(matrix["rows"]), 12)
        self.assertTrue(matrix["router_predicates_pass"])
        for row in matrix["rows"]:
            with self.subTest(quote=row["quote"], profile=row["profile"]):
                self.assertLess(row["terminal_tracked_token_T_raw"],
                                row["launch_total_supply_raw"])
                self.assertTrue(all(row["arithmetic_bounds"].values()))
                if row["profile"] == "FACTORY_MINIMUM_NEGATIVE":
                    self.assertFalse(row["candidate_eligible_in_reduced_model"])
                    self.assertFalse(row["size_within_candidate_policy"])
                else:
                    self.assertTrue(row["candidate_eligible_in_reduced_model"])
        medium = next(row for row in matrix["rows"] if row["quote"] == "MON"
                      and row["profile"] == "MEDIUM")
        self.assertEqual(medium["launch_total_supply_raw"], 1_000_000 * 10**18)
        self.assertEqual(medium["terminal_tracked_token_T_raw"],
                         1_000_000 * 10**18 * 100 // (100 + 97))

    def test_profile_artifact_matches_generator(self):
        root = Path(__file__).resolve().parents[3]
        artifact = root / "evidence/launchpad/kuru/parameter-profile-matrix-2026-09-30.json"
        self.assertEqual(json.loads(artifact.read_text()), build_matrix())

    def test_one_shot_crossing_quote_is_not_configured_threshold(self):
        for decimals in (18, 6):
            with self.subTest(quote_decimals=decimals):
                threshold = 100 * 10**decimals
                result = one_shot_crossing_quote(
                    launch_supply=1_000_000 * 10**18,
                    phantom_quote=threshold,
                    graduation_threshold=threshold,
                    curve_fee_bps=100,
                    creator_tax_bps=50,
                )
                # The same exact values are asserted by the native and pinned
                # Circle Foundry crossing-buy regression, independently.
                self.assertEqual(result.secured_quote, threshold + 2)
                self.assertEqual(result.terminal_tokens, 500_000 * 10**18)

    def test_prelaunch_quote_witness_artifact_matches_generator(self):
        root = Path(__file__).resolve().parents[3]
        artifact = root / "evidence/launchpad/kuru/prelaunch-q-threshold-counterexample-2026-09-30.json"
        self.assertEqual(json.loads(artifact.read_text()), build_witness())

    def test_round_trips_change_terminal_quote_despite_restored_token_reserve(self):
        for decimals in (18, 6):
            with self.subTest(quote_decimals=decimals):
                threshold = 100 * 10**decimals
                result = round_trip_crossing_quote(
                    launch_supply=1_000_000 * 10**18,
                    phantom_quote=threshold,
                    graduation_threshold=threshold,
                    curve_fee_bps=100,
                    creator_tax_bps=50,
                    rounds=10,
                    round_trip_gross_quote=10,
                )
                self.assertEqual(result.token_reserve_before_crossing, 1_000_000 * 10**18)
                self.assertEqual(result.real_quote_before_crossing, 10)
                self.assertEqual(result.secured_quote, threshold + 22)

    def test_minimum_two_raw_cycle_repeats_one_thousand_times_in_model(self):
        for decimals in (18, 6):
            with self.subTest(quote_decimals=decimals):
                threshold = 100 * 10**decimals
                args = dict(
                    launch_supply=1_000_000 * 10**18,
                    phantom_quote=threshold,
                    graduation_threshold=threshold,
                    curve_fee_bps=100,
                    creator_tax_bps=50,
                )
                with self.assertRaisesRegex(ValueError, "round trip sell is invalid"):
                    round_trip_crossing_quote(**args, rounds=1,
                                              round_trip_gross_quote=1)
                for rounds in (1, 16, 1000):
                    result = round_trip_crossing_quote(
                        **args, rounds=rounds, round_trip_gross_quote=2,
                    )
                    self.assertEqual(result.real_quote_before_crossing, rounds)
                    self.assertEqual(result.token_reserve_before_crossing,
                                     1_000_000 * 10**18)
                    self.assertEqual(result.secured_quote,
                                     threshold + 2 + 2 * rounds)

    def test_round_trip_witness_artifact_matches_generator(self):
        root = Path(__file__).resolve().parents[3]
        artifact = root / "evidence/launchpad/kuru/prelaunch-round-trip-witness-2026-09-30.json"
        self.assertEqual(json.loads(artifact.read_text()), build_round_trip_witness())

    def test_exact_completion_quote_matches_both_crossing_witnesses(self):
        for decimals in (18, 6):
            with self.subTest(quote_decimals=decimals):
                threshold = 100 * 10**decimals
                initial = CurveCompletionState(
                    phantom_quote=threshold, tracked_quote=0,
                    quote_fee_balance=0, creator_tax_balance=0,
                    tracked_tokens=1_000_000 * 10**18,
                    reserved_tokens=500_000 * 10**18,
                    curve_fee_bps=100, creator_tax_bps=50,
                )
                direct = completion_terminal_quote(initial)
                self.assertEqual(direct.terminal_real_quote, threshold + 2)
                self.assertEqual(direct.gross_quote_in,
                                 one_shot_crossing_quote(
                                     launch_supply=initial.tracked_tokens,
                                     phantom_quote=threshold,
                                     graduation_threshold=threshold,
                                     curve_fee_bps=100, creator_tax_bps=50,
                                 ).gross_quote_spent)
                for rounds in (1, 10, 16, 1000):
                    after_cycles = CurveCompletionState(
                        phantom_quote=threshold, tracked_quote=rounds,
                        quote_fee_balance=0, creator_tax_balance=0,
                        tracked_tokens=initial.tracked_tokens,
                        reserved_tokens=initial.reserved_tokens,
                        curve_fee_bps=100, creator_tax_bps=50,
                    )
                    self.assertEqual(completion_terminal_quote(after_cycles).terminal_real_quote,
                                     threshold + 2 + 2 * rounds)

    def test_completion_quote_rejects_intermediate_uint256_overflow(self):
        too_large = CurveCompletionState(
            phantom_quote=2**255, tracked_quote=0,
            quote_fee_balance=0, creator_tax_balance=0,
            tracked_tokens=10**18, reserved_tokens=10**17,
            curve_fee_bps=100, creator_tax_bps=50,
        )
        with self.assertRaises(OverflowError):
            completion_terminal_quote(too_large)

    def test_terminal_quote_product_lower_bound_covers_threshold(self):
        checked = 0
        for supply in range(2, 65):
            for phantom in range(1, 33):
                for threshold in range(1, 33):
                    reserved = supply * phantom // (phantom + threshold)
                    if not 0 < reserved < supply:
                        continue
                    lower = terminal_quote_lower_bound(
                        initial_tokens=supply, phantom_quote=phantom,
                        reserved_tokens=reserved,
                    )
                    self.assertGreaterEqual(lower, threshold)
                    self.assertEqual((phantom + lower) * reserved >= supply * phantom,
                                     True)
                    checked += 1
        self.assertGreater(checked, 50_000)

    def test_liveness_ceiling_blocks_fifth_round_trip_sell_not_completion(self):
        for decimals in (18, 6):
            with self.subTest(quote_decimals=decimals):
                phantom = 100 * 10**decimals
                supply = 1_000_000 * 10**18
                floor = supply // 2
                ceiling = phantom + 10
                state = CurveCompletionState(
                    phantom_quote=phantom, tracked_quote=0,
                    quote_fee_balance=0, creator_tax_balance=0,
                    tracked_tokens=supply, reserved_tokens=floor,
                    curve_fee_bps=100, creator_tax_bps=50,
                )
                self.assertLessEqual(completion_terminal_quote(state).terminal_real_quote,
                                     ceiling)
                for cycle in range(5):
                    bought = 2 * state.tracked_tokens // (phantom + state.tracked_quote + 2)
                    after_buy = CurveCompletionState(
                        phantom_quote=phantom, tracked_quote=state.tracked_quote + 2,
                        quote_fee_balance=0, creator_tax_balance=0,
                        tracked_tokens=state.tracked_tokens - bought,
                        reserved_tokens=floor, curve_fee_bps=100, creator_tax_bps=50,
                    )
                    self.assertLessEqual(completion_terminal_quote(after_buy).terminal_real_quote,
                                         ceiling)
                    gross_sell = bought * (phantom + after_buy.tracked_quote) // supply
                    self.assertEqual(gross_sell, 1)
                    after_sell = CurveCompletionState(
                        phantom_quote=phantom,
                        tracked_quote=after_buy.tracked_quote - gross_sell,
                        quote_fee_balance=0, creator_tax_balance=0,
                        tracked_tokens=supply, reserved_tokens=floor,
                        curve_fee_bps=100, creator_tax_bps=50,
                    )
                    predicted = completion_terminal_quote(after_sell).terminal_real_quote
                    if cycle < 4:
                        self.assertLessEqual(predicted, ceiling)
                        state = after_sell
                    else:
                        self.assertEqual(predicted, phantom + 12)
                        self.assertGreater(predicted, ceiling)
                        # Research-only semantic guard rejects this sell and
                        # keeps the accepted after-buy state completable.
                        self.assertEqual(
                            completion_terminal_quote(after_buy).terminal_real_quote,
                            ceiling,
                        )

    def test_completion_liveness_artifact_matches_generator(self):
        root = Path(__file__).resolve().parents[3]
        artifact = root / "evidence/launchpad/kuru/completion-liveness-witness-2026-09-30.json"
        self.assertEqual(json.loads(artifact.read_text()), build_liveness_witness())


if __name__ == "__main__":
    unittest.main()
