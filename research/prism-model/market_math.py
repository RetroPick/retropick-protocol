"""Exact market-math helpers for RetroPick/PRISM Phase 1.

These functions model accounting identities and executable-value relations.
They do NOT assert that real exchange prices instantly converge to theoretical values.
"""
from __future__ import annotations

from fractions import Fraction
from typing import Mapping, Sequence

from replication import F


class MarketMathError(ValueError):
    pass


def _nonnegative(value, name: str) -> Fraction:
    v = F(value)
    if v < 0:
        raise MarketMathError(f"{name} must be non-negative")
    return v


def _vector(values: Sequence, name: str) -> tuple[Fraction, ...]:
    out = tuple(F(v) for v in values)
    if not out:
        raise MarketMathError(f"{name} must be non-empty")
    if any(v < 0 for v in out):
        raise MarketMathError(f"{name} must be non-negative")
    return out


def dot_nonnegative(weights: Sequence, values: Sequence) -> Fraction:
    """Exact dot product for non-negative Phase-1 economic vectors."""
    x = _vector(weights, "weights")
    p = _vector(values, "values")
    if len(x) != len(p):
        raise MarketMathError("vector dimension mismatch")
    return sum((x[i] * p[i] for i in range(len(x))), Fraction(0))


# ---------------------------------------------------------------------------
# Native binary complete-set accounting
# ---------------------------------------------------------------------------


def assert_complete_set_conservation(
    yes_supply,
    no_supply,
    collateral_locked,
) -> bool:
    """Require the canonical fully-collateralized binary complete-set relation.

    In the simple Phase-1 model, every collateral unit split creates exactly one
    YES and one NO, and merge burns one of each. Therefore live complete-set
    supply and locked collateral remain equal.
    """
    y = _nonnegative(yes_supply, "yes_supply")
    n = _nonnegative(no_supply, "no_supply")
    c = _nonnegative(collateral_locked, "collateral_locked")
    if not (y == n == c):
        raise MarketMathError(
            "complete-set conservation violated: expected YES == NO == collateral"
        )
    return True


def complete_set_open_interest(yes_supply, no_supply, collateral_locked=None) -> Fraction:
    """Return economic open interest for the canonical fully collateralized market.

    This intentionally does not return YES + NO, which double-counts a complete
    set. If collateral is supplied, conservation is checked explicitly.
    """
    y = _nonnegative(yes_supply, "yes_supply")
    n = _nonnegative(no_supply, "no_supply")
    if collateral_locked is None:
        if y != n:
            raise MarketMathError("YES and NO supply diverged")
        return y
    c = _nonnegative(collateral_locked, "collateral_locked")
    assert_complete_set_conservation(y, n, c)
    return c


def split_and_sell_profit(
    bid_yes,
    bid_no,
    *,
    collateral_unit=1,
    total_cost=0,
) -> Fraction:
    """Executable gross/net profit from split collateral then sell YES+NO at bids."""
    by = _nonnegative(bid_yes, "bid_yes")
    bn = _nonnegative(bid_no, "bid_no")
    c = _nonnegative(collateral_unit, "collateral_unit")
    cost = _nonnegative(total_cost, "total_cost")
    return by + bn - c - cost


def buy_and_merge_profit(
    ask_yes,
    ask_no,
    *,
    collateral_unit=1,
    total_cost=0,
) -> Fraction:
    """Executable gross/net profit from buy YES+NO at asks then merge to collateral."""
    ay = _nonnegative(ask_yes, "ask_yes")
    an = _nonnegative(ask_no, "ask_no")
    c = _nonnegative(collateral_unit, "collateral_unit")
    cost = _nonnegative(total_cost, "total_cost")
    return c - ay - an - cost


# ---------------------------------------------------------------------------
# PRISM executable create/redeem value
# ---------------------------------------------------------------------------


def prism_create_cost(weights: Sequence, asks: Sequence, *, fees=0) -> Fraction:
    """Executable component acquisition cost for one PRISM unit."""
    fee = _nonnegative(fees, "fees")
    return dot_nonnegative(weights, asks) + fee


def prism_redeem_value(weights: Sequence, bids: Sequence, *, fees=0) -> Fraction:
    """Executable sale value after in-kind redemption of one PRISM unit."""
    fee = _nonnegative(fees, "fees")
    value = dot_nonnegative(weights, bids) - fee
    return value


def prism_practical_band(
    weights: Sequence,
    bids: Sequence,
    asks: Sequence,
    *,
    redeem_fees=0,
    create_fees=0,
    redeem_risk=0,
    create_risk=0,
) -> tuple[Fraction, Fraction]:
    """Return a practical create/redeem reference band.

    lower = executable redeem value - redeem-side risk allowance
    upper = executable creation cost + create-side risk allowance

    This is a reference relation, not a protocol-enforced price interval.
    """
    rd = prism_redeem_value(weights, bids, fees=redeem_fees)
    cc = prism_create_cost(weights, asks, fees=create_fees)
    rr = _nonnegative(redeem_risk, "redeem_risk")
    cr = _nonnegative(create_risk, "create_risk")
    return rd - rr, cc + cr


# ---------------------------------------------------------------------------
# Resolution valuation identities
# ---------------------------------------------------------------------------


def partial_resolution_nav(
    weights: Sequence,
    *,
    resolved: Mapping[int, object],
    unresolved_marks: Mapping[int, object],
) -> Fraction:
    """Value a basket when some components have fixed terminal values.

    Every component index must appear exactly once in either `resolved` or
    `unresolved_marks`.
    """
    x = _vector(weights, "weights")
    expected = set(range(len(x)))
    r_keys = set(resolved.keys())
    u_keys = set(unresolved_marks.keys())
    if r_keys & u_keys:
        raise MarketMathError("component cannot be both resolved and unresolved")
    if r_keys | u_keys != expected:
        raise MarketMathError("resolved/unresolved maps must cover every component")

    total = Fraction(0)
    for i, w in enumerate(x):
        raw = resolved[i] if i in resolved else unresolved_marks[i]
        v = _nonnegative(raw, f"component_value[{i}]")
        total += w * v
    return total


def post_resolution_pair_value(final_payout, quote_usd_price) -> Fraction:
    """Idealized resolved PRISM/quote exchange ratio before fees/risk.

    If one PRISM redeems for R USD-like settlement units and one quote token is
    worth Q USD, the relative value is R/Q quote tokens.
    """
    r = _nonnegative(final_payout, "final_payout")
    q = F(quote_usd_price)
    if q <= 0:
        raise MarketMathError("quote_usd_price must be positive")
    return r / q
