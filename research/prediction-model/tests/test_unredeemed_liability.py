"""Cursors and liability before any redeem, then after redeeming 1 YES."""

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from domain import Outcome, ResolutionResult  # noqa: E402
from market import activate_binary, create_market  # noqa: E402


EVIDENCE = (
    Path(__file__).resolve().parents[3]
    / "evidence"
    / "research"
    / "prediction"
    / "unredeemed-liability-2026-09-26.json"
)
SPLIT_AMOUNT = 4


def _figures(market) -> dict[str, str]:
    return {
        "collateral_locked": str(market.collateral_locked),
        "liability": str(market.liability()),
        "no_redeemed": str(market.no_redeemed),
        "yes_redeemed": str(market.yes_redeemed),
    }


def python_witness() -> dict[str, object]:
    market = create_market(integer=True, collateral="COLL", dust_sink="SINK")
    activate_binary(market, market_id="m", resolver="resolver", spec_hash="h")
    market.split("alice", SPLIT_AMOUNT, SPLIT_AMOUNT)
    before = _figures(market)
    market.close_mint()
    market.begin_resolution()
    market.resolve("resolver", ResolutionResult.YES_WIN)
    market.open_redemption()
    payout = market.redeem("alice", Outcome.YES, 1)
    after = _figures(market)
    return {
        "after_redeem_yes_1": after,
        "before_redeem": before,
        "function": "PredictionMarket.redeem",
        "module": "research/prediction-model/market.py",
        "payout": str(payout),
        "split_amount": str(SPLIT_AMOUNT),
    }


def _matches(side: object, expected_before: dict[str, str], expected_after: dict[str, str]) -> bool:
    if not isinstance(side, dict):
        return False
    return side.get("before_redeem") == expected_before and side.get("after_redeem_yes_1") == expected_after


class UnredeemedLiabilityTests(unittest.TestCase):
    def test_cursors_are_zero_before_redeem_and_liability_matches_locked(self):
        observed = python_witness()
        before = {
            "collateral_locked": "4",
            "liability": "4",
            "no_redeemed": "0",
            "yes_redeemed": "0",
        }
        after = {
            "collateral_locked": "3",
            "liability": "3",
            "no_redeemed": "0",
            "yes_redeemed": "1",
        }
        self.assertEqual(observed["before_redeem"], before)
        self.assertEqual(observed["after_redeem_yes_1"], after)
        self.assertEqual(observed["payout"], "1")

        prior: dict[str, object] = {}
        if EVIDENCE.exists():
            loaded = json.loads(EVIDENCE.read_text(encoding="utf-8"))
            if isinstance(loaded, dict) and "solidity" in loaded:
                prior["solidity"] = loaded["solidity"]
        solidity = prior.get("solidity")
        python_ok = _matches(observed, before, after)
        solidity_ok = _matches(solidity, before, after)
        if python_ok and solidity_ok:
            classification = "existing_rule"
            kernels_agree = True
        elif solidity is None:
            classification = "measured"
            kernels_agree = False
        else:
            classification = "recorded_contradiction"
            kernels_agree = False
        report: dict[str, object] = {
            "adr_added": False,
            "canonical_math1": "FAIL",
            "case": "unredeemed_cursors_and_liability",
            "classification": classification,
            "id": "UNREDEEMED-LIABILITY",
            "implementations_changed": False,
            "kernels_agree": kernels_agree,
            "pred_contract_1": "not_pass",
            "pred_kuru_1": "blocked",
            "pred_math_1": "partial",
            "python": observed,
            "s_p16": "open",
            "x_i01_through_x_i07": "NOT_YET_VALIDATED",
        }
        if solidity is not None:
            report["solidity"] = solidity
        EVIDENCE.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        if solidity is not None:
            self.assertEqual(classification, "existing_rule")
