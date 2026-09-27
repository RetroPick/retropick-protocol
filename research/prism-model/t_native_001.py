"""T-NATIVE-001. Split and merge conserve complete-set collateral.

The written row is the pre-resolution equality in
docs/prism/math/01_DEFINITIONS.md and INV-N01/N02/N04. This module does not
change BinaryCompleteSetMarket or its payout rule.
"""

from __future__ import annotations

import time
from fractions import Fraction
from typing import Any

import sympy
import z3

from native_market import BinaryCompleteSetMarket, NativeMarketError


def _gap_identity() -> bool:
    yes, no, collateral, quantity = sympy.symbols("Sy Sn C q")
    split_yes_no = sympy.expand((yes + quantity) - (no + quantity) - (yes - no))
    split_yes_collateral = sympy.expand((yes + quantity) - (collateral + quantity) - (yes - collateral))
    merge_yes_no = sympy.expand((yes - quantity) - (no - quantity) - (yes - no))
    merge_yes_collateral = sympy.expand((yes - quantity) - (collateral - quantity) - (yes - collateral))
    return split_yes_no == split_yes_collateral == merge_yes_no == merge_yes_collateral == 0


def _broken_equality_unsat(kind: str) -> str:
    yes, no, collateral, quantity = z3.Reals("Sy Sn C q")
    solver = z3.Solver()
    solver.add(yes == no, no == collateral, quantity > 0)
    if kind == "merge":
        solver.add(quantity <= yes)
        yes_after, no_after, collateral_after = yes - quantity, no - quantity, collateral - quantity
    elif kind == "split":
        yes_after, no_after, collateral_after = yes + quantity, no + quantity, collateral + quantity
    else:
        raise ValueError(kind)
    solver.add(z3.Or(yes_after != no_after, yes_after != collateral_after))
    return str(solver.check())


def _view(market: BinaryCompleteSetMarket) -> tuple[Fraction, Fraction, Fraction]:
    return market.yes_supply, market.no_supply, market.collateral_locked


def discharge_t_native_001() -> dict[str, Any]:
    """S_Y = S_N = C_locked is unchanged by an active split or an equal merge."""

    started = time.perf_counter()
    identity = _gap_identity()
    split_status = _broken_equality_unsat("split")
    merge_status = _broken_equality_unsat("merge")

    market = BinaryCompleteSetMarket()
    market.split(100)
    market.merge(25)
    conserved = market.yes_supply == market.no_supply == market.collateral_locked == 75
    interest = market.open_interest() == 75

    rejected = BinaryCompleteSetMarket()
    rejected.split(75)
    before = _view(rejected)
    merge_rejected = False
    try:
        rejected.merge(76)
    except NativeMarketError:
        merge_rejected = True
    after = _view(rejected)
    elapsed = time.perf_counter() - started
    discharged = (
        identity
        and split_status == "unsat"
        and merge_status == "unsat"
        and conserved
        and interest
        and merge_rejected
        and before == after
    )
    return {
        "id": "T-NATIVE-001",
        "written_claim": "canonical binary split/merge conserves complete-set collateral accounting",
        "statement": "While the market is active, S_Y = S_N = C_locked, a split of q adds q to all three, and a merge of q subtracts q from all three",
        "checker": "sympy_z3_and_binary_complete_set",
        "sympy_version": sympy.__version__,
        "z3_version": str(z3.get_version_string()),
        "gap_identity": identity,
        "split_breaks_equality": split_status,
        "merge_breaks_equality": merge_status,
        "model_check": {
            "split": 100,
            "merge": 25,
            "yes": str(market.yes_supply),
            "no": str(market.no_supply),
            "collateral": str(market.collateral_locked),
            "open_interest": str(market.open_interest()),
        },
        "rejected_merge": {
            "quantity": 76,
            "supply": 75,
            "rejected": merge_rejected,
            "unchanged": before == after,
        },
        "assumptions": [
            "normalized exact quantities",
            "the market starts with S_Y = S_N = C_locked",
            "split and merge run only while ACTIVE",
            "merge quantity is positive and no greater than both supplies",
            "BinaryCompleteSetMarket is the executable model",
            "resolution payout is not this statement",
        ],
        "classification": "PROVEN_UNDER_ASSUMPTIONS" if discharged else "COUNTEREXAMPLE_FOUND",
        "counterexample": None
        if discharged
        else {"gap_identity": identity, "split": split_status, "merge": merge_status, "conserved": conserved},
        "canonical_math1": "FAIL",
        "runtime_seconds": round(elapsed, 6),
    }
