"""Minimum-cost exact replication. A float vector is not a certificate."""

from __future__ import annotations

import sys
import unittest
from fractions import Fraction
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from minimum_cost_replication import (  # noqa: E402
    COST_UNBOUNDED,
    DOMAIN,
    EXACT,
    PRODUCT_NOT_REPLICABLE,
    DomainError,
    minimum_cost_exact_replication,
)
from replication import payoff  # noqa: E402


class MinimumCostReplicationTests(unittest.TestCase):
    def test_and_is_not_replicated_by_marginals_and_constant(self):
        # Columns are A, B, and the constant 1. Rows are states 00, 01, 10, 11.
        matrix = ((0, 0, 1), (0, 1, 1), (1, 0, 1), (1, 1, 1))
        target = (0, 0, 0, 1)
        result = minimum_cost_exact_replication(matrix, target, (1, 1, 1))
        self.assertEqual(result.status, PRODUCT_NOT_REPLICABLE)
        self.assertEqual(result.reason, "equality_inconsistent")
        self.assertIsNone(result.x)
        self.assertFalse(result.rechecked_equal)
        self.assertEqual(result.classification, "EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN")
        self.assertIn("16", DOMAIN)

    def test_cheaper_of_two_exact_columns(self):
        result = minimum_cost_exact_replication(((1, 1), (2, 2)), (1, 2), (3, 1))
        self.assertEqual(result.status, EXACT)
        self.assertEqual(result.x, (Fraction(0), Fraction(1)))
        self.assertEqual(result.cost, Fraction(1))
        self.assertTrue(result.rechecked_equal)
        self.assertEqual(payoff(((1, 1), (2, 2)), result.x), (Fraction(1), Fraction(2)))

    def test_minimum_among_three_exact_solutions(self):
        matrix = ((1, 0, 1), (0, 1, 1))
        result = minimum_cost_exact_replication(matrix, (1, 1), (2, 2, 1))
        self.assertEqual(result.x, (Fraction(0), Fraction(0), Fraction(1)))
        self.assertEqual(result.cost, Fraction(1))
        self.assertEqual(payoff(matrix, result.x), (Fraction(1), Fraction(1)))
        expensive = (Fraction(1), Fraction(1), Fraction(0))
        self.assertEqual(payoff(matrix, expensive), (Fraction(1), Fraction(1)))
        self.assertLess(result.cost, 4)

    def test_equal_costs_pick_the_lexicographic_vertex(self):
        result = minimum_cost_exact_replication(((1, 1),), (1,), (1, 1))
        self.assertEqual(result.x, (Fraction(0), Fraction(1)))
        self.assertEqual(result.cost, Fraction(1))

    def test_negative_unit_cost_stays_bounded_when_the_ray_is_costly(self):
        result = minimum_cost_exact_replication(((1, 0),), (1,), (-1, 5))
        self.assertEqual(result.status, EXACT)
        self.assertEqual(result.x, (Fraction(1), Fraction(0)))
        self.assertEqual(result.cost, Fraction(-1))

    def test_negative_cost_ray_is_not_a_minimum(self):
        result = minimum_cost_exact_replication(((1, -1),), (0,), (0, -1))
        self.assertEqual(result.status, COST_UNBOUNDED)
        self.assertIsNone(result.x)
        self.assertEqual(result.reason, "negative_cost_ray")

    def test_nonnegative_infeasible_target(self):
        result = minimum_cost_exact_replication(((1, 1),), (-1,), (1, 1))
        self.assertEqual(result.status, PRODUCT_NOT_REPLICABLE)
        self.assertEqual(result.reason, "no_nonnegative_basic_feasible_solution")

    def test_domain_bound_is_enforced(self):
        matrix = [[1] * 9]
        with self.assertRaises(DomainError):
            minimum_cost_exact_replication(matrix, [1], [1] * 9)


if __name__ == "__main__":
    unittest.main()
