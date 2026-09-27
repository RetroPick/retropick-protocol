"""Split of 1 while the market is still DRAFT."""

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from domain import Outcome, PredictionError  # noqa: E402
from market import create_market  # noqa: E402


EVIDENCE = (
    Path(__file__).resolve().parents[3]
    / "evidence"
    / "research"
    / "prediction"
    / "draft-split-2026-09-26.json"
)


def _books(market) -> dict[str, str]:
    alice = market.balances.get("alice")
    yes = 0 if alice is None else alice[Outcome.YES]
    no = 0 if alice is None else alice[Outcome.NO]
    return {
        "alice_no": str(no),
        "alice_yes": str(yes),
        "collateral_locked": str(market.collateral_locked),
        "no_supply": str(market.no_supply),
        "state": market.state.value,
        "yes_supply": str(market.yes_supply),
    }


def python_witness() -> dict[str, object]:
    market = create_market(integer=True, collateral="COLL", dust_sink="SINK", max_amount=10**9)
    before = _books(market)
    error = ""
    try:
        market.split("alice", 1, 1)
    except PredictionError as exc:
        error = str(exc)
    after = _books(market)
    return {
        "after": after,
        "attempted": "1",
        "before": before,
        "error": error,
        "function": "PredictionMarket.split",
        "module": "research/prediction-model/market.py",
    }


class DraftSplitTests(unittest.TestCase):
    def test_split_while_draft_leaves_books_at_zero(self):
        observed = python_witness()
        prior: dict[str, object] = {}
        if EVIDENCE.exists():
            loaded = json.loads(EVIDENCE.read_text(encoding="utf-8"))
            if isinstance(loaded, dict) and "solidity" in loaded:
                prior["solidity"] = loaded["solidity"]
        rejected = (
            observed["error"] == "split only while OPEN"
            and observed["after"] == observed["before"]
            and observed["before"]["collateral_locked"] == "0"
            and observed["before"]["yes_supply"] == "0"
            and observed["before"]["no_supply"] == "0"
            and observed["before"]["alice_yes"] == "0"
            and observed["before"]["alice_no"] == "0"
            and observed["before"]["state"] == "DRAFT"
        )
        solidity = prior.get("solidity")
        solidity_held = (
            isinstance(solidity, dict)
            and solidity.get("error") == "BadState"
            and solidity.get("after") == solidity.get("before")
            and solidity.get("before", {}).get("collateral_locked") == "0"
            and solidity.get("before", {}).get("yes_supply") == "0"
            and solidity.get("before", {}).get("no_supply") == "0"
            and solidity.get("before", {}).get("state") == "DRAFT"
        )
        if rejected and solidity_held:
            classification = "existing_rule"
            kernels_agree = True
        elif solidity is None:
            classification = "measured"
            kernels_agree = False
        else:
            classification = "recorded_contradiction"
            kernels_agree = False
        report: dict[str, object] = {
            "id": "DRAFT-SPLIT",
            "case": "draft_split",
            "classification": classification,
            "rule": "split of 1 while DRAFT reverts and collateral, YES supply, and NO supply stay 0",
            "kernels_agree": kernels_agree,
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
        EVIDENCE.parent.mkdir(parents=True, exist_ok=True)
        EVIDENCE.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        self.assertTrue(rejected)
        self.assertEqual(observed["before"]["state"], "DRAFT")
        if solidity is not None:
            self.assertEqual(classification, "existing_rule")
            self.assertTrue(kernels_agree)


if __name__ == "__main__":
    unittest.main()
