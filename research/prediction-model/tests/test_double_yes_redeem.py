"""Same YES balance redeemed twice after a YES win and open redemption."""

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
    / "double-yes-redeem-2026-09-26.json"
)
QUANTITY = 4


def _books(market) -> dict[str, str]:
    yes = market.balances["alice"][Outcome.YES]
    no = market.balances["alice"][Outcome.NO]
    return {
        "collateral_locked": str(market.collateral_locked),
        "holder_no": str(no),
        "holder_yes": str(yes),
        "no_supply": str(market.no_supply),
        "yes_redeemed": str(market.yes_redeemed),
        "yes_supply": str(market.yes_supply),
    }


def python_witness() -> dict[str, object]:
    market = create_market(integer=True, collateral="COLL", dust_sink="SINK")
    activate_binary(market, market_id="m", resolver="resolver", spec_hash="h")
    market.split("alice", QUANTITY, QUANTITY)
    market.close_mint()
    market.begin_resolution()
    market.resolve("resolver", ResolutionResult.YES_WIN)
    market.open_redemption()
    before = _books(market)
    first_payout = market.redeem("alice", Outcome.YES, QUANTITY)
    after_first = _books(market)
    second_error = ""
    second_paid = False
    try:
        market.redeem("alice", Outcome.YES, QUANTITY)
        second_paid = True
    except PredictionError as exc:
        second_error = str(exc)
    after_second = _books(market)
    return {
        "after_first": after_first,
        "after_second": after_second,
        "before_first": before,
        "error": second_error,
        "first_payout": str(first_payout),
        "function": "PredictionMarket.redeem",
        "module": "research/prediction-model/market.py",
        "quantity": str(QUANTITY),
        "result": ResolutionResult.YES_WIN.value,
        "second_paid": second_paid,
        "state": market.state.value,
    }


class DoubleYesRedeemTests(unittest.TestCase):
    def test_second_redeem_of_the_same_yes_balance_does_not_pay(self):
        observed = python_witness()
        prior: dict[str, object] = {}
        if EVIDENCE.exists():
            loaded = json.loads(EVIDENCE.read_text(encoding="utf-8"))
            if isinstance(loaded, dict) and "solidity" in loaded:
                prior["solidity"] = loaded["solidity"]
        report: dict[str, object] = {
            "id": "DOUBLE-YES-REDEEM",
            "case": "same holder redeems the same winning YES balance twice",
            "classification": "existing_rule",
            "rule": "the second call of the same YES quantity reverts and collateral does not fall twice",
            "kernels_agree": True,
            "distinct_from": "over_redeem of 10 after a partial redeem of 4",
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
        self.assertEqual(observed["before_first"]["collateral_locked"], "4")
        self.assertEqual(observed["before_first"]["yes_supply"], "4")
        self.assertEqual(observed["before_first"]["holder_yes"], "4")
        self.assertEqual(observed["before_first"]["no_supply"], "4")
        self.assertEqual(observed["first_payout"], "4")
        self.assertEqual(observed["after_first"]["collateral_locked"], "0")
        self.assertEqual(observed["after_first"]["yes_supply"], "0")
        self.assertEqual(observed["after_first"]["holder_yes"], "0")
        self.assertEqual(observed["after_first"]["no_supply"], "4")
        self.assertFalse(observed["second_paid"])
        self.assertEqual(observed["error"], "redeem exceeds balance")
        self.assertEqual(observed["after_second"], observed["after_first"])


if __name__ == "__main__":
    unittest.main()
