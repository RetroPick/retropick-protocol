import json
import sys
import unittest
from fractions import Fraction
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from generate_partial_resolution_fixtures import build

from lifecycle import SeriesState
from model import PrismSeries
from partial_resolution import (
    PartialResolutionError,
    apply_transform,
    mismatched_portfolio,
    portfolio_preserves,
)


G = [[0, 1], [0, 0], [1, 1], [1, 0]]
WEIGHTS = [Fraction(3, 5), Fraction(2, 5)]


def fresh() -> PrismSeries:
    series = PrismSeries(G, WEIGHTS)
    series.activate()
    series.mint_with_exact_backing(1000)
    return series


class PartialResolutionTests(unittest.TestCase):
    def test_component_transform_preserves_remaining_states(self):
        series = fresh()
        planned = apply_transform(series, 1, 1)
        self.assertEqual(planned["cash_added"], 400)
        self.assertEqual(series.backing, [Fraction(600), Fraction(0)])
        self.assertEqual(series.transformed_settlement, 400)
        self.assertEqual(series.possible_states, {0, 2})
        self.assertEqual(series.supply, 1000)
        self.assertEqual(series.state, SeriesState.MINT_PAUSED)
        self.assertTrue(all(weight >= 0 for weight in series.weights))
        self.assertTrue(
            portfolio_preserves(
                G,
                [600, 400],
                0,
                series.backing,
                series.transformed_settlement,
                sorted(series.possible_states),
            )
        )

    def test_wrong_component_index_is_rejected(self):
        series = fresh()
        with self.assertRaises(PartialResolutionError):
            apply_transform(series, 2, 1)
        with self.assertRaises(PartialResolutionError):
            apply_transform(series, -1, 1)
        self.assertEqual(series.backing, [Fraction(600), Fraction(400)])
        self.assertEqual(series.transformed_settlement, 0)
        self.assertEqual(series.possible_states, {0, 1, 2, 3})

    def test_nonequivalent_payout_is_rejected(self):
        series = fresh()
        with self.assertRaises(PartialResolutionError):
            apply_transform(series, 1, 2)
        self.assertEqual(series.supply, 1000)
        self.assertEqual(series.transformed_settlement, 0)
        control = mismatched_portfolio(series, 1, 1)
        self.assertFalse(control["equivalent"])
        self.assertEqual(control["wrong_index"], 0)
        self.assertEqual(control["new_cash"], 400)
        self.assertEqual(control["new_backing"], [Fraction(0), Fraction(400)])

    def test_reorder_of_consistent_resolutions_matches(self):
        forward = fresh()
        apply_transform(forward, 0, 1)
        apply_transform(forward, 1, 1)
        backward = fresh()
        apply_transform(backward, 1, 1)
        apply_transform(backward, 0, 1)
        self.assertEqual(forward.transformed_settlement, backward.transformed_settlement)
        self.assertEqual(forward.transformed_settlement, 1000)
        self.assertEqual(forward.backing, backward.backing)
        self.assertEqual(forward.backing, [Fraction(0), Fraction(0)])
        self.assertEqual(forward.possible_states, backward.possible_states)
        self.assertEqual(forward.possible_states, {2})
        self.assertEqual(forward.supply, backward.supply)

    def test_second_resolution_of_same_component_is_rejected(self):
        series = fresh()
        apply_transform(series, 1, 1)
        with self.assertRaises(PartialResolutionError):
            apply_transform(series, 1, 1)
        self.assertEqual(series.transformed_settlement, 400)

    def test_negative_weight_is_rejected(self):
        with self.assertRaises(Exception):
            PrismSeries(G, [Fraction(3, 5), Fraction(-1, 5)])

    def test_committed_fixture_matches_live_model(self):
        path = Path(__file__).resolve().parents[1] / "fixtures" / "partial_resolution.json"
        committed = json.loads(path.read_text(encoding="utf-8"))
        self.assertEqual(committed, build())


if __name__ == "__main__":
    unittest.main()
