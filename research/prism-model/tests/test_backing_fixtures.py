import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from generate_backing_fixtures import build


class BackingFixtureFileTests(unittest.TestCase):
    def test_committed_fixture_matches_live_model(self):
        path = Path(__file__).resolve().parents[1] / "fixtures" / "backing_kernel.json"
        committed = json.loads(path.read_text(encoding="utf-8"))
        self.assertEqual(committed, build())


if __name__ == "__main__":
    unittest.main()
