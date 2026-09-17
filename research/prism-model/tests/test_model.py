import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import unittest
from fractions import Fraction

from model import PrismSeries, ModelError


G = [[0, 1], [0, 0], [1, 1], [1, 0]]
X = [Fraction(3, 5), Fraction(2, 5)]


class ModelTests(unittest.TestCase):
    def test_mint_can_consume_predeposited_surplus_without_underbacking(self):
        s = PrismSeries(G, X)
        s.activate()
        s.deposit_backing([700, 500])
        self.assertEqual(s.backing_margin(), (Fraction(700), Fraction(500)))

        s.mint(1000)

        self.assertEqual(s.backing_margin(), (Fraction(100), Fraction(100)))
        self.assertTrue(s.assert_component_backed())

    def test_exact_backed_mint_preserves_existing_margin(self):
        s = PrismSeries(G, X)
        s.activate()
        s.deposit_backing([100, 50])
        before = s.backing_margin()

        s.mint_with_exact_backing(1000)

        self.assertEqual(before, (Fraction(100), Fraction(50)))
        self.assertEqual(s.backing_margin(), before)
        self.assertEqual(s.backing, [Fraction(700), Fraction(450)])

    def test_exact_mint_then_redeem(self):
        s = PrismSeries(G, X)
        s.activate()
        s.mint_with_exact_backing(1000)
        self.assertEqual(s.backing, [Fraction(600), Fraction(400)])

        released = s.redeem_in_kind(250)

        self.assertEqual(released, (Fraction(150), Fraction(100)))
        self.assertEqual(s.supply, 750)
        self.assertTrue(s.assert_component_backed())

    def test_overmint_rejected(self):
        s = PrismSeries(G, X)
        s.activate()
        s.deposit_backing([599, 400])
        with self.assertRaises(ModelError):
            s.mint(1000)

    def test_terminal_solvency_all_states(self):
        s = PrismSeries(G, X)
        s.activate()
        s.mint_with_exact_backing(1000)
        self.assertTrue(all(row[3] for row in s.terminal_solvency()))

    def test_canonical_pfedbtc_payoff_vector(self):
        s = PrismSeries(G, X)
        self.assertEqual(
            s.terminal_payoff_vector,
            (
                Fraction(2, 5),
                Fraction(0),
                Fraction(1),
                Fraction(3, 5),
            ),
        )


if __name__ == "__main__":
    unittest.main()
