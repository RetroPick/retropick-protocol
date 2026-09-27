"""Exact enumeration of written T-LC-001, no resurrection into issuance."""

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from t_lc_001 import discharge_t_lc_001  # noqa: E402


EVIDENCE = Path(__file__).resolve().parents[3] / "evidence" / "research" / "prism"
ALLOWED = [
    "ACTIVE->MINT_PAUSED",
    "ACTIVE->RESOLUTION_PENDING",
    "DRAFT->ACTIVE",
    "MINT_PAUSED->RESOLUTION_PENDING",
    "REDEEMABLE->ARCHIVED",
    "RESOLUTION_PENDING->RESOLVED",
    "RESOLVED->REDEEMABLE",
]


class TLc001Tests(unittest.TestCase):
    def test_no_resurrection_into_issuance(self):
        report = discharge_t_lc_001()
        path = EVIDENCE / "t-lc-001-2026-09-26.json"
        path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")
        self.assertEqual(report["id"], "T-LC-001")
        self.assertEqual(report["classification"], "PROVEN_UNDER_ASSUMPTIONS")
        self.assertIsNone(report["counterexample"])
        self.assertEqual(report["states"], [
            "DRAFT",
            "ACTIVE",
            "MINT_PAUSED",
            "RESOLUTION_PENDING",
            "RESOLVED",
            "REDEEMABLE",
            "ARCHIVED",
        ])
        self.assertEqual(report["pair_count"], 49)
        self.assertEqual(report["allowed_edges"], ALLOWED)
        self.assertEqual(report["allowed_count"], 7)
        self.assertEqual(report["rejected_count"], 42)
        self.assertEqual(report["resurrection_edges"], [])
        self.assertEqual(report["resurrection_paths"], [])
        self.assertTrue(report["resolved_distinct_from_redeemable"])
        self.assertFalse(report["redeemable_to_resolved"])
        self.assertFalse(report["cancel_draft_edge"])
        self.assertTrue(all(not row["permitted"] and row["raised"] for row in report["forbidden"]))
        self.assertEqual(report["canonical_math1"], "FAIL")
        self.assertGreaterEqual(report["runtime_seconds"], 0)


if __name__ == "__main__":
    unittest.main()
