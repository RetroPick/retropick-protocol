"""Shared types for the prediction reference model.

Amounts in the exact model are :class:`fractions.Fraction`.
Amounts in the integer model are non-negative Python ``int`` values standing
for raw token units. JSON fixtures encode both as decimal strings.
"""

from __future__ import annotations

from enum import Enum
from fractions import Fraction
from typing import Union


Amount = Union[int, Fraction]


class MarketState(str, Enum):
    DRAFT = "DRAFT"
    OPEN = "OPEN"
    LOCKED = "LOCKED"
    RESOLUTION_PENDING = "RESOLUTION_PENDING"
    RESOLVED = "RESOLVED"
    REDEEMABLE = "REDEEMABLE"
    ARCHIVED = "ARCHIVED"


# Task-program names recorded as aliases. They are not a rename of the
# canonical machine in docs/prism/protocol/STATE_MACHINE.md.
STATE_ALIASES = {
    "ACTIVE": MarketState.OPEN,
    "MINT_CLOSED": MarketState.LOCKED,
}


class Outcome(str, Enum):
    YES = "YES"
    NO = "NO"


class ResolutionResult(str, Enum):
    YES_WIN = "YES_WIN"
    NO_WIN = "NO_WIN"
    INVALID = "INVALID"


class CollateralClass(str, Enum):
    """Phase-1 admission class for the collateral token.

    Only STANDARD is qualified. The other classes exist so tests can show the
    failure mode instead of silently supporting it.
    """

    STANDARD = "STANDARD"
    FEE_ON_TRANSFER = "FEE_ON_TRANSFER"
    REBASING = "REBASING"
    ERC777 = "ERC777"
    FALSE_RETURN = "FALSE_RETURN"


class PredictionError(ValueError):
    """Rejected prediction-market operation. State must be unchanged."""


def as_amount(value: Amount, *, integer: bool) -> Amount:
    if integer:
        if isinstance(value, bool) or not isinstance(value, int):
            raise PredictionError("integer model requires an int amount")
        if value < 0:
            raise PredictionError("amount must be non-negative")
        return value
    if isinstance(value, Fraction):
        amount = value
    else:
        amount = Fraction(value)
    if amount < 0:
        raise PredictionError("amount must be non-negative")
    return amount


def amount_to_str(value: Amount) -> str:
    if isinstance(value, Fraction):
        return f"{value.numerator}/{value.denominator}" if value.denominator != 1 else str(value.numerator)
    return str(value)
