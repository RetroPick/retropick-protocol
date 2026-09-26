"""Locks the fresh MATH-1 settlement counterexample and the candidate repair."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from math1_probe import (  # noqa: E402
    and_counterexample,
    component_round_trip_samples,
    cumulative_floor_dust,
    search_cumulative_dust,
    settlement_fragmentation_counterexample,
    sympy_identity,
    z3_reports,
)


class Math1ProbeTests(unittest.TestCase):
    def test_per_call_settlement_floor_strands_holder_value(self):
        row = settlement_fragmentation_counterexample()
        self.assertEqual(row["classification"], "COUNTEREXAMPLE_FOUND")
        self.assertEqual(row["fragmented_paid_raw"], 0)
        self.assertEqual(row["one_shot_floor_raw"], 1)
        self.assertEqual(row["swept_dust_raw"], 2)
        self.assertGreater(row["swept_dust_raw"], row["one_shot_floor_raw"])

    def test_cumulative_floor_dust_is_at_most_one_in_the_grid(self):
        report = search_cumulative_dust()
        self.assertTrue(report["bounded_by_one"])
        sample = cumulative_floor_dust(2, 10**18 - 1)
        self.assertEqual(sample["paid"], sample["one_shot"])
        self.assertLessEqual(sample["dust"], 1)

    def test_component_round_trip_sample(self):
        self.assertEqual(component_round_trip_samples(30, seed=1)["mismatches"], 0)

    def test_and_is_not_replicable(self):
        self.assertEqual(and_counterexample()["classification"], "COUNTEREXAMPLE_FOUND")

    def test_z3_and_sympy_available_results(self):
        z3_row = z3_reports()
        self.assertNotEqual(z3_row.get("status"), "BLOCKED_TOOL")
        self.assertEqual(z3_row["and_with_constant"], "COUNTEREXAMPLE_FOUND")
        self.assertEqual(z3_row["two_component_terminal_solvency"], "PROVEN_UNDER_ASSUMPTIONS")
        sympy_row = sympy_identity()
        self.assertEqual(sympy_row["classification"], "PROVEN_UNDER_ASSUMPTIONS")


if __name__ == "__main__":
    unittest.main()
