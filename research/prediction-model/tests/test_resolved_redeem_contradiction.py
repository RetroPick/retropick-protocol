"""Contradiction 2: native redeem is legal in RESOLVED; prediction redeem is not."""

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PRISM = Path(__file__).resolve().parents[2] / "prism-model"
sys.path.insert(0, str(PRISM))
sys.path.insert(0, str(ROOT))

from domain import MarketState, Outcome, PredictionError, ResolutionResult  # noqa: E402
from lifecycle import redeem_allowed  # noqa: E402
from market import activate_binary, create_market  # noqa: E402
from native_market import BinaryCompleteSetMarket, NativeMarketState  # noqa: E402


EVIDENCE = (
    Path(__file__).resolve().parents[3]
    / "evidence"
    / "research"
    / "prediction"
    / "resolved-redeem-contradiction-2026-09-26.json"
)


def witness() -> dict[str, object]:
    native = BinaryCompleteSetMarket()
    native.split(4)
    native.resolve("YES")
    native_state = native.state.value
    native_collateral_before = str(native.collateral_locked)
    native_payout = str(native.redeem("YES", 1))
    prediction = create_market(integer=True, collateral="COLL", dust_sink="SINK")
    activate_binary(prediction, market_id="m", resolver="resolver", spec_hash="h")
    prediction.split("alice", 4, 4)
    prediction.close_mint()
    prediction.begin_resolution()
    prediction.resolve("resolver", ResolutionResult.YES_WIN)
    prediction_state = prediction.state.value
    prediction_collateral_before = str(prediction.collateral_locked)
    prediction_yes_before = str(prediction.yes_supply)
    rejected = False
    message = ""
    try:
        prediction.redeem("alice", Outcome.YES, 1)
    except PredictionError as exc:
        rejected = True
        message = str(exc)
    return {
        "id": "CONTRADICTION-2-RESOLVED-REDEEM",
        "classification": "recorded_contradiction",
        "contradiction_open": True,
        "theorem_pass": False,
        "math_1_progress": False,
        "canonical_math1": "FAIL",
        "pred_math_1": "partial",
        "pred_contract_1": "not_pass",
        "functions_changed": False,
        "native_market": {
            "module": "research/prism-model/native_market.py",
            "function": "BinaryCompleteSetMarket.redeem",
            "states": [state.value for state in NativeMarketState],
            "redeemable_state_present": any(
                state.value == "REDEEMABLE" for state in NativeMarketState
            ),
            "state_at_redeem": native_state,
            "outcome": "YES",
            "quantity": "1",
            "payout": native_payout,
            "state_after": native.state.value,
            "collateral_before": native_collateral_before,
            "collateral_after": str(native.collateral_locked),
            "yes_supply_after": str(native.yes_supply),
            "no_supply_after": str(native.no_supply),
        },
        "prediction_market": {
            "module": "research/prediction-model/market.py",
            "function": "PredictionMarket.redeem",
            "state_at_redeem": prediction_state,
            "redeem_allowed_in_resolved": redeem_allowed(MarketState.RESOLVED),
            "redeem_allowed_in_redeemable": redeem_allowed(MarketState.REDEEMABLE),
            "outcome": "YES",
            "quantity": "1",
            "rejected": rejected,
            "error": message,
            "state_after": prediction.state.value,
            "collateral_before": prediction_collateral_before,
            "collateral_after": str(prediction.collateral_locked),
            "yes_supply_before": prediction_yes_before,
            "yes_supply_after": str(prediction.yes_supply),
            "no_supply_after": str(prediction.no_supply),
            "yes_redeemed_after": str(prediction.yes_redeemed),
        },
    }


class ResolvedRedeemContradictionTests(unittest.TestCase):
    def test_native_redeem_in_resolved_and_prediction_rejects_before_redeemable(self):
        report = witness()
        EVIDENCE.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        native = report["native_market"]
        prediction = report["prediction_market"]
        self.assertIsInstance(native, dict)
        self.assertIsInstance(prediction, dict)
        self.assertEqual(report["classification"], "recorded_contradiction")
        self.assertTrue(report["contradiction_open"])
        self.assertFalse(report["theorem_pass"])
        self.assertFalse(report["math_1_progress"])
        self.assertEqual(report["canonical_math1"], "FAIL")
        self.assertEqual(report["pred_math_1"], "partial")
        self.assertEqual(report["pred_contract_1"], "not_pass")
        self.assertEqual(native["state_at_redeem"], "RESOLVED")
        self.assertEqual(native["payout"], "1")
        self.assertEqual(native["state_after"], "RESOLVED")
        self.assertEqual(native["collateral_before"], "4")
        self.assertEqual(native["collateral_after"], "3")
        self.assertFalse(native["redeemable_state_present"])
        self.assertEqual(prediction["state_at_redeem"], "RESOLVED")
        self.assertTrue(prediction["rejected"])
        self.assertEqual(prediction["error"], "redeem only while REDEEMABLE")
        self.assertEqual(prediction["state_after"], "RESOLVED")
        self.assertEqual(prediction["collateral_before"], "4")
        self.assertEqual(prediction["collateral_after"], "4")
        self.assertEqual(prediction["yes_supply_after"], "4")
        self.assertEqual(prediction["yes_redeemed_after"], "0")
        self.assertFalse(prediction["redeem_allowed_in_resolved"])
        self.assertTrue(prediction["redeem_allowed_in_redeemable"])


if __name__ == "__main__":
    unittest.main()
