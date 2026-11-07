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

    def test_actual_hosted_grouped_invariants(self):
        root = Path(__file__).resolve().parents[2]
        path = root / "evidence/launchpad/community-economy-v2/2026-11-06-hardening/ci/hosted-42180279136/invariants.json"
        data = json.loads(path.read_text(), object_pairs_hook=unique_object)
        result = check_results(data, minimum=4, required_suites=[
            "GraduationCoordinatorV2InvariantTest", "RetroPickCurrentCurveV2InvariantTest"])
        self.assertEqual(result["status"], "PASS")
        self.assertEqual(result["counts"]["passed"], 5)
        self.assertEqual(result["runnerCounts"]["passed"], 3)

    def test_invariant_groups_cannot_forge_counts_or_hide_failures(self):
        import copy
        group = {"status": "Success", "invariant_count": 2,
                 "invariant_predicate_results": [
                     {"name": "invariantA", "status": "Success"},
                     {"name": "invariantB", "status": "Success"}],
                 "kind": {"Invariant": {"runs": 256, "calls": 32768}}}
        def wrap(g):
            return {"x:FixtureTest": {"test_results": {"invariantA()": g}}}
        self.assertEqual(check_results(wrap(group), 2)["status"], "PASS")
        for key, value in [("invariant_count", 3), ("invariant_count", True),
                           ("invariant_predicate_results", []), ("kind", {"Unit": {}})]:
            bad = copy.deepcopy(group); bad[key] = value
            with self.subTest(key=key, value=value), self.assertRaises(ValueError):
                check_results(wrap(bad))
        bad = copy.deepcopy(group)
        bad["invariant_predicate_results"][1]["name"] = "invariantA"
        with self.assertRaises(ValueError):
            check_results(wrap(bad))
        for status in ["Failure", "Skipped"]:
            bad = copy.deepcopy(group); bad["status"] = status
            self.assertEqual(check_results(wrap(bad))["status"], "FAIL")
            bad = copy.deepcopy(group); bad["invariant_predicate_results"][0]["status"] = status
            self.assertEqual(check_results(wrap(bad))["status"], "FAIL")

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
