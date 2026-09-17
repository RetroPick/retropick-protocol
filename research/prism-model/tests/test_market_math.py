import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import unittest
from fractions import Fraction

from market_math import (
    MarketMathError,
    assert_complete_set_conservation,
    buy_and_merge_profit,
    complete_set_open_interest,
    partial_resolution_nav,
    post_resolution_pair_value,
    prism_create_cost,
    prism_practical_band,
    prism_redeem_value,
    split_and_sell_profit,
)


X = [Fraction(3, 5), Fraction(2, 5)]


class CompleteSetMathTests(unittest.TestCase):
    def test_complete_set_conservation_and_open_interest(self):
        self.assertTrue(assert_complete_set_conservation(100, 100, 100))
        self.assertEqual(complete_set_open_interest(100, 100, 100), 100)
        self.assertEqual(complete_set_open_interest(100, 100), 100)

    def test_open_interest_does_not_double_count_yes_plus_no(self):
        self.assertEqual(complete_set_open_interest(250, 250, 250), 250)
        self.assertNotEqual(complete_set_open_interest(250, 250, 250), 500)

    def test_supply_drift_is_rejected(self):
        with self.assertRaises(MarketMathError):
            complete_set_open_interest(100, 99)
        with self.assertRaises(MarketMathError):
            assert_complete_set_conservation(100, 100, 99)

    def test_split_and_sell_uses_bids(self):
        profit = split_and_sell_profit(
            Fraction(55, 100),
            Fraction(50, 100),
            total_cost=Fraction(1, 100),
        )
        self.assertEqual(profit, Fraction(4, 100))

    def test_buy_and_merge_uses_asks(self):
        profit = buy_and_merge_profit(
            Fraction(45, 100),
            Fraction(50, 100),
            total_cost=Fraction(1, 100),
        )
        self.assertEqual(profit, Fraction(4, 100))


class PrismMarketMathTests(unittest.TestCase):
    def test_create_and_redeem_values(self):
        asks = [Fraction(40, 100), Fraction(70, 100)]
        bids = [Fraction(38, 100), Fraction(68, 100)]

        create = prism_create_cost(X, asks, fees=Fraction(1, 100))
        redeem = prism_redeem_value(X, bids, fees=Fraction(1, 100))

        self.assertEqual(create, Fraction(53, 100))
        self.assertEqual(redeem, Fraction(49, 100))
        self.assertLessEqual(redeem, create)

    def test_practical_band_widens_with_risk(self):
        bids = [Fraction(38, 100), Fraction(68, 100)]
        asks = [Fraction(40, 100), Fraction(70, 100)]
        lower, upper = prism_practical_band(
            X,
            bids,
            asks,
            redeem_fees=Fraction(1, 100),
            create_fees=Fraction(1, 100),
            redeem_risk=Fraction(2, 100),
            create_risk=Fraction(3, 100),
        )
        self.assertEqual(lower, Fraction(47, 100))
        self.assertEqual(upper, Fraction(56, 100))

    def test_partial_resolution_nav(self):
        # 0.6 component A has resolved to 1; 0.4 component B still marks at 0.30.
        nav = partial_resolution_nav(
            X,
            resolved={0: 1},
            unresolved_marks={1: Fraction(30, 100)},
        )
        self.assertEqual(nav, Fraction(72, 100))

    def test_partial_resolution_requires_full_partition(self):
        with self.assertRaises(MarketMathError):
            partial_resolution_nav(X, resolved={0: 1}, unresolved_marks={})
        with self.assertRaises(MarketMathError):
            partial_resolution_nav(X, resolved={0: 1}, unresolved_marks={0: 1, 1: 1})

    def test_post_resolution_pair_moves_with_quote_asset(self):
        final_payout = Fraction(60, 100)
        self.assertEqual(post_resolution_pair_value(final_payout, 2), Fraction(30, 100))
        self.assertEqual(post_resolution_pair_value(final_payout, 1), Fraction(60, 100))

    def test_zero_payout_has_zero_protocol_relative_value(self):
        self.assertEqual(post_resolution_pair_value(0, 2), 0)


if __name__ == "__main__":
    unittest.main()
