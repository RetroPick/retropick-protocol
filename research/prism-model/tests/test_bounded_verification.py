import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import unittest
from fractions import Fraction

from bounded_verification import (
    run_phase1_bounded_suite,
    verify_mint_redeem_grid,
    verify_settlement_redemption_grid,
    verify_terminal_solvency_grid,
)


G = [
    [0, 1],
    [0, 0],
    [1, 1],
    [1, 0],
]
X = [Fraction(3, 5), Fraction(2, 5)]


class BoundedVerificationTests(unittest.TestCase):
    def test_mint_redeem_grid_has_no_counterexample(self):
        report = verify_mint_redeem_grid(
            X,
            max_supply=5,
            max_extra=2,
            max_quantity=4,
        )
        self.assertGreater(report["mint_cases"], 0)
        self.assertGreater(report["redeem_cases"], 0)

    def test_terminal_solvency_grid_has_no_counterexample(self):
        report = verify_terminal_solvency_grid(
            G,
            X,
            max_supply=5,
            max_extra=2,
        )
        self.assertEqual(report["terminal_cases"], 6 * 3 * 4)

    def test_settlement_grid_has_no_counterexample(self):
        report = verify_settlement_redemption_grid(
            Fraction(3, 5),
            max_supply=5,
            max_extra=2,
        )
        expected = 3 * sum(s + 1 for s in range(6))
        self.assertEqual(report["settlement_cases"], expected)

    def test_standard_suite(self):
        report = run_phase1_bounded_suite(
            G,
            X,
            final_payout=Fraction(1),
            max_supply=4,
            max_extra=2,
            max_quantity=3,
        )
        self.assertGreater(report["mint_cases"], 0)
        self.assertGreater(report["redeem_cases"], 0)
        self.assertGreater(report["terminal_cases"], 0)
        self.assertGreater(report["settlement_cases"], 0)


if __name__ == "__main__":
    unittest.main()
