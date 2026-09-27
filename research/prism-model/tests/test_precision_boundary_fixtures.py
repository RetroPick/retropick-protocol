"""Lock the 6/8/18 Solidity fixture split. Does not change payout formulas."""

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from generate_precision_boundary_fixtures import OUT, build  # noqa: E402
from precision_boundary import UINT256_MAX  # noqa: E402


EVIDENCE = Path(__file__).resolve().parents[3] / "evidence" / "research" / "prism"


class PrecisionBoundaryFixtureTests(unittest.TestCase):
    def test_solidity_domain_excludes_overflow_and_keeps_per_call_in_python(self):
        report = build()
        OUT.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
        evidence = {
            "id": "PRECISION-BOUNDARY-SOLIDITY",
            "solidity_case_count": report["solidity_case_count"],
            "excluded_overflow_count": report["excluded_overflow_count"],
            "excluded_zero_supply_count": report["excluded_zero_supply_count"],
            "per_call_regression_count": report["per_call_regression_count"],
            "per_call_rule_in_solidity": report["per_call_rule_in_solidity"],
            "kernel_status": report["kernel_status"],
            "math_1": report["math_1"],
            "cx_fp_settlement_001": report["cx_fp_settlement_001"],
            "excluded_overflow": report["excluded_overflow"],
        }
        path = EVIDENCE / "precision-boundary-solidity-2026-09-26.json"
        path.write_text(json.dumps(evidence, indent=2, sort_keys=True) + "\n", encoding="utf-8")

        self.assertEqual(report["cell_count"], 168)
        self.assertEqual(
            report["solidity_case_count"] + report["excluded_overflow_count"] + report["excluded_zero_supply_count"],
            168,
        )
        self.assertEqual(report["excluded_zero_supply_count"], 24)
        self.assertGreater(report["excluded_overflow_count"], 0)
        self.assertEqual(report["per_call_regression_count"], 48)
        self.assertFalse(report["per_call_rule_in_solidity"])
        self.assertEqual(report["kernel_status"], "differential_research_kernel")
        self.assertEqual(report["math_1"], "FAIL")
        for row in report["cases"]:
            self.assertLessEqual(int(row["supply"]) * int(row["payout_wad"]), UINT256_MAX)
            self.assertNotEqual(row["supply"], "0")
            self.assertEqual(row["paid_total"], row["one_shot_floor"])
        overflow_keys = {(row["decimals"], row["supply"], row["payout_wad"]) for row in report["excluded_overflow"]}
        for row in report["cases"]:
            self.assertNotIn((row["decimals"], row["supply"], row["payout_wad"]), overflow_keys)
        for row in report["excluded_overflow"]:
            self.assertGreater(int(row["supply"]) * int(row["payout_wad"]), UINT256_MAX)
        canonical = report["cx_fp_settlement_001"]
        self.assertEqual([row["decimals"] for row in canonical], [6, 8, 18])
        for row in canonical:
            self.assertEqual(row["per_call_receipts"], ["0", "0"])
            self.assertEqual(row["one_shot_floor_raw"], "1")
            self.assertEqual(row["required_raw"], "2")
            self.assertEqual(row["sweepable_dust_raw"], "2")
            self.assertFalse(row["solidity_implements_per_call_rule"])
        self.assertTrue(all(not row["solidity_implements_per_call_rule"] for row in report["per_call_regressions"]))


if __name__ == "__main__":
    unittest.main()
