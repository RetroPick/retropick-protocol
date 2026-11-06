"""Qualification gates must distinguish execution evidence from an empty green runner."""
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

from check_foundry_results import check_results, unique_object


def suite(*statuses):
    return {"test/Fixture.t.sol:FixtureTest": {"test_results": {
        f"test{i}()": {"status": status} for i, status in enumerate(statuses)}}}


class FoundryResultsTest(unittest.TestCase):
    def test_success_inventory_and_minimum(self):
        result = check_results(suite("Success", "Success"), 2, ["FixtureTest"])
        self.assertEqual(result["status"], "PASS")
        self.assertEqual(result["counts"], {"passed": 2, "failed": 0, "skipped": 0})
        self.assertEqual(len(result["inventory"]), 2)

    def test_failure_blocks_even_with_success(self):
        self.assertEqual(check_results(suite("Success", "Failure"))["status"], "FAIL")

    def test_skip_is_not_a_pass(self):
        self.assertEqual(check_results(suite("Success", "Skipped"))["status"], "FAIL")
        self.assertEqual(check_results(suite("Skipped"))["status"], "FAIL")

    def test_empty_selection_is_not_a_pass(self):
        self.assertEqual(check_results(suite())["status"], "FAIL")
        with self.assertRaises(ValueError):
            check_results({})

    def test_expected_inventory_missing(self):
        result = check_results(suite("Success"), required_suites=["AuthorityTest"])
        self.assertEqual(result["status"], "FAIL")
        self.assertEqual(result["missingSuites"], ["AuthorityTest"])

    def test_empty_required_suite_cannot_borrow_other_suite_passes(self):
        data = suite("Success")
        data["test/Auth.t.sol:AuthorityTest"] = {"test_results": {}}
        result = check_results(data, required_suites=["AuthorityTest"])
        self.assertEqual(result["status"], "FAIL")
        self.assertEqual(result["emptySuites"], ["test/Auth.t.sol:AuthorityTest"])

    def test_minimum_cannot_be_weakened_to_zero(self):
        with self.assertRaises(ValueError):
            check_results(suite("Success"), 0)
        self.assertEqual(check_results(suite("Success"), 2)["status"], "FAIL")

    def test_invalid_or_future_schema_fails_closed(self):
        for data in [[], {"suite": {}}, {"suite": {"test_results": []}}, suite("FutureStatus")]:
            with self.subTest(data=data), self.assertRaises(ValueError):
                check_results(data)

    def test_duplicate_suite_or_test_cannot_hide_failure(self):
        with self.assertRaises(ValueError):
            json.loads('{"x": {"status": "Failure"}, "x": {"status": "Success"}}', object_pairs_hook=unique_object)

    def test_cli_corrupt_json_creates_failed_artifact(self):
        script = Path(__file__).with_name("check_foundry_results.py")
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / "input.json"
            output = Path(directory) / "summary.json"
            source.write_text("not JSON")
            result = subprocess.run([sys.executable, str(script), str(source), "--summary", str(output)], capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(json.loads(output.read_text())["status"], "FAIL")


if __name__ == "__main__":
    unittest.main()
