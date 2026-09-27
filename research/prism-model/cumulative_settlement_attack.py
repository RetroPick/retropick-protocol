"""Attack the cumulative-floor candidate. Does not edit FixedPointSettlement.

The aggregate bound is an integer identity when every payout is the global
cursor delta:

    paid(R) = floor(R * payout / D)
    sum of deltas over any partition of [0, supply] = floor(supply * payout / D)

Dust against that one-shot floor is 0. If the starting balance is exactly
ceil(supply * payout / D), the residual is ceil - floor, which is 0 or 1.

A per-holder cursor does not telescope. It remains a negative control.
"""

from __future__ import annotations

import functools
import itertools
import json
import random
import time
from typing import Any

from cumulative_settlement import (
    CumulativeFloorSettlement,
    ceil_funding,
    cumulative_delta,
    one_shot_floor,
    per_holder_cursor_total,
)
from fixed_point import WAD, mul_div_floor
from fixed_point_model import FixedPointModelError, FixedPointSettlement, decimal_factor


PAYOUTS = (0, 1, WAD // 3, WAD - 1, WAD, WAD + 1, 2 * WAD)
PRIMARY_DECIMALS = 18
UNIT_SEQUENCE_MAX = 12
COMPOSITION_MAX = 12
LABELED_COMPOSITION_MAX = 8
OTHER_DECIMAL_MAX = 8
SINGLE_CALL_SPLIT_MAX = 24
RANDOM_TRIALS = 300
RANDOM_SUPPLY_MAX = 400
TINY_STREAM = 4096


@functools.cache
def _compositions(n: int) -> tuple[tuple[int, ...], ...]:
    if n == 0:
        return ((),)
    rows: list[tuple[int, ...]] = []
    for size in range(1, n + 1):
        for tail in _compositions(n - size):
            rows.append((size,) + tail)
    return tuple(rows)


def _settle(supply: int, payout: int, decimals: int, chunks: list[tuple[str, int]], balance: int | None = None):
    totals: dict[str, int] = {}
    for holder, quantity in chunks:
        totals[holder] = totals.get(holder, 0) + quantity
    if sum(totals.values()) != supply:
        raise FixedPointModelError("chunks do not sum to supply")
    funded = ceil_funding(supply, payout, decimals) if balance is None else balance
    book = CumulativeFloorSettlement(supply, payout, decimals, funded, totals)
    book.make_redeemable()
    for holder, quantity in chunks:
        book.redeem(holder, quantity)
    return book


def _check_aggregate(supply: int, payout: int, decimals: int, chunks: list[tuple[str, int]], balance: int | None = None) -> str | None:
    funded = ceil_funding(supply, payout, decimals) if balance is None else balance
    if funded < ceil_funding(supply, payout, decimals):
        return "underfunded setup"
    book = _settle(supply, payout, decimals, chunks, funded)
    target = one_shot_floor(supply, payout, decimals)
    if book.paid_raw != target:
        return f"paid {book.paid_raw} != one-shot {target}"
    if sum(book.receipts.values()) != book.paid_raw:
        return "receipts do not sum to paid"
    if book.supply_units != 0 or book.redeemed_units != supply:
        return "cursor did not consume supply"
    residual = book.balance_raw
    expected_residual = funded - target
    if residual != expected_residual:
        return f"residual {residual} != funded-minus-floor {expected_residual}"
    if balance is None and residual not in (0, 1):
        return f"ceil-funded residual {residual} outside {{0,1}}"
    if book.paid_raw > funded:
        return "paid more than funded balance"
    return None


def canonical_counterexample_still_fails() -> dict[str, Any]:
    required = 2
    book = FixedPointSettlement(2, WAD - 1, 18, required)
    book.make_redeemable()
    first = book.redeem(1)
    second = book.redeem(1)
    dust = book.sweepable_dust()
    one_shot = one_shot_floor(2, WAD - 1, 18)
    return {
        "id": "CX-FP-SETTLEMENT-001",
        "classification": "COUNTEREXAMPLE_FOUND",
        "fragmented_paid_raw": first + second,
        "one_shot_floor_raw": one_shot,
        "required_raw": required,
        "swept_dust_raw": dust,
        "permanent": True,
    }


def original_case_on_candidate() -> dict[str, Any]:
    rows = {}
    for order in (("A", "B"), ("B", "A")):
        chunks = [(order[0], 1), (order[1], 1)]
        book = _settle(2, WAD - 1, 18, chunks)
        rows["".join(order)] = {
            "receipts": dict(book.receipts),
            "paid": book.paid_raw,
            "residual": book.balance_raw,
        }
    negative = per_holder_cursor_total([("A", 1), ("B", 1)], WAD - 1, 18)
    return {
        "candidate_paid": rows["AB"]["paid"],
        "candidate_residual": rows["AB"]["residual"],
        "orders": rows,
        "per_holder_cursor_paid": negative,
    }


def per_call_mint_then_oneshot_redeem(supply: int, payout: int, decimals: int) -> int:
    """Negative control. Not the candidate. Fragmented per-call floors can charge 0."""

    denominator = WAD * decimal_factor(decimals)
    charged = supply * mul_div_floor(1, payout, denominator)
    return one_shot_floor(supply, payout, decimals) - charged


def shared_cumulative_round_trip(mint_chunks: list[int], redeem_chunks: list[int], payout: int, decimals: int) -> int:
    """Hypothetical shared global cursor. Net collateral is charged minus refunded."""

    if sum(mint_chunks) != sum(redeem_chunks):
        raise FixedPointModelError("round trip quantities differ")
    cursor = 0
    charged = 0
    for quantity in mint_chunks:
        charged += cumulative_delta(cursor, quantity, payout, decimals)
        cursor += quantity
    refunded = 0
    for quantity in redeem_chunks:
        if quantity > cursor:
            raise FixedPointModelError("redeem exceeds cursor")
        refunded += cumulative_delta(cursor - quantity, quantity, payout, decimals)
        cursor -= quantity
    return charged - refunded


def _record_failure(failures: list[dict[str, Any]], kind: str, detail: str, **fields: Any) -> None:
    if len(failures) >= 8:
        return
    failures.append({"kind": kind, "detail": detail, **fields})


def run_attack() -> dict[str, Any]:
    started = time.perf_counter()
    failures: list[dict[str, Any]] = []
    states = 0
    transitions = 0
    decimals_domain = (18, 6, 0)
    max_shortfall = 0
    max_surplus = 0

    canonical = canonical_counterexample_still_fails()
    original = original_case_on_candidate()
    if canonical["fragmented_paid_raw"] != 0 or canonical["swept_dust_raw"] != 2:
        _record_failure(failures, "canonical-regression-lost", "per-call counterexample changed")
    if original["candidate_paid"] != 1 or original["candidate_residual"] != 1:
        _record_failure(failures, "original-case", "candidate did not pay the one-shot floor")
    if original["per_holder_cursor_paid"] != 0:
        _record_failure(failures, "negative-control", "per-holder cursor unexpectedly telescoped")

    for decimals in decimals_domain:
        denominator = WAD * decimal_factor(decimals)
        payouts = PAYOUTS + (denominator - 1, denominator, denominator // 3, denominator + 1)
        composition_max = COMPOSITION_MAX if decimals == PRIMARY_DECIMALS else OTHER_DECIMAL_MAX
        unit_max = UNIT_SEQUENCE_MAX if decimals == PRIMARY_DECIMALS else OTHER_DECIMAL_MAX
        labeled_max = LABELED_COMPOSITION_MAX if decimals == PRIMARY_DECIMALS else OTHER_DECIMAL_MAX
        split_max = SINGLE_CALL_SPLIT_MAX if decimals == PRIMARY_DECIMALS else OTHER_DECIMAL_MAX
        for payout in payouts:
            for supply in range(0, composition_max + 1):
                states += 1
                if supply == 0:
                    book = CumulativeFloorSettlement(0, payout, decimals, 0, {})
                    book.make_redeemable()
                    transitions += 1
                    if book.paid_raw != 0 or book.balance_raw != 0:
                        _record_failure(failures, "zero-supply", "zero supply paid or retained balance", payout=payout, decimals=decimals)
                    continue
                for parts in _compositions(supply):
                    chunks = [("A", part) for part in parts]
                    states += 1
                    detail = _check_aggregate(supply, payout, decimals, chunks)
                    transitions += len(chunks)
                    if detail:
                        _record_failure(failures, "composition", detail, supply=supply, payout=str(payout), decimals=decimals, parts=parts)

            for supply in range(1, unit_max + 1):
                for mask in range(1 << supply):
                    chunks = [("A" if (mask >> index) & 1 else "B", 1) for index in range(supply)]
                    states += 1
                    detail = _check_aggregate(supply, payout, decimals, chunks)
                    transitions += supply
                    if detail:
                        _record_failure(
                            failures,
                            "unit-sequence",
                            detail,
                            supply=supply,
                            payout=str(payout),
                            decimals=decimals,
                            mask=mask,
                        )
                        break

            for supply in range(1, labeled_max + 1):
                for parts in _compositions(supply):
                    width = len(parts)
                    for assignment in range(1 << width):
                        chunks = [
                            ("A" if (assignment >> index) & 1 else "B", part) for index, part in enumerate(parts)
                        ]
                        states += 1
                        detail = _check_aggregate(supply, payout, decimals, chunks)
                        transitions += width
                        if detail:
                            _record_failure(failures, "labeled-composition", detail, supply=supply, payout=str(payout))
                            break
                    if failures and failures[-1]["kind"] == "labeled-composition":
                        break

            for supply in range(1, split_max + 1):
                for owned in range(0, supply + 1):
                    for order in ("AB", "BA"):
                        chunks: list[tuple[str, int]] = []
                        if order == "AB":
                            if owned:
                                chunks.append(("A", owned))
                            if supply - owned:
                                chunks.append(("B", supply - owned))
                        else:
                            if supply - owned:
                                chunks.append(("B", supply - owned))
                            if owned:
                                chunks.append(("A", owned))
                        book = _settle(supply, payout, decimals, chunks)
                        states += 1
                        transitions += len(chunks)
                        isolated_a = one_shot_floor(owned, payout, decimals)
                        isolated_b = one_shot_floor(supply - owned, payout, decimals)
                        short_a = isolated_a - book.receipts.get("A", 0)
                        short_b = isolated_b - book.receipts.get("B", 0)
                        surplus_a = book.receipts.get("A", 0) - isolated_a
                        surplus_b = book.receipts.get("B", 0) - isolated_b
                        max_shortfall = max(max_shortfall, short_a, short_b)
                        max_surplus = max(max_surplus, surplus_a, surplus_b)
                        if short_a > 0 or short_b > 0 or surplus_a > 1 or surplus_b > 1:
                            _record_failure(
                                failures,
                                "single-call-holder-bound",
                                "single-call receipt left the isolated floor or floor+1",
                                supply=supply,
                                payout=str(payout),
                                owned=owned,
                                order=order,
                            )
                        if book.paid_raw != one_shot_floor(supply, payout, decimals):
                            _record_failure(failures, "single-call-aggregate", "single-call split missed one-shot")

    rng = random.Random(20260926)
    for _ in range(RANDOM_TRIALS):
        decimals = rng.choice(decimals_domain)
        denominator = WAD * decimal_factor(decimals)
        supply = rng.randint(1, RANDOM_SUPPLY_MAX)
        payout = rng.choice(
            [0, 1, denominator - 1, denominator, rng.randint(0, denominator * 3), rng.randint(0, 2**256 - 1)]
        )
        remaining = supply
        chunks = []
        while remaining:
            quantity = rng.randint(1, remaining)
            holder = "A" if rng.randrange(2) == 0 else "B"
            chunks.append((holder, quantity))
            remaining -= quantity
        states += 1
        detail = _check_aggregate(supply, payout, decimals, chunks)
        transitions += len(chunks)
        if detail:
            _record_failure(failures, "random", detail, supply=supply, payout=str(payout), decimals=decimals)
        permuted = chunks[:]
        rng.shuffle(permuted)
        detail = _check_aggregate(supply, payout, decimals, permuted)
        states += 1
        transitions += len(permuted)
        if detail:
            _record_failure(failures, "permutation", detail, supply=supply, payout=str(payout))

    large_cases = [
        (2**128, 2**200, 18, [1, 2**64, 2**128 - 1 - 2**64]),
        (2**256 - 1, 2**256 - 1, 18, [1, 2**128, (2**256 - 1) - 1 - 2**128]),
        (2**256 - 1, 1, 0, [2**256 - 1]),
        (1, 2**256 - 1, 6, [1]),
        (10**6, 10**18 - 1, 18, [1] * 5 + [10**6 - 5]),
    ]
    for supply, payout, decimals, parts in large_cases:
        if sum(parts) != supply:
            _record_failure(failures, "large-setup", "parts do not sum", supply=str(supply))
            continue
        chunks = [("A" if index % 2 == 0 else "B", part) for index, part in enumerate(parts)]
        states += 1
        detail = _check_aggregate(supply, payout, decimals, chunks)
        transitions += len(chunks)
        if detail:
            _record_failure(failures, "large", detail, supply=str(supply), payout=str(payout), decimals=decimals)
        for perm in set(itertools.permutations(chunks)):
            states += 1
            detail = _check_aggregate(supply, payout, decimals, list(perm))
            transitions += len(perm)
            if detail:
                _record_failure(failures, "large-permutation", detail, supply=str(supply))
                break

    cycle_mismatches = 0
    cycle_samples = 0
    for decimals in decimals_domain:
        denominator = WAD * decimal_factor(decimals)
        for payout in (0, 1, WAD - 1, denominator - 1, denominator):
            for parts in _compositions(8):
                cycle_samples += 1
                net = shared_cumulative_round_trip(list(parts), list(reversed(parts)), payout, decimals)
                other = shared_cumulative_round_trip(list(parts), [sum(parts)], payout, decimals)
                if net != 0 or other != 0:
                    cycle_mismatches += 1
                    _record_failure(failures, "shared-cursor-cycle", f"net {net} reverse {other}")
    extraction = per_call_mint_then_oneshot_redeem(2, WAD - 1, 18)

    rejected = _rejection_probe()
    transitions += rejected["attempts"]
    if rejected["mutated"]:
        _record_failure(failures, "rejection", "rejected call mutated state")

    donation_detail = _check_aggregate(2, WAD - 1, 18, [("A", 1), ("B", 1)], balance=7)
    if donation_detail:
        _record_failure(failures, "donation", donation_detail)
    tiny_chunks = [("A" if index % 2 == 0 else "B", 1) for index in range(TINY_STREAM)]
    tiny_detail = _check_aggregate(TINY_STREAM, WAD - 1, 18, tiny_chunks)
    states += 1
    transitions += TINY_STREAM
    if tiny_detail:
        _record_failure(failures, "tiny-stream", tiny_detail, supply=TINY_STREAM)
    fragmented = _self_fragmentation_example()
    if fragmented["paid"] != fragmented["one_shot"] or fragmented["shortfall_received_by_other"] is not True:
        _record_failure(failures, "self-fragmentation", "split redemption moved value outside the aggregate bound")

    elapsed = time.perf_counter() - started
    classification = "COUNTEREXAMPLE_FOUND" if failures else "PROVEN_UNDER_ASSUMPTIONS"
    domain_classification = "COUNTEREXAMPLE_FOUND" if failures else "EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN"
    return {
        "candidate": "CumulativeFloorSettlement",
        "canonical_rule": "FixedPointSettlement.redeem",
        "canonical_math1": "FAIL",
        "canonical_counterexample": canonical,
        "original_case": original,
        "leakage_bound": {
            "statement": "For any partition of a fixed supply, global-cursor payouts sum to floor(supply * payout / D). Against exact ceil funding the residual is 0 or 1. A single redemption pays floor(q * payout / D) or one more.",
            "classification": classification,
            "domain_check": domain_classification,
            "assumptions": [
                "non-negative integers",
                "D = 10^18 * 10^(18-decimals) with decimals in 0..18",
                "no mint on the settlement candidate",
                "starting balance >= ceil(supply * payout / D)",
                "every payout equals paid(R+q) - paid(R) on one global redeemed cursor",
                "the whole supply is redeemed",
            ],
        },
        "per_call_mint_extraction_raw": extraction,
        "shared_cursor_cycle_samples": cycle_samples,
        "shared_cursor_cycle_mismatches": cycle_mismatches,
        "single_call_max_shortfall_vs_isolated_floor": max_shortfall,
        "single_call_max_surplus_vs_isolated_floor": max_surplus,
        "self_fragmentation": fragmented,
        "rejection": rejected,
        "domain": {
            "decimals": list(decimals_domain),
            "payouts_include": [str(item) for item in PAYOUTS],
            "composition_supply_max": COMPOSITION_MAX,
            "unit_sequence_supply_max": UNIT_SEQUENCE_MAX,
            "labeled_composition_supply_max": LABELED_COMPOSITION_MAX,
            "single_call_split_max": SINGLE_CALL_SPLIT_MAX,
            "random_trials": RANDOM_TRIALS,
            "random_supply_max": RANDOM_SUPPLY_MAX,
            "random_seed": 20260926,
            "large_supplies": ["2^128", "2^256-1", "10^6"],
            "tiny_stream": TINY_STREAM,
            "other_decimal_supply_max": OTHER_DECIMAL_MAX,
            "primary_decimals": PRIMARY_DECIMALS,
        },
        "states": states,
        "transitions": transitions,
        "failures": failures,
        "runtime_seconds": round(elapsed, 6),
        "new_counterexample": failures[0] if failures else None,
        "solidity": "not_written",
    }


def _self_fragmentation_example() -> dict[str, Any]:
    """A holder who splits can miss a carry that the other holder receives.

    Aggregate paid still equals the one-shot floor. This is not dust capture.
    """

    payout = (WAD // 2) + 1
    chunks = [("A", 1), ("B", 1), ("A", 1)]
    book = _settle(3, payout, 18, chunks)
    isolated_a = one_shot_floor(2, payout, 18)
    return {
        "payout_wad": payout,
        "receipts": dict(book.receipts),
        "paid": book.paid_raw,
        "one_shot": one_shot_floor(3, payout, 18),
        "residual": book.balance_raw,
        "holder_a_below_isolated_floor": book.receipts["A"] < isolated_a,
        "shortfall_received_by_other": book.receipts["A"] + book.receipts["B"] == book.paid_raw,
    }


def _rejection_probe() -> dict[str, Any]:
    attempts = 0
    mutated = False
    closed = CumulativeFloorSettlement(2, WAD - 1, 18, 2, {"A": 1, "B": 1})
    before = _view(closed)
    attempts += 1
    try:
        closed.redeem("A", 1)
    except FixedPointModelError:
        pass
    else:
        mutated = True
    if _view(closed) != before:
        mutated = True

    opened = CumulativeFloorSettlement(2, WAD - 1, 18, 2, {"A": 1, "B": 1})
    opened.make_redeemable()
    baseline = _view(opened)
    for call in (
        lambda: opened.redeem("A", 0),
        lambda: opened.redeem("A", -1),
        lambda: opened.redeem("C", 1),
        lambda: opened.redeem("A", 2),
    ):
        attempts += 1
        try:
            call()
        except FixedPointModelError:
            pass
        else:
            mutated = True
        if _view(opened) != baseline:
            mutated = True
    attempts += 1
    try:
        CumulativeFloorSettlement(2, WAD - 1, 18, 1, {"A": 2}).make_redeemable()
    except FixedPointModelError:
        pass
    else:
        mutated = True
    return {"attempts": attempts, "mutated": mutated}


def _view(book: CumulativeFloorSettlement) -> tuple[Any, ...]:
    return (
        book.supply_units,
        book.balance_raw,
        book.redeemed_units,
        book.paid_raw,
        book.redeemable,
        tuple(sorted(book.balances.items())),
        tuple(sorted(book.receipts.items())),
    )


COMPOSITION_SUPPLY16 = 16


def _primary_payouts(decimals: int) -> tuple[int, ...]:
    denominator = WAD * decimal_factor(decimals)
    seen: list[int] = []
    for payout in PAYOUTS + (denominator - 1, denominator, denominator // 3, denominator + 1):
        if payout not in seen:
            seen.append(payout)
    return tuple(seen)


def _chunks_for(parts: tuple[int, ...], labeling: str) -> list[tuple[str, int]]:
    if labeling == "all-A":
        return [("A", part) for part in parts]
    if labeling == "alternating":
        return [("A" if index % 2 == 0 else "B", part) for index, part in enumerate(parts)]
    raise FixedPointModelError(f"unknown labeling {labeling}")


def run_supply16_compositions() -> dict[str, Any]:
    """Compositions through supply 16 on 18 decimals. Does not change the payout rule.

    The recorded attack stopped at composition supply 12. This walk is only that
    axis, with two holders: every part on A, and parts alternating A/B.
    """

    started = time.perf_counter()
    failures: list[dict[str, Any]] = []
    states = 0
    transitions = 0
    decimals = PRIMARY_DECIMALS
    payouts = _primary_payouts(decimals)
    fairness_payout = (WAD // 2) + 1

    def _fail(kind: str, detail: str, **fields: Any) -> None:
        failures.append({"kind": kind, "detail": detail, **fields})

    for payout in payouts:
        for supply in range(0, COMPOSITION_SUPPLY16 + 1):
            states += 1
            if supply == 0:
                book = CumulativeFloorSettlement(0, payout, decimals, 0, {})
                book.make_redeemable()
                transitions += 1
                if book.paid_raw != 0 or book.balance_raw != 0:
                    _fail("zero-supply", "zero supply paid or retained balance", supply=0, payout=payout, parts=[])
                continue
            for parts in _compositions(supply):
                for labeling in ("all-A", "alternating"):
                    chunks = _chunks_for(parts, labeling)
                    states += 1
                    detail = _check_aggregate(supply, payout, decimals, chunks)
                    transitions += len(chunks)
                    if detail:
                        _fail(
                            "composition",
                            detail,
                            supply=supply,
                            payout=payout,
                            parts=list(parts),
                            labeling=labeling,
                        )

    original_rows = {}
    for order in (("A", "B"), ("B", "A")):
        chunks = [(order[0], 1), (order[1], 1)]
        states += 1
        detail = _check_aggregate(2, WAD - 1, decimals, chunks)
        transitions += len(chunks)
        book = _settle(2, WAD - 1, decimals, chunks)
        original_rows["".join(order)] = {"paid": book.paid_raw, "residual": book.balance_raw, "receipts": dict(book.receipts)}
        if detail:
            _fail("original-case", detail, supply=2, payout=WAD - 1, parts=[1, 1], order="".join(order))

    fairness_chunks = [("A", 1), ("B", 1), ("A", 1)]
    states += 1
    fairness_detail = _check_aggregate(3, fairness_payout, decimals, fairness_chunks)
    transitions += len(fairness_chunks)
    fairness_book = _settle(3, fairness_payout, decimals, fairness_chunks)
    fairness = {
        "payout_wad": fairness_payout,
        "paid": fairness_book.paid_raw,
        "one_shot": one_shot_floor(3, fairness_payout, decimals),
        "residual": fairness_book.balance_raw,
        "receipts": dict(fairness_book.receipts),
    }
    if fairness_detail:
        _fail("fairness-case", fairness_detail, supply=3, payout=fairness_payout, parts=[1, 1, 1])
    if fairness["paid"] > fairness["one_shot"]:
        _fail("fairness-overpay", "partition paid more than the one-shot floor", supply=3, payout=fairness_payout, parts=[1, 1, 1])

    minimal = None
    if failures:
        minimal = min(failures, key=lambda row: (row.get("supply", 0), row.get("payout", 0), len(row.get("parts", [])), tuple(row.get("parts", [])), row["kind"]))
    elapsed = time.perf_counter() - started
    clean = not failures
    return {
        "axis": "compositions",
        "previous_composition_supply_max": COMPOSITION_MAX,
        "composition_supply_max": COMPOSITION_SUPPLY16,
        "decimals": decimals,
        "holders": ["A", "B"],
        "labelings": ["all-A", "alternating"],
        "payouts": [str(payout) for payout in payouts],
        "states": states,
        "transitions": transitions,
        "runtime_seconds": round(elapsed, 6),
        "failures": failures[:8],
        "failure_count": len(failures),
        "minimal_counterexample": minimal,
        "domain_check": "EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN" if clean else "COUNTEREXAMPLE_FOUND",
        "canonical_math1": "FAIL",
        "original_case": original_rows,
        "fairness_case": fairness,
        "asserts": [
            "total paid equals floor(supply * payout / D)",
            "ceil-funded residual is 0 or 1",
            "no partition pays more than the one-shot floor",
        ],
    }


def main() -> None:
    report = run_attack()
    print(json.dumps(report, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
