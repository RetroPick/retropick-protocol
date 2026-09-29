"""Targeted exact-integer negative and representative controls for Kuru freeze."""

import json
import unittest
from pathlib import Path

from benchmark_launch_profiles import build_matrix
from launchpad_seed_model import (
    quote_first_seed, quote_opening_ticks, valid_router_parameters,
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


if __name__ == "__main__":
    unittest.main()
