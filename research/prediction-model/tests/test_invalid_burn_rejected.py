"""Burn of NO after the INVALID YES dust stream."""

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from domain import Outcome, PredictionError, ResolutionResult  # noqa: E402
from market import activate_binary, create_market  # noqa: E402


EVIDENCE = (
    Path(__file__).resolve().parents[3]
    / "evidence"
    / "research"
    / "prediction"
    / "invalid-burn-rejected-2026-09-26.json"
)


def _books(market) -> dict[str, str]:
    alice = market.balances["alice"]
    return {
        "alice_no": str(alice[Outcome.NO]),
        "alice_yes": str(alice[Outcome.YES]),
        "collateral_locked": str(market.collateral_locked),
        "no_supply": str(market.no_supply),
        "state": market.state.value,
        "yes_supply": str(market.yes_supply),
    }


def python_witness() -> dict[str, object]:
    market = create_market(integer=True, collateral="COLL", dust_sink="SINK", max_amount=10**9)
    activate_binary(market, market_id="m1", resolver="resolver", spec_hash="spec-1")
    market.split("alice", 5, 5)
    market.close_mint()
    market.begin_resolution()
    market.resolve("resolver", ResolutionResult.INVALID)
    market.open_redemption()
    payouts = [int(market.redeem("alice", Outcome.YES, 1)) for _ in range(5)]
    before = _books(market)
    error = ""
    try:
        market.burn_worthless("alice", Outcome.NO, 1)
    except PredictionError as exc:
        error = str(exc)
    after = _books(market)
    return {
        "after": after,
        "attempted": "1",
        "before": before,
        "error": error,
        "function": "PredictionMarket.burn_worthless",
        "module": "research/prediction-model/market.py",
        "side": "NO",
        "yes_payouts": [str(item) for item in payouts],
    }


class InvalidBurnRejectedTests(unittest.TestCase):
    def test_burn_no_after_invalid_yes_dust_is_rejected(self):
        observed = python_witness()
        prior: dict[str, object] = {}
        if EVIDENCE.exists():
            loaded = json.loads(EVIDENCE.read_text(encoding="utf-8"))
            if isinstance(loaded, dict) and "solidity" in loaded:
                prior["solidity"] = loaded["solidity"]
        rejected = (
            observed["error"] == "side is not worthless"
            and observed["after"] == observed["before"]
            and observed["before"]["collateral_locked"] == "3"
            and observed["before"]["yes_supply"] == "0"
            and observed["before"]["no_supply"] == "5"
            and observed["yes_payouts"] == ["0", "1", "0", "1", "0"]
        )
        solidity = prior.get("solidity")
        solidity_held = (
            isinstance(solidity, dict)
            and solidity.get("error") == "NotWorthless"
            and solidity.get("after") == solidity.get("before")
            and solidity.get("before", {}).get("collateral_locked") == "3"
            and solidity.get("before", {}).get("yes_supply") == "0"
            and solidity.get("before", {}).get("no_supply") == "5"
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
            "id": "INVALID-BURN-REJECTED",
            "case": "invalid_burn_rejected",
            "classification": classification,
            "rule": "after the INVALID YES dust stream, burn of NO 1 reverts and the books stay put",
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
        EVIDENCE.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        self.assertTrue(rejected)
        self.assertEqual(observed["before"]["state"], "REDEEMABLE")
        self.assertEqual(observed["before"]["alice_no"], "5")
        self.assertEqual(observed["before"]["alice_yes"], "0")
        if solidity is not None:
            self.assertEqual(classification, "existing_rule")
            self.assertTrue(kernels_agree)


if __name__ == "__main__":
    unittest.main()
