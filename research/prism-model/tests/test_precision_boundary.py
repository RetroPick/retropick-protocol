"""Bounded 6/8/18 integer matrix for both settlement rules."""

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from precision_boundary import discharge_precision_boundary  # noqa: E402


EVIDENCE = Path(__file__).resolve().parents[3] / "evidence" / "research" / "prism"


class PrecisionBoundaryTests(unittest.TestCase):
    def test_decimal_bound_matrix(self):
        report = discharge_precision_boundary()
        path = EVIDENCE / "precision-boundary-6-8-18-2026-09-26.json"
        path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")
        self.assertEqual(report["id"], "PRECISION-BOUNDARY-6-8-18")
        self.assertEqual(report["cells"], 168)
        self.assertEqual(report["zero_supply_cells"], 24)
        self.assertEqual(report["one_unit_cells"], 24)
        self.assertEqual(report["domain"]["decimals"], [6, 8, 18])
        self.assertFalse(report["domain"]["full_uint256_enumeration"])
        self.assertEqual(report["new_counterexamples"], [])
        self.assertEqual(report["guard_rejections"], 0)
        self.assertGreater(report["same_defect_cells"], 0)
        reproduced = report["reproduced_counterexample"]
        self.assertEqual([row["decimals"] for row in reproduced], [6, 8, 18])
        for row in reproduced:
            self.assertEqual(row["id"], "CX-FP-SETTLEMENT-001")
            self.assertTrue(row["same_defect"])
            self.assertFalse(row["new_rule"])
            self.assertEqual(row["per_call_receipts"], [0, 0])
            self.assertEqual(row["one_shot_floor_raw"], 1)
            self.assertEqual(row["required_raw"], 2)
            self.assertEqual(row["sweepable_dust_raw"], 2)
        self.assertEqual(report["classification"], "EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN")
        self.assertEqual(report["canonical_math1"], "FAIL")
        self.assertGreater(report["runtime_seconds"], 0)


if __name__ == "__main__":
    unittest.main()
