"""Split at the uint256 boundary."""

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from domain import PredictionError  # noqa: E402
from market import UINT256_MAX, activate_binary, create_market  # noqa: E402


EVIDENCE = (
    Path(__file__).resolve().parents[3]
    / "evidence"
    / "research"
    / "prediction"
    / "uint256-split-2026-09-26.json"
)


def _books(market) -> dict[str, str]:
    return {
        "collateral_locked": str(market.collateral_locked),
        "no_supply": str(market.no_supply),
        "state": market.state.value,
        "yes_supply": str(market.yes_supply),
    }


def python_witness() -> dict[str, object]:
    market = create_market(integer=True, collateral="COLL", dust_sink="SINK")
    activate_binary(market, market_id="m", resolver="resolver", spec_hash="h")
    before = _books(market)
    max_error = ""
    try:
        market.split("alice", UINT256_MAX, UINT256_MAX)
    except PredictionError as exc:
        max_error = str(exc)
    after_max = _books(market)
    second_error = ""
    try:
        market.split("alice", 1, 1)
    except PredictionError as exc:
        second_error = str(exc)
    after_second = _books(market)
    return {
        "after_max": after_max,
        "after_second": after_second,
        "before": before,
        "can_represent_uint256_max": True,
        "function": "PredictionMarket.split",
        "max_amount": str(UINT256_MAX),
        "max_error": max_error,
        "module": "research/prediction-model/market.py",
        "second_amount": "1",
        "second_error": second_error,
        "second_supply": str(UINT256_MAX + 1),
    }


class Uint256SplitTests(unittest.TestCase):
    def test_split_at_uint256_boundary(self):
        observed = python_witness()
        prior: dict[str, object] = {}
        if EVIDENCE.exists():
            loaded = json.loads(EVIDENCE.read_text(encoding="utf-8"))
            if isinstance(loaded, dict) and "solidity" in loaded:
                prior["solidity"] = loaded["solidity"]
        max_supply = str(UINT256_MAX)
        above = str(UINT256_MAX + 1)
        python_grew = (
            observed["max_error"] == ""
            and observed["second_error"] == ""
            and observed["after_max"]["collateral_locked"] == max_supply
            and observed["after_max"]["yes_supply"] == max_supply
            and observed["after_max"]["no_supply"] == max_supply
            and observed["after_second"]["collateral_locked"] == above
            and observed["after_second"]["yes_supply"] == above
            and observed["after_second"]["no_supply"] == above
        )
        solidity = prior.get("solidity")
        solidity_held = isinstance(solidity, dict) and solidity.get("second_reverted") is True and solidity.get(
            "wrapped"
        ) is False
        if solidity_held and python_grew:
            classification = "recorded_contradiction"
            kernels_agree = False
        elif solidity_held and not python_grew:
            classification = "existing_rule"
            kernels_agree = True
        else:
            classification = "measured"
            kernels_agree = solidity_held and python_grew
        report: dict[str, object] = {
            "id": "UINT256-SPLIT",
            "case": "split at the uint256 boundary",
            "classification": classification,
            "rule": "Solidity split of the maximum succeeds and a further split(1) reverts without wrapping supply. Python accepts the further split and the supply becomes 2**256.",
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
        self.assertEqual(observed["before"]["collateral_locked"], "0")
        self.assertEqual(observed["before"]["yes_supply"], "0")
        self.assertEqual(observed["before"]["no_supply"], "0")
        self.assertEqual(observed["before"]["state"], "OPEN")
        self.assertEqual(observed["max_error"], "")
        self.assertEqual(observed["after_max"]["collateral_locked"], max_supply)
        self.assertEqual(observed["after_max"]["yes_supply"], max_supply)
        self.assertEqual(observed["after_max"]["no_supply"], max_supply)
        self.assertEqual(observed["second_error"], "")
        self.assertEqual(observed["after_second"]["collateral_locked"], above)
        self.assertEqual(observed["after_second"]["yes_supply"], above)
        self.assertEqual(observed["after_second"]["no_supply"], above)
        self.assertGreater(int(observed["after_second"]["yes_supply"]), int(observed["after_max"]["yes_supply"]))
        if solidity is not None:
            self.assertEqual(classification, "recorded_contradiction")
            self.assertFalse(kernels_agree)
            self.assertEqual(solidity["after_second"]["yes_supply"], max_supply)
            self.assertEqual(solidity["after_second"]["no_supply"], max_supply)
            self.assertEqual(solidity["after_second"]["collateral_locked"], max_supply)
            self.assertEqual(solidity["error"], "Panic(0x11)")


if __name__ == "__main__":
    unittest.main()
