"""Reachability of PredictionMarket Underfunded and LiveLiability.

The kernel checks are:

- openRedemption reverts Underfunded when collateralLocked < liability()
- archive reverts LiveLiability when both supplies are already 0 and liability() != 0

This module does not change those formulas. A reachable witness is a
counterexample. A discharged claim is PROVEN_UNDER_ASSUMPTIONS for the
implemented numerators only: YES (2, 0), NO (0, 2), INVALID (1, 1),
denominator 2.
"""

from __future__ import annotations

import time
from typing import Any

import sympy as sp

from domain import MarketState, Outcome, PredictionError, ResolutionResult
from exhaustive_search import _key
from market import PredictionMarket, activate_binary, create_market


COUNTEREXAMPLE_ERRORS = {
    "settlement underfunded",
    "archive requires zero liability",
    "P-I08 collateral below liability",
}


def _floor_gap(symbol: sp.Symbol) -> sp.Expr:
    return sp.simplify(symbol - (sp.floor(symbol / 2) + sp.floor(symbol / 2)))


def sympy_identities() -> dict[str, Any]:
    """Discharge the floor identities SymPy can decide for denominator 2."""

    collateral, y0, redeemed_yes, yes_supply = sp.symbols(
        "C y0 Ry Ys", integer=True, nonnegative=True
    )
    half_k = sp.symbols("k", integer=True, nonnegative=True)
    invalid_gap = _floor_gap(collateral)
    even_gap = sp.simplify(invalid_gap.subs(collateral, 2 * half_k))
    odd_gap = sp.simplify(invalid_gap.subs(collateral, 2 * half_k + 1))
    invalid_archive = sp.simplify(
        sp.floor(y0 / 2) + sp.floor(y0 / 2) - sp.floor(y0 / 2) - sp.floor(y0 / 2)
    )
    yes_liability = sp.simplify(sp.floor(2 * (yes_supply + redeemed_yes) / 2) - sp.floor(2 * redeemed_yes / 2))
    no_supply, redeemed_no = sp.symbols("Ns Rn", integer=True, nonnegative=True)
    no_liability = sp.simplify(sp.floor(2 * (no_supply + redeemed_no) / 2) - sp.floor(2 * redeemed_no / 2))
    zero_numerator = sp.simplify(sp.floor(0 * y0 / 2))
    discharged = (
        even_gap == 0
        and odd_gap == 1
        and invalid_archive == 0
        and yes_liability == yes_supply
        and no_liability == no_supply
        and zero_numerator == 0
    )
    return {
        "sympy_version": sp.__version__,
        "discharged": bool(discharged),
        "invalid_open_gap_even": str(even_gap),
        "invalid_open_gap_odd": str(odd_gap),
        "invalid_archive_liability": str(invalid_archive),
        "yes_liability_when_supply_remains": str(yes_liability),
        "no_liability_when_supply_remains": str(no_liability),
        "zero_numerator_contribution": str(zero_numerator),
    }


def _snapshot(market: PredictionMarket) -> dict[str, str]:
    return {
        "state": market.state.value,
        "result": "" if market.result is None else market.result.value,
        "collateral_locked": str(market.collateral_locked),
        "yes_supply": str(market.yes_supply),
        "no_supply": str(market.no_supply),
        "yes_redeemed": str(market.yes_redeemed),
        "no_redeemed": str(market.no_redeemed),
        "liability": str(market.liability()),
    }


def _observe(market: PredictionMarket) -> str:
    if market.state is MarketState.RESOLVED and market.collateral_locked < market.liability():
        return "openRedemption Underfunded"
    if (
        market.state is MarketState.REDEEMABLE
        and market.yes_supply == 0
        and market.no_supply == 0
        and market.liability() != 0
    ):
        return "archive LiveLiability"
    return ""


def _apply(trial: PredictionMarket, name: str, arg: object) -> None:
    if name == "split":
        trial.split("alice", arg, arg)  # type: ignore[arg-type]
    elif name == "merge":
        trial.merge("alice", arg)  # type: ignore[arg-type]
    elif name == "redeem_yes":
        trial.redeem("alice", Outcome.YES, arg)  # type: ignore[arg-type]
    elif name == "redeem_no":
        trial.redeem("alice", Outcome.NO, arg)  # type: ignore[arg-type]
    elif name == "burn_yes":
        trial.burn_worthless("alice", Outcome.YES, arg)  # type: ignore[arg-type]
    elif name == "burn_no":
        trial.burn_worthless("alice", Outcome.NO, arg)  # type: ignore[arg-type]
    elif name == "close":
        trial.close_mint()
    elif name == "begin":
        trial.begin_resolution()
    elif name == "resolve_yes":
        trial.resolve("resolver", ResolutionResult.YES_WIN)
    elif name == "resolve_no":
        trial.resolve("resolver", ResolutionResult.NO_WIN)
    elif name == "resolve_invalid":
        trial.resolve("resolver", ResolutionResult.INVALID)
    elif name == "open":
        trial.open_redemption()
    elif name == "archive":
        trial.archive()
    else:
        raise AssertionError(name)


def search_reachable(*, max_unit: int = 3) -> dict[str, Any]:
    """Walk the integer model. Funding rejects are witnesses, not ordinary skips."""

    started = time.perf_counter()
    root = create_market(
        integer=True,
        collateral="COLL",
        dust_sink="SINK",
        max_amount=max_unit,
        position_cap=max_unit,
    )
    activate_binary(root, market_id="branches", resolver="resolver", spec_hash="branches")
    seen = {_key(root)}
    queue = [root]
    transitions = 0
    resolved_states = 0
    zero_supply_redeemable = 0
    archived_states = 0
    witness = ""
    witness_state: dict[str, str] = {}

    while queue and not witness:
        current = queue.pop()
        hit = _observe(current)
        if hit:
            witness = hit
            witness_state = _snapshot(current)
            break
        if current.state is MarketState.RESOLVED:
            resolved_states += 1
            if not (
                current.yes_supply == current.no_supply == current.collateral_locked
                and current.yes_redeemed == 0
                and current.no_redeemed == 0
            ):
                witness = "resolved state broke equal-supply assumption"
                witness_state = _snapshot(current)
                break
        if (
            current.state is MarketState.REDEEMABLE
            and current.yes_supply == 0
            and current.no_supply == 0
        ):
            zero_supply_redeemable += 1
        if current.state is MarketState.ARCHIVED:
            archived_states += 1
        actions: list[tuple[str, object]] = []
        for qty in range(1, max_unit + 1):
            actions.extend(
                [
                    ("split", qty),
                    ("merge", qty),
                    ("redeem_yes", qty),
                    ("redeem_no", qty),
                    ("burn_yes", qty),
                    ("burn_no", qty),
                ]
            )
        actions.extend(
            [
                ("close", None),
                ("begin", None),
                ("resolve_yes", None),
                ("resolve_no", None),
                ("resolve_invalid", None),
                ("open", None),
                ("archive", None),
            ]
        )
        for name, arg in actions:
            trial = current.clone()
            transitions += 1
            try:
                _apply(trial, name, arg)
            except PredictionError as exc:
                message = str(exc)
                if message in COUNTEREXAMPLE_ERRORS:
                    witness = f"{name}: {message}"
                    witness_state = _snapshot(trial)
                    break
                continue
            hit = _observe(trial)
            if hit:
                witness = f"{name}: {hit}"
                witness_state = _snapshot(trial)
                break
            key = _key(trial)
            if key not in seen:
                seen.add(key)
                queue.append(trial)
        if witness:
            break

    elapsed = time.perf_counter() - started
    return {
        "max_unit": max_unit,
        "states": len(seen),
        "transitions": transitions,
        "resolved_states": resolved_states,
        "zero_supply_redeemable": zero_supply_redeemable,
        "archived_states": archived_states,
        "witness": witness,
        "witness_state": witness_state,
        "runtime_seconds": round(elapsed, 6),
        "result": "COUNTEREXAMPLE_FOUND" if witness else "EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN",
    }


def classify(*, max_unit: int = 3) -> dict[str, Any]:
    symbolic = sympy_identities()
    domain = search_reachable(max_unit=max_unit)
    if domain["result"] == "COUNTEREXAMPLE_FOUND" or not symbolic["discharged"]:
        classification = "COUNTEREXAMPLE_FOUND"
    else:
        classification = "PROVEN_UNDER_ASSUMPTIONS"
    return {
        "classification": classification,
        "branches": ["Underfunded", "LiveLiability"],
        "numerators": {"YES_WIN": [2, 0], "NO_WIN": [0, 2], "INVALID": [1, 1], "denominator": 2},
        "assumptions": [
            "Quantities are non-negative integers.",
            "Split and merge are the only pre-resolution quantity changes, and they keep yesSupply = noSupply = collateralLocked with both redeemed cursors at 0.",
            "resolve sets exactly one of (2, 0), (0, 2), (1, 1) over denominator 2.",
            "openRedemption's funding check runs in RESOLVED, before any redeem or worthless burn.",
            "Redeem preserves each side's supply-plus-redeemed cursor. A worthless burn is allowed only when that side's numerator is 0, and it does not increase the redeemed cursor.",
            "archive evaluates LiveLiability only after both supplies are 0.",
            "A fee-on-transfer split reverts, so it does not create unequal supplies. There is no admin mint.",
        ],
        "argument": (
            "At openRedemption the redeemed cursors are 0 and both supplies equal collateral C. "
            "YES liability is C, NO liability is C, and INVALID liability is floor(C/2)+floor(C/2), "
            "which is C on even C and C-1 on odd C. SymPy simplifies those even and odd gaps to 0 and 1. "
            "At archive, YES liability reduces to the remaining YES supply and NO liability to the remaining NO supply, "
            "so both are 0 once the supplies are 0. INVALID cannot burn either side. Its two cursors stay equal to the "
            "resolution supply, and SymPy simplifies the four floor(y0/2) terms to 0 when both supplies have been redeemed."
        ),
        "sympy": symbolic,
        "domain_check": domain,
        "coverage_not_executed": True,
    }


def main() -> None:
    import json
    from pathlib import Path

    payload = classify()
    out = Path(__file__).resolve().parents[2] / "evidence" / "research" / "prediction" / "unreachable-branches-2026-09-26.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    print(f"wrote {out}")
    print(payload["classification"])
    domain = payload["domain_check"]
    print(
        f"domain states={domain['states']} transitions={domain['transitions']} "
        f"resolved={domain['resolved_states']} zero_supply={domain['zero_supply_redeemable']} "
        f"archived={domain['archived_states']} runtime={domain['runtime_seconds']}"
    )
    if domain["witness"]:
        print(f"witness {domain['witness']} {domain['witness_state']}")


if __name__ == "__main__":
    main()
