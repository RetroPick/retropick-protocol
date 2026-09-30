"""Bounded all-Q checks for the *candidate*, not accepted, Kuru envelope."""

import unittest
import json
from pathlib import Path

from benchmark_launch_profiles import PROFILE_INPUTS
from bounded_q_envelope import build_matrix
from terminal_q_interval import check_terminal_q, check_terminal_q_interval


class TerminalQIntervalTest(unittest.TestCase):
    def test_candidate_matrix_checks_every_raw_q_in_illustrative_interval(self):
        matrix = build_matrix()
        artifact = json.loads((Path(__file__).parents[3] /
            "evidence/launchpad/kuru/terminal-q-bounded-envelope-2026-09-30.json"
        ).read_text())
        self.assertEqual(len(matrix["rows"]), 2 * len(PROFILE_INPUTS))
        self.assertEqual(sum(row["checked_raw_q_cells"] for row in matrix["rows"]), 155)
        self.assertEqual(sum(row["valid_cells"] for row in matrix["rows"]), 128)
        self.assertEqual(artifact["total_raw_q_cells"], 155)
        self.assertEqual(artifact["valid_raw_q_cells"], 128)
        for row in matrix["rows"]:
            with self.subTest(profile=row["profile"], quote=row["quote"]):
                self.assertEqual(
                    row["checked_raw_q_cells"],
                    row["illustrative_ceiling_q_raw"] - row["proven_lower_q_raw"] + 1,
                )
                self.assertTrue(all(row["monotone_fields_observed"].values()))
                if row["profile"] == "FACTORY_MINIMUM_NEGATIVE":
                    self.assertEqual(row["valid_cells"], 0)
                    self.assertIn(
                        "vault_order_sizes_within_candidate_min_max",
                        row["first_invalid_constraints"],
                    )
                else:
                    self.assertTrue(row["all_cells_valid_in_reduced_model"])
                matching = [item for item in artifact["rows"] if
                    item["profile"] == row["profile"] and item["quote"] == row["quote"]]
                self.assertEqual(len(matching), 1)
                self.assertEqual(matching[0]["cells"], row["checked_raw_q_cells"])
                self.assertEqual(matching[0]["valid"], row["valid_cells"])

    def test_wide_interval_refused_instead_of_endpoint_assumption(self):
        with self.assertRaisesRegex(ValueError, "too wide"):
            check_terminal_q_interval(
                launch_supply=1_000 * 10**18,
                phantom_quote=10**18,
                graduation_threshold=10**18,
                quote_decimals=18,
                graduation_quote_ceiling=10**18 + 1001,
            )

    def test_ceiling_below_proven_lower_bound_refused(self):
        with self.assertRaisesRegex(ValueError, "below proven terminal lower bound"):
            check_terminal_q_interval(
                launch_supply=1_000 * 10**18,
                phantom_quote=10**18,
                graduation_threshold=10**18,
                quote_decimals=18,
                graduation_quote_ceiling=10**18 - 1,
            )

    def test_small_seed_is_not_admitted_by_positive_b_alone(self):
        result = check_terminal_q(
            terminal_tokens=5 * 10**17,
            phantom_quote=10**18,
            secured_quote=10**18,
            quote_decimals=18,
        )
        self.assertFalse(result["valid"])
        self.assertTrue(result["constraints"]["base_seed_positive"])
        self.assertFalse(result["constraints"]["vault_order_sizes_within_candidate_min_max"])


if __name__ == "__main__":
    unittest.main()
