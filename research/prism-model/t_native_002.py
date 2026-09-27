"""T-NATIVE-002. A valid binary terminal payoff sums to one.

The written row is YES(omega)+NO(omega)=1 for a valid terminal world.
Invalid and void payoffs are unspecified and are not assigned here.
This module does not change BinaryCompleteSetMarket.
"""

from __future__ import annotations

import time
from typing import Any

import z3

from native_market import BinaryCompleteSetMarket, NativeMarketError, NativeMarketState


def _valid_sum_unsat() -> str:
    winner = z3.Int("w")
    yes_pay = z3.If(winner == 0, z3.IntVal(1), z3.IntVal(0))
    no_pay = z3.If(winner == 1, z3.IntVal(1), z3.IntVal(0))
    solver = z3.Solver()
    solver.add(z3.Or(winner == 0, winner == 1))
    solver.add(yes_pay + no_pay != 1)
    return str(solver.check())


def _unit_payoffs(winner: str) -> tuple[int, int]:
    market = BinaryCompleteSetMarket()
    market.split(1)
    market.resolve(winner)
    yes = market.redeem("YES", 1)
    no = market.redeem("NO", 1)
    return int(yes), int(no)


def discharge_t_native_002() -> dict[str, Any]:
    """YES pays 1 and NO pays 0, or the reverse, on a valid winner."""

    started = time.perf_counter()
    negation = _valid_sum_unsat()
    yes_win = _unit_payoffs("YES")
    no_win = _unit_payoffs("NO")

    invalid = BinaryCompleteSetMarket()
    invalid.split(1)
    rejected = False
    try:
        invalid.resolve("INVALID")
    except NativeMarketError:
        rejected = True
    elapsed = time.perf_counter() - started
    valid = yes_win == (1, 0) and no_win == (0, 1) and negation == "unsat"
    unspecified = rejected and invalid.winner is None and invalid.state == NativeMarketState.ACTIVE
    discharged = valid and unspecified
    return {
        "id": "T-NATIVE-002",
        "written_claim": "valid binary terminal payoff satisfies YES(omega)+NO(omega)=1",
        "statement": "On a valid YES or NO resolution, the unit YES payoff plus the unit NO payoff is 1",
        "checker": "z3_and_binary_complete_set",
        "z3_version": str(z3.get_version_string()),
        "valid_sum_negation": negation,
        "yes_wins": {"yes": yes_win[0], "no": yes_win[1], "sum": yes_win[0] + yes_win[1]},
        "no_wins": {"yes": no_win[0], "no": no_win[1], "sum": no_win[0] + no_win[1]},
        "invalid_void": {
            "payout": "unspecified",
            "resolve_rejected": rejected,
            "winner": invalid.winner,
            "state": invalid.state.value,
        },
        "assumptions": [
            "a valid terminal winner is YES or NO",
            "the winning side pays one normalized unit and the losing side pays zero",
            "invalid and void payoffs are not part of this statement",
            "BinaryCompleteSetMarket is the executable model and is not modified",
        ],
        "classification": "PROVEN_UNDER_ASSUMPTIONS" if discharged else "COUNTEREXAMPLE_FOUND",
        "counterexample": None
        if discharged
        else {"negation": negation, "yes_wins": yes_win, "no_wins": no_win, "invalid_rejected": rejected},
        "canonical_math1": "FAIL",
        "runtime_seconds": round(elapsed, 6),
    }
