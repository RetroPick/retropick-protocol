"""T-PARTIAL-002. Backing value is unchanged on the conditioned terminal states.

The written row is the boxed identity in docs/prism/math/05_BACKING_SOLVENCY.md
section 7. This module does not change partial_resolution.py.
"""

from __future__ import annotations

import time
from fractions import Fraction
from typing import Any

import sympy
import z3

from model import PrismSeries
from partial_resolution import mismatched_portfolio, portfolio_preserves, prospective_transform


def _replacement_gap(components: int, index: int) -> bool:
    backing = sympy.Matrix(components, 1, lambda i, _j: sympy.symbols(f"B{i}"))
    payoff = sympy.Matrix(components, 1, lambda i, _j: sympy.symbols(f"g{i}"))
    cash, payout = sympy.symbols("C r")
    old = cash + (backing.T * payoff)[0]
    replaced = sympy.Matrix(backing)
    replaced[index] = 0
    new = cash + backing[index] * payout + (replaced.T * payoff)[0]
    gap = sympy.expand(new - old - backing[index] * (payout - payoff[index]))
    on_remaining = sympy.expand((new - old).subs(payoff[index], payout))
    return gap == 0 and on_remaining == 0


def _value_iff_component_payoff() -> str:
    cash, balance, payoff, payout = z3.Reals("C B g r")
    old = cash + balance * payoff
    new = cash + balance * payout
    solver = z3.Solver()
    solver.add(z3.Xor(old == new, balance * payoff == balance * payout))
    return str(solver.check())


def _remaining_state_negation() -> str:
    cash, kept, resolved, kept_payoff, resolved_payoff, payout = z3.Reals("C K B gk g r")
    old = cash + kept * kept_payoff + resolved * resolved_payoff
    new = cash + kept * kept_payoff + resolved * payout
    solver = z3.Solver()
    solver.add(resolved_payoff == payout, old != new)
    return str(solver.check())


def discharge_t_partial_002() -> dict[str, Any]:
    """V'(omega) = V(omega) on states whose resolved component payoff equals r.

    On one state the two backing values are equal if and only if the cash
    credit equals that component's payoff contribution.
    """

    started = time.perf_counter()
    shapes = [
        (components, index)
        for components in range(1, 5)
        for index in range(components)
    ]
    failed = [shape for shape in shapes if not _replacement_gap(*shape)]
    iff_status = _value_iff_component_payoff()
    remaining_status = _remaining_state_negation()

    matrix = [[0, 1], [0, 0], [1, 1], [1, 0]]
    weights = [Fraction(3, 5), Fraction(2, 5)]
    series = PrismSeries(matrix, weights)
    series.activate()
    series.mint_with_exact_backing(1000)
    planned = prospective_transform(
        series.payoff_matrix,
        series.backing,
        series.transformed_settlement,
        series.possible_states,
        1,
        1,
        series.weights,
    )
    on_remaining = portfolio_preserves(
        series.payoff_matrix,
        series.backing,
        series.transformed_settlement,
        planned["backing"],
        planned["cash"],
        sorted(planned["remaining"]),
    )
    off_remaining = portfolio_preserves(
        series.payoff_matrix,
        series.backing,
        series.transformed_settlement,
        planned["backing"],
        planned["cash"],
        [1],
    )
    control = mismatched_portfolio(series, 1, 1)
    elapsed = time.perf_counter() - started
    discharged = (
        not failed
        and iff_status == "unsat"
        and remaining_status == "unsat"
        and on_remaining
        and not off_remaining
        and not control["equivalent"]
        and planned["cash_added"] == Fraction(400)
    )
    return {
        "id": "T-PARTIAL-002",
        "written_claim": "V'_B(omega)=V_B(omega) for every remaining state with g_i(omega)=r_i after replacing component i by cash B_i*r_i",
        "algebraic_iff": "on one state, old backing value equals new backing value iff B_i*g_i equals the cash credit B_i*r_i",
        "checker": "sympy_z3_and_partial_resolution",
        "sympy_version": sympy.__version__,
        "z3_version": str(z3.get_version_string()),
        "shapes": [list(shape) for shape in shapes],
        "failed_shapes": [list(shape) for shape in failed],
        "value_iff_component_payoff": iff_status,
        "remaining_state_negation": remaining_status,
        "model_check": {
            "cash_added": str(planned["cash_added"]),
            "remaining": sorted(planned["remaining"]),
            "preserves_remaining": on_remaining,
            "preserves_state_outside": off_remaining,
            "mismatched_portfolio_equivalent": control["equivalent"],
        },
        "assumptions": [
            "one resolved component is replaced by cash equal to balance times its payout",
            "other component balances and prior cash are unchanged",
            "a remaining state is one whose component payoff equals that payout",
            "partial_resolution.py is the executable model and is not modified",
        ],
        "classification": "PROVEN_UNDER_ASSUMPTIONS" if discharged else "COUNTEREXAMPLE_FOUND",
        "counterexample": None if discharged else {"failed_shapes": [list(shape) for shape in failed], "iff": iff_status, "remaining": remaining_status},
        "canonical_math1": "FAIL",
        "runtime_seconds": round(elapsed, 6),
    }
