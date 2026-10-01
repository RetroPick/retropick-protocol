import json
import unittest
from pathlib import Path

from benchmark_launch_profiles import PROFILE_INPUTS
from p0_terminal_envelope import build_matrix, largest_sufficient_endpoint
from terminal_q_interval import prove_interval_sufficient


ROOT = Path(__file__).parents[3]
ARTIFACT = ROOT / "evidence/launchpad/kuru/p0-terminal-envelope-2026-10-01.json"
POSITIVE_PROFILES = [
    row for row in PROFILE_INPUTS if row[0] != "FACTORY_MINIMUM_NEGATIVE"
]


class P0TerminalEnvelopeTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.matrix = build_matrix()
        cls.rows = {(row["quote"], row["profile"]): row for row in cls.matrix["rows"]}

    def test_matrix_classification_rejects_policy_interpretation(self):
        self.assertEqual(
            self.matrix["classification"],
            "CONSERVATIVE_SUFFICIENT_ENDPOINT_MATRIX_NOT_ACCEPTED_P0_POLICY",
        )
        self.assertIn("not economic graduation ceilings", self.matrix["policy_warning"])
        self.assertIn("not real-fork qualification", self.matrix["policy_warning"])

    def test_positive_quote_profiles_have_sufficient_bounded_endpoint(self):
        for quote in ("MON", "CIRCLE_TEST_USDC"):
            for name, *_ in POSITIVE_PROFILES:
                with self.subTest(quote=quote, profile=name):
                    row = self.rows[quote, name]
                    envelope = row["sufficient_endpoint"]
                    self.assertTrue(envelope["bounded"])
                    self.assertGreaterEqual(
                        envelope["upper_q_raw"],
                        100 * row["graduation_threshold_raw"],
                    )
                    self.assertIsNotNone(envelope["failing_successor_q_raw"])
                    self.assertGreater(
                        envelope["failing_successor_q_raw"], envelope["upper_q_raw"]
                    )
                    self.assertTrue(row["sufficient_at_reported_upper"])
                    self.assertTrue(row["threshold_within_envelope"])
                    self.assertTrue(row["stress_100x_threshold_within_envelope"])

    def test_positive_endpoints_are_exact_admissible_not_just_sufficient(self):
        for quote in ("MON", "CIRCLE_TEST_USDC"):
            for name, *_ in POSITIVE_PROFILES:
                with self.subTest(quote=quote, profile=name):
                    row = self.rows[quote, name]
                    checks = row["endpoint_exact_checks"]
                    self.assertTrue(checks["fresh_immediate_completion"]["valid"])
                    self.assertTrue(checks["configured_threshold"]["valid"])
                    self.assertTrue(checks["sufficient_upper"]["valid"])
                    self.assertTrue(row["initial_completion_within_envelope"])
                    self.assertLessEqual(
                        row["proven_lower_q_raw"],
                        row["fresh_immediate_completion_q_raw"],
                    )
                    self.assertLessEqual(
                        row["fresh_immediate_completion_q_raw"],
                        row["sufficient_endpoint"]["upper_q_raw"],
                    )

    def test_factory_minimum_negative_is_preserved(self):
        for quote in ("MON", "CIRCLE_TEST_USDC"):
            with self.subTest(quote=quote):
                row = self.rows[quote, "FACTORY_MINIMUM_NEGATIVE"]
                self.assertFalse(row["sufficient_at_reported_upper"])
                self.assertFalse(row["initial_completion_within_envelope"])
                self.assertFalse(row["stress_100x_threshold_within_envelope"])
                self.assertEqual(
                    row["sufficient_endpoint"]["reason"],
                    "lower endpoint already fails sufficient conditions",
                )
                failed = [
                    name
                    for name, value in row["sufficient_endpoint"]["proof_at_upper"][
                        "checks"
                    ].items()
                    if not value
                ]
                self.assertIn("vault_order_sizes_within_candidate_min_max", failed)

    def test_lower_above_threshold_still_produces_ordered_interval(self):
        # SMALL's product lower bound is threshold+1. The generator must seed
        # binary search at max(lower, threshold), not an inverted interval.
        for quote, decimals in (("MON", 18), ("CIRCLE_TEST_USDC", 6)):
            with self.subTest(quote=quote):
                scale = 10**decimals
                name, supply_units, phantom_units, threshold_units = next(
                    row for row in PROFILE_INPUTS if row[0] == "SMALL"
                )
                supply = supply_units * 10**18
                phantom = phantom_units * scale
                threshold = threshold_units * scale
                terminal = supply * phantom // (phantom + threshold)
                row = self.rows[quote, name]
                self.assertEqual(row["proven_lower_q_raw"], threshold + 1)
                envelope = largest_sufficient_endpoint(
                    terminal_tokens=terminal,
                    phantom_quote=phantom,
                    lower_q=threshold + 1,
                    quote_decimals=decimals,
                    initial_upper=threshold,
                )
                self.assertGreater(envelope["upper_q_raw"], threshold)
                self.assertTrue(
                    prove_interval_sufficient(
                        terminal_tokens=terminal,
                        phantom_quote=phantom,
                        lower_q=threshold + 1,
                        upper_q=envelope["upper_q_raw"],
                        quote_decimals=decimals,
                    )["all_q_proven_in_reduced_model"]
                )

    def test_bounded_successor_fails_sufficient_conditions(self):
        # These successor values are specific to the fixed candidate tuple and
        # prove the report records a boundary of this generator, not an open
        # invitation to treat every uint256 Q as covered.
        witnesses = {
            ("MON", "MINIMUM_VALID_LAUNCH"): 10_737_418_240_000_000_000_000,
            ("CIRCLE_TEST_USDC", "MINIMUM_VALID_LAUNCH"): 10_737_418_240,
        }
        for (quote, profile), successor in witnesses.items():
            with self.subTest(quote=quote, profile=profile):
                row = self.rows[quote, profile]
                self.assertEqual(
                    row["sufficient_endpoint"]["failing_successor_q_raw"], successor
                )
                proof = prove_interval_sufficient(
                    terminal_tokens=row["terminal_tokens_raw"],
                    phantom_quote=row["phantom_quote_raw"],
                    lower_q=row["proven_lower_q_raw"],
                    upper_q=successor,
                    quote_decimals=row["quote_decimals"],
                )
                self.assertFalse(proof["all_q_proven_in_reduced_model"])

    def test_artifact_matches_generator(self):
        artifact = json.loads(ARTIFACT.read_text())
        self.assertEqual(artifact, self.matrix)

    def test_artifact_rows_are_complete_and_unique(self):
        artifact = json.loads(ARTIFACT.read_text())
        self.assertEqual(len(artifact["rows"]), 2 * len(PROFILE_INPUTS))
        self.assertEqual(len(self.rows), len(artifact["rows"]))


if __name__ == "__main__":
    unittest.main()
