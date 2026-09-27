"""Ordered compositions of the existing INVALID floors.

This is not ``exhaustive_search.explore``. That search is the market state
machine. ``test_invalid_dust_is_modulus_two`` is a 1-unit stream. This walk
only partitions a bounded outstanding supply.

The cumulative rule is ``integer_payout_delta`` with numerator 1 and
denominator 2. The per-call rule is ``per_call_floor_half``. Neither formula
is changed. Holder labels match the PRISM supply composition style. The
INVALID cursor is per side, so the label does not change the paid total.
"""

from __future__ import annotations

import functools
import time
from typing import Any

from complete_set import integer_payout_delta, integer_side_obligation, per_call_floor_half
from fixed_point import fragmentation_gap, half_up_both_sides


SUPPLY_MAX = 16
HOLDERS = ("A", "B")
LABELINGS = ("all-A", "alternating")
NUMERATOR = 1
DENOMINATOR = 2


@functools.cache
def compositions(n: int) -> tuple[tuple[int, ...], ...]:
    if n == 0:
        return ((),)
    rows: list[tuple[int, ...]] = []
    for size in range(1, n + 1):
        for tail in compositions(n - size):
            rows.append((size,) + tail)
    return tuple(rows)


def _holders_for(parts: tuple[int, ...], labeling: str) -> tuple[str, ...]:
    if labeling == "all-A":
        return tuple("A" for _ in parts)
    if labeling == "alternating":
        return tuple("A" if index % 2 == 0 else "B" for index in range(len(parts)))
    raise ValueError(f"unknown labeling {labeling}")


def _replay_side(parts: tuple[int, ...]) -> tuple[int, int]:
    cursor = 0
    cumulative = 0
    per_call = 0
    for quantity in parts:
        cumulative += integer_payout_delta(cursor, quantity, NUMERATOR, DENOMINATOR)
        per_call += per_call_floor_half(quantity)
        cursor += quantity
    return cumulative, per_call


def discharge_invalid_floor_compositions() -> dict[str, Any]:
    started = time.perf_counter()
    states = 0
    transitions = 0
    labeled_compositions = 0
    cumulative_failures: list[dict[str, Any]] = []
    gap_rows = 0
    smallest: dict[str, Any] | None = None

    for supply in range(0, SUPPLY_MAX + 1):
        states += 1
        one_shot = integer_side_obligation(supply, NUMERATOR, DENOMINATOR)
        if supply == 0:
            yes_paid, yes_per_call = _replay_side(())
            no_paid, no_per_call = _replay_side(())
            transitions += 2
            if yes_paid != 0 or no_paid != 0 or yes_per_call != 0 or no_per_call != 0 or one_shot != 0:
                cumulative_failures.append(
                    {
                        "supply": 0,
                        "parts": [],
                        "labeling": "all-A",
                        "yes_paid": yes_paid,
                        "no_paid": no_paid,
                        "one_shot": one_shot,
                    }
                )
            continue
        for parts in compositions(supply):
            for labeling in LABELINGS:
                states += 1
                labeled_compositions += 1
                holders = _holders_for(parts, labeling)
                yes_paid, yes_per_call = _replay_side(parts)
                no_paid, no_per_call = _replay_side(parts)
                transitions += 2 * len(parts)
                residual = supply - yes_paid - no_paid
                if (
                    yes_paid != one_shot
                    or no_paid != one_shot
                    or yes_per_call != no_per_call
                    or residual != supply % 2
                    or sum(parts) != supply
                ):
                    cumulative_failures.append(
                        {
                            "supply": supply,
                            "parts": list(parts),
                            "labeling": labeling,
                            "holders": list(holders),
                            "yes_paid": yes_paid,
                            "no_paid": no_paid,
                            "one_shot": one_shot,
                            "residual": residual,
                        }
                    )
                gap = one_shot - yes_per_call
                if gap > 0:
                    gap_rows += 1
                    witness = {
                        "supply": supply,
                        "parts": list(parts),
                        "labeling": labeling,
                        "holders": list(holders),
                        "one_shot": one_shot,
                        "cumulative_paid": yes_paid,
                        "per_call_paid": yes_per_call,
                        "gap": gap,
                    }
                    if smallest is None or (
                        supply,
                        len(parts),
                        parts,
                        labeling,
                    ) < (
                        smallest["supply"],
                        len(smallest["parts"]),
                        tuple(smallest["parts"]),
                        smallest["labeling"],
                    ):
                        smallest = witness

    elapsed = time.perf_counter() - started
    half_payment = half_up_both_sides(1)
    cumulative_clean = not cumulative_failures
    half_up_status = "COUNTEREXAMPLE_FOUND" if half_payment > 1 else "EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN"
    return {
        "id": "PRED-INVALID-FLOOR-COMPOSITIONS",
        "domain": (
            "ordered compositions of outstanding INVALID supply 0..16, "
            "holders A and B, labelings all-A and alternating, both YES and NO cursors"
        ),
        "supply_max": SUPPLY_MAX,
        "supply_min": 0,
        "holders": list(HOLDERS),
        "labelings": list(LABELINGS),
        "numerator": NUMERATOR,
        "denominator": DENOMINATOR,
        "states": states,
        "transitions": transitions,
        "labeled_compositions": labeled_compositions,
        "runtime_seconds": round(elapsed, 6),
        "cumulative_floor": {
            "classification": "EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN" if cumulative_clean else "COUNTEREXAMPLE_FOUND",
            "counterexample": cumulative_failures[0] if cumulative_failures else None,
            "failure_count": len(cumulative_failures),
            "rule": "integer_payout_delta(redeemed_before, quantity, 1, 2)",
            "one_shot": "integer_side_obligation(supply, 1, 2)",
        },
        "per_call_floor": {
            "classification": "COUNTEREXAMPLE_FOUND" if smallest is not None else "EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN",
            "smallest_witness": smallest,
            "gap_rows": gap_rows,
            "rule": "per_call_floor_half",
            "fragmentation_gap_supply_5": fragmentation_gap(5),
        },
        "half_up": {
            "classification": half_up_status,
            "quantity": 1,
            "both_sides_payment": half_payment,
            "collateral_unit": 1,
            "rule": "naive_half_up on each side",
        },
        "pred_math_1": "partial",
        "canonical_math1": "FAIL",
        "kernel_status": "research_candidate",
        "formula_changed": False,
        "distinct_from_market_search": (
            "exhaustive_search.explore is the market state machine and is not called. "
            "test_invalid_dust_is_modulus_two remains the 1-unit stream for amounts 1..32."
        ),
    }
