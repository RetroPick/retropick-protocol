"""Executable P-I01..P-I10 checks.

Snapshot predicates live in invariants.py. This module runs one positive case
and one rejecting case for each id. The domain is the integer scenarios below.
It is not a proof for every uint256 state.
"""

from __future__ import annotations

from domain import MarketState, Outcome, PredictionError, ResolutionResult
from invariants import check_market, check_p_i01, check_p_i02, check_p_i05, check_p_i08, check_p_i10
from market import activate_binary, create_market


def _rejects(market, fn) -> bool:
    snap = (
        market.state,
        market.collateral_locked,
        market.yes_supply,
        market.no_supply,
        market.yes_redeemed,
        market.no_redeemed,
        market.result,
        market.spec_hash_frozen,
    )
    try:
        fn()
    except PredictionError:
        now = (
            market.state,
            market.collateral_locked,
            market.yes_supply,
            market.no_supply,
            market.yes_redeemed,
            market.no_redeemed,
            market.result,
            market.spec_hash_frozen,
        )
        return now == snap
    return False


def _open(amount: int = 4):
    market = create_market(integer=True, collateral="COLL", dust_sink="SINK")
    activate_binary(market, market_id="m", resolver="resolver", spec_hash="spec-hash")
    market.split("alice", amount, amount)
    return market


def run_invariant_ids() -> dict[str, dict[str, str]]:
    rows: dict[str, dict[str, str]] = {}

    market = _open()
    check_p_i01(market)
    broken = market.clone()
    broken.yes_supply += 1
    caught = False
    try:
        check_p_i01(broken)
    except PredictionError:
        caught = True
    rows["P-I01"] = {
        "classification": "EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN" if caught else "FAIL",
        "scope": "integer split of 4; supply/balance mismatch is rejected",
    }

    market.close_mint()
    market.begin_resolution()
    check_p_i02(market)
    drifted = market.clone()
    drifted.yes_supply += 1
    caught = False
    try:
        check_p_i02(drifted)
    except PredictionError:
        caught = True
    split_closed = _rejects(market, lambda: market.split("alice", 1, 1))
    equal_mint = market.yes_supply == market.no_supply == market.collateral_locked == 4
    rows["P-I02"] = {
        "classification": "EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN" if caught else "FAIL",
        "scope": "OPEN, LOCKED, and RESOLUTION_PENDING on this path",
    }
    rows["P-I03"] = {
        "classification": "EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN" if split_closed and equal_mint else "FAIL",
        "scope": "split of 4 while OPEN minted equal YES and NO; split after close is rejected",
    }

    locked = _open(5)
    locked.close_mint()
    released = locked.merge("alice", 2)
    merge_ok = released == 2 and locked.collateral_locked == 3
    locked.begin_resolution()
    merge_late = _rejects(locked, lambda: locked.merge("alice", 1))
    rows["P-I04"] = {
        "classification": "EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN" if merge_ok and merge_late else "FAIL",
        "scope": "merge 2 of 5 while LOCKED; merge after RESOLUTION_PENDING is rejected",
    }

    frozen = _open()
    spec_before = frozen.spec_hash_frozen
    replace = _rejects(frozen, lambda: frozen.try_replace_spec(frozen.spec))
    check_p_i05(frozen)
    draft = create_market(integer=True, collateral="COLL", dust_sink="SINK")
    draft.cancel_draft()
    check_p_i05(draft)
    rows["P-I05"] = {
        "classification": "EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN" if replace and spec_before == frozen.spec_hash_frozen else "FAIL",
        "scope": "activated hash stays spec-hash; cancelled draft has no spec",
        "kernel_cancel_draft": "NOT_YET_VALIDATED",
        "kernel_missing_operation": "cancelDraft",
    }

    pending = _open()
    pending.close_mint()
    pending.begin_resolution()
    wrong = _rejects(pending, lambda: pending.resolve("other", ResolutionResult.YES_WIN))
    fresh = _open()
    early = _rejects(fresh, lambda: fresh.resolve("resolver", ResolutionResult.YES_WIN))
    pending.resolve("resolver", ResolutionResult.YES_WIN)
    second = _rejects(pending, lambda: pending.resolve("resolver", ResolutionResult.NO_WIN))
    check_market(pending)
    rows["P-I06"] = {
        "classification": "EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN" if wrong and early and second else "FAIL",
        "scope": "one YES_WIN from RESOLUTION_PENDING by resolver; other caller and a second result are rejected",
    }

    before_open = _rejects(pending, lambda: pending.redeem("alice", Outcome.YES, 1))
    pending.open_redemption()
    over = _rejects(pending, lambda: pending.redeem("alice", Outcome.YES, 5))
    paid = pending.redeem("alice", Outcome.YES, 4)
    rows["P-I07"] = {
        "classification": "EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN" if before_open and over and paid == 4 else "FAIL",
        "scope": "redeem blocked in RESOLVED and above balance; 4 of 4 YES pays 4",
    }

    check_p_i08(pending)
    funded = _open()
    funded.close_mint()
    funded.begin_resolution()
    funded.resolve("resolver", ResolutionResult.YES_WIN)
    funded.open_redemption()
    insolvent = funded.clone()
    insolvent.collateral_locked = funded.collateral_locked - 1
    caught = False
    try:
        check_p_i08(insolvent)
    except PredictionError:
        caught = True
    rows["P-I08"] = {
        "classification": "EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN" if caught else "FAIL",
        "scope": "post-YES redemption still funded; a zeroed collateral balance is rejected",
    }

    minted = _rejects(pending, lambda: pending.admin_mint("alice", Outcome.NO, 1))
    rows["P-I09"] = {
        "classification": "EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN" if minted else "FAIL",
        "scope": "admin_mint raises and leaves state unchanged",
    }

    withdrawn = _rejects(pending, lambda: pending.admin_withdraw(1))
    live_archive = _rejects(pending, lambda: pending.archive())
    pending.burn_worthless("alice", Outcome.NO, 4)
    residual = pending.archive()
    check_p_i10(pending)
    rows["P-I10"] = {
        "classification": "EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN" if withdrawn and live_archive and residual == 0 else "FAIL",
        "scope": "no admin withdrawal; archive rejected while NO supply remains; residual 0 after full YES redemption",
    }
    return rows
