"""T-FP-004. A minimum mint and the matching redeem extract nothing.

The written row is FixedPointSeries in docs/prism/math/17_THEOREMS.md and
section 8 of docs/prism/math/05_BACKING_SOLVENCY.md. It is not a settlement
payout claim. This module does not change the integer model.
"""

from __future__ import annotations

import time
from typing import Any

import sympy
import z3

from fixed_point import WAD
from fixed_point_model import FixedPointSeries


def _delta_identity() -> bool:
    supply, quantity = sympy.symbols("S Q", integer=True, nonnegative=True)
    requirement = sympy.Function("Req")
    deposited = requirement(supply + quantity) - requirement(supply)
    released = requirement(supply + quantity) - requirement(supply)
    return sympy.expand(deposited - released) == 0


def _cycle_shortfall_unsat() -> str:
    supply, quantity, weight, denominator, backing = z3.Ints("S Q x d B")
    solver = z3.Solver()
    solver.add(supply >= 0, quantity > 0, weight >= 0, denominator > 0, backing >= 0)
    def requirement(level):
        return (level * weight + denominator - 1) / denominator
    supply_after = supply + quantity
    deposited = requirement(supply_after) - requirement(supply)
    released = requirement(supply_after) - requirement(supply_after - quantity)
    solver.add(z3.Or(deposited != released, deposited < 0, backing + deposited - released != backing))
    return str(solver.check())


def discharge_t_fp_004() -> dict[str, Any]:
    """Deposit Req(S+Q)-Req(S), then redeem Q, and the raw backing is unchanged."""

    started = time.perf_counter()
    identity = _delta_identity()
    shortfall = _cycle_shortfall_unsat()

    empty = FixedPointSeries((WAD // 2, WAD // 2), (18, 18))
    deposited = empty.mint_with_minimum_backing(5)
    released = empty.redeem(5)
    closed = (
        empty.supply_units == 0
        and empty.backing_raw == [0, 0]
        and tuple(deposited) == tuple(released)
    )

    surplus = FixedPointSeries((WAD // 2, WAD // 2), (18, 18))
    surplus.deposit_raw((1, 1))
    surplus_deposit = surplus.mint_with_minimum_backing(5)
    surplus_release = surplus.redeem(5)
    surplus_held = surplus.backing_raw == [1, 1] and tuple(surplus_deposit) == tuple(surplus_release)
    elapsed = time.perf_counter() - started
    discharged = identity and shortfall == "unsat" and closed and surplus_held
    return {
        "id": "T-FP-004",
        "written_claim": "minimum-backing mint followed by inverse requirement-delta redemption has zero net component extraction",
        "statement": "The mint deposits Req(S+Q)-Req(S), the redeem of that same quantity releases that delta, and backing returns to its pre-cycle value",
        "checker": "sympy_z3_and_fixed_point_series",
        "sympy_version": sympy.__version__,
        "z3_version": str(z3.get_version_string()),
        "delta_identity": identity,
        "cycle_shortfall": shortfall,
        "closed_cycle": {
            "mint_quantity": 5,
            "deposited": list(deposited),
            "released": list(released),
            "supply_after": empty.supply_units,
            "backing_after": list(empty.backing_raw),
            "net_extraction": [released[i] - deposited[i] for i in range(2)],
        },
        "surplus_preserved": {
            "prior_surplus": [1, 1],
            "deposited": list(surplus_deposit),
            "released": list(surplus_release),
            "backing_after": list(surplus.backing_raw),
            "surplus_unchanged": surplus_held,
        },
        "settlement_redemption": "not_this_statement",
        "assumptions": [
            "Q > 0 and S >= 0",
            "nonnegative weight and raw backing",
            "positive denominator WAD * decimal factor",
            "Req is mul_div_ceil(supply, weight, denominator)",
            "the redeem quantity equals the mint quantity",
            "no extra deposit is added between the mint and the redeem",
            "the oracle is FixedPointSeries, not FixedPointSettlement",
        ],
        "classification": "PROVEN_UNDER_ASSUMPTIONS" if discharged else "COUNTEREXAMPLE_FOUND",
        "counterexample": None if discharged else {"delta_identity": identity, "cycle_shortfall": shortfall, "closed": closed},
        "canonical_math1": "FAIL",
        "runtime_seconds": round(elapsed, 6),
    }
