"""Supply-16 cumulative compositions and the bounded backing grid.

Neither search edits a payout or backing formula. Canonical MATH-1 stays FAIL.
"""

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from backing_domain import run_backing_domain  # noqa: E402
from cumulative_settlement_attack import run_supply16_compositions  # noqa: E402


EVIDENCE = Path(__file__).resolve().parents[3] / "evidence" / "research" / "prism"


class ExtendedDomainTests(unittest.TestCase):
    def test_supply16_compositions_stay_within_the_one_shot_floor(self):
        report = run_supply16_compositions()
        self.assertEqual(report["composition_supply_max"], 16)
        self.assertEqual(report["previous_composition_supply_max"], 12)
        self.assertEqual(report["decimals"], 18)
        self.assertEqual(report["holders"], ["A", "B"])
        self.assertEqual(report["states"], 917612)
        self.assertEqual(report["transitions"], 7340046)
        self.assertEqual(report["failure_count"], 0)
        self.assertIsNone(report["minimal_counterexample"])
        self.assertEqual(report["domain_check"], "EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN")
        self.assertEqual(report["canonical_math1"], "FAIL")
        self.assertEqual(report["original_case"]["AB"]["paid"], 1)
        self.assertEqual(report["original_case"]["AB"]["residual"], 1)
        self.assertEqual(report["original_case"]["BA"]["paid"], 1)
        self.assertEqual(report["original_case"]["BA"]["residual"], 1)
        fairness = report["fairness_case"]
        self.assertEqual(fairness["payout_wad"], 500000000000000001)
        self.assertEqual(fairness["paid"], fairness["one_shot"])
        self.assertEqual(fairness["paid"], 1)
        self.assertEqual(fairness["residual"], 1)
        self.assertLessEqual(fairness["paid"], fairness["one_shot"])
        self.assertGreater(report["runtime_seconds"], 0)
        path = EVIDENCE / "cumulative-floor-supply16-2026-09-26.json"
        path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")

    def test_backing_grid_preserves_component_backing(self):
        report = run_backing_domain()
        self.assertEqual(report["states"], 81)
        self.assertEqual(report["transitions"], 2187)
        self.assertEqual(report["accepted"], 1044)
        self.assertEqual(report["rejected"], 1143)
        self.assertEqual(report["failure_count"], 0)
        self.assertIsNone(report["minimal_counterexample"])
        self.assertEqual(report["domain_check"], "EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN")
        self.assertEqual(report["weights"], ["0", "1/2", "1"])
        self.assertGreater(report["runtime_seconds"], 0)
        path = EVIDENCE / "backing-domain-2026-09-26.json"
        path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")


if __name__ == "__main__":
    unittest.main()
