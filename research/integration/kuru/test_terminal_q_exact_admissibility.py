import random
import unittest

from benchmark_launch_profiles import PROFILE_INPUTS
from terminal_q_exact_admissibility import (
    build_declared_p0_matrix, prove_declared_interval,
)
from terminal_q_interval import check_terminal_q


class TerminalQExactAdmissibilityTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.matrix = build_declared_p0_matrix()
        cls.rows = {
            (row["quote"], row["profile"]): row for row in cls.matrix["rows"]
        }

    def test_positive_p0_profiles_prove_declared_50x_domain(self):
        for row in self.matrix["rows"]:
            if row["profile"] == "FACTORY_MINIMUM_NEGATIVE":
                continue
            with self.subTest(quote=row["quote"], profile=row["profile"]):
                self.assertTrue(row["all_q_admissible"])
                self.assertEqual(
                    row["declared_upper_q_raw"],
                    50 * row["graduation_threshold_raw"],
                )

    def test_declared_domain_endpoints_are_directly_admissible(self):
        for row in self.matrix["rows"]:
            if row["profile"] == "FACTORY_MINIMUM_NEGATIVE":
                continue
            for endpoint in row["proof"]["exact_endpoint_checks"].values():
                self.assertTrue(endpoint["valid"])

    def test_random_raw_q_values_inside_declared_domain(self):
        rng = random.Random(0x4A4A4A)
        checks = 0
        for row in self.matrix["rows"]:
            if row["profile"] == "FACTORY_MINIMUM_NEGATIVE":
                continue
            samples = [
                rng.randrange(row["declared_lower_q_raw"],
                              row["declared_upper_q_raw"] + 1)
                for _ in range(20)
            ]
            for q in samples:
                result = check_terminal_q(
                    terminal_tokens=row["terminal_tokens_raw"],
                    phantom_quote=row["phantom_quote_raw"],
                    secured_quote=q,
                    quote_decimals=row["quote_decimals"],
                )
                self.assertTrue(result["valid"])
                checks += 1
        self.assertEqual(checks, 200)

    def test_factory_minimum_negative_remains_permanent(self):
        for quote in ("MON", "CIRCLE_CANONICAL_TEST_USDC"):
            row = self.rows[quote, "FACTORY_MINIMUM_NEGATIVE"]
            self.assertFalse(row["all_q_admissible"])
            self.assertEqual(
                row["classification"],
                "PERMANENT_NEGATIVE_PROFILE_NOT_IN_P0_LAUNCH_ENVELOPE",
            )

    def test_small_declared_domain_cross_checks_every_raw_q(self):
        # This geometry exercises every integer in a profile-sized domain
        # while keeping the default suite inexpensive.
        proof = prove_declared_interval(
            terminal_tokens=47_619_047_619_047_619_047_619,
            phantom_quote=10_000_000, lower_q=10_000_000,
            upper_q=10_009_999, quote_decimals=6,
        )
        self.assertTrue(proof["all_q_admissible"])
        for q in range(10_000_000, 10_010_000):
            self.assertTrue(check_terminal_q(
                terminal_tokens=47_619_047_619_047_619_047_619,
                phantom_quote=10_000_000,
                secured_quote=q, quote_decimals=6,
            )["valid"])


if __name__ == "__main__":
    unittest.main()
