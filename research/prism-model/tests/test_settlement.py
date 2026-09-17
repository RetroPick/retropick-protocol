import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import unittest
from fractions import Fraction

from model import PrismSeries, ModelError


G = [[0,1],[0,0],[1,1],[1,0]]
X = [Fraction(3,5), Fraction(2,5)]


class SettlementTests(unittest.TestCase):
    def test_underfunded_cannot_become_redeemable(self):
        s = PrismSeries(G, X)
        s.activate()
        s.mint_with_exact_backing(100)
        s.start_resolution()
        s.resolve(3)  # 0.6/share
        s.fund_settlement(59)
        with self.assertRaises(ModelError):
            s.make_redeemable()

    def test_exact_final_redemption(self):
        s = PrismSeries(G, X)
        s.activate()
        s.mint_with_exact_backing(100)
        s.start_resolution()
        s.resolve(3)
        s.fund_settlement(60)
        s.make_redeemable()
        self.assertEqual(s.redeem_final(25), Fraction(15))
        self.assertEqual(s.supply, 75)
        self.assertEqual(s.settlement_balance, 45)


if __name__ == "__main__":
    unittest.main()
