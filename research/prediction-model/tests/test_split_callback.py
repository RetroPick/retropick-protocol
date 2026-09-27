"""ERC777 is rejected at construction. Nested split is rejected by the reentrancy flag."""

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from domain import CollateralClass, Outcome, PredictionError  # noqa: E402
from market import PredictionMarket, activate_binary, create_market  # noqa: E402


EVIDENCE = (
    Path(__file__).resolve().parents[3]
    / "evidence"
    / "research"
    / "prediction"
    / "split-callback-2026-09-26.json"
)


def python_witness() -> dict[str, object]:
    created = False
    admission = ""
    try:
        create_market(
            integer=True,
            collateral="X",
            dust_sink="SINK",
            collateral_class=CollateralClass.ERC777,
        )
        created = True
    except PredictionError as exc:
        admission = str(exc)

    market = create_market(integer=True, collateral="COLL", dust_sink="SINK")
    activate_binary(market, market_id="m", resolver="resolver", spec_hash="h")

    def reenter(live: PredictionMarket) -> None:
        live.split("alice", 1, 1)

    nested = ""
    try:
        market.split("alice", 5, 5, hook=reenter)
    except PredictionError as exc:
        nested = str(exc)
    return {
        "erc777_callback": False,
        "erc777_created": created,
        "admission_error": admission,
        "nested_split_error": nested,
        "collateral_locked": str(market.collateral_locked),
        "yes_supply": str(market.yes_supply),
        "no_supply": str(market.no_supply),
        "yes_balance": str(market.balances.get("alice", {}).get(Outcome.YES, 0)),
        "guard": "_enter",
    }


class SplitCallbackTests(unittest.TestCase):
    def test_erc777_class_and_nested_split(self):
        observed = python_witness()
        prior: dict[str, object] = {}
        if EVIDENCE.exists():
            loaded = json.loads(EVIDENCE.read_text(encoding="utf-8"))
            if isinstance(loaded, dict) and "solidity" in loaded:
                prior["solidity"] = loaded["solidity"]
        report: dict[str, object] = {
            "id": "SPLIT-CALLBACK",
            "case": "erc777-style callback during split transferFrom",
            "classification": "existing_guard",
            "guard": "nonReentrant",
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
        self.assertFalse(observed["erc777_created"])
        self.assertFalse(observed["erc777_callback"])
        self.assertEqual(
            observed["admission_error"],
            "Phase-1 admits only standard ERC-20 collateral, got ERC777",
        )
        self.assertEqual(observed["nested_split_error"], "reentrancy")
        self.assertEqual(observed["collateral_locked"], "0")
        self.assertEqual(observed["yes_supply"], "0")
        self.assertEqual(observed["no_supply"], "0")


if __name__ == "__main__":
    unittest.main()
