"""Payoff-equivalent partial backing transform.

Research candidate. This is not an accepted oracle, not MATH-1 PASS, and not
CONTRACT-1. It does not move prediction tokens.

A resolved component may be replaced by settlement cash only when every
remaining feasible terminal state has the same backing value before and after,
weights stay non-negative, and supply is unchanged. A portfolio that misses
that equality is rejected.
"""

from __future__ import annotations

from fractions import Fraction
from typing import Sequence

from model import ModelError, PrismSeries
from replication import F, normalize_matrix


class PartialResolutionError(ValueError):
    pass


def terminal_backing_value(backing: Sequence, cash, row: Sequence) -> Fraction:
    total = F(cash)
    if len(backing) != len(row):
        raise PartialResolutionError("backing dimension mismatch")
    for amount, payoff in zip(backing, row):
        total += F(amount) * F(payoff)
    return total


def portfolio_preserves(
    matrix: Sequence[Sequence],
    old_backing: Sequence,
    old_cash,
    new_backing: Sequence,
    new_cash,
    remaining_states: Sequence[int],
) -> bool:
    rows = normalize_matrix(matrix)
    states = list(remaining_states)
    if not states:
        return False
    for state in states:
        if state < 0 or state >= len(rows):
            raise PartialResolutionError("terminal state out of range")
        old_value = terminal_backing_value(old_backing, old_cash, rows[state])
        new_value = terminal_backing_value(new_backing, new_cash, rows[state])
        if old_value != new_value:
            return False
    return True


def prospective_transform(
    matrix: Sequence[Sequence],
    backing: Sequence,
    cash,
    possible_states: Sequence[int],
    component_index: int,
    payout,
    weights: Sequence,
) -> dict:
    rows = normalize_matrix(matrix)
    held = [F(value) for value in backing]
    if len(held) != len(rows[0]):
        raise PartialResolutionError("backing dimension mismatch")
    if any(F(weight) < 0 for weight in weights):
        raise PartialResolutionError("negative weight")
    if len(weights) != len(held):
        raise PartialResolutionError("weight dimension mismatch")
    index = int(component_index)
    if index < 0 or index >= len(held):
        raise PartialResolutionError("invalid component index")
    resolved_payout = F(payout)
    if resolved_payout < 0:
        raise PartialResolutionError("negative resolved payout")
    remaining = {
        int(state)
        for state in possible_states
        if rows[int(state)][index] == resolved_payout
    }
    if not remaining:
        raise PartialResolutionError("component payout inconsistent with remaining terminal states")
    new_backing = list(held)
    cash_added = new_backing[index] * resolved_payout
    new_backing[index] = Fraction(0)
    new_cash = F(cash) + cash_added
    if not portfolio_preserves(rows, held, cash, new_backing, new_cash, sorted(remaining)):
        raise PartialResolutionError("transform changes payoff on a remaining state")
    return {
        "backing": new_backing,
        "cash": new_cash,
        "remaining": remaining,
        "cash_added": cash_added,
        "weights": tuple(F(weight) for weight in weights),
    }


def apply_transform(series: PrismSeries, component_index: int, payout) -> dict:
    """Apply the existing series transform after the equivalence check.

    `resolve_component` remains the mutation. A disagreement between that
    mutation and the checked portfolio is COUNTEREXAMPLE_FOUND.
    """

    if int(component_index) in series.resolved_components:
        raise PartialResolutionError("component already resolved")
    supply_before = series.supply
    weights_before = tuple(series.weights)
    planned = prospective_transform(
        series.payoff_matrix,
        series.backing,
        series.transformed_settlement,
        series.possible_states,
        component_index,
        payout,
        series.weights,
    )
    try:
        cash = series.resolve_component(component_index, payout)
    except ModelError as exc:
        raise PartialResolutionError(str(exc)) from exc
    if cash != planned["cash_added"]:
        raise PartialResolutionError(
            f"COUNTEREXAMPLE_FOUND: resolve_component cash {cash} != planned {planned['cash_added']}"
        )
    if [F(value) for value in series.backing] != planned["backing"]:
        raise PartialResolutionError("COUNTEREXAMPLE_FOUND: resolve_component backing disagrees")
    if set(series.possible_states) != planned["remaining"]:
        raise PartialResolutionError("COUNTEREXAMPLE_FOUND: resolve_component states disagree")
    if series.transformed_settlement != planned["cash"]:
        raise PartialResolutionError("COUNTEREXAMPLE_FOUND: transformed settlement disagrees")
    if series.supply != supply_before:
        raise PartialResolutionError("COUNTEREXAMPLE_FOUND: transform changed supply")
    if tuple(series.weights) != weights_before or any(weight < 0 for weight in series.weights):
        raise PartialResolutionError("COUNTEREXAMPLE_FOUND: weights changed")
    return planned


def mismatched_portfolio(series: PrismSeries, intended_index: int, payout) -> dict:
    """Negative control: remove a different component than the one that resolved.

    The cash credit still uses the intended component. Remaining states are the
    states consistent with that component's payout. The resulting portfolio is
    not payoff-equivalent.
    """

    index = int(intended_index)
    if index < 0 or index >= len(series.backing):
        raise PartialResolutionError("invalid component index")
    wrong = 0 if index != 0 else 1
    if wrong >= len(series.backing):
        raise PartialResolutionError("series needs two components for this control")
    resolved_payout = F(payout)
    remaining = [
        state
        for state in sorted(series.possible_states)
        if series.payoff_matrix[state][index] == resolved_payout
    ]
    new_backing = [F(value) for value in series.backing]
    cash_added = new_backing[index] * resolved_payout
    new_backing[wrong] = Fraction(0)
    new_cash = series.transformed_settlement + cash_added
    equivalent = portfolio_preserves(
        series.payoff_matrix,
        series.backing,
        series.transformed_settlement,
        new_backing,
        new_cash,
        remaining,
    )
    return {
        "wrong_index": wrong,
        "intended_index": index,
        "payout": resolved_payout,
        "remaining": remaining,
        "old_backing": [F(value) for value in series.backing],
        "old_cash": series.transformed_settlement,
        "new_backing": new_backing,
        "new_cash": new_cash,
        "equivalent": equivalent,
    }
