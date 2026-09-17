import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import unittest
from fractions import Fraction

from replication import payoff, find_exact_nonnegative_replication, is_exactly_replicable


class ReplicationTests(unittest.TestCase):
    def test_weighted_payoff(self):
        G = [[0,1],[0,0],[1,1],[1,0]]
        self.assertEqual(
            payoff(G, [Fraction(3,5), Fraction(2,5)]),
            (Fraction(2,5), Fraction(0), Fraction(1), Fraction(3,5)),
        )

    def test_known_and_is_not_replicable(self):
        G = [[0,0],[0,1],[1,0],[1,1]]
        target = [0,0,0,1]
        self.assertIsNone(find_exact_nonnegative_replication(G, target))
        self.assertFalse(is_exactly_replicable(G, target))

    def test_exact_component_is_replicable(self):
        G = [[0,0],[0,1],[1,0],[1,1]]
        target = [0,1,0,1]
        x = find_exact_nonnegative_replication(G, target)
        self.assertEqual(x, (Fraction(0), Fraction(1)))


if __name__ == "__main__":
    unittest.main()
