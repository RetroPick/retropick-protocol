"""Python has no collateral withdrawal while supply is outstanding."""

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
    / "live-collateral-withdrawal-2026-09-26.json"
)


def python_witness() -> dict[str, object]:
    market = create_market(integer=True, collateral="COLL", dust_sink="SINK")
    activate_binary(market, market_id="m", resolver="resolver", spec_hash="h")
    market.split("alice", 4, 4)
    message = ""
    try:
        market.admin_withdraw(1)
    except PredictionError as exc:
        message = str(exc)
    return {
        "function": "admin_withdraw",
        "error": message,
        "collateral_locked": str(market.collateral_locked),
        "yes_supply": str(market.yes_supply),
        "no_supply": str(market.no_supply),
    }


class LiveCollateralWithdrawalTests(unittest.TestCase):
    def test_admin_withdraw_leaves_supply_and_collateral(self):
        observed = python_witness()
        prior: dict[str, object] = {}
        if EVIDENCE.exists():
            loaded = json.loads(EVIDENCE.read_text(encoding="utf-8"))
            if isinstance(loaded, dict) and "solidity" in loaded:
                prior["solidity"] = loaded["solidity"]
        report: dict[str, object] = {
            "id": "LIVE-COLLATERAL-WITHDRAWAL",
            "case": "privileged caller withdraws collateral while supply is outstanding",
            "classification": "existing_rule",
            "rule": "merge and redeem burn before transfer; archive and cancelDraft do not pay live supply; no withdraw function",
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
        self.assertEqual(observed["error"], "no admin withdrawal of collateral")
        self.assertEqual(observed["collateral_locked"], "4")
        self.assertEqual(observed["yes_supply"], "4")
        self.assertEqual(observed["no_supply"], "4")


if __name__ == "__main__":
    unittest.main()
