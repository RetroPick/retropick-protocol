"""Targeted exact-integer negative and representative controls for Kuru freeze."""

import unittest

from launchpad_seed_model import quote_first_seed, valid_router_parameters


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
            ("tick_size", 0), ("min_size", 0), ("max_size", 1),
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
        # B=floor(T*Q/(P+Q)); the relative upward drift is < 1/B.
        self.assertLessEqual(
            result.kuru_first_ask_price_scaled * result.base_seed,
            result.terminal_price_scaled * (result.base_seed + 1)
            + result.base_seed,
        )
        self.assertTrue(result.seedable_in_reduced_model)

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


if __name__ == "__main__":
    unittest.main()
