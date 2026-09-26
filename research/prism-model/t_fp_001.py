"""T-FP-001. Ceil total-supply backing prevents an underreserved mint.

The written row is the component-mint claim in docs/prism/math/17_THEOREMS.md
and section 8 of docs/prism/math/05_BACKING_SOLVENCY.md. It is not a claim
about settlement redemption. This module does not change the integer model.
"""

from __future__ import annotations

import time
from typing import Any

import z3

from fixed_point import WAD
from fixed_point_model import (
    FixedPointModelError,
    FixedPointSeries,
    decimal_factor,
    required_component_raw,
)


def _ceil_shortfall_unsat() -> str:
    numerator, denominator = z3.Ints("n d")
    solver = z3.Solver()
    solver.add(numerator >= 0, denominator > 0)
    requirement = (numerator + denominator - 1) / denominator
    solver.add(requirement * denominator < numerator)
    return str(solver.check())


def _backed_raw_shortfall_unsat() -> str:
    backing, factor, wad, numerator = z3.Ints("B f W n")
    solver = z3.Solver()
    solver.add(backing >= 0, factor > 0, wad > 0, numerator >= 0)
    denominator = wad * factor
    requirement = (numerator + denominator - 1) / denominator
    solver.add(backing >= requirement)
    solver.add(backing * factor * wad < numerator)
    return str(solver.check())


def _snapshot(series: FixedPointSeries) -> tuple[int, tuple[int, ...]]:
    return series.supply_units, tuple(series.backing_raw)


def discharge_t_fp_001() -> dict[str, Any]:
    """Req_i(S) = ceil(S*x_i/(WAD*f_i)) covers S*x_i/WAD after normalization.

    A mint below that raw requirement is rejected and leaves the series unchanged.
    """

    started = time.perf_counter()
    ceil_status = _ceil_shortfall_unsat()
    backed_status = _backed_raw_shortfall_unsat()

    floor_raw = (1 * 1) // (WAD * decimal_factor(18))
    ceil_raw = required_component_raw(1, 1, 18)
    floor_covers = floor_raw * decimal_factor(18) * WAD >= 1
    ceil_covers = ceil_raw * decimal_factor(18) * WAD >= 1

    rejected = FixedPointSeries((1, 1), (18, 18))
    rejected.deposit_raw((1, 0))
    before = _snapshot(rejected)
    mint_rejected = False
    try:
        rejected.mint(1)
    except FixedPointModelError:
        mint_rejected = True
    after = _snapshot(rejected)

    accepted = FixedPointSeries((1, 1), (18, 18))
    accepted.deposit_raw((ceil_raw, ceil_raw))
    accepted.mint(1)
    accepted_covers = all(
        accepted.backing_raw[i] * decimal_factor(18) * WAD >= accepted.supply_units * accepted.weights_wad[i]
        for i in range(2)
    )
    accepted_matches_requirement = accepted.backing_raw == list(accepted.required_backing_raw())
    elapsed = time.perf_counter() - started
    discharged = (
        ceil_status == "unsat"
        and backed_status == "unsat"
        and mint_rejected
        and before == after
        and accepted_covers
        and accepted_matches_requirement
        and ceil_covers
        and not floor_covers
    )
    return {
        "id": "T-FP-001",
        "written_claim": "ceil total-supply component requirement prevents integer mint underreservation",
        "statement": "A mint is accepted only when raw backing is at least Req_i(S+Q)=ceil((S+Q)*x_i/(WAD*f_i)) for every component, and that raw amount normalizes to at least (S+Q)*x_i/WAD",
        "checker": "z3_and_fixed_point_series",
        "z3_version": str(z3.get_version_string()),
        "ceil_shortfall": ceil_status,
        "backed_raw_shortfall": backed_status,
        "floor_control": {
            "supply": 1,
            "weight": 1,
            "decimals": 18,
            "floor_raw": floor_raw,
            "ceil_raw": ceil_raw,
            "floor_covers_exact": floor_covers,
            "ceil_covers_exact": ceil_covers,
        },
        "rejected_mint": {
            "rejected": mint_rejected,
            "unchanged": before == after,
            "supply": after[0],
            "backing": list(after[1]),
        },
        "accepted_mint": {
            "supply": accepted.supply_units,
            "backing": list(accepted.backing_raw),
            "covers_exact": accepted_covers,
            "equals_requirement": accepted_matches_requirement,
        },
        "settlement_redemption": "not_this_statement",
        "assumptions": [
            "nonnegative supply, weight, and raw backing",
            "positive WAD and decimal factor",
            "requirement is mul_div_ceil(supply, weight, WAD * factor)",
            "normalized units are raw times the decimal factor",
            "the claim is component mint backing, not settlement payout",
        ],
        "classification": "PROVEN_UNDER_ASSUMPTIONS" if discharged else "COUNTEREXAMPLE_FOUND",
        "counterexample": None if discharged else {"ceil_shortfall": ceil_status, "backed_raw_shortfall": backed_status, "floor_covers_exact": floor_covers},
        "canonical_math1": "FAIL",
        "runtime_seconds": round(elapsed, 6),
    }
