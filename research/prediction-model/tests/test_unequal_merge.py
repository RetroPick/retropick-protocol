"""Merge of unequal YES and NO balances before resolution."""

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from domain import MarketState, Outcome, PredictionError  # noqa: E402
from market import activate_binary, create_market  # noqa: E402


EVIDENCE = (
    Path(__file__).resolve().parents[3]
    / "evidence"
    / "research"
    / "prediction"
    / "unequal-merge-2026-09-26.json"
)
QUANTITY = 4
MOVED_YES = 3
ATTEMPTED = 4


def _holder(market, account: str) -> dict[str, str]:
    bal = market.balances.get(account, {})
    return {
        "no": str(bal.get(Outcome.NO, 0)),
        "yes": str(bal.get(Outcome.YES, 0)),
    }


def _books(market) -> dict[str, object]:
    return {
        "alice": _holder(market, "alice"),
        "bob": _holder(market, "bob"),
        "collateral_locked": str(market.collateral_locked),
        "no_supply": str(market.no_supply),
        "state": market.state.value,
        "yes_supply": str(market.yes_supply),
    }


def python_witness() -> dict[str, object]:
    market = create_market(integer=True, collateral="COLL", dust_sink="SINK")
    activate_binary(market, market_id="m", resolver="resolver", spec_hash="h")
    market.split("alice", QUANTITY, QUANTITY)
    alice = market.balances["alice"]
    bob = market.balances.setdefault("bob", {Outcome.YES: 0, Outcome.NO: 0})
    alice[Outcome.YES] -= MOVED_YES
    bob[Outcome.YES] += MOVED_YES
    before = _books(market)
    released = False
    error = ""
    try:
        market.merge("alice", ATTEMPTED)
        released = True
    except PredictionError as exc:
        error = str(exc)
    after = _books(market)
    return {
        "after": after,
        "attempted": str(ATTEMPTED),
        "before": before,
        "error": error,
        "function": "PredictionMarket.merge",
        "module": "research/prediction-model/market.py",
        "moved_yes": str(MOVED_YES),
        "open_before_resolution": before["state"] == MarketState.OPEN.value,
        "setup": "the reference model has no outcome transfer; the witness moves 3 YES from alice to bob on the balance books",
        "quantity": str(QUANTITY),
        "released": released,
        "returned": released,
    }


class UnequalMergeTests(unittest.TestCase):
    def test_merge_of_unequal_yes_and_no_leaves_books_unchanged(self):
        observed = python_witness()
        prior: dict[str, object] = {}
        if EVIDENCE.exists():
            loaded = json.loads(EVIDENCE.read_text(encoding="utf-8"))
            if isinstance(loaded, dict) and "solidity" in loaded:
                prior["solidity"] = loaded["solidity"]
        before = observed["before"]
        after = observed["after"]
        rejected = (
            observed["error"] == "merge requires equal YES and NO balances"
            and observed["released"] is False
            and after == before
        )
        report: dict[str, object] = {
            "id": "UNEQUAL-MERGE",
            "case": "merge of unequal YES and NO amounts before resolution",
            "classification": "existing_rule" if rejected else "COUNTEREXAMPLE_FOUND",
            "rule": "merge of the larger side reverts and collateral, YES supply, and NO supply stay unchanged",
            "kernels_agree": True,
            "theorem_pass": False,
            "math_1_progress": False,
            "canonical_math1": "FAIL",
            "pred_math_1": "partial",
            "pred_contract_1": "not_pass",
            "implementations_changed": False,
            "python": observed,
        }
        if prior:
            report["solidity"] = prior["solidity"]
        EVIDENCE.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        self.assertEqual(before["state"], "OPEN")
        self.assertEqual(before["alice"], {"no": "4", "yes": "1"})
        self.assertEqual(before["bob"], {"no": "0", "yes": "3"})
        self.assertEqual(before["collateral_locked"], "4")
        self.assertEqual(before["yes_supply"], "4")
        self.assertEqual(before["no_supply"], "4")
        self.assertFalse(observed["released"])
        self.assertFalse(observed["returned"])
        self.assertEqual(observed["error"], "merge requires equal YES and NO balances")
        self.assertEqual(after, before)
        self.assertEqual(report["classification"], "existing_rule")


if __name__ == "__main__":
    unittest.main()
