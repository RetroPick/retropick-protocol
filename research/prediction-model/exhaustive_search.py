"""Bounded exhaustive exploration of the integer prediction state machine."""

from __future__ import annotations

import time

from domain import MarketState, Outcome, PredictionError, ResolutionResult
from market import PredictionMarket, activate_binary, create_market


def _key(market: PredictionMarket) -> tuple:
    alice = market.balances.get("alice", {Outcome.YES: 0, Outcome.NO: 0})
    return (
        market.state.value,
        market.collateral_locked,
        market.yes_supply,
        market.no_supply,
        alice[Outcome.YES],
        alice[Outcome.NO],
        None if market.result is None else market.result.value,
        market.yes_redeemed,
        market.no_redeemed,
        market.residual_to_sink,
    )


def explore(*, max_unit: int = 3, seed_supply: int = 0) -> dict[str, int | float | str]:
    start = time.perf_counter()
    root = create_market(
        integer=True,
        collateral="COLL",
        dust_sink="SINK",
        max_amount=max_unit,
        position_cap=max_unit,
    )
    activate_binary(root, market_id="ex", resolver="resolver", spec_hash="ex-hash")
    if seed_supply:
        root.split("alice", seed_supply, seed_supply)

    seen = {_key(root)}
    queue = [root]
    transitions = 0
    failures = 0
    counterexample = ""

    def enqueue(market: PredictionMarket) -> None:
        nonlocal transitions
        transitions += 1
        key = _key(market)
        if key not in seen:
            seen.add(key)
            queue.append(market)

    while queue:
        current = queue.pop()
        actions: list[tuple[str, object]] = []
        for qty in range(1, max_unit + 1):
            actions.append(("split", qty))
            actions.append(("merge", qty))
            actions.append(("redeem_yes", qty))
            actions.append(("redeem_no", qty))
            actions.append(("burn_yes", qty))
            actions.append(("burn_no", qty))
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
            try:
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
            except PredictionError:
                continue
            except Exception as exc:  # pragma: no cover - invariant bugs surface here
                failures += 1
                counterexample = f"{name}:{exc}"
                break
            if trial.collateral_locked < trial.liability():
                failures += 1
                counterexample = f"{name}:underfunded"
                break
            enqueue(trial)
        if failures:
            break

    elapsed = time.perf_counter() - start
    return {
        "max_unit": max_unit,
        "seed_supply": seed_supply,
        "states": len(seen),
        "transitions": transitions,
        "failures": failures,
        "counterexample": counterexample,
        "runtime_seconds": round(elapsed, 6),
        "result": "EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN" if failures == 0 else "COUNTEREXAMPLE_FOUND",
        "terminal_archived": sum(1 for key in seen if key[0] == MarketState.ARCHIVED.value),
    }
