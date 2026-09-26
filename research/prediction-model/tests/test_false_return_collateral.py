"""False-return collateral is rejected at construction in the reference model."""

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from domain import CollateralClass, PredictionError  # noqa: E402
from market import create_market  # noqa: E402


EVIDENCE = (
    Path(__file__).resolve().parents[3]
    / "evidence"
    / "research"
    / "prediction"
    / "false-return-collateral-2026-09-26.json"
)


def python_witness() -> dict[str, object]:
    created = False
    message = ""
    try:
        create_market(
            integer=True,
            collateral="FALSE",
            dust_sink="SINK",
            collateral_class=CollateralClass.FALSE_RETURN,
        )
        created = True
    except PredictionError as exc:
        message = str(exc)
    return {
        "created": created,
        "error": message,
        "function": "create_market",
        "collateral_class": CollateralClass.FALSE_RETURN.value,
        "module": "research/prediction-model/market.py",
        "transfer_invoked": False,
    }


class FalseReturnCollateralTests(unittest.TestCase):
    def test_false_return_class_is_rejected_at_construction(self):
        observed = python_witness()
        prior: dict[str, object] = {}
        if EVIDENCE.exists():
            loaded = json.loads(EVIDENCE.read_text(encoding="utf-8"))
            if isinstance(loaded, dict) and "solidity" in loaded:
                prior["solidity"] = loaded["solidity"]
        report: dict[str, object] = {
            "id": "FALSE-RETURN-COLLATERAL",
            "case": "collateral token whose transfer returns false",
            "classification": "recorded_contradiction",
            "contradiction_open": True,
            "theorem_pass": False,
            "math_1_progress": False,
            "canonical_math1": "FAIL",
            "pred_math_1": "partial",
            "pred_contract_1": "not_pass",
            "implementations_changed": False,
            "disagreement": (
                "Python rejects FALSE_RETURN at construction and does not call transfer. "
                "Solidity constructs and activates the market. split calls transferFrom, "
                "which returns false, and SafeERC20 reverts. Supplies stay 0. "
                "The rejection points differ."
            ),
            "python": observed,
        }
        if prior:
            report["solidity"] = prior["solidity"]
        EVIDENCE.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        self.assertFalse(observed["created"])
        self.assertEqual(
            observed["error"],
            "Phase-1 admits only standard ERC-20 collateral, got FALSE_RETURN",
        )
        self.assertFalse(observed["transfer_invoked"])


if __name__ == "__main__":
    unittest.main()
