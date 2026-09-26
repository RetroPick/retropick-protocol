"""Write machine-readable fixtures for the component-backing research kernel.

Integers come from FixedPointSeries.deposit_raw, mint, and redeem, and from
ReservationLedger.deposit and reserve. This script does not change those
modules and it does not call FixedPointSettlement.redeem.

A PrismSeries cross-check records whether the existing exact-model examples
agree with the integer series on those same quantities. Disagreement stops
the generator. It is not a prompt to edit either model.
"""

from __future__ import annotations

import json
import sys
from fractions import Fraction
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from fixed_point import WAD  # noqa: E402
from fixed_point_model import (  # noqa: E402
    FixedPointModelError,
    FixedPointSeries,
    required_component_raw,
)
from model import ModelError, PrismSeries  # noqa: E402
from reservation_ledger import ReservationError, ReservationLedger  # noqa: E402

OUT = Path(__file__).resolve().parent / "fixtures" / "backing_kernel.json"

W6 = 6 * 10**17
W4 = 4 * 10**17
G = [[0, 1], [0, 0], [1, 1], [1, 0]]
X = [Fraction(3, 5), Fraction(2, 5)]


def _error_code(exc: FixedPointModelError) -> str:
    message = str(exc)
    if "insufficient" in message:
        return "insufficient_backing"
    if "invalid redemption" in message:
        return "invalid_quantity"
    if "must be positive" in message:
        return "zero_quantity"
    return "other"


def _snapshot(series: FixedPointSeries, holder: int) -> dict:
    return {
        "supply": str(series.supply_units),
        "backing": [str(value) for value in series.backing_raw],
        "holder_balance": str(holder),
        "required": [str(value) for value in series.required_backing_raw()],
    }


def _run_series(case_id: str, weights: list[int], decimals: list[int], ops: list[tuple]) -> dict:
    series = FixedPointSeries(weights, decimals)
    holder = 0
    steps = []
    for op, payload in ops:
        before = _snapshot(series, holder)
        try:
            released = None
            if op == "deposit":
                series.deposit_raw(payload)
            elif op == "mint":
                series.mint(payload)
                holder += int(payload)
            elif op == "redeem":
                released = series.redeem(payload)
                holder -= int(payload)
            else:
                raise SystemExit(f"unknown op {op}")
        except FixedPointModelError as exc:
            row = {"op": op, "expect": "reject", "error": _error_code(exc), **before}
            if op == "deposit":
                row["amounts"] = [str(int(value)) for value in payload]
            else:
                row["quantity"] = str(int(payload))
            if row["error"] == "insufficient_backing" and op == "mint":
                requirement = series.required_backing_raw(series.supply_units + int(payload))
                for index, (have, need) in enumerate(zip(series.backing_raw, requirement)):
                    if have < need:
                        row["fail_index"] = index
                        row["fail_backing"] = str(have)
                        row["fail_required"] = str(need)
                        break
            if row["error"] == "other":
                raise SystemExit(f"{case_id} unclassified reject: {exc}") from exc
            steps.append(row)
            continue
        row = {"op": op, "expect": "ok", **_snapshot(series, holder)}
        if op == "deposit":
            row["amounts"] = [str(int(value)) for value in payload]
        else:
            row["quantity"] = str(int(payload))
        if released is not None:
            row["released"] = [str(int(value)) for value in released]
            naive = [
                str(required_component_raw(int(payload), weights[index], decimals[index]))
                for index in range(len(weights))
            ]
            row["naive_ceil_of_quantity"] = naive
            row["requirement_delta_differs_from_naive_ceil"] = row["released"] != naive
        steps.append(row)
    return {
        "id": case_id,
        "component_count": len(weights),
        "weights_wad": [str(int(value)) for value in weights],
        "decimals": list(decimals),
        "step_count": len(steps),
        "steps": steps,
    }


def _preview_requirement(weights: list[int], decimals: list[int], supply: int) -> list[int]:
    series = FixedPointSeries(weights, decimals)
    return list(series.required_backing_raw(supply))


def _prism_cross_check() -> dict:
    exact = PrismSeries(G, X)
    exact.activate()
    exact.deposit_backing([700, 500])
    exact.mint(1000)
    integer = FixedPointSeries([W6, W4], [18, 18])
    integer.deposit_raw([700, 500])
    integer.mint(1000)
    exact_backing = [int(value) for value in exact.backing]
    if exact_backing != list(integer.backing_raw) or int(exact.supply) != integer.supply_units:
        raise SystemExit(
            "COUNTEREXAMPLE_FOUND: PrismSeries surplus mint disagrees with FixedPointSeries "
            f"exact={exact_backing} supply={int(exact.supply)} "
            f"integer={list(integer.backing_raw)} supply={integer.supply_units}"
        )
    margin = [int(value) for value in exact.backing_margin()]
    if margin != [100, 100]:
        raise SystemExit(f"COUNTEREXAMPLE_FOUND: surplus margin moved to {margin}")

    over = PrismSeries(G, X)
    over.activate()
    over.deposit_backing([599, 400])
    over_rejected = False
    try:
        over.mint(1000)
    except ModelError:
        over_rejected = True
    over_integer = FixedPointSeries([W6, W4], [18, 18])
    over_integer.deposit_raw([599, 400])
    integer_rejected = False
    try:
        over_integer.mint(1000)
    except FixedPointModelError:
        integer_rejected = True
    if not over_rejected or not integer_rejected:
        raise SystemExit("COUNTEREXAMPLE_FOUND: overmint was accepted by one of the models")
    if int(over.supply) != 0 or over_integer.supply_units != 0:
        raise SystemExit("COUNTEREXAMPLE_FOUND: rejected overmint changed supply")

    exact_redeem = PrismSeries(G, X)
    exact_redeem.activate()
    exact_redeem.mint_with_exact_backing(1000)
    released_exact = tuple(int(value) for value in exact_redeem.redeem_in_kind(250))
    integer_redeem = FixedPointSeries([W6, W4], [18, 18])
    integer_redeem.deposit_raw([600, 400])
    integer_redeem.mint(1000)
    released_integer = integer_redeem.redeem(250)
    if released_exact != released_integer or int(exact_redeem.supply) != integer_redeem.supply_units:
        raise SystemExit(
            "COUNTEREXAMPLE_FOUND: in-kind redeem disagrees "
            f"exact={released_exact} supply={int(exact_redeem.supply)} "
            f"integer={released_integer} supply={integer_redeem.supply_units}"
        )
    return {
        "status": "agree",
        "weights_wad": [str(W6), str(W4)],
        "decimals": [18, 18],
        "surplus_deposit": ["700", "500"],
        "surplus_mint": "1000",
        "surplus_backing": ["700", "500"],
        "surplus_supply": "1000",
        "surplus_margin": ["100", "100"],
        "overmint_deposit": ["599", "400"],
        "overmint_quantity": "1000",
        "overmint_rejected": True,
        "redeem_deposit": ["600", "400"],
        "redeem_mint": "1000",
        "redeem_quantity": "250",
        "redeem_released": [str(value) for value in released_integer],
        "redeem_supply": str(integer_redeem.supply_units),
    }


def _reservation() -> dict:
    ledger = ReservationLedger()
    ledger.deposit("FED_YES", 100)
    empty_rejected = False
    try:
        ledger.reserve("", {"FED_YES": 1})
    except ReservationError:
        empty_rejected = True
    if not empty_rejected:
        raise SystemExit("COUNTEREXAMPLE_FOUND: empty series id was accepted")
    if ledger.total_reserved("FED_YES") != 0 or ledger.available("FED_YES") != 100:
        raise SystemExit("COUNTEREXAMPLE_FOUND: empty series reject changed the ledger")
    ledger.reserve("SERIES_A", {"FED_YES": 60})
    available_after_a = ledger.available("FED_YES")
    reserved_after_a = ledger.total_reserved("FED_YES")
    duplicate_rejected = False
    try:
        ledger.reserve("SERIES_B", {"FED_YES": 50})
    except ReservationError:
        duplicate_rejected = True
    if not duplicate_rejected:
        raise SystemExit("COUNTEREXAMPLE_FOUND: duplicate source reservation was accepted")
    if ledger.total_reserved("FED_YES") != reserved_after_a or ledger.available("FED_YES") != available_after_a:
        raise SystemExit("COUNTEREXAMPLE_FOUND: rejected duplicate reservation changed the ledger")
    available_after_reject = ledger.available("FED_YES")
    reserved_after_reject = ledger.total_reserved("FED_YES")
    ledger.reserve("SERIES_B", {"FED_YES": 40})
    if ledger.total_reserved("FED_YES") != 100 or ledger.available("FED_YES") != 0:
        raise SystemExit(
            "COUNTEREXAMPLE_FOUND: reservation totals moved "
            f"reserved={ledger.total_reserved('FED_YES')} available={ledger.available('FED_YES')}"
        )
    return {
        "asset_label": "FED_YES",
        "series_a_label": "SERIES_A",
        "series_b_label": "SERIES_B",
        "asset_id": "1",
        "series_a": "1",
        "series_b": "2",
        "deposit": "100",
        "balance_after_deposit": str(int(ledger.balance("FED_YES"))),
        "empty_series_amount": "1",
        "empty_series_rejected": True,
        "available_after_empty_reject": "100",
        "total_reserved_after_empty_reject": "0",
        "reserve_a": "60",
        "available_after_a": str(int(available_after_a)),
        "total_reserved_after_a": str(int(reserved_after_a)),
        "reserve_b_rejected": "50",
        "available_after_reject": str(int(available_after_reject)),
        "total_reserved_after_reject": str(int(reserved_after_reject)),
        "reserve_b_accepted": "40",
        "total_reserved": str(int(ledger.total_reserved("FED_YES"))),
        "available": str(int(ledger.available("FED_YES"))),
        "reserved_a": str(int(ledger.reserved_for("SERIES_A", "FED_YES"))),
        "reserved_b": str(int(ledger.reserved_for("SERIES_B", "FED_YES"))),
    }


def _mark_release_probe(case: dict) -> None:
    if case["id"] != "redeem_in_kind_small":
        return
    steps = case["steps"]
    if steps[-1]["op"] != "redeem" or steps[-1]["expect"] != "ok":
        raise SystemExit("redeem_in_kind_small must end on a successful redeem")
    if steps[-1]["released"][0] == "0":
        raise SystemExit("redeem_in_kind_small component 0 must release a positive amount")
    if steps[-2]["supply"] == steps[-1]["supply"]:
        raise SystemExit("redeem_in_kind_small did not change supply")
    case["supply_before_release"] = steps[-2]["supply"]
    case["supply_at_release"] = steps[-1]["supply"]
    case["backing0_at_release"] = steps[-1]["backing"][0]


def build() -> dict:
    weights = [W6, W4]
    mixed = [18, 6]
    same = [18, 18]
    required_five = _preview_requirement(weights, mixed, 5)
    if required_five[0] < 1:
        raise SystemExit("component 0 requirement for supply 5 is zero; short mint needs a gap")
    short = [required_five[0] - 1, required_five[1]]
    exact_thousand = _preview_requirement(weights, same, 1000)
    wad_delta = list(FixedPointSeries(weights, mixed).minimum_incremental_backing(WAD))

    cases = [
        _run_series("deposit_only", weights, mixed, [("deposit", required_five)]),
        _run_series(
            "mint_within_backing",
            weights,
            mixed,
            [("deposit", required_five), ("mint", 5)],
        ),
        _run_series("mint_short", weights, mixed, [("deposit", short), ("mint", 5)]),
        _run_series("mint_before_deposit", weights, mixed, [("mint", 5)]),
        _run_series("mint_zero", weights, mixed, [("mint", 0)]),
        _run_series(
            "redeem_in_kind_small",
            weights,
            mixed,
            [("deposit", required_five), ("mint", 5), ("redeem", 2)],
        ),
        _run_series(
            "redeem_above_balance",
            weights,
            mixed,
            [("deposit", required_five), ("mint", 5), ("redeem", 6)],
        ),
        _run_series(
            "prism_surplus_mint",
            weights,
            same,
            [("deposit", [700, 500]), ("mint", 1000)],
        ),
        _run_series(
            "prism_overmint",
            weights,
            same,
            [("deposit", [599, 400]), ("mint", 1000)],
        ),
        _run_series(
            "prism_in_kind_redeem",
            weights,
            same,
            [("deposit", exact_thousand), ("mint", 1000), ("redeem", 250)],
        ),
        _run_series(
            "wad_minimum_backing",
            weights,
            mixed,
            [("deposit", wad_delta), ("mint", WAD), ("redeem", WAD // 3)],
        ),
    ]
    for case in cases:
        _mark_release_probe(case)
    payload = {
        "schema": "component_backing_kernel_fixtures_v1",
        "source": "research/prism-model/fixed_point_model.py FixedPointSeries and reservation_ledger.py",
        "not_settlement": True,
        "not_fixed_point_settlement_redeem": True,
        "canonical_oracle": False,
        "math_1": "FAIL",
        "contract_1": "not_met",
        "v2_promotion": False,
        "case_count": len(cases),
        "cases": cases,
        "prism_cross_check": _prism_cross_check(),
        "reservation": _reservation(),
    }
    _lock(payload)
    return payload


def _lock(payload: dict) -> None:
    by_id = {row["id"]: row for row in payload["cases"]}
    within = by_id["mint_within_backing"]["steps"][-1]
    if within["expect"] != "ok" or within["supply"] != "5":
        raise SystemExit("mint within backing did not reach supply 5")
    short = by_id["mint_short"]["steps"][-1]
    if short["expect"] != "reject" or short["error"] != "insufficient_backing" or short["supply"] != "0":
        raise SystemExit("short mint was not rejected with supply still 0")
    early = by_id["mint_before_deposit"]["steps"][-1]
    if early["expect"] != "reject" or early["supply"] != "0":
        raise SystemExit("mint before deposit was not rejected")
    zero = by_id["mint_zero"]["steps"][-1]
    if zero["expect"] != "reject" or zero["error"] != "zero_quantity":
        raise SystemExit("zero mint was not rejected")
    redeem = by_id["redeem_in_kind_small"]["steps"][-1]
    if redeem["expect"] != "ok" or redeem["quantity"] != "2":
        raise SystemExit("small in-kind redeem did not succeed")
    if not redeem["requirement_delta_differs_from_naive_ceil"]:
        raise SystemExit("small redeem did not distinguish requirement delta from naive ceil")
    above = by_id["redeem_above_balance"]["steps"][-1]
    if above["expect"] != "reject" or above["error"] != "invalid_quantity" or above["holder_balance"] != "5":
        raise SystemExit("redeem above balance was not rejected")
    prism = by_id["prism_in_kind_redeem"]["steps"][-1]
    if prism["released"] != ["150", "100"] or prism["supply"] != "750":
        raise SystemExit(f"prism-image redeem moved: {prism['released']} supply {prism['supply']}")
    reservation = payload["reservation"]
    if reservation["total_reserved"] != "100" or reservation["available"] != "0":
        raise SystemExit("duplicate-source reservation did not end fully reserved")
    if payload["prism_cross_check"]["status"] != "agree":
        raise SystemExit("prism cross-check is not agree")


def main() -> None:
    payload = build()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    print(f"wrote {OUT}")
    print(f"cases {payload['case_count']}")
    print(f"prism_cross_check {payload['prism_cross_check']['status']}")
    reservation = payload["reservation"]
    print(
        "reservation "
        f"deposit={reservation['deposit']} reserve_a={reservation['reserve_a']} "
        f"rejected={reservation['reserve_b_rejected']} accepted={reservation['reserve_b_accepted']} "
        f"total_reserved={reservation['total_reserved']} available={reservation['available']}"
    )
    for case in payload["cases"]:
        last = case["steps"][-1]
        extra = ""
        if "released" in last:
            extra = f" released={','.join(last['released'])}"
        print(
            f"{case['id']} expect={last['expect']} supply={last['supply']} "
            f"backing={','.join(last['backing'])}{extra}"
        )


if __name__ == "__main__":
    main()
