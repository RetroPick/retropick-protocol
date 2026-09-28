"""Keep aggregate conservation separate from holder-level allocation fairness."""

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from holder_fairness_attack import alternating_witness, run  # noqa: E402


class HolderFairnessAttackTests(unittest.TestCase):
    def test_ordered_fragmentation_diverts_more_than_one_raw_unit(self):
        report = run()
        self.assertEqual(report["classification"], "COUNTEREXAMPLE_FOUND")
        self.assertEqual(report["formal_family"]["classification"], "PROVEN_UNDER_ASSUMPTIONS")
        self.assertTrue(all(result == "unsat" for result in report["formal_family"]["negated_claim_results"].values()))
        for case in report["executable_cases"]:
            self.assertEqual(case["aggregate_paid_raw"], case["aggregate_one_shot_floor_raw"])
            self.assertEqual(case["holder_a_paid_raw"], "0")
            self.assertEqual(case["holder_b_paid_raw"], str(case["pairs"]))
            self.assertEqual(case["holder_a_shortfall_raw"], str(case["pairs"] // 2))
            self.assertEqual(case["residual_raw"], "1")
        largest = [case for case in report["executable_cases"] if case["decimals"] == 18 and case["pairs"] == 1_000][0]
        self.assertEqual(largest["holder_a_shortfall_raw"], "500")

    def test_machine_fixture_is_python_derived(self):
        path = Path(__file__).resolve().parents[1] / "fixtures" / "holder_fairness.json"
        fixture = json.loads(path.read_text(encoding="utf-8"))
        self.assertEqual(fixture["classification"], "COUNTEREXAMPLE_FOUND")
        for case in fixture["cases"]:
            self.assertEqual(case, alternating_witness(case["decimals"], case["pairs"]))


if __name__ == "__main__":
    unittest.main()
