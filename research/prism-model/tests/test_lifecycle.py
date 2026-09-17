import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import unittest

from lifecycle import SeriesState, transition, LifecycleError


class LifecycleTests(unittest.TestCase):
    def test_happy_path(self):
        state = SeriesState.DRAFT
        for target in [
            SeriesState.ACTIVE,
            SeriesState.RESOLUTION_PENDING,
            SeriesState.RESOLVED,
            SeriesState.REDEEMABLE,
            SeriesState.ARCHIVED,
        ]:
            state = transition(state, target)
        self.assertEqual(state, SeriesState.ARCHIVED)

    def test_no_resurrection(self):
        with self.assertRaises(LifecycleError):
            transition(SeriesState.RESOLVED, SeriesState.ACTIVE)

    def test_no_draft_to_redeemable(self):
        with self.assertRaises(LifecycleError):
            transition(SeriesState.DRAFT, SeriesState.REDEEMABLE)


if __name__ == "__main__":
    unittest.main()
