"""Synthetic market quotes are not solvency and not Kuru."""

from __future__ import annotations

import sys
import unittest
from fractions import Fraction
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from market_microstructure import (  # noqa: E402
    accounting_snapshot,
    crossed_book,
    depth_book,
    empty_book,
    normal_book,
    quote,
    run,
    _walk,
)


class MarketMicrostructureTests(unittest.TestCase):
    def test_normal_book_is_a_simulation(self):
        books, quantity, weights, terms = normal_book()
        row = quote(books, quantity, weights, terms)
        self.assertEqual(row.classification, "SUPPORTED_BY_SIMULATION")
        self.assertEqual(row.create_cost, Fraction(117, 2))
        self.assertEqual(row.redeem_value, Fraction(87, 2))
        self.assertGreater(row.create_cost, row.redeem_value)

    def test_crossed_book_can_show_redeem_above_create(self):
        books, quantity, weights, terms = crossed_book()
        row = quote(books, quantity, weights, terms)
        self.assertEqual(row.classification, "SUPPORTED_BY_SIMULATION")
        self.assertEqual(row.create_cost, Fraction(5))
        self.assertEqual(row.redeem_value, Fraction(8))
        self.assertGreater(row.redeem_value, row.create_cost)
        self.assertEqual(accounting_snapshot()["h_equals_gx"], "true")
        self.assertEqual(accounting_snapshot()["backing_covers_weights"], "true")

    def test_empty_book_is_not_yet_validated_and_accounting_is_unchanged(self):
        books, quantity, weights, terms = empty_book()
        row = quote(books, quantity, weights, terms)
        self.assertEqual(row.classification, "NOT_YET_VALIDATED")
        self.assertIsNone(row.create_cost)
        self.assertEqual(accounting_snapshot()["h_equals_gx"], "true")

    def test_depth_walk_is_exact(self):
        book, size = depth_book()
        self.assertEqual(_walk(book.asks, size), Fraction(44))

    def test_runtime_is_recorded(self):
        report = run()
        self.assertGreater(report["runtime_seconds"], 0)
        self.assertEqual(report["arbitrage_will_happen"], "NOT_YET_VALIDATED")
        self.assertTrue(report["not_a_protocol_theorem"])
        self.assertTrue(report["not_kuru_liquidity"])
        self.assertEqual(report["accounting_unchanged_by_quotes"]["h_equals_gx"], "true")


if __name__ == "__main__":
    unittest.main()
