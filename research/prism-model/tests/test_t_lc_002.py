"""Exact enumeration of written T-LC-002, final resolution committed once."""

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from t_lc_002 import discharge_t_lc_002  # noqa: E402


EVIDENCE = Path(__file__).resolve().parents[3] / "evidence" / "research" / "prism"


class TLc002Tests(unittest.TestCase):
    def test_final_resolution_commits_once(self):
        report = discharge_t_lc_002()
        path = EVIDENCE / "t-lc-002-2026-09-26.json"
        path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")
        self.assertEqual(report["id"], "T-LC-002")
        self.assertEqual(report["classification"], "PROVEN_UNDER_ASSUMPTIONS")
        self.assertIsNone(report["counterexample"])
        self.assertEqual(report["accepting_state"], "RESOLUTION_PENDING")
        pending = next(row for row in report["state_guard"] if row["state"] == "RESOLUTION_PENDING")
        self.assertEqual(pending["accepted_count"], 1)
        self.assertEqual(pending["final"]["state"], "RESOLVED")
        self.assertTrue(pending["rejected_unchanged"])
        for row in report["state_guard"]:
            if row["state"] == "RESOLUTION_PENDING":
                continue
            self.assertEqual(row["accepted_count"], 0)
            self.assertTrue(row["rejected_unchanged"])
        api = report["api_commit"]
        self.assertEqual(api["accepted_count"], 1)
        self.assertEqual(api["final"]["state"], "RESOLVED")
        self.assertEqual(api["final"]["payout"], api["expected_payout"])
        self.assertTrue(api["rejected_unchanged"])
        narrow = report["narrow_commit"]
        self.assertEqual(narrow["accepted_count"], 1)
        self.assertEqual(narrow["accepted"][0]["index"], 0)
        self.assertEqual(narrow["final"]["payout"], narrow["expected_payout"])
        after = report["after_commit"]
        self.assertEqual(after["resolved_state"], "RESOLVED")
        self.assertEqual(after["redeemable_state"], "REDEEMABLE")
        self.assertEqual(after["archived_state"], "ARCHIVED")
        self.assertTrue(report["resolved_distinct_from_redeemable"])
        self.assertFalse(after["redeemable_attempt"]["accepted"])
        self.assertTrue(after["redeemable_attempt"]["unchanged"])
        self.assertFalse(after["archived_attempt"]["accepted"])
        self.assertTrue(after["archived_attempt"]["unchanged"])
        self.assertTrue(all(row["raised"] and row["unchanged"] for row in after["reopen"]))
        self.assertEqual(report["canonical_math1"], "FAIL")
        self.assertGreaterEqual(report["runtime_seconds"], 0)


if __name__ == "__main__":
    unittest.main()
