import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from unreachable_branches import classify


class UnreachableBranchTests(unittest.TestCase):
    def test_funding_branches_are_discharged(self):
        report = classify(max_unit=3)
        self.assertEqual(report["classification"], "PROVEN_UNDER_ASSUMPTIONS")
        self.assertTrue(report["sympy"]["discharged"])
        self.assertEqual(report["sympy"]["invalid_archive_liability"], "0")
        self.assertEqual(report["sympy"]["invalid_open_gap_even"], "0")
        self.assertEqual(report["sympy"]["invalid_open_gap_odd"], "1")
        self.assertEqual(report["domain_check"]["result"], "EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN")
        self.assertEqual(report["domain_check"]["witness"], "")
        self.assertGreater(report["domain_check"]["resolved_states"], 0)
        self.assertGreater(report["domain_check"]["zero_supply_redeemable"], 0)
        self.assertTrue(report["coverage_not_executed"])


if __name__ == "__main__":
    unittest.main()
