"""Z3 discharge of written T-NATIVE-002, the valid binary terminal sum."""

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from t_native_002 import discharge_t_native_002  # noqa: E402


EVIDENCE = Path(__file__).resolve().parents[3] / "evidence" / "research" / "prism"


class TNative002Tests(unittest.TestCase):
    def test_valid_binary_payoff_sums_to_one(self):
        report = discharge_t_native_002()
        path = EVIDENCE / "t-native-002-2026-09-26.json"
        path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")
        self.assertEqual(report["id"], "T-NATIVE-002")
        self.assertEqual(report["classification"], "PROVEN_UNDER_ASSUMPTIONS")
        self.assertIsNone(report["counterexample"])
        self.assertEqual(report["valid_sum_negation"], "unsat")
        self.assertEqual(report["yes_wins"], {"no": 0, "sum": 1, "yes": 1})
        self.assertEqual(report["no_wins"], {"no": 1, "sum": 1, "yes": 0})
        invalid = report["invalid_void"]
        self.assertEqual(invalid["payout"], "unspecified")
        self.assertTrue(invalid["resolve_rejected"])
        self.assertIsNone(invalid["winner"])
        self.assertEqual(invalid["state"], "ACTIVE")
        self.assertEqual(report["canonical_math1"], "FAIL")
        self.assertGreater(report["runtime_seconds"], 0)


if __name__ == "__main__":
    unittest.main()
