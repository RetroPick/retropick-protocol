"""A single split argument of 2**256 after a split of 10."""

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from domain import PredictionError  # noqa: E402
from market import activate_binary, create_market  # noqa: E402


EVIDENCE = (
    Path(__file__).resolve().parents[3]
    / "evidence"
    / "research"
    / "prediction"
    / "split-max-2026-09-26.json"
)
PRIOR = 10
ATTEMPTED = 2**256


def _books(market) -> dict[str, str]:
    return {
        "collateral_locked": str(market.collateral_locked),
        "no_supply": str(market.no_supply),
        "state": market.state.value,
        "yes_supply": str(market.yes_supply),
    }


def python_witness() -> dict[str, object]:
    market = create_market(integer=True, collateral="COLL", dust_sink="SINK", max_amount=10**9)
    activate_binary(market, market_id="m1", resolver="resolver", spec_hash="spec-1")
    market.split("alice", PRIOR, PRIOR)
    before = _books(market)
    error = ""
    try:
        market.split("alice", ATTEMPTED, ATTEMPTED)
    except PredictionError as exc:
        error = str(exc)
    after = _books(market)
    return {
        "after": after,
        "attempted": str(ATTEMPTED),
        "before": before,
        "error": error,
        "function": "PredictionMarket.split",
        "max_amount": str(10**9),
        "module": "research/prediction-model/market.py",
        "prior_split": str(PRIOR),
    }


class SplitMaxTests(unittest.TestCase):
    def test_split_of_two_to_the_256_leaves_the_prior_split(self):
        observed = python_witness()
        prior: dict[str, object] = {}
        if EVIDENCE.exists():
            loaded = json.loads(EVIDENCE.read_text(encoding="utf-8"))
            if isinstance(loaded, dict) and "solidity" in loaded:
                prior["solidity"] = loaded["solidity"]
        stayed = (
            observed["error"] == "amount exceeds configured maximum"
            and observed["after"] == observed["before"]
            and observed["before"]["collateral_locked"] == "10"
            and observed["before"]["yes_supply"] == "10"
            and observed["before"]["no_supply"] == "10"
        )
        solidity = prior.get("solidity")
        solidity_held = (
            isinstance(solidity, dict)
            and solidity.get("call_representable") is False
            and solidity.get("after") == solidity.get("before")
            and solidity.get("before", {}).get("yes_supply") == "10"
        )
        classification = "existing_rule" if stayed and (solidity is None or solidity_held) else "recorded_contradiction"
        report: dict[str, object] = {
            "id": "SPLIT-MAX",
            "case": "split_max",
            "classification": classification if solidity is not None else "measured",
            "rule": "a single split argument of 2**256 is rejected and the prior split of 10 stays in place",
            "kernels_agree": bool(stayed and solidity_held),
            "theorem_pass": False,
            "math_1_progress": False,
            "canonical_math1": "FAIL",
            "pred_math_1": "partial",
            "pred_contract_1": "not_pass",
            "implementations_changed": False,
            "python": observed,
        }
        if solidity is not None:
            report["solidity"] = solidity
        EVIDENCE.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        self.assertTrue(stayed)
        self.assertEqual(observed["before"]["state"], "OPEN")
        if solidity is not None:
            self.assertEqual(classification, "existing_rule")
            self.assertTrue(report["kernels_agree"])
            self.assertEqual(solidity["error"], "amount is not a uint256")


if __name__ == "__main__":
    unittest.main()
