import unittest

from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "models"))
from prediction_p0 import PredictionP0


class PredictionP0ModelTest(unittest.TestCase):
    def test_standard_outcome_token_zero_and_self_transfers_are_noops(self):
        model = PredictionP0()
        model.activate()
        model.split("alice", 5)
        before = model.snapshot("alice", "bob")
        model.transfer("alice", "alice", "YES", 2)
        model.transfer("alice", "bob", "NO", 0)
        self.assertEqual(model.snapshot("alice", "bob"), before)


if __name__ == "__main__":
    unittest.main()
