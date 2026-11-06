#!/usr/bin/env python3
"""Fail closed on incomplete mandatory local Foundry JSON results; never qualifies forks."""
import argparse
import json
from pathlib import Path


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"Duplicate JSON key: {key}")
        result[key] = value
    return result


def check_results(data, minimum=1, required_suites=()):
    if minimum < 1:
        raise ValueError("Minimum test count must be positive")
    if not isinstance(data, dict) or not data:
        raise ValueError("Expected nonempty Foundry suite object")
    counts = {"passed": 0, "failed": 0, "skipped": 0}
    inventory = []
    suites = []
    empty_suites = []
    status_keys = {"Success": "passed", "Failure": "failed", "Skipped": "skipped"}
    for suite, result in data.items():
        if not isinstance(result, dict) or not isinstance(result.get("test_results"), dict):
            raise ValueError(f"Invalid suite result: {suite}")
        suites.append(suite)
        if not result["test_results"]:
            empty_suites.append(suite)
        for name, test in result["test_results"].items():
            if not isinstance(test, dict) or test.get("status") not in status_keys:
                raise ValueError(f"Unknown test result: {suite}:{name}")
            counts[status_keys[test["status"]]] += 1
            inventory.append({"suite": suite, "test": name, "status": test["status"]})
    missing = [name for name in required_suites if not any(s.rsplit(":", 1)[-1] == name for s in suites)]
    passed = counts["passed"] >= minimum and counts["failed"] == 0 and counts["skipped"] == 0 and not missing and not empty_suites
    return {"status": "PASS" if passed else "FAIL", "environment": "MANDATORY_LOCAL_SUITE",
            "counts": counts, "minimumTests": minimum, "missingSuites": missing, "emptySuites": empty_suites, "inventory": inventory}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("results", type=Path)
    parser.add_argument("--summary", type=Path)
    parser.add_argument("--min-tests", type=int, default=1)
    parser.add_argument("--required-suite", action="append", default=[])
    args = parser.parse_args()
    try:
        data = json.loads(args.results.read_text(), object_pairs_hook=unique_object)
        result = check_results(data, args.min_tests, args.required_suite)
    except (OSError, ValueError) as error:
        result = {"status": "FAIL", "error": str(error)}
    encoded = json.dumps(result, indent=2) + "\n"
    if args.summary:
        args.summary.write_text(encoded)
    print(encoded, end="")
    return 0 if result["status"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
