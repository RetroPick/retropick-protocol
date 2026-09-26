"""Each P-I01..P-I10 id has an executable case."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from invariant_ids import run_invariant_ids  # noqa: E402


class InvariantIdTests(unittest.TestCase):
    def test_each_id_holds_on_its_scenario(self):
        report = run_invariant_ids()
        self.assertEqual(set(report), {f"P-I0{index}" for index in range(1, 10)} | {"P-I10"})
        for identifier, row in report.items():
            self.assertEqual(row["classification"], "EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN", identifier)
        self.assertEqual(report["P-I05"]["kernel_cancel_draft"], "measured")
        self.assertEqual(report["P-I05"]["kernel_operation"], "cancelDraft")
        self.assertEqual(report["P-I05"]["cancelled_draft_reason"], "CANCELLED_BEFORE_ACTIVATION")
        self.assertEqual(report["P-I05"]["cancelled_draft_collateral"], "0")


if __name__ == "__main__":
    unittest.main()
