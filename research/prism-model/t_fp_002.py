"""T-FP-002. Requirement-delta redemption keeps remaining supply backed.

The written row is FixedPointSeries.redeem in docs/prism/math/17_THEOREMS.md
and section 8 of docs/prism/math/05_BACKING_SOLVENCY.md. It is not a claim
about FixedPointSettlement.redeem. This module does not change the integer model.
"""

from __future__ import annotations

import time
from typing import Any

import sympy
import z3

from fixed_point import WAD
from fixed_point_model import FixedPointSeries


def _margin_identity() -> bool:
    backing, old_req, new_req = sympy.symbols("B R Rp", integer=True)
    release = old_req - new_req
    remaining = backing - release
    return sympy.expand(remaining - new_req - (backing - old_req)) == 0


def _remaining_shortfall_unsat() -> str:
    supply, quantity, weight, denominator, backing = z3.Ints("S Q x d B")
    solver = z3.Solver()
    solver.add(supply >= 0, quantity >= 0, quantity <= supply, weight >= 0, denominator > 0)
    old_numerator = supply * weight
    new_numerator = (supply - quantity) * weight
    old_req = (old_numerator + denominator - 1) / denominator
    new_req = (new_numerator + denominator - 1) / denominator
    solver.add(backing >= old_req)
    release = old_req - new_req
    solver.add(backing - release < new_req)
    return str(solver.check())


def discharge_t_fp_002() -> dict[str, Any]:
    """If B >= Req(S) and the release is Req(S)-Req(S-Q), then B' >= Req(S-Q)."""

    started = time.perf_counter()
    identity = _margin_identity()
    shortfall = _remaining_shortfall_unsat()

    series = FixedPointSeries((WAD // 2, WAD // 2), (18, 18))
    series.mint_with_minimum_backing(5)
    before_req = series.required_backing_raw()
    before_backing = tuple(series.backing_raw)
    released = series.redeem(2)
    after_req = series.required_backing_raw()
    after_backing = tuple(series.backing_raw)
    still_backed = all(after_backing[i] >= after_req[i] for i in range(2))
    margin_held = all(
        after_backing[i] - after_req[i] == before_backing[i] - before_req[i] for i in range(2)
    )
    elapsed = time.perf_counter() - started
    discharged = identity and shortfall == "unsat" and still_backed and margin_held and series.supply_units == 3
    return {
        "id": "T-FP-002",
        "written_claim": "requirement-delta redemption cannot leave remaining supply below the conservative raw requirement",
        "statement": "Release_i=Req_i(S)-Req_i(S-Q). If B_i>=Req_i(S), then B_i'>=Req_i(S-Q)",
        "checker": "sympy_z3_and_fixed_point_series",
        "sympy_version": sympy.__version__,
        "z3_version": str(z3.get_version_string()),
        "margin_identity": identity,
        "remaining_shortfall": shortfall,
        "model_check": {
            "supply_before": 5,
            "redeemed": 2,
            "supply_after": series.supply_units,
            "weights": [WAD // 2, WAD // 2],
            "decimals": [18, 18],
            "requirement_before": list(before_req),
            "backing_before": list(before_backing),
            "released": list(released),
            "requirement_after": list(after_req),
            "backing_after": list(after_backing),
            "still_backed": still_backed,
            "margin_unchanged": margin_held,
        },
        "settlement_redemption": "not_this_statement",
        "assumptions": [
            "0 <= Q <= S",
            "nonnegative weight and raw backing",
            "positive denominator WAD * decimal factor",
            "Req is mul_div_ceil(supply, weight, denominator)",
            "backing before redemption is at least Req(S)",
            "the oracle is FixedPointSeries.redeem, not FixedPointSettlement.redeem",
        ],
        "classification": "PROVEN_UNDER_ASSUMPTIONS" if discharged else "COUNTEREXAMPLE_FOUND",
        "counterexample": None if discharged else {"margin_identity": identity, "remaining_shortfall": shortfall, "still_backed": still_backed},
        "canonical_math1": "FAIL",
        "runtime_seconds": round(elapsed, 6),
    }
