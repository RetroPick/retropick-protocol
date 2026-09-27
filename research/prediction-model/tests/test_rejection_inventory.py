"""Differential table of prediction calls that are expected to reject."""

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
    / "rejection-inventory-2026-09-26.json"
)

# One rejecting argument per remaining public call and state.
# Recorded pairs are omitted: draft split, second activate, split after close,
# merge after resolution, redeem while RESOLVED, second resolution, cancel from
# OPEN or REDEEMABLE, and the OPEN archive or redeem calls in the withdrawal log.
ROWS: tuple[tuple[str, str, str], ...] = (
    ("DRAFT", "merge", "1"),
    ("DRAFT", "close_mint", ""),
    ("DRAFT", "begin_resolution", ""),
    ("DRAFT", "resolve", "YES_WIN"),
    ("DRAFT", "open_redemption", ""),
    ("DRAFT", "redeem_yes", "1"),
    ("DRAFT", "redeem_no", "1"),
    ("DRAFT", "burn_yes", "1"),
    ("DRAFT", "burn_no", "1"),
    ("DRAFT", "archive", ""),
    ("OPEN", "split", "0"),
    ("OPEN", "merge", "0"),
    ("OPEN", "begin_resolution", ""),
    ("OPEN", "resolve", "YES_WIN"),
    ("OPEN", "open_redemption", ""),
    ("OPEN", "burn_yes", "1"),
    ("OPEN", "burn_no", "1"),
    ("LOCKED", "activate", ""),
    ("LOCKED", "cancel_draft", ""),
    ("LOCKED", "merge", "0"),
    ("LOCKED", "close_mint", ""),
    ("LOCKED", "resolve", "YES_WIN"),
    ("LOCKED", "open_redemption", ""),
    ("LOCKED", "redeem_yes", "1"),
    ("LOCKED", "redeem_no", "1"),
    ("LOCKED", "burn_yes", "1"),
    ("LOCKED", "burn_no", "1"),
    ("LOCKED", "archive", ""),
    ("RESOLUTION_PENDING", "activate", ""),
    ("RESOLUTION_PENDING", "cancel_draft", ""),
    ("RESOLUTION_PENDING", "split", "1"),
    ("RESOLUTION_PENDING", "merge", "1"),
    ("RESOLUTION_PENDING", "close_mint", ""),
    ("RESOLUTION_PENDING", "begin_resolution", ""),
    ("RESOLUTION_PENDING", "open_redemption", ""),
    ("RESOLUTION_PENDING", "redeem_yes", "1"),
    ("RESOLUTION_PENDING", "redeem_no", "1"),
    ("RESOLUTION_PENDING", "burn_yes", "1"),
    ("RESOLUTION_PENDING", "burn_no", "1"),
    ("RESOLUTION_PENDING", "archive", ""),
    ("RESOLVED", "activate", ""),
    ("RESOLVED", "cancel_draft", ""),
    ("RESOLVED", "split", "1"),
    ("RESOLVED", "close_mint", ""),
    ("RESOLVED", "begin_resolution", ""),
    ("RESOLVED", "burn_yes", "1"),
    ("RESOLVED", "burn_no", "1"),
    ("RESOLVED", "archive", ""),
    ("REDEEMABLE", "activate", ""),
    ("REDEEMABLE", "split", "1"),
    ("REDEEMABLE", "merge", "1"),
    ("REDEEMABLE", "close_mint", ""),
    ("REDEEMABLE", "begin_resolution", ""),
    ("REDEEMABLE", "resolve", "YES_WIN"),
    ("REDEEMABLE", "open_redemption", ""),
    ("REDEEMABLE", "redeem_yes", "0"),
    ("REDEEMABLE", "redeem_no", "0"),
    ("REDEEMABLE", "burn_yes", "1"),
    ("REDEEMABLE", "archive", ""),
    ("ARCHIVED", "activate", ""),
    ("ARCHIVED", "cancel_draft", ""),
    ("ARCHIVED", "split", "1"),
    ("ARCHIVED", "merge", "1"),
    ("ARCHIVED", "close_mint", ""),
    ("ARCHIVED", "begin_resolution", ""),
    ("ARCHIVED", "resolve", "YES_WIN"),
    ("ARCHIVED", "open_redemption", ""),
    ("ARCHIVED", "redeem_yes", "1"),
    ("ARCHIVED", "redeem_no", "1"),
    ("ARCHIVED", "burn_yes", "1"),
    ("ARCHIVED", "burn_no", "1"),
    ("ARCHIVED", "archive", ""),
)


def _fresh():
    return create_market(integer=True, collateral="COLL", dust_sink="SINK", max_amount=10**9)


def _at(state: str):
    market = _fresh()
    if state == "DRAFT":
        return market
    activate_binary(market, market_id="m", resolver="resolver", spec_hash="h")
    market.split("alice", 4, 4)
    if state == "OPEN":
        return market
    market.close_mint()
    if state == "LOCKED":
        return market
    market.begin_resolution()
    if state == "RESOLUTION_PENDING":
        return market
    market.resolve("resolver", ResolutionResult.YES_WIN)
    if state == "RESOLVED":
        return market
    market.open_redemption()
    if state == "REDEEMABLE":
        return market
    market.redeem("alice", Outcome.YES, 4)
    market.burn_worthless("alice", Outcome.NO, 4)
    market.archive()
    return market


def _books(market) -> tuple[str, str, str, str]:
    return (
        market.state.value,
        str(market.collateral_locked),
        str(market.yes_supply),
        str(market.no_supply),
    )


def _call(market, function: str, argument: str) -> None:
    if function == "activate":
        activate_binary(market, market_id="m", resolver="resolver", spec_hash="h")
        return
    if function == "cancel_draft":
        market.cancel_draft()
        return
    if function == "split":
        amount = int(argument)
        market.split("alice", amount, amount)
        return
    if function == "merge":
        market.merge("alice", int(argument))
        return
    if function == "close_mint":
        market.close_mint()
        return
    if function == "begin_resolution":
        market.begin_resolution()
        return
    if function == "resolve":
        market.resolve("resolver", ResolutionResult.YES_WIN)
        return
    if function == "open_redemption":
        market.open_redemption()
        return
    if function == "redeem_yes":
        market.redeem("alice", Outcome.YES, int(argument))
        return
    if function == "redeem_no":
        market.redeem("alice", Outcome.NO, int(argument))
        return
    if function == "burn_yes":
        market.burn_worthless("alice", Outcome.YES, int(argument))
        return
    if function == "burn_no":
        market.burn_worthless("alice", Outcome.NO, int(argument))
        return
    if function == "archive":
        market.archive()
        return
    raise AssertionError(function)


def python_rows() -> list[dict[str, str]]:
    measured: list[dict[str, str]] = []
    for state, function, argument in ROWS:
        market = _at(state)
        before = _books(market)
        error = ""
        try:
            _call(market, function, argument)
        except PredictionError as exc:
            error = str(exc)
        after = _books(market)
        measured.append(
            {
                "argument": argument,
                "collateral_after": after[1],
                "collateral_before": before[1],
                "function": function,
                "no_after": after[3],
                "no_before": before[3],
                "python_error": error,
                "state": state,
                "state_after": after[0],
                "state_before": before[0],
                "yes_after": after[2],
                "yes_before": before[2],
            }
        )
    return measured


def _classify_row(row: dict[str, str]) -> str:
    integers_same = (
        row["collateral_before"] == row["collateral_after"] == row["solidity_collateral_after"]
        and row["yes_before"] == row["yes_after"] == row["solidity_yes_after"]
        and row["no_before"] == row["no_after"] == row["solidity_no_after"]
        and row["collateral_before"] == row["solidity_collateral_before"]
        and row["yes_before"] == row["solidity_yes_before"]
        and row["no_before"] == row["solidity_no_before"]
    )
    python_rejects = row["python_error"] != ""
    solidity_rejects = row["solidity_error"] != ""
    if python_rejects and solidity_rejects and integers_same and row["state_after"] == row["solidity_state_after"]:
        return "existing_rule"
    return "recorded_contradiction"


class RejectionInventoryTests(unittest.TestCase):
    def test_rejection_inventory(self):
        observed = python_rows()
        self.assertEqual(len(observed), len(ROWS))
        prior_solidity: list[dict[str, str]] = []
        if EVIDENCE.exists():
            loaded = json.loads(EVIDENCE.read_text(encoding="utf-8"))
            if isinstance(loaded, dict) and isinstance(loaded.get("solidity_rows"), list):
                prior_solidity = loaded["solidity_rows"]
        rows: list[dict[str, str]] = []
        disagreeing: list[str] = []
        if len(prior_solidity) == len(observed):
            for item, solid in zip(observed, prior_solidity):
                merged = dict(item)
                merged.update(solid)
                kind = _classify_row(merged)
                merged["classification"] = kind
                if kind != "existing_rule":
                    disagreeing.append(f"{item['function']}|{item['state']}|{item['argument']}")
                rows.append(merged)
            classification = "existing_rule" if not disagreeing else "recorded_contradiction"
        else:
            rows = observed
            classification = "measured"
        report: dict[str, object] = {
            "id": "REJECTION-INVENTORY",
            "case": "rejection_inventory",
            "classification": classification,
            "row_count": len(rows),
            "disagreeing_rows": disagreeing,
            "kernels_agree": classification == "existing_rule",
            "theorem_pass": False,
            "math_1_progress": False,
            "canonical_math1": "FAIL",
            "pred_math_1": "partial",
            "pred_contract_1": "not_pass",
            "implementations_changed": False,
            "rows": rows,
        }
        if prior_solidity:
            report["solidity_rows"] = prior_solidity
        EVIDENCE.parent.mkdir(parents=True, exist_ok=True)
        EVIDENCE.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        self.assertTrue(all(row["python_error"] for row in observed))
        self.assertTrue(all(row["state_before"] == row["state"] for row in observed))
        if prior_solidity:
            self.assertEqual(disagreeing, ["archive|DRAFT|"])
            self.assertEqual(classification, "recorded_contradiction")


if __name__ == "__main__":
    unittest.main()
