"""SymPy and Z3 discharge of written T-PARTIAL-001, the partial-resolution NAV split."""

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from t_partial_001 import discharge_t_partial_001  # noqa: E402


EVIDENCE = Path(__file__).resolve().parents[3] / "evidence" / "research" / "prism"


class TPartial001Tests(unittest.TestCase):
    def test_nav_decomposes_by_resolved_and_unresolved_sets(self):
        report = discharge_t_partial_001()
        path = EVIDENCE / "t-partial-001-2026-09-26.json"
        path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")
        self.assertEqual(report["id"], "T-PARTIAL-001")
        self.assertEqual(report["classification"], "PROVEN_UNDER_ASSUMPTIONS")
        self.assertIsNone(report["counterexample"])
        self.assertEqual(report["failed_shapes"], [])
        self.assertEqual(report["shapes_checked"], 30)
        self.assertEqual(report["identity_negation"], "unsat")
        self.assertEqual(report["linearity_negation"], "unsat")
        self.assertEqual(report["oracle_partitions"], 30)
        self.assertEqual(report["oracle_mismatches"], [])
        self.assertEqual(report["documented_basket"]["nav"], "18/25")
        self.assertEqual(report["documented_basket"]["expected"], "18/25")
        self.assertTrue(report["non_partition"]["gap_rejected"])
        self.assertTrue(report["non_partition"]["overlap_rejected"])
        self.assertEqual(report["negative_mark"], "rejected_outside_nonnegative_domain")
        self.assertEqual(report["canonical_math1"], "FAIL")
        self.assertGreater(report["runtime_seconds"], 0)


if __name__ == "__main__":
    unittest.main()
