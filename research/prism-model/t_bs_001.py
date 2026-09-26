"""T-BS-001. An exact-backed mint preserves component backing and margin.

The written row is section 2 of docs/prism/math/05_BACKING_SOLVENCY.md.
The bounded mint grid is a finite check, not this identity. This module does
not change PrismSeries.
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
    after = (backing + quantity * weight) - (supply + quantity) * weight
    return sympy.expand(after - before) == 0


def _shortfall_unsat() -> str:
    backing, supply, quantity, weight = z3.Reals("B S Q x")
    solver = z3.Solver()
    solver.add(quantity > 0, backing >= supply * weight)
    solver.add(backing + quantity * weight < (supply + quantity) * weight)
    return str(solver.check())


def _margins(series: PrismSeries) -> tuple[Fraction, ...]:
    return tuple(series.backing_margin())


def discharge_t_bs_001() -> dict[str, Any]:
    """B' = B + Qx and S' = S + Q leave M' = M and B' >= S'x."""

    started = time.perf_counter()
    identity = _margin_identity()
    shortfall = _shortfall_unsat()

    matrix = [[0, 1], [0, 0], [1, 1], [1, 0]]
    weights = [Fraction(3, 5), Fraction(2, 5)]
    fresh = PrismSeries(matrix, weights)
    fresh.activate()
    before_fresh = _margins(fresh)
    fresh.mint_with_exact_backing(1000)
    after_fresh = _margins(fresh)

    surplus = PrismSeries(matrix, weights)
    surplus.activate()
    surplus.deposit_backing([1, 0])
    before_surplus = _margins(surplus)
    surplus.mint_with_exact_backing(5)
    after_surplus = _margins(surplus)
    elapsed = time.perf_counter() - started
    fresh_ok = before_fresh == after_fresh == (Fraction(0), Fraction(0)) and fresh.backing == [Fraction(600), Fraction(400)]
    surplus_ok = before_surplus == after_surplus == (Fraction(1), Fraction(0))
    discharged = identity and shortfall == "unsat" and fresh_ok and surplus_ok and fresh.supply == 1000
    return {
        "id": "T-BS-001",
        "written_claim": "exact-backed mint preserves component backing and margin",
        "statement": "If B_i >= S*x_i, S' = S+Q, and B_i' = B_i+Q*x_i, then B_i' >= S'*x_i and the margin is unchanged",
        "checker": "sympy_z3_and_prism_series",
        "sympy_version": sympy.__version__,
        "z3_version": str(z3.get_version_string()),
        "margin_identity": identity,
        "backing_shortfall": shortfall,
        "exact_mint": {
            "quantity": 1000,
            "margin_before": [str(value) for value in before_fresh],
            "margin_after": [str(value) for value in after_fresh],
            "backing_after": [str(value) for value in fresh.backing],
            "supply_after": str(fresh.supply),
        },
        "surplus_mint": {
            "quantity": 5,
            "margin_before": [str(value) for value in before_surplus],
            "margin_after": [str(value) for value in after_surplus],
        },
        "assumptions": [
            "exact arithmetic",
            "Q > 0",
            "backing before the mint is at least S*x_i",
            "the mint deposits exactly Q*x_i and then increases supply by Q",
            "one component; other components are independent",
            "PrismSeries.mint_with_exact_backing is the executable model",
        ],
        "classification": "PROVEN_UNDER_ASSUMPTIONS" if discharged else "COUNTEREXAMPLE_FOUND",
        "counterexample": None if discharged else {"margin_identity": identity, "backing_shortfall": shortfall},
        "canonical_math1": "FAIL",
        "runtime_seconds": round(elapsed, 6),
    }
