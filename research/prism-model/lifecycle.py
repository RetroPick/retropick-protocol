"""Canonical PRISM lifecycle state machine."""
from enum import Enum


class LifecycleError(ValueError):
    pass


class SeriesState(str, Enum):
    DRAFT = "DRAFT"
    ACTIVE = "ACTIVE"
    MINT_PAUSED = "MINT_PAUSED"
    RESOLUTION_PENDING = "RESOLUTION_PENDING"
    RESOLVED = "RESOLVED"
    REDEEMABLE = "REDEEMABLE"
    ARCHIVED = "ARCHIVED"


_ALLOWED = {
    SeriesState.DRAFT: {SeriesState.ACTIVE},
    SeriesState.ACTIVE: {
        SeriesState.MINT_PAUSED,
        SeriesState.RESOLUTION_PENDING,
    },
    SeriesState.MINT_PAUSED: {SeriesState.RESOLUTION_PENDING},
    SeriesState.RESOLUTION_PENDING: {SeriesState.RESOLVED},
    SeriesState.RESOLVED: {SeriesState.REDEEMABLE},
    SeriesState.REDEEMABLE: {SeriesState.ARCHIVED},
    SeriesState.ARCHIVED: set(),
}


def can_transition(current: SeriesState, target: SeriesState) -> bool:
    return target in _ALLOWED[current]


def transition(current: SeriesState, target: SeriesState) -> SeriesState:
    if not can_transition(current, target):
        raise LifecycleError(f"illegal transition: {current.value} -> {target.value}")
    return target
