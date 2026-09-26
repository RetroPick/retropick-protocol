"""Adversarial sequences for the prediction reference model.

Each case either rejects with unchanged state or records a named counterexample
of an unqualified policy. Qualified Phase-1 behavior must not pay an attacker.
"""

from __future__ import annotations

from domain import CollateralClass, MarketState, Outcome, PredictionError, ResolutionResult
from market import PredictionMarket, activate_binary, create_market


def _fresh(amount: int = 10) -> PredictionMarket:
    market = create_market(integer=True, collateral="COLL", dust_sink="SINK", max_amount=10**9)
    activate_binary(market, market_id="m1", resolver="resolver", spec_hash="spec-1")
    market.split("alice", amount, amount)
    return market


def _rejects(market: PredictionMarket, fn) -> bool:
    snap = (
        market.state,
        market.collateral_locked,
        market.yes_supply,
        market.no_supply,
        market.result,
    )
    try:
        fn()
    except PredictionError:
        now = (
            market.state,
            market.collateral_locked,
            market.yes_supply,
            market.no_supply,
            market.result,
        )
        return now == snap
    return False


def run_sequences() -> dict[str, str]:
    results: dict[str, str] = {}

    market = _fresh()
    results["split_zero"] = "REJECTED" if _rejects(market, lambda: market.split("alice", 0, 0)) else "FAIL"
    results["split_max"] = (
        "REJECTED" if _rejects(market, lambda: market.split("alice", 2**256, 2**256)) else "FAIL"
    )

    market.close_mint()
    results["split_after_close"] = (
        "REJECTED" if _rejects(market, lambda: market.split("alice", 1, 1)) else "FAIL"
    )
    results["merge_unequal"] = (
        "REJECTED" if _rejects(market, lambda: market.merge("bob", 1)) else "FAIL"
    )

    market.begin_resolution()
    market.resolve("resolver", ResolutionResult.YES_WIN)
    results["merge_after_resolution"] = (
        "REJECTED" if _rejects(market, lambda: market.merge("alice", 1)) else "FAIL"
    )
    results["double_resolve"] = (
        "REJECTED"
        if _rejects(market, lambda: market.resolve("resolver", ResolutionResult.NO_WIN))
        else "FAIL"
    )
    results["redeem_before_open"] = (
        "REJECTED" if _rejects(market, lambda: market.redeem("alice", Outcome.YES, 1)) else "FAIL"
    )
    results["wrong_resolver"] = (
        "REJECTED"
        if _rejects(market, lambda: market.resolve("other", ResolutionResult.YES_WIN))
        else "FAIL"
    )

    market.open_redemption()
    first = market.redeem("alice", Outcome.YES, 4)
    results["double_redeem_same_balance"] = (
        "REJECTED" if first == 4 and _rejects(market, lambda: market.redeem("alice", Outcome.YES, 10)) else "FAIL"
    )
    loser = market.redeem("alice", Outcome.NO, 3)
    results["redeem_loser"] = "PAYS_ZERO" if loser == 0 else "FAIL"
    results["admin_mint"] = "REJECTED" if _rejects(market, lambda: market.admin_mint("alice", Outcome.YES, 1)) else "FAIL"
    results["admin_withdraw"] = "REJECTED" if _rejects(market, lambda: market.admin_withdraw(1)) else "FAIL"
    results["pause_during_redemption"] = (
        "REJECTED" if _rejects(market, lambda: market.pause_redemption()) else "FAIL"
    )
    results["spec_replace"] = (
        "REJECTED"
        if _rejects(
            market,
            lambda: market.try_replace_spec(market.spec),  # type: ignore[arg-type]
        )
        else "FAIL"
    )

    short = create_market(integer=True, collateral="COLL", dust_sink="SINK")
    activate_binary(short, market_id="m2", resolver="resolver", spec_hash="spec-2")
    results["fee_on_transfer_shortfall"] = (
        "REJECTED" if _rejects(short, lambda: short.split("alice", 100, 99)) else "FAIL"
    )

    def reenter(live: PredictionMarket) -> None:
        live.split("alice", 1, 1)

    results["reentrancy_during_split"] = (
        "REJECTED" if _rejects(short, lambda: short.split("alice", 5, 5, hook=reenter)) else "FAIL"
    )

    try:
        create_market(
            integer=True,
            collateral="REB",
            dust_sink="SINK",
            collateral_class=CollateralClass.REBASING,
        )
        results["rebasing_collateral"] = "FAIL"
    except PredictionError:
        results["rebasing_collateral"] = "REJECTED"

    for klass in (CollateralClass.ERC777, CollateralClass.FALSE_RETURN, CollateralClass.FEE_ON_TRANSFER):
        try:
            create_market(integer=True, collateral="X", dust_sink="SINK", collateral_class=klass)
            results[f"class_{klass.value}"] = "FAIL"
        except PredictionError:
            results[f"class_{klass.value}"] = "REJECTED"

    invalid = _fresh(5)
    invalid.close_mint()
    invalid.begin_resolution()
    invalid.resolve("resolver", ResolutionResult.INVALID)
    invalid.open_redemption()
    paid = 0
    for _ in range(5):
        paid += invalid.redeem("alice", Outcome.YES, 1)
    results["invalid_dust_yes_side"] = "BOUNDED" if paid == 2 and invalid.collateral_locked == 3 else "FAIL"
    results["invalid_burn_rejected"] = (
        "REJECTED" if _rejects(invalid, lambda: invalid.burn_worthless("alice", Outcome.NO, 1)) else "FAIL"
    )

    wrong = _fresh(2)
    results["state_is_open_alias_domain"] = "OPEN" if wrong.state is MarketState.OPEN else "FAIL"
    return results
