"""Pure complete-set accounting helpers."""

from __future__ import annotations

from fractions import Fraction

from resolution import denominator, payout_numerators
from domain import Amount, Outcome, PredictionError, ResolutionResult


def liability_pre_resolution(collateral_locked: Amount) -> Amount:
    return collateral_locked


def exact_payout(result: ResolutionResult, side: Outcome, quantity: Fraction) -> Fraction:
    yes_num, no_num = payout_numerators(result)
    num = yes_num if side is Outcome.YES else no_num
    return quantity * Fraction(num, denominator())


def integer_payout_delta(redeemed_before: int, quantity: int, numerator: int, den: int) -> int:
    """Cumulative floor payout for one redemption.

    Total paid after redeeming ``R`` units is ``floor(R * numerator / den)``.
    This redemption pays the difference of those floors. For numerator/den in
    {0/2, 2/2, 1/2} the total paid across a side never exceeds
    ``floor(supply * numerator / den)``.
    """

    if redeemed_before < 0 or quantity < 0:
        raise PredictionError("redemption cursor and quantity must be non-negative")
    if quantity == 0:
        return 0
    if numerator < 0 or den <= 0:
        raise PredictionError("payout fraction must be non-negative")
    before = (redeemed_before * numerator) // den
    after = ((redeemed_before + quantity) * numerator) // den
    return after - before


def integer_side_obligation(supply_at_resolution: int, numerator: int, den: int = 2) -> int:
    return (supply_at_resolution * numerator) // den


def naive_half_up(quantity: int) -> int:
    """ceil(q/2). Insolvent if both outcome sides use it on an odd unit."""

    if quantity < 0:
        raise PredictionError("quantity must be non-negative")
    return (quantity + 1) // 2


def per_call_floor_half(quantity: int) -> int:
    if quantity < 0:
        raise PredictionError("quantity must be non-negative")
    return quantity // 2
