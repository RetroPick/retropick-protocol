"""Machine check that a global cursor telescopes, and a per-holder cursor does not.

The discharged identity is: for paid(R) = floor(R * payout / D), any composition
of one global cursor sums to paid(supply) - paid(0). paid(0) = 0, so the sum is
floor(supply * payout / D).

The proof is the inductive cancellation of one cursor. It is not a proof of the
canonical per-call rule. Canonical MATH-1 stays FAIL. This file does not change
cumulative_settlement.py.
"""

from __future__ import annotations

import time
from typing import Any

from cumulative_settlement import cumulative_delta, one_shot_floor, per_holder_cursor_total
from fixed_point import WAD


def sympy_global_cursor() -> dict[str, str]:
    import sympy

    paid = sympy.Function("paid")
    cursor, chunk = sympy.symbols("cursor chunk")
    inductive = sympy.simplify(
        (paid(cursor) - paid(0)) + (paid(cursor + chunk) - paid(cursor)) - (paid(cursor + chunk) - paid(0))
    )
    parts = sympy.symbols("q1:6")
    running = 0
    total = 0
    for part in parts:
        nxt = running + part
        total += paid(nxt) - paid(running)
        running = nxt
    explicit = sympy.simplify(total - (paid(running) - paid(0)))
    payout, denominator, supply = sympy.symbols("payout denominator supply", integer=True, nonnegative=True)
    floor_at_zero = sympy.floor(sympy.Integer(0) * payout / denominator)
    holds = inductive == 0 and explicit == 0 and floor_at_zero == 0
    return {
        "sympy_version": sympy.__version__,
        "inductive_step_cancels": str(inductive == 0),
        "five_part_composition_cancels": str(explicit == 0),
        "floor_of_zero_is_zero": str(floor_at_zero == 0),
        "classification": "PROVEN_UNDER_ASSUMPTIONS" if holds else "COUNTEREXAMPLE_FOUND",
        "assumptions": "one global cursor; paid(R)=floor(R*payout/D); D>0; non-negative integers; paid(0)=0",
    }


def sympy_per_holder_is_not_the_same() -> dict[str, str]:
    import sympy

    payout, denominator = sympy.symbols("payout denominator", integer=True, positive=True)
    gap = sympy.floor(2 * payout / denominator) - 2 * sympy.floor(payout / denominator)
    witness = gap.subs({payout: WAD - 1, denominator: WAD})
    decision = gap.equals(0)
    identically_zero = "undecided" if decision is None else str(decision)
    return {
        "sympy_version": sympy.__version__,
        "identically_zero": identically_zero,
        "witness_payout": str(WAD - 1),
        "witness_gap": str(witness),
        "classification": "COUNTEREXAMPLE_FOUND" if witness != 0 else "UNEXPECTED_EQUALITY",
    }


def z3_witness() -> dict[str, str]:
    import z3

    payout, denominator = z3.Ints("payout denominator")
    solver = z3.Solver()
    solver.add(payout == WAD - 1, denominator == WAD)
    solver.add((2 * payout) / denominator != 2 * (payout / denominator))
    differed = solver.check() == z3.sat
    return {
        "z3_version": str(z3.get_version_string()),
        "per_holder_differs_on_original_case": "true" if differed else "false",
        "classification": "COUNTEREXAMPLE_FOUND" if differed else "UNEXPECTED_EQUALITY",
    }


def python_regression() -> dict[str, int | str]:
    payout = WAD - 1
    decimals = 18
    global_paid = cumulative_delta(0, 1, payout, decimals) + cumulative_delta(1, 1, payout, decimals)
    per_holder = per_holder_cursor_total([("A", 1), ("B", 1)], payout, decimals)
    one_shot = one_shot_floor(2, payout, decimals)
    return {
        "global_paid": global_paid,
        "one_shot": one_shot,
        "per_holder_paid": per_holder,
        "global_matches_one_shot": str(global_paid == one_shot),
        "per_holder_matches_one_shot": str(per_holder == one_shot),
    }


def run() -> dict[str, Any]:
    started = time.perf_counter()
    report = {
        "canonical_math_1": "FAIL",
        "identity": "sum of global-cursor deltas = floor(supply * payout / D)",
        "global_cursor": sympy_global_cursor(),
        "per_holder_cursor": sympy_per_holder_is_not_the_same(),
        "z3_witness": z3_witness(),
        "python_regression": python_regression(),
        "runtime_seconds": round(time.perf_counter() - started, 6),
    }
    return report


if __name__ == "__main__":
    import json

    print(json.dumps(run(), indent=2, sort_keys=True))
