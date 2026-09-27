"""T-BS-003. Component backing implies terminal solvency for every finite basket.

math1_probe.py discharges one state and two components only. The written
statement in docs/prism/math/05_BACKING_SOLVENCY.md sums over every component.
This module does not change that probe or PrismSeries.
"""

from __future__ import annotations

import time
from fractions import Fraction
from typing import Any

import sympy
import z3

from model import PrismSeries


def _gap_is_margin_dot_payoff() -> bool:
    index = sympy.symbols("i", integer=True, positive=True)
    count = sympy.symbols("n", integer=True, positive=True)
    supply = sympy.symbols("S")
    backing, weight, payoff = sympy.Function("B"), sympy.Function("x"), sympy.Function("g")
    value = sympy.Sum(backing(index) * payoff(index), (index, 1, count))
    liability = supply * sympy.Sum(weight(index) * payoff(index), (index, 1, count))
    margin_sum = sympy.Sum((backing(index) - supply * weight(index)) * payoff(index), (index, 1, count))
    return sympy.simplify(value - liability - margin_sum) == 0


def _inductive_step_unsat() -> str:
    partial, margin, payoff = z3.Reals("P M g")
    solver = z3.Solver()
    solver.add(partial >= 0, margin >= 0, payoff >= 0)
    solver.add(partial + margin * payoff < 0)
    return str(solver.check())


def _negative_payoff_breaks() -> bool:
    solver = z3.Solver()
    margin, payoff = z3.Reals("M g")
    solver.add(margin > 0, payoff < 0)
    solver.add(margin * payoff < 0)
    return solver.check() == z3.sat


def discharge_t_bs_003() -> dict[str, Any]:
    """V(omega) - L(omega) is the sum of nonnegative margin-payoff products."""

    started = time.perf_counter()
    identity = _gap_is_margin_dot_payoff()
    step = _inductive_step_unsat()
    negative_breaks = _negative_payoff_breaks()

    matrix = [[1, 0, 0], [0, 1, 1], [1, 1, 0], [0, 0, 1]]
    weights = [Fraction(1, 2), Fraction(1, 4), Fraction(1, 4)]
    series = PrismSeries(matrix, weights)
    series.activate()
    series.mint_with_exact_backing(4)
    solvency = series.terminal_solvency()
    all_solvent = all(backed for _state, _value, _liability, backed in solvency)
    elapsed = time.perf_counter() - started
    discharged = identity and step == "unsat" and all_solvent and len(weights) == 3
    return {
        "id": "T-BS-003",
        "written_claim": "exact non-negative replication plus component backing implies terminal solvency",
        "statement": "If B_i >= S*x_i and g_i(omega) >= 0, then sum_i B_i*g_i(omega) >= S*sum_i x_i*g_i(omega) for every finite component count and every terminal state",
        "prior_probe": "math1_probe.z3_reports two components and one state only",
        "checker": "sympy_z3_and_prism_series",
        "sympy_version": sympy.__version__,
        "z3_version": str(z3.get_version_string()),
        "component_counts": "every finite n >= 1",
        "gap_is_margin_dot_payoff": identity,
        "inductive_step": step,
        "negative_payoff_outside_assumption": {
            "breaks_inequality": negative_breaks,
            "supply": 1,
            "weight": 1,
            "backing": 2,
            "payoff": -1,
            "backing_value": -2,
            "liability": -1,
        },
        "model_check": {
            "components": 3,
            "states": len(matrix),
            "supply": str(series.supply),
            "all_solvent": all_solvent,
            "rows": [
                {
                    "state": state,
                    "backing_value": str(value),
                    "liability": str(liability),
                    "solvent": backed,
                }
                for state, value, liability, backed in solvency
            ],
        },
        "assumptions": [
            "finite component count",
            "exact arithmetic",
            "B_i >= S*x_i for every component",
            "g_i(omega) >= 0 for every component and terminal state",
            "h(omega) is the state-wise sum of x_i*g_i(omega)",
            "the two-component probe is not re-run and is not this general sum",
        ],
        "classification": "PROVEN_UNDER_ASSUMPTIONS" if discharged else "COUNTEREXAMPLE_FOUND",
        "counterexample": None if discharged else {"identity": identity, "inductive_step": step, "all_solvent": all_solvent},
        "canonical_math1": "FAIL",
        "runtime_seconds": round(elapsed, 6),
    }
