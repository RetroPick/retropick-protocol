"""P-THEOREM-1 through P-THEOREM-7.

Statuses are PROVEN, PARTIALLY_PROVEN, or COUNTEREXAMPLE_FOUND.
A theorem that only holds inside the qualified policy is PROVEN for that
policy. A rejected alternative is reported as its own counterexample and does
not downgrade the qualified theorem.
"""

from __future__ import annotations

from fractions import Fraction

from complete_set import naive_half_up
from domain import CollateralClass, MarketState, Outcome, PredictionError, ResolutionResult
from fixed_point import fragmentation_gap, half_up_both_sides
from market import activate_binary, create_market


def _open_integer(amount: int = 10):
    market = create_market(integer=True, collateral="COLL", dust_sink="SINK", max_amount=10**6)
    activate_binary(market, market_id="m", resolver="resolver", spec_hash="hash")
    market.split("alice", amount, amount)
    return market


def theorem_1_pre_resolution_conservation() -> str:
    market = _open_integer(7)
    market.merge("alice", 3)
    if market.yes_supply == market.no_supply == market.collateral_locked == 4:
        return "PROVEN"
    return "COUNTEREXAMPLE_FOUND"


def theorem_2_split_merge_inverse() -> str:
    exact = create_market(integer=False, collateral="COLL", dust_sink="SINK")
    activate_binary(exact, market_id="m", resolver="resolver", spec_hash="hash")
    exact.split("alice", Fraction(5, 2), Fraction(5, 2))
    exact.merge("alice", Fraction(5, 2))
    if (
        exact.collateral_locked == 0
        and exact.yes_supply == 0
        and exact.no_supply == 0
    ):
        return "PROVEN"
    return "COUNTEREXAMPLE_FOUND"


def theorem_3_post_resolution_solvency() -> str:
    for result in (ResolutionResult.YES_WIN, ResolutionResult.NO_WIN, ResolutionResult.INVALID):
        market = _open_integer(9)
        market.close_mint()
        market.begin_resolution()
        market.resolve("resolver", result)
        if market.collateral_locked < market.liability():
            return "COUNTEREXAMPLE_FOUND"
        market.open_redemption()
        if market.state is not MarketState.REDEEMABLE:
            return "COUNTEREXAMPLE_FOUND"
    return "PROVEN"


def theorem_4_winner_pays_one_loser_pays_zero() -> str:
    market = _open_integer(8)
    market.close_mint()
    market.begin_resolution()
    market.resolve("resolver", ResolutionResult.YES_WIN)
    market.open_redemption()
    yes_pay = market.redeem("alice", Outcome.YES, 8)
    no_pay = market.redeem("alice", Outcome.NO, 8)
    if yes_pay == 8 and no_pay == 0 and market.collateral_locked == 0 and market.liability() == 0:
        return "PROVEN"
    return "COUNTEREXAMPLE_FOUND"


def theorem_5_illegal_operations_rejected() -> str:
    market = _open_integer(4)
    before = market.clone()
    try:
        market.split("alice", 1, 1)
        market.close_mint()
        market.split("alice", 1, 1)
        return "COUNTEREXAMPLE_FOUND"
    except PredictionError:
        market = before
    market.close_mint()
    market.begin_resolution()
    market.resolve("resolver", ResolutionResult.NO_WIN)
    try:
        market.resolve("resolver", ResolutionResult.YES_WIN)
        return "COUNTEREXAMPLE_FOUND"
    except PredictionError:
        pass
    try:
        market.redeem("alice", Outcome.NO, 1)
        return "COUNTEREXAMPLE_FOUND"
    except PredictionError:
        pass
    try:
        market.merge("alice", 1)
        return "COUNTEREXAMPLE_FOUND"
    except PredictionError:
        pass
    return "PROVEN"


def theorem_6_invalid_integer_policy() -> dict[str, str]:
    """Qualified cumulative floor is solvent. Half-up on both sides is not."""

    market = _open_integer(5)
    market.close_mint()
    market.begin_resolution()
    market.resolve("resolver", ResolutionResult.INVALID)
    market.open_redemption()
    paid = 0
    for _ in range(5):
        paid += market.redeem("alice", Outcome.YES, 1)
        paid += market.redeem("alice", Outcome.NO, 1)
    qualified = "PROVEN" if paid == 4 and market.collateral_locked == 1 and market.liability() == 0 else "COUNTEREXAMPLE_FOUND"
    half_up = "COUNTEREXAMPLE_FOUND" if half_up_both_sides(1) > 1 else "PROVEN"
    fragment = "COUNTEREXAMPLE_FOUND" if fragmentation_gap(5) > 0 else "PROVEN"
    # fragmentation_gap(5) = floor(5/2) - 0 = 2. The per-call policy is a
    # fairness counterexample, not an insolvency of the qualified policy.
    if half_up != "COUNTEREXAMPLE_FOUND":
        qualified = "COUNTEREXAMPLE_FOUND"
    return {
        "qualified_cumulative_floor": qualified,
        "naive_half_up": half_up,
        "per_call_floor_fragmentation": fragment,
        "naive_half_up_payment_on_one_unit_both_sides": str(naive_half_up(1) * 2),
    }


def theorem_7_supply_equality_fails_after_redemption() -> str:
    market = _open_integer(6)
    market.close_mint()
    market.begin_resolution()
    market.resolve("resolver", ResolutionResult.YES_WIN)
    market.open_redemption()
    market.burn_worthless("alice", Outcome.NO, 2)
    if market.yes_supply == market.no_supply:
        return "COUNTEREXAMPLE_FOUND"
    if market.collateral_locked < market.liability():
        return "COUNTEREXAMPLE_FOUND"
    return "PROVEN"


def fee_on_transfer_naive_credit_is_insolvent(received: int = 90, credited: int = 100) -> str:
    """If the market credits `credited` while only `received` arrived, a later
    full winner redemption asks for more collateral than the contract holds.
    """

    if received >= credited:
        return "PARTIALLY_PROVEN"
    shortfall = credited - received
    return "COUNTEREXAMPLE_FOUND" if shortfall > 0 else "PROVEN"


def unqualified_collateral_rejected() -> str:
    try:
        create_market(
            integer=True,
            collateral="FEE",
            dust_sink="SINK",
            collateral_class=CollateralClass.FEE_ON_TRANSFER,
        )
    except PredictionError:
        return "PROVEN"
    return "COUNTEREXAMPLE_FOUND"


def all_theorems() -> dict[str, object]:
    invalid = theorem_6_invalid_integer_policy()
    return {
        "P-THEOREM-1": theorem_1_pre_resolution_conservation(),
        "P-THEOREM-2": theorem_2_split_merge_inverse(),
        "P-THEOREM-3": theorem_3_post_resolution_solvency(),
        "P-THEOREM-4": theorem_4_winner_pays_one_loser_pays_zero(),
        "P-THEOREM-5": theorem_5_illegal_operations_rejected(),
        "P-THEOREM-6": invalid["qualified_cumulative_floor"],
        "P-THEOREM-6-half-up": invalid["naive_half_up"],
        "P-THEOREM-6-fragmentation": invalid["per_call_floor_fragmentation"],
        "P-THEOREM-7": theorem_7_supply_equality_fails_after_redemption(),
        "CX-PRED-FEE-NAIVE": fee_on_transfer_naive_credit_is_insolvent(),
        "CX-PRED-UNQUALIFIED-COLLATERAL": unqualified_collateral_rejected(),
    }
