"""A second result after the first YES resolution."""

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from domain import PredictionError, ResolutionResult  # noqa: E402
from market import activate_binary, create_market  # noqa: E402
from resolution import payout_numerators  # noqa: E402


EVIDENCE = (
    Path(__file__).resolve().parents[3]
    / "evidence"
    / "research"
    / "prediction"
    / "second-yes-resolution-2026-09-26.json"
)
QUANTITY = 4


def _books(market) -> dict[str, str]:
    yes_num, no_num = payout_numerators(market.result)
    return {
        "collateral_locked": str(market.collateral_locked),
        "no_numerator": str(no_num),
        "no_supply": str(market.no_supply),
        "result": market.result.value,
        "state": market.state.value,
        "yes_numerator": str(yes_num),
        "yes_supply": str(market.yes_supply),
    }


def python_witness() -> dict[str, object]:
    market = create_market(integer=True, collateral="COLL", dust_sink="SINK")
    activate_binary(market, market_id="m", resolver="resolver", spec_hash="h")
    market.split("alice", QUANTITY, QUANTITY)
    market.close_mint()
    market.begin_resolution()
    market.resolve("resolver", ResolutionResult.YES_WIN)
    before = _books(market)
    second_error = ""
    changed = False
    try:
        market.resolve("resolver", ResolutionResult.NO_WIN)
        changed = True
    except PredictionError as exc:
        second_error = str(exc)
    after = _books(market)
    return {
        "after_second": after,
        "before_second": before,
        "changed": changed,
        "error": second_error,
        "first_result": ResolutionResult.YES_WIN.value,
        "function": "PredictionMarket.resolve",
        "module": "research/prediction-model/market.py",
        "quantity": str(QUANTITY),
        "second_result": ResolutionResult.NO_WIN.value,
    }


class SecondYesResolutionTests(unittest.TestCase):
    def test_second_result_leaves_the_yes_payout_vector(self):
        observed = python_witness()
        prior: dict[str, object] = {}
        if EVIDENCE.exists():
            loaded = json.loads(EVIDENCE.read_text(encoding="utf-8"))
            if isinstance(loaded, dict) and "solidity" in loaded:
                prior["solidity"] = loaded["solidity"]
        report: dict[str, object] = {
            "id": "SECOND-YES-RESOLUTION",
            "case": "resolver commits a second different result after the first YES resolution",
            "classification": "existing_rule",
            "rule": "the second resolve reverts and the payout vector stays YES_WIN numerators 2 and 0",
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
        self.assertEqual(observed["before_second"]["result"], "YES_WIN")
        self.assertEqual(observed["before_second"]["yes_numerator"], "2")
        self.assertEqual(observed["before_second"]["no_numerator"], "0")
        self.assertEqual(observed["before_second"]["collateral_locked"], "4")
        self.assertEqual(observed["before_second"]["yes_supply"], "4")
        self.assertEqual(observed["before_second"]["no_supply"], "4")
        self.assertFalse(observed["changed"])
        self.assertEqual(observed["error"], "illegal transition RESOLVED -> RESOLVED")
        self.assertEqual(observed["after_second"], observed["before_second"])


if __name__ == "__main__":
    unittest.main()
