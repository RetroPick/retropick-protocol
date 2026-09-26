"""Canonical native-market lifecycle.

Names follow docs/prism/protocol/STATE_MACHINE.md:
DRAFT, OPEN, LOCKED, RESOLUTION_PENDING, RESOLVED, REDEEMABLE, ARCHIVED.

OPEN is the task-program's ACTIVE. LOCKED is the task-program's MINT_CLOSED.
"""

from __future__ import annotations

from domain import STATE_ALIASES, MarketState, PredictionError


_ALLOWED: dict[MarketState, frozenset[MarketState]] = {
    MarketState.DRAFT: frozenset({MarketState.OPEN, MarketState.ARCHIVED}),
    MarketState.OPEN: frozenset({MarketState.LOCKED}),
    MarketState.LOCKED: frozenset({MarketState.RESOLUTION_PENDING}),
    MarketState.RESOLUTION_PENDING: frozenset({MarketState.RESOLVED}),
    MarketState.RESOLVED: frozenset({MarketState.REDEEMABLE}),
    MarketState.REDEEMABLE: frozenset({MarketState.ARCHIVED}),
    MarketState.ARCHIVED: frozenset(),
}


def resolve_state_name(name: str) -> MarketState:
    if name in STATE_ALIASES:
        return STATE_ALIASES[name]
    try:
        return MarketState(name)
    except ValueError as exc:
        raise PredictionError(f"unknown state {name}") from exc


def can_transition(current: MarketState, target: MarketState) -> bool:
    return target in _ALLOWED[current]


def transition(current: MarketState, target: MarketState) -> MarketState:
    if not can_transition(current, target):
        raise PredictionError(f"illegal transition {current.value} -> {target.value}")
    return target


def split_allowed(state: MarketState) -> bool:
    return state is MarketState.OPEN


def merge_allowed(state: MarketState) -> bool:
    return state in (MarketState.OPEN, MarketState.LOCKED)


def redeem_allowed(state: MarketState) -> bool:
    return state is MarketState.REDEEMABLE
