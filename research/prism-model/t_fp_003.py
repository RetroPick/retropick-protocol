"""T-FP-003. Guarded floor redemption preserves remaining settlement funding.

The written row is FixedPointSettlement in docs/prism/math/17_THEOREMS.md and
section 8 of docs/prism/math/05_BACKING_SOLVENCY.md. It does not claim that
per-call floors sum to the one-shot floor. This module does not change redeem.
"""

from __future__ import annotations

import time
from typing import Any

import z3

from fixed_point import WAD
from fixed_point_model import FixedPointModelError, FixedPointSettlement


def _funded_shortfall_unsat() -> str:
    supply, quantity, payout, denominator, balance = z3.Ints("S Q R D B")
    solver = z3.Solver()
    solver.add(supply >= 0, quantity > 0, quantity <= supply, payout >= 0, denominator > 0, balance >= 0)
    old_requirement = (supply * payout + denominator - 1) / denominator
    new_requirement = ((supply - quantity) * payout + denominator - 1) / denominator
    paid = (quantity * payout) / denominator
    solver.add(balance >= old_requirement)
    solver.add(balance - paid < new_requirement)
    return str(solver.check())


def _snapshot(book: FixedPointSettlement) -> tuple[int, int, bool]:
    return book.supply_units, book.balance_raw, book.redeemable


def discharge_t_fp_003() -> dict[str, Any]:
    """Accepted floor redemptions leave balance at least Req(S-Q).

    A book that starts at the ceil requirement cannot be driven below the
    remaining ceil by the per-call floor. The same floor still underpays the
    supply-2 witness. That underpayment is not this statement.
    """

    started = time.perf_counter()
    shortfall = _funded_shortfall_unsat()

    fragmented = FixedPointSettlement(2, WAD - 1, 18, balance_raw=2)
    fragmented.make_redeemable()
    first = fragmented.redeem(1)
    after_first = (
        fragmented.supply_units,
        fragmented.balance_raw,
        fragmented.required_balance_raw(),
    )
    second = fragmented.redeem(1)
    dust = fragmented.sweepable_dust()
    one_shot = (2 * (WAD - 1)) // WAD
    funding_held = after_first[1] >= after_first[2] and fragmented.balance_raw >= fragmented.required_balance_raw()

    guarded = FixedPointSettlement(2, WAD, 18, balance_raw=1, redeemable=True)
    before = _snapshot(guarded)
    rejected = False
    try:
        guarded.redeem(1)
    except FixedPointModelError:
        rejected = True
    after = _snapshot(guarded)
    elapsed = time.perf_counter() - started
    discharged = (
        shortfall == "unsat"
        and first == 0
        and second == 0
        and one_shot == 1
        and dust == 2
        and funding_held
        and rejected
        and before == after
    )
    return {
        "id": "T-FP-003",
        "written_claim": "conservative aggregate settlement requirement plus guarded rounded redemption preserves funding",
        "statement": "A redemption pays floor(Q*R/(WAD*f)) and is accepted only when the remaining balance is at least Req(S-Q)=ceil((S-Q)*R/(WAD*f))",
        "checker": "z3_and_fixed_point_settlement",
        "z3_version": str(z3.get_version_string()),
        "funded_shortfall": shortfall,
        "fragmentation_witness": {
            "supply": 2,
            "payout_wad": WAD - 1,
            "decimals": 18,
            "required_raw": 2,
            "first_payout": first,
            "second_payout": second,
            "one_shot_floor": one_shot,
            "sweepable_dust": dust,
            "after_first_supply": after_first[0],
            "after_first_balance": after_first[1],
            "after_first_required": after_first[2],
            "funding_held": funding_held,
            "holders_receive_one_shot": first + second == one_shot,
        },
        "rejected_underfunded_call": {
            "supply": 2,
            "payout_wad": WAD,
            "balance": 1,
            "rejected": rejected,
            "unchanged": before == after,
        },
        "holder_sum_claim": "not_this_statement",
        "cx_fp_settlement_001": "COUNTEREXAMPLE_FOUND",
        "assumptions": [
            "nonnegative supply, payout, and balance",
            "0 < Q <= S",
            "positive denominator WAD * decimal factor",
            "the book starts at or above the ceil requirement",
            "payout is the per-call floor",
            "the claim is remaining funding, not holder fairness",
        ],
        "classification": "PROVEN_UNDER_ASSUMPTIONS" if discharged else "COUNTEREXAMPLE_FOUND",
        "counterexample": None
        if discharged
        else {
            "funded_shortfall": shortfall,
            "fragmented_paid": first + second,
            "one_shot_floor": one_shot,
            "funding_held": funding_held,
        },
        "canonical_math1": "FAIL",
        "runtime_seconds": round(elapsed, 6),
    }
