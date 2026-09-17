import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import unittest
from fractions import Fraction

from model import PrismSeries, ModelError


G = [[0,1],[0,0],[1,1],[1,0]]
X = [Fraction(3,5), Fraction(2,5)]


class ModelTests(unittest.TestCase):
    def test_mint_preserves_backing_margin(self):
        s = PrismSeries(G, X)
        s.activate()
        s.deposit_backing([700, 500])
        before = s.backing_margin()
        s.mint(1000)
        after = s.backing_margin()
        self.assertEqual(before, (Fraction(700), Fraction(500)))
        self.assertEqual(after, (Fraction(100), Fraction(100)))

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


if __name__ == "__main__":
    unittest.main()
