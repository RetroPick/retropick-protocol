"""Terminal liability and settlement helpers."""
from fractions import Fraction
from typing import Sequence

from replication import F, payoff


class SettlementError(ValueError):
    pass


def terminal_backing_value(
    backing: Sequence, component_payoffs_for_state: Sequence
) -> Fraction:
    if len(backing) != len(component_payoffs_for_state):
        raise SettlementError("dimension mismatch")
    values = [F(v) for v in backing]
    payouts = [F(v) for v in component_payoffs_for_state]
    if any(v < 0 for v in values + payouts):
        raise SettlementError("negative backing/payoff unsupported in Phase 1")
    return sum(b * p for b, p in zip(values, payouts))


def terminal_liability(supply, payout_per_share) -> Fraction:
    s, r = F(supply), F(payout_per_share)
    if s < 0 or r < 0:
        raise SettlementError("negative supply/payout unsupported")
    return s * r


def settlement_is_funded(balance, supply, payout_per_share) -> bool:
    return F(balance) >= terminal_liability(supply, payout_per_share)
