"""Bounded 6/8/18 settlement precision matrix.

Checks the canonical per-call rule and the candidate cumulative floor on one
configured integer domain. It does not change either payout formula and it is
not a uint256 enumeration.
"""

from __future__ import annotations

import time
from typing import Any

from cumulative_settlement import (
    CumulativeFloorSettlement,
    ceil_funding,
    one_shot_floor,
)
from fixed_point import WAD
from fixed_point_model import (
    FixedPointModelError,
    FixedPointSettlement,
    decimal_factor,
    redemption_payout_raw_floor,
    required_settlement_raw,
)


DECIMALS = (6, 8, 18)
SUPPLIES = (0, 1, 2, 2**8, 2**16, 2**32, 2**64)
UINT256_MAX = 2**256 - 1


def denominator(decimals: int) -> int:
    return WAD * decimal_factor(decimals)


def payouts_for(decimals: int) -> tuple[int, ...]:
    scale = denominator(decimals)
    return (
        0,
        1,
        scale // 2,
        scale - 1,
        scale,
        scale + 1,
        2**128,
        UINT256_MAX,
    )


def _same_defect(supply: int, payout: int, paid: int, one_shot: int) -> bool:
    return supply >= 2 and paid < one_shot


def _per_call(supply: int, payout: int, decimals: int) -> dict[str, Any]:
    required = required_settlement_raw(supply, payout, decimals)
    one_shot = redemption_payout_raw_floor(supply, payout, decimals)
    book = FixedPointSettlement(supply, payout, decimals, balance_raw=required)
    book.make_redeemable()
    if supply == 0:
        supply_before = book.supply_units
        balance_before = book.balance_raw
        rejected = False
        try:
            book.redeem(1)
        except FixedPointModelError:
            rejected = True
        unchanged = book.supply_units == supply_before and book.balance_raw == balance_before
        dust = book.sweepable_dust()
        return {
            "kind": "zero-supply",
            "one_unit_rejected": rejected and unchanged,
            "dust": dust,
            "required": required,
            "funding_holds": dust == required == 0,
            "underpay": False,
            "overpay": False,
            "guard_rejected": False,
        }
    paid_one = book.redeem(1)
    expected_one = redemption_payout_raw_floor(1, payout, decimals)
    funding_holds = book.balance_raw >= book.required_balance_raw()
    if supply == 1:
        dust = book.sweepable_dust()
        return {
            "kind": "one-unit",
            "paid": paid_one,
            "expected_one": expected_one,
            "one_shot": one_shot,
            "dust": dust,
            "required": required,
            "funding_holds": funding_holds and book.supply_units == 0,
            "matches_floor": paid_one == expected_one == one_shot,
            "dust_bound": dust == required - paid_one and dust in (0, 1),
            "underpay": False,
            "overpay": paid_one > one_shot,
            "guard_rejected": False,
        }
    rest = supply - 1
    try:
        paid_rest = book.redeem(rest)
    except FixedPointModelError:
        return {
            "kind": "guard",
            "funding_holds": book.balance_raw >= book.required_balance_raw(),
            "underpay": False,
            "overpay": False,
            "guard_rejected": True,
            "paid_one": paid_one,
            "expected_one": expected_one,
        }
    paid = paid_one + paid_rest
    dust = book.sweepable_dust()
    return {
        "kind": "split",
        "paid": paid,
        "paid_one": paid_one,
        "expected_one": expected_one,
        "one_shot": one_shot,
        "dust": dust,
        "required": required,
        "funding_holds": funding_holds and book.supply_units == 0 and dust == required - paid,
        "matches_floor": paid_one == expected_one,
        "underpay": _same_defect(supply, payout, paid, one_shot),
        "overpay": paid > one_shot,
        "guard_rejected": False,
    }


def _cumulative(supply: int, payout: int, decimals: int) -> dict[str, Any]:
    funded = ceil_funding(supply, payout, decimals)
    target = one_shot_floor(supply, payout, decimals)
    if supply == 0:
        book = CumulativeFloorSettlement(0, payout, decimals, funded, {})
        book.make_redeemable()
        rejected = False
        try:
            book.redeem("A", 1)
        except FixedPointModelError:
            rejected = True
        return {
            "paid": book.paid_raw,
            "residual": book.balance_raw,
            "one_unit_rejected": rejected,
            "telescopes": book.paid_raw == 0 and book.balance_raw == funded == 0,
            "residual_bound": book.balance_raw in (0, 1),
        }
    balances = {"A": supply} if supply == 1 else {"A": 1, "B": supply - 1}
    book = CumulativeFloorSettlement(supply, payout, decimals, funded, balances)
    book.make_redeemable()
    book.redeem("A", 1 if supply > 1 else supply)
    if supply > 1:
        book.redeem("B", supply - 1)
    residual = book.balance_raw
    return {
        "paid": book.paid_raw,
        "residual": residual,
        "one_shot": target,
        "telescopes": book.paid_raw == target and book.supply_units == 0,
        "residual_bound": residual == funded - target and residual in (0, 1),
    }


def _canonical_shape(decimals: int) -> dict[str, Any]:
    scale = denominator(decimals)
    payout = scale - 1
    book = FixedPointSettlement(2, payout, decimals, balance_raw=2)
    book.make_redeemable()
    first = book.redeem(1)
    second = book.redeem(1)
    dust = book.sweepable_dust()
    one_shot = redemption_payout_raw_floor(2, payout, decimals)
    required = required_settlement_raw(2, payout, decimals)
    return {
        "id": "CX-FP-SETTLEMENT-001",
        "decimals": decimals,
        "denominator": str(scale),
        "supply": 2,
        "payout_wad": str(payout),
        "per_call_receipts": [first, second],
        "fragmented_paid_raw": first + second,
        "one_shot_floor_raw": one_shot,
        "required_raw": required,
        "sweepable_dust_raw": dust,
        "same_defect": first == 0 and second == 0 and one_shot == 1 and required == 2 and dust == 2,
        "new_rule": False,
    }


def discharge_precision_boundary() -> dict[str, Any]:
    """Walk the configured decimal and bound matrix once."""

    started = time.perf_counter()
    cells = 0
    per_call_failures: list[dict[str, Any]] = []
    cumulative_failures: list[dict[str, Any]] = []
    guard_rejections = 0
    same_defect_cells = 0
    minimized: dict[str, Any] | None = None
    zero_supply_cells = 0
    one_unit_cells = 0
    for decimals in DECIMALS:
        for supply in SUPPLIES:
            for payout in payouts_for(decimals):
                cells += 1
                per_call = _per_call(supply, payout, decimals)
                cumulative = _cumulative(supply, payout, decimals)
                if supply == 0:
                    zero_supply_cells += 1
                if supply == 1:
                    one_unit_cells += 1
                if per_call.get("guard_rejected"):
                    guard_rejections += 1
                if per_call.get("underpay"):
                    same_defect_cells += 1
                    witness = {
                        "decimals": decimals,
                        "supply": supply,
                        "payout_wad": str(payout),
                        "paid": per_call["paid"],
                        "one_shot": per_call["one_shot"],
                    }
                    if minimized is None or (supply, payout, decimals) < (
                        int(minimized["supply"]),
                        int(minimized["payout_wad"]),
                        int(minimized["decimals"]),
                    ):
                        minimized = witness
                broken = (
                    not per_call["funding_holds"]
                    or per_call["overpay"]
                    or (supply == 0 and not per_call["one_unit_rejected"])
                    or (supply == 1 and not (per_call["matches_floor"] and per_call["dust_bound"]))
                    or (
                        per_call["kind"] == "split"
                        and not per_call["matches_floor"]
                    )
                )
                if broken and len(per_call_failures) < 8:
                    per_call_failures.append(
                        {
                            "decimals": decimals,
                            "supply": supply,
                            "payout_wad": str(payout),
                            "result": {key: value for key, value in per_call.items() if key != "kind"},
                            "kind": per_call["kind"],
                        }
                    )
                cumulative_broken = not cumulative["telescopes"] or not cumulative["residual_bound"]
                if supply == 0:
                    cumulative_broken = cumulative_broken or not cumulative["one_unit_rejected"]
                if cumulative_broken and len(cumulative_failures) < 8:
                    cumulative_failures.append(
                        {
                            "decimals": decimals,
                            "supply": supply,
                            "payout_wad": str(payout),
                            "paid": str(cumulative["paid"]),
                            "residual": str(cumulative["residual"]),
                        }
                    )
    reproduced = [_canonical_shape(decimals) for decimals in DECIMALS]
    elapsed = time.perf_counter() - started
    new_counterexamples = per_call_failures + cumulative_failures
    reproduced_ok = all(row["same_defect"] for row in reproduced)
    clean = not new_counterexamples and reproduced_ok and zero_supply_cells == 24 and one_unit_cells == 24
    return {
        "id": "PRECISION-BOUNDARY-6-8-18",
        "written_scope": "6/8/18 decimal matrix and configured large bounds for both settlement rules",
        "domain": {
            "decimals": list(DECIMALS),
            "supplies": [str(supply) for supply in SUPPLIES],
            "payouts": "0, 1, D/2, D-1, D, D+1, 2^128, 2^256-1",
            "denominator": "D = 10^18 * 10^(18-decimals)",
            "uint256_max": str(UINT256_MAX),
            "full_uint256_enumeration": False,
        },
        "cells": cells,
        "zero_supply_cells": zero_supply_cells,
        "one_unit_cells": one_unit_cells,
        "same_defect_cells": same_defect_cells,
        "guard_rejections": guard_rejections,
        "minimized_same_defect": minimized,
        "reproduced_counterexample": reproduced,
        "new_counterexamples": new_counterexamples,
        "classification": "EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN" if clean else "COUNTEREXAMPLE_FOUND",
        "canonical_math1": "FAIL",
        "runtime_seconds": round(elapsed, 6),
    }
