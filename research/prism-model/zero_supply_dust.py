"""Classify the existing zero-supply settlement residual.

This module does not add a sweep, a redemption rule, or a constructor change.
It does not edit the cumulative-floor payout or FixedPointSettlement.redeem.
"""

from __future__ import annotations

import inspect
import re
import time
from fractions import Fraction
from pathlib import Path
from typing import Any

import z3

from cumulative_settlement import (
    CumulativeFloorSettlement,
    ceil_funding,
    cumulative_delta,
    one_shot_floor,
    settlement_denominator,
)
from fixed_point import WAD
from fixed_point_model import FixedPointModelError, FixedPointSeries, FixedPointSettlement
from lifecycle import SeriesState
from model import ModelError, PrismSeries
from precision_boundary import DECIMALS, payouts_for


KERNEL_PATH = (
    Path(__file__).resolve().parents[1]
    / "contract-kernels"
    / "src"
    / "prism"
    / "CandidateCumulativeSettlement.sol"
)
EXACT_MATRIX = ((0, 1), (0, 0), (1, 1), (1, 0))
EXACT_WEIGHTS = (Fraction(3, 5), Fraction(2, 5))


def _public_methods(cls: type) -> list[str]:
    return sorted(
        name
        for name, value in inspect.getmembers(cls, predicate=inspect.isfunction)
        if not name.startswith("_")
    )


def _ceil_floor_gap_unsat() -> str:
    numerator, denominator = z3.Ints("n d")
    solver = z3.Solver()
    solver.add(numerator >= 0, denominator > 0)
    gap = (numerator + denominator - 1) / denominator - numerator / denominator
    solver.add(z3.Or(gap < 0, gap > 1))
    return str(solver.check())


def _reject_redeem(book: CumulativeFloorSettlement, holder: str) -> str:
    try:
        book.redeem(holder, 1)
    except FixedPointModelError as exc:
        return str(exc)
    return ""


def _post_zero_attempts(book: CumulativeFloorSettlement) -> dict[str, Any]:
    balance_before = book.balance_raw
    supply_before = book.supply_units
    paid_before = book.paid_raw
    make_error = ""
    try:
        book.make_redeemable()
    except FixedPointModelError as exc:
        make_error = str(exc)
    holders = list(book.balances) or ["A"]
    rejections = {holder: _reject_redeem(book, holder) for holder in holders}
    rejections["stranger"] = _reject_redeem(book, "stranger")
    return {
        "supply_before": supply_before,
        "balance_before": balance_before,
        "paid_before": paid_before,
        "make_redeemable_error": make_error,
        "redeem_errors": rejections,
        "supply_after": book.supply_units,
        "balance_after": book.balance_raw,
        "paid_after": book.paid_raw,
        "withdrew": book.balance_raw < balance_before,
        "state_unchanged": (
            book.balance_raw == balance_before
            and book.supply_units == supply_before
            and book.paid_raw == paid_before
        ),
    }


def _redeem_pair(book: CumulativeFloorSettlement) -> tuple[int, int]:
    first = book.redeem("A", 1)
    second = book.redeem("B", 1)
    return first, second


def _constructed_at_supply_zero() -> dict[str, Any]:
    cells = []
    for decimals in DECIMALS:
        for payout in payouts_for(decimals):
            funded = ceil_funding(0, payout, decimals)
            cumulative = CumulativeFloorSettlement(0, payout, decimals, funded, {})
            cumulative.make_redeemable()
            cumulative_error = _reject_redeem(cumulative, "A")
            canonical = FixedPointSettlement(0, payout, decimals, balance_raw=funded)
            canonical.make_redeemable()
            canonical_error = ""
            try:
                canonical.redeem(1)
            except FixedPointModelError as exc:
                canonical_error = str(exc)
            dust_read = canonical.sweepable_dust()
            cells.append(
                {
                    "decimals": decimals,
                    "payout_wad": payout,
                    "ceil_funding": funded,
                    "cumulative_rejected": cumulative_error == "unknown holder",
                    "cumulative_balance": cumulative.balance_raw,
                    "cumulative_paid": cumulative.paid_raw,
                    "cumulative_supply": cumulative.supply_units,
                    "canonical_rejected": canonical_error == "invalid settlement redemption quantity",
                    "canonical_balance": canonical.balance_raw,
                    "canonical_dust_read": dust_read,
                    "dust_read_left_balance": canonical.balance_raw == funded,
                }
            )
    intact = all(
        cell["ceil_funding"] == 0
        and cell["cumulative_rejected"]
        and cell["cumulative_balance"] == 0
        and cell["cumulative_paid"] == 0
        and cell["cumulative_supply"] == 0
        and cell["canonical_rejected"]
        and cell["canonical_balance"] == 0
        and cell["canonical_dust_read"] == 0
        and cell["dust_read_left_balance"]
        for cell in cells
    )
    return {
        "label": "constructed_at_supply_0",
        "python_cumulative": "object accepted; exact ceil funding is 0; one-unit redemption rejected; balance stays 0",
        "python_canonical_settlement": "object accepted; redeem(1) rejected; sweepable_dust() reads 0 and does not move the balance",
        "solidity_candidate": "constructor reverts ZeroSupply; the object is not created",
        "cell_count": len(cells),
        "all_cells_match": intact,
        "sample": cells[0],
        "residual": 0,
    }


def _after_full_redemption() -> dict[str, Any]:
    denominator = settlement_denominator(18)
    payout = WAD - 1
    required = ceil_funding(2, payout, 18)
    target = one_shot_floor(2, payout, 18)
    residual_one = CumulativeFloorSettlement(2, payout, 18, required, {"A": 1, "B": 1})
    residual_one.make_redeemable()
    first, second = _redeem_pair(residual_one)
    expected_first = cumulative_delta(0, 1, payout, 18)
    expected_second = cumulative_delta(1, 1, payout, 18)
    attempts = _post_zero_attempts(residual_one)

    residual_zero = CumulativeFloorSettlement(2, 0, 18, 0, {"A": 1, "B": 1})
    residual_zero.make_redeemable()
    zero_first, zero_second = _redeem_pair(residual_zero)
    zero_attempts = _post_zero_attempts(residual_zero)

    surplus = CumulativeFloorSettlement(2, payout, 18, required + 3, {"A": 1, "B": 1})
    surplus.make_redeemable()
    surplus_first, surplus_second = _redeem_pair(surplus)
    surplus_attempts = _post_zero_attempts(surplus)

    canonical = FixedPointSettlement(2, payout, 18, balance_raw=required)
    canonical.make_redeemable()
    canonical_first = canonical.redeem(1)
    canonical_second = canonical.redeem(1)
    canonical_dust = canonical.sweepable_dust()
    canonical_balance_after_read = canonical.balance_raw

    gap = (2 * payout + denominator - 1) // denominator - (2 * payout) // denominator
    exact_ceil = (
        residual_one.supply_units == 0
        and residual_one.balance_raw == gap
        and residual_one.paid_raw == target
        and first == expected_first
        and second == expected_second
        and gap in (0, 1)
        and attempts["state_unchanged"]
        and not attempts["withdrew"]
        and residual_zero.balance_raw == 0
        and zero_first == 0
        and zero_second == 0
        and zero_attempts["state_unchanged"]
        and surplus.balance_raw == required + 3 - target
        and surplus_first == first
        and surplus_second == second
        and surplus_attempts["state_unchanged"]
        and not surplus_attempts["withdrew"]
        and canonical.supply_units == 0
        and canonical_dust == canonical_balance_after_read
        and canonical_balance_after_read == required - canonical_first - canonical_second
    )
    return {
        "label": "supply_reaches_0_after_full_redemption",
        "exact_ceil_observed": exact_ceil,
        "candidate_residual_one": {
            "supply": 2,
            "payout_wad": payout,
            "decimals": 18,
            "funded": required,
            "first_payout": first,
            "second_payout": second,
            "paid_raw": residual_one.paid_raw,
            "one_shot_floor": target,
            "residual": residual_one.balance_raw,
            "gap": gap,
            "post_zero": attempts,
        },
        "candidate_residual_zero": {
            "payout_wad": 0,
            "funded": 0,
            "first_payout": zero_first,
            "second_payout": zero_second,
            "residual": residual_zero.balance_raw,
            "post_zero": zero_attempts,
        },
        "surplus_above_ceil": {
            "funded": required + 3,
            "paid_raw": surplus.paid_raw,
            "residual": surplus.balance_raw,
            "assumption": "outside exact ceil funding",
            "withdrawn": surplus_attempts["withdrew"],
        },
        "canonical_per_call_read": {
            "first_payout": canonical_first,
            "second_payout": canonical_second,
            "sweepable_dust_read": canonical_dust,
            "balance_after_read": canonical_balance_after_read,
            "read_moved_balance": canonical_balance_after_read != canonical_dust,
            "note": "CX-FP-SETTLEMENT-001 sitting balance. sweepable_dust reads it and does not transfer it",
        },
    }


def _one_unit_at_supply_zero() -> dict[str, Any]:
    constructed = CumulativeFloorSettlement(0, WAD - 1, 18, 0, {})
    constructed.make_redeemable()
    constructed_attempts = _post_zero_attempts(constructed)

    depleted = CumulativeFloorSettlement(2, WAD - 1, 18, 2, {"A": 1, "B": 1})
    depleted.make_redeemable()
    _redeem_pair(depleted)
    depleted_attempts = _post_zero_attempts(depleted)

    canonical = FixedPointSettlement(0, WAD - 1, 18, balance_raw=0)
    canonical.make_redeemable()
    canonical_error = ""
    try:
        canonical.redeem(1)
    except FixedPointModelError as exc:
        canonical_error = str(exc)
    dust_read = canonical.sweepable_dust()
    return {
        "label": "one_unit_redemption_at_supply_0",
        "constructed": constructed_attempts,
        "after_depletion": depleted_attempts,
        "canonical_error": canonical_error,
        "canonical_balance": canonical.balance_raw,
        "canonical_dust_read": dust_read,
        "rejected_and_unchanged": (
            constructed_attempts["state_unchanged"]
            and not constructed_attempts["withdrew"]
            and depleted_attempts["state_unchanged"]
            and not depleted_attempts["withdrew"]
            and canonical_error == "invalid settlement redemption quantity"
            and canonical.balance_raw == 0
            and dust_read == 0
        ),
    }


def _exact_series() -> dict[str, Any]:
    constructed = PrismSeries(
        EXACT_MATRIX,
        EXACT_WEIGHTS,
        state=SeriesState.RESOLVED,
        final_payout=Fraction(1),
        supply=Fraction(0),
        settlement_balance=Fraction(0),
    )
    constructed.make_redeemable()
    constructed_error = ""
    try:
        constructed.redeem_final(1)
    except ModelError as exc:
        constructed_error = str(exc)
    constructed_balance = constructed.settlement_balance
    constructed.archive()

    depleted = PrismSeries(
        EXACT_MATRIX,
        EXACT_WEIGHTS,
        state=SeriesState.REDEEMABLE,
        final_payout=Fraction(1),
        supply=Fraction(2),
        settlement_balance=Fraction(5),
    )
    paid = depleted.redeem_final(2)
    depleted_error = ""
    try:
        depleted.redeem_final(1)
    except ModelError as exc:
        depleted_error = str(exc)
    balance_before_archive = depleted.settlement_balance
    depleted.archive()
    return {
        "constructed_supply": 0,
        "constructed_redeem_error": constructed_error,
        "constructed_balance_before_archive": str(constructed_balance),
        "constructed_balance_after_archive": str(constructed.settlement_balance),
        "constructed_state": constructed.state.value,
        "full_redemption_paid": str(paid),
        "full_redemption_error": depleted_error,
        "full_redemption_balance_before_archive": str(balance_before_archive),
        "full_redemption_balance_after_archive": str(depleted.settlement_balance),
        "archive_moved_settlement_balance": (
            constructed.settlement_balance != constructed_balance
            or depleted.settlement_balance != balance_before_archive
        ),
    }


def _component_backing_sweep() -> dict[str, Any]:
    series = FixedPointSeries((WAD,), (18,), supply_units=0, backing_raw=[2])
    swept = series.sweep_dust()
    return {
        "class": "FixedPointSeries",
        "method": "sweep_dust",
        "returned": list(swept),
        "backing_after": list(series.backing_raw),
        "scope": "component backing_raw, not a settlement-token balance",
    }


def _solidity_inventory(source: str) -> dict[str, Any]:
    functions = re.findall(r"function\s+([A-Za-z0-9_]+)", source)
    transfer_lines = [line.strip() for line in source.splitlines() if "safeTransfer" in line]
    return {
        "functions": functions,
        "safe_transfer_lines": transfer_lines,
        "safe_transfer_count": len(transfer_lines),
        "sweep_function": any(name.lower().startswith("sweep") for name in functions),
        "reverts_zero_supply": "revert ZeroSupply();" in source,
        "redeem_transfers_only_nonzero_payout": "if (payout != 0)" in source,
    }


def discharge_zero_supply_dust() -> dict[str, Any]:
    """Observe the residual. Do not invent a withdrawal rule."""

    started = time.perf_counter()
    gap_unsat = _ceil_floor_gap_unsat()
    constructed = _constructed_at_supply_zero()
    redeemed = _after_full_redemption()
    one_unit = _one_unit_at_supply_zero()
    exact = _exact_series()
    component = _component_backing_sweep()
    source = KERNEL_PATH.read_text()
    solidity = _solidity_inventory(source)
    cumulative_methods = _public_methods(CumulativeFloorSettlement)
    canonical_methods = _public_methods(FixedPointSettlement)
    elapsed = time.perf_counter() - started

    residual_one = redeemed["candidate_residual_one"]["residual"]
    bound_holds = (
        gap_unsat == "unsat"
        and constructed["all_cells_match"]
        and constructed["cell_count"] == 24
        and redeemed["exact_ceil_observed"]
        and residual_one in (0, 1)
        and one_unit["rejected_and_unchanged"]
    )
    settlement_withdrew = (
        redeemed["candidate_residual_one"]["post_zero"]["withdrew"]
        or redeemed["candidate_residual_zero"]["post_zero"]["withdrew"]
        or redeemed["surplus_above_ceil"]["withdrawn"]
        or one_unit["constructed"]["withdrew"]
        or one_unit["after_depletion"]["withdrew"]
        or exact["archive_moved_settlement_balance"]
        or redeemed["canonical_per_call_read"]["read_moved_balance"]
    )
    extraction = None
    if settlement_withdrew or solidity["safe_transfer_count"] != 1 or solidity["sweep_function"]:
        extraction = {
            "settlement_withdrew": settlement_withdrew,
            "solidity": solidity,
            "candidate_residual": residual_one,
        }
    sweep_policy = "NOT_YET_VALIDATED" if extraction is None else "COUNTEREXAMPLE_FOUND"
    return {
        "id": "ZERO-SUPPLY-DUST",
        "statement": "Classify the existing zero-supply settlement residual. Do not add a sweep.",
        "checker": "z3_and_existing_settlement_functions",
        "z3_version": str(z3.get_version_string()),
        "ceil_floor_gap": gap_unsat,
        "residual_bound": "PROVEN_UNDER_ASSUMPTIONS" if bound_holds else "COUNTEREXAMPLE_FOUND",
        "residual_bound_statement": "Under exact ceil funding, ceil(supply*payout/D) - floor(supply*payout/D) is 0 or 1, and that gap is what remains after the cumulative floor is paid.",
        "sweep_policy": sweep_policy,
        "sweep_policy_statement": "No settlement function withdraws the residual. It sits in balance_raw or in the settlement-token balance.",
        "extraction_witness": extraction,
        "cases": {
            "constructed_at_supply_0": constructed,
            "supply_reaches_0_after_full_redemption": redeemed,
            "one_unit_redemption_at_supply_0": one_unit,
        },
        "exact_rational_series": exact,
        "component_backing_sweep": component,
        "cumulative_public_methods": cumulative_methods,
        "canonical_settlement_public_methods": canonical_methods,
        "solidity": solidity,
        "zero_supply_python_cells": constructed["cell_count"],
        "cx_fp_settlement_001": "COUNTEREXAMPLE_FOUND",
        "canonical_math1": "FAIL",
        "kernel_status": "differential_research_kernel",
        "assumptions": [
            "nonnegative integer supply and payout",
            "positive settlement denominator",
            "exact ceil funding for the 0-or-1 residual bound",
            "funding above the ceil is surplus and is outside that bound",
            "FixedPointSeries.sweep_dust moves component backing, not settlement balance",
            "the candidate constructor still reverts ZeroSupply",
        ],
        "runtime_seconds": round(elapsed, 6),
    }
