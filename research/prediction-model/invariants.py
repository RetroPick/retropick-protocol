"""P-I01 through P-I10 checks against a market snapshot."""

from __future__ import annotations

from fractions import Fraction

from lifecycle import MarketState
from resolution import denominator, payout_numerators
from domain import Outcome, PredictionError


def _non_negative(value) -> bool:
    return value >= 0


def check_p_i01(market) -> None:
    if not _non_negative(market.collateral_locked):
        raise PredictionError("P-I01 collateral negative")
    if not _non_negative(market.yes_supply) or not _non_negative(market.no_supply):
        raise PredictionError("P-I01 supply negative")
    for balances in market.balances.values():
        if not _non_negative(balances[Outcome.YES]) or not _non_negative(balances[Outcome.NO]):
            raise PredictionError("P-I01 balance negative")
    yes_balances = sum((balances[Outcome.YES] for balances in market.balances.values()), market.zero)
    no_balances = sum((balances[Outcome.NO] for balances in market.balances.values()), market.zero)
    if yes_balances != market.yes_supply or no_balances != market.no_supply:
        raise PredictionError("P-I01 supply does not match balances")


def check_p_i02(market) -> None:
    if market.state in (MarketState.OPEN, MarketState.LOCKED, MarketState.RESOLUTION_PENDING):
        if not (market.yes_supply == market.no_supply == market.collateral_locked):
            raise PredictionError("P-I02 pre-resolution conservation failed")


def check_p_i05(market) -> None:
    if market.cancel_reason == "CANCELLED_BEFORE_ACTIVATION":
        if market.state is not MarketState.ARCHIVED or market.spec is not None:
            raise PredictionError("P-I05 cancelled draft must stay spec-free and archived")
    elif market.state is not MarketState.DRAFT:
        if market.spec is None or market.spec_hash_frozen != market.spec.spec_hash:
            raise PredictionError("P-I05 resolution spec mutated or missing")


def check_p_i06(market) -> None:
    if market.resolved_once and market.result is None:
        raise PredictionError("P-I06 resolved flag without result")
    if market.result is not None and market.state in (
        MarketState.DRAFT,
        MarketState.OPEN,
        MarketState.LOCKED,
        MarketState.RESOLUTION_PENDING,
    ):
        raise PredictionError("P-I06 result committed before resolution")


def check_p_i08(market) -> None:
    if market.collateral_locked < market.liability():
        raise PredictionError("P-I08 collateral below liability")


def check_p_i10(market) -> None:
    if market.state is MarketState.ARCHIVED and (market.yes_supply != market.zero or market.no_supply != market.zero):
        raise PredictionError("P-I10 archived with live supply")


def check_market(market) -> None:
    """Raise PredictionError if any Phase-1 snapshot invariant fails."""

    check_p_i01(market)
    check_p_i02(market)
    check_p_i05(market)
    check_p_i06(market)
    check_p_i08(market)
    check_p_i10(market)

    if market.result is not None and market.integer:
        yes_num, no_num = payout_numerators(market.result)
        den = denominator()
        y0 = market.yes_supply + market.yes_redeemed
        n0 = market.no_supply + market.no_redeemed
        paid = ((market.yes_redeemed * yes_num) // den) + ((market.no_redeemed * no_num) // den)
        obligation = ((y0 * yes_num) // den) + ((n0 * no_num) // den)
        if market.collateral_at_resolution - paid != market.collateral_locked + market.residual_to_sink:
            raise PredictionError("P-I08 integer collateral cursor diverged")
        if obligation - paid != market.liability():
            raise PredictionError("P-I08 integer liability cursor diverged")
        if isinstance(market.collateral_locked, Fraction):
            raise PredictionError("integer market stored a fraction")
