"""T-BS-002. Exact in-kind redemption preserves remaining backing and margin.

The written row is section 3 of docs/prism/math/05_BACKING_SOLVENCY.md.
The bounded redeem grid is a finite check, not this identity. This module
does not change PrismSeries.
"""

from __future__ import annotations

import time
from fractions import Fraction
from typing import Any

import sympy
import z3

from model import PrismSeries


def _margin_identity() -> bool:
    backing, supply, quantity, weight = sympy.symbols("B S Q x")
    before = backing - supply * weight
    after = (backing - quantity * weight) - (supply - quantity) * weight
    return sympy.expand(after - before) == 0


def _shortfall_unsat() -> str:
    backing, supply, quantity, weight = z3.Reals("B S Q x")
    solver = z3.Solver()
    solver.add(quantity > 0, quantity <= supply, weight >= 0, backing >= supply * weight)
    solver.add(backing - quantity * weight < (supply - quantity) * weight)
    return str(solver.check())


def discharge_t_bs_002() -> dict[str, Any]:
    """B' = B - Qx and S' = S - Q leave M' = M and B' >= S'x."""

    started = time.perf_counter()
    identity = _margin_identity()
    shortfall = _shortfall_unsat()

    matrix = [[0, 1], [0, 0], [1, 1], [1, 0]]
    weights = [Fraction(3, 5), Fraction(2, 5)]
    series = PrismSeries(matrix, weights)
    series.activate()
    series.mint_with_exact_backing(1000)
    before = tuple(series.backing_margin())
    released = series.redeem_in_kind(250)
    after = tuple(series.backing_margin())

    surplus = PrismSeries(matrix, weights)
    surplus.activate()
    surplus.deposit_backing([1, 0])
    surplus.mint_with_exact_backing(5)
    surplus_before = tuple(surplus.backing_margin())
    surplus.redeem_in_kind(2)
    surplus_after = tuple(surplus.backing_margin())
    elapsed = time.perf_counter() - started
    exact_ok = (
        before == after == (Fraction(0), Fraction(0))
        and released == (Fraction(150), Fraction(100))
        and series.supply == 750
        and series.backing == [Fraction(450), Fraction(300)]
    )
    surplus_ok = surplus_before == surplus_after == (Fraction(1), Fraction(0))
    discharged = identity and shortfall == "unsat" and exact_ok and surplus_ok
    return {
        "id": "T-BS-002",
        "written_claim": "exact in-kind redemption preserves remaining backing",
        "statement": "If 0<Q<=S and B_i>=S*x_i, with S'=S-Q and B_i'=B_i-Q*x_i, then B_i'>=S'*x_i and the margin is unchanged",
        "checker": "sympy_z3_and_prism_series",
        "sympy_version": sympy.__version__,
        "z3_version": str(z3.get_version_string()),
        "margin_identity": identity,
        "backing_shortfall": shortfall,
        "exact_redeem": {
            "supply_before": 1000,
            "quantity": 250,
            "released": [str(value) for value in released],
            "margin_before": [str(value) for value in before],
            "margin_after": [str(value) for value in after],
            "backing_after": [str(value) for value in series.backing],
            "supply_after": str(series.supply),
        },
        "surplus_redeem": {
            "quantity": 2,
            "margin_before": [str(value) for value in surplus_before],
            "margin_after": [str(value) for value in surplus_after],
        },
        "assumptions": [
            "exact arithmetic",
            "0 < Q <= S",
            "nonnegative weight",
            "backing before redemption is at least S*x_i",
            "the redemption decreases supply by Q and backing by Q*x_i",
            "PrismSeries.redeem_in_kind is the executable model",
        ],
        "classification": "PROVEN_UNDER_ASSUMPTIONS" if discharged else "COUNTEREXAMPLE_FOUND",
        "counterexample": None if discharged else {"margin_identity": identity, "backing_shortfall": shortfall},
        "canonical_math1": "FAIL",
        "runtime_seconds": round(elapsed, 6),
    }
