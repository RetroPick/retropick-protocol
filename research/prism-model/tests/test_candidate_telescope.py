"""Global-cursor telescope is proved under the stated assumptions. Per-holder is not."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from candidate_telescope_proof import run  # noqa: E402


class CandidateTelescopeProofTests(unittest.TestCase):
    def test_global_cursor_identity_and_per_holder_regression(self):
        report = run()
        self.assertEqual(report["canonical_math_1"], "FAIL")
        self.assertEqual(report["global_cursor"]["classification"], "PROVEN_UNDER_ASSUMPTIONS")
        self.assertEqual(report["global_cursor"]["inductive_step_cancels"], "True")
        self.assertEqual(report["global_cursor"]["floor_of_zero_is_zero"], "True")
        self.assertEqual(report["per_holder_cursor"]["classification"], "COUNTEREXAMPLE_FOUND")
        self.assertEqual(report["per_holder_cursor"]["witness_gap"], "1")
        self.assertEqual(report["z3_witness"]["classification"], "COUNTEREXAMPLE_FOUND")
        regression = report["python_regression"]
        self.assertEqual(regression["global_paid"], 1)
        self.assertEqual(regression["one_shot"], 1)
        self.assertEqual(regression["per_holder_paid"], 0)
        self.assertGreater(report["runtime_seconds"], 0)


if __name__ == "__main__":
    unittest.main()
