"""Split of one unit past the configured maximum of 1000000000."""

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
    / "configured-split-maximum-2026-09-26.json"
)
MAXIMUM = 1000000000
ATTEMPTED = MAXIMUM + 1


def _books(market) -> dict[str, str]:
    return {
        "collateral_locked": str(market.collateral_locked),
        "no_supply": str(market.no_supply),
        "state": market.state.value,
        "yes_supply": str(market.yes_supply),
    }


def python_witness() -> dict[str, object]:
    market = create_market(integer=True, collateral="COLL", dust_sink="SINK", max_amount=MAXIMUM)
    activate_binary(market, market_id="m", resolver="resolver", spec_hash="h")
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
        "max_amount": str(MAXIMUM),
        "module": "research/prediction-model/market.py",
    }


class ConfiguredSplitMaximumTests(unittest.TestCase):
    def test_split_one_past_the_configured_maximum(self):
        observed = python_witness()
        prior: dict[str, object] = {}
        if EVIDENCE.exists():
            loaded = json.loads(EVIDENCE.read_text(encoding="utf-8"))
            if isinstance(loaded, dict) and "solidity" in loaded:
                prior["solidity"] = loaded["solidity"]
        rejected = (
            observed["error"] == "amount exceeds configured maximum"
            and observed["after"] == observed["before"]
            and observed["before"]["collateral_locked"] == "0"
            and observed["before"]["yes_supply"] == "0"
            and observed["before"]["no_supply"] == "0"
        )
        solidity = prior.get("solidity")
        solidity_minted = (
            isinstance(solidity, dict)
            and solidity.get("error") == ""
            and solidity.get("after", {}).get("collateral_locked") == str(ATTEMPTED)
            and solidity.get("after", {}).get("yes_supply") == str(ATTEMPTED)
            and solidity.get("after", {}).get("no_supply") == str(ATTEMPTED)
        )
        if rejected and solidity_minted:
            classification = "recorded_contradiction"
            kernels_agree = False
        elif rejected and solidity is None:
            classification = "measured"
            kernels_agree = False
        elif rejected and isinstance(solidity, dict) and solidity.get("error"):
            classification = "existing_rule"
            kernels_agree = True
        else:
            classification = "COUNTEREXAMPLE_FOUND"
            kernels_agree = False
        report: dict[str, object] = {
            "id": "CONFIGURED-SPLIT-MAXIMUM",
            "case": "split(1000000001)",
            "classification": classification,
            "rule": "Python with max_amount 1000000000 rejects split(1000000001). Solidity has no such cap.",
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
        self.assertEqual(observed["before"]["state"], "OPEN")
        if solidity is not None:
            self.assertEqual(classification, "recorded_contradiction")
            self.assertFalse(kernels_agree)
            self.assertEqual(solidity["before"]["collateral_locked"], "0")
            self.assertEqual(solidity["before"]["yes_supply"], "0")
            self.assertEqual(solidity["before"]["no_supply"], "0")


if __name__ == "__main__":
    unittest.main()
