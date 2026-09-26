"""Checks that the existing PRISM model already implements and no earlier test asserted.

R-I02 is INV-P02: activated weights and the payoff matrix stay fixed.
R-I11's remaining edges are the lifecycle examples not named in test_lifecycle.py.
R-I12 is INV-P12: final resolution is committed once.
"""

from __future__ import annotations

import sys
import unittest
from fractions import Fraction
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from lifecycle import LifecycleError, SeriesState, transition  # noqa: E402
from model import ModelError, PrismSeries  # noqa: E402


G = [[0, 1], [0, 0], [1, 1], [1, 0]]
WEIGHTS = [Fraction(3, 5), Fraction(2, 5)]


def _activated() -> PrismSeries:
    series = PrismSeries(G, WEIGHTS)
    series.activate()
    return series


class PrismInvariantIdTests(unittest.TestCase):
    def test_r_i02_activated_weights_and_matrix_stay_fixed(self):
        series = _activated()
        weights = series.weights
        matrix = series.payoff_matrix
        series.mint_with_exact_backing(1000)
        series.redeem_in_kind(100)
        series.resolve_component(1, 1)
        series.start_resolution()
        series.resolve(2)
        self.assertEqual(series.weights, weights)
        self.assertEqual(series.payoff_matrix, matrix)
        self.assertEqual(series.terminal_payoff_vector[2], Fraction(1))

    def test_r_i11_redeemable_and_archived_do_not_reopen(self):
        with self.assertRaises(LifecycleError):
            transition(SeriesState.REDEEMABLE, SeriesState.ACTIVE)
        for target in (
            SeriesState.DRAFT,
            SeriesState.ACTIVE,
            SeriesState.MINT_PAUSED,
            SeriesState.RESOLUTION_PENDING,
            SeriesState.RESOLVED,
            SeriesState.REDEEMABLE,
            SeriesState.ARCHIVED,
        ):
            with self.assertRaises(LifecycleError):
                transition(SeriesState.ARCHIVED, target)

    def test_r_i12_final_resolution_is_committed_once(self):
        series = _activated()
        series.mint_with_exact_backing(1000)
        series.start_resolution()
        series.resolve(2)
        payout = series.final_payout
        with self.assertRaises(ModelError):
            series.resolve(0)
        self.assertEqual(series.final_payout, payout)
        self.assertEqual(series.state, SeriesState.RESOLVED)


if __name__ == "__main__":
    unittest.main()
