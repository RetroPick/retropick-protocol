"""Stateful binary prediction market.

The market contract is the collateral controller. Outcome balances live in
this model as the ERC-20 balances the controller would mint and burn.
There is no separate vault object and no admin mint.
"""

from __future__ import annotations

from copy import deepcopy
from fractions import Fraction
from typing import Callable, Optional

from complete_set import exact_payout, integer_payout_delta, integer_side_obligation
from domain import (
    Amount,
    CollateralClass,
    MarketState,
    Outcome,
    PredictionError,
    ResolutionResult,
    as_amount,
)
from invariants import check_market
from lifecycle import merge_allowed, redeem_allowed, split_allowed, transition
from resolution import ResolutionSpec, denominator, payout_numerators


UINT256_MAX = 2**256 - 1
Hook = Callable[["PredictionMarket"], None]


class PredictionMarket:
    def __init__(
        self,
        *,
        integer: bool,
        collateral: str,
        dust_sink: str,
        collateral_class: CollateralClass = CollateralClass.STANDARD,
        max_amount: int = UINT256_MAX,
        position_cap: int | None = None,
    ) -> None:
        if collateral_class is not CollateralClass.STANDARD:
            raise PredictionError(
                f"Phase-1 admits only standard ERC-20 collateral, got {collateral_class.value}"
            )
        self.integer = integer
        self.collateral = collateral
        self.dust_sink = dust_sink
        self.collateral_class = collateral_class
        self.max_amount = max_amount
        self.position_cap = position_cap
        self.zero: Amount = 0 if integer else Fraction(0)
        self.state = MarketState.DRAFT
        self.spec: Optional[ResolutionSpec] = None
        self.spec_hash_frozen: Optional[str] = None
        self.result: Optional[ResolutionResult] = None
        self.resolved_once = False
        self.collateral_locked: Amount = self.zero
        self.collateral_at_resolution: Amount = self.zero
        self.yes_supply: Amount = self.zero
        self.no_supply: Amount = self.zero
        self.yes_redeemed: Amount = self.zero
        self.no_redeemed: Amount = self.zero
        self.balances: dict[str, dict[Outcome, Amount]] = {}
        self.residual_to_sink: Amount = self.zero
        self._entered = False
        self.cancel_reason: Optional[str] = None

    def clone(self) -> "PredictionMarket":
        return deepcopy(self)

    def _amt(self, value: Amount) -> Amount:
        amount = as_amount(value, integer=self.integer)
        if self.integer and isinstance(amount, int) and amount > self.max_amount:
            raise PredictionError("amount exceeds configured maximum")
        return amount

    def _bal(self, account: str) -> dict[Outcome, Amount]:
        if account not in self.balances:
            self.balances[account] = {Outcome.YES: self.zero, Outcome.NO: self.zero}
        return self.balances[account]

    def liability(self) -> Amount:
        if self.result is None:
            return self.collateral_locked
        if self.integer:
            assert isinstance(self.yes_supply, int)
            assert isinstance(self.no_supply, int)
            assert isinstance(self.yes_redeemed, int)
            assert isinstance(self.no_redeemed, int)
            yes_num, no_num = payout_numerators(self.result)
            den = denominator()
            y0 = self.yes_supply + self.yes_redeemed
            n0 = self.no_supply + self.no_redeemed
            obligation = integer_side_obligation(y0, yes_num, den) + integer_side_obligation(n0, no_num, den)
            paid = integer_side_obligation(self.yes_redeemed, yes_num, den) + integer_side_obligation(
                self.no_redeemed, no_num, den
            )
            return obligation - paid
        assert isinstance(self.yes_supply, Fraction)
        assert isinstance(self.no_supply, Fraction)
        return exact_payout(self.result, Outcome.YES, self.yes_supply) + exact_payout(
            self.result, Outcome.NO, self.no_supply
        )

    def _enter(self) -> None:
        if self._entered:
            raise PredictionError("reentrancy")
        self._entered = True

    def _leave(self) -> None:
        self._entered = False

    def _guarded(self, hook: Optional[Hook]) -> None:
        if hook is not None:
            hook(self)

    def activate(self, spec: ResolutionSpec) -> None:
        self._enter()
        try:
            if self.state is not MarketState.DRAFT:
                raise PredictionError("activate only from DRAFT")
            if spec.collateral != self.collateral:
                raise PredictionError("resolution spec collateral does not match market")
            self.spec = spec
            self.spec_hash_frozen = spec.spec_hash
            self.state = transition(self.state, MarketState.OPEN)
            check_market(self)
        finally:
            self._leave()

    def cancel_draft(self) -> None:
        self._enter()
        try:
            if self.state is not MarketState.DRAFT:
                raise PredictionError("cancel only from DRAFT")
            if self.collateral_locked != self.zero:
                raise PredictionError("draft holds no collateral")
            self.cancel_reason = "CANCELLED_BEFORE_ACTIVATION"
            self.state = transition(self.state, MarketState.ARCHIVED)
        finally:
            self._leave()

    def split(self, account: str, amount: Amount, received: Amount, hook: Optional[Hook] = None) -> None:
        self._enter()
        try:
            if not split_allowed(self.state):
                raise PredictionError("split only while OPEN")
            quantity = self._amt(amount)
            got = self._amt(received)
            if quantity <= self.zero:
                raise PredictionError("split quantity must be positive")
            if got != quantity:
                raise PredictionError("collateral received must equal credited amount")
            if self.position_cap is not None and self.collateral_locked + quantity > self.position_cap:
                raise PredictionError("split exceeds position cap")
            self._guarded(hook)
            bal = self._bal(account)
            self.collateral_locked += quantity
            self.yes_supply += quantity
            self.no_supply += quantity
            bal[Outcome.YES] += quantity
            bal[Outcome.NO] += quantity
            check_market(self)
        finally:
            self._leave()

    def merge(self, account: str, amount: Amount, hook: Optional[Hook] = None) -> Amount:
        self._enter()
        try:
            if not merge_allowed(self.state):
                raise PredictionError("merge only while OPEN or LOCKED")
            quantity = self._amt(amount)
            if quantity <= self.zero:
                raise PredictionError("merge quantity must be positive")
            bal = self._bal(account)
            if bal[Outcome.YES] < quantity or bal[Outcome.NO] < quantity:
                raise PredictionError("merge requires equal YES and NO balances")
            self._guarded(hook)
            bal[Outcome.YES] -= quantity
            bal[Outcome.NO] -= quantity
            self.yes_supply -= quantity
            self.no_supply -= quantity
            self.collateral_locked -= quantity
            check_market(self)
            return quantity
        finally:
            self._leave()

    def close_mint(self) -> None:
        self._enter()
        try:
            self.state = transition(self.state, MarketState.LOCKED)
            check_market(self)
        finally:
            self._leave()

    def begin_resolution(self) -> None:
        self._enter()
        try:
            self.state = transition(self.state, MarketState.RESOLUTION_PENDING)
            check_market(self)
        finally:
            self._leave()

    def resolve(self, caller: str, result: ResolutionResult) -> None:
        self._enter()
        try:
            if self.spec is None:
                raise PredictionError("market has no resolution spec")
            if caller != self.spec.resolver:
                raise PredictionError("resolver mismatch")
            if result not in (ResolutionResult.YES_WIN, ResolutionResult.NO_WIN, ResolutionResult.INVALID):
                raise PredictionError("Phase-1 result must be YES_WIN, NO_WIN, or INVALID")
            self.state = transition(self.state, MarketState.RESOLVED)
            self.result = result
            self.resolved_once = True
            self.collateral_at_resolution = self.collateral_locked
            check_market(self)
        finally:
            self._leave()

    def open_redemption(self) -> None:
        self._enter()
        try:
            if self.collateral_locked < self.liability():
                raise PredictionError("settlement underfunded")
            self.state = transition(self.state, MarketState.REDEEMABLE)
            check_market(self)
        finally:
            self._leave()

    def _payout(self, side: Outcome, quantity: Amount) -> Amount:
        assert self.result is not None
        if not self.integer:
            assert isinstance(quantity, Fraction)
            return exact_payout(self.result, side, quantity)
        assert isinstance(quantity, int)
        yes_num, no_num = payout_numerators(self.result)
        num = yes_num if side is Outcome.YES else no_num
        redeemed = self.yes_redeemed if side is Outcome.YES else self.no_redeemed
        assert isinstance(redeemed, int)
        return integer_payout_delta(redeemed, quantity, num, denominator())

    def redeem(self, account: str, side: Outcome, amount: Amount) -> Amount:
        self._enter()
        try:
            if not redeem_allowed(self.state):
                raise PredictionError("redeem only while REDEEMABLE")
            quantity = self._amt(amount)
            if quantity <= self.zero:
                raise PredictionError("redeem quantity must be positive")
            bal = self._bal(account)
            if bal[side] < quantity:
                raise PredictionError("redeem exceeds balance")
            payout = self._payout(side, quantity)
            if payout > self.collateral_locked:
                raise PredictionError("payout exceeds collateral")
            bal[side] -= quantity
            if side is Outcome.YES:
                self.yes_supply -= quantity
                self.yes_redeemed += quantity
            else:
                self.no_supply -= quantity
                self.no_redeemed += quantity
            self.collateral_locked -= payout
            check_market(self)
            return payout
        finally:
            self._leave()

    def burn_worthless(self, account: str, side: Outcome, amount: Amount) -> None:
        self._enter()
        try:
            if not redeem_allowed(self.state):
                raise PredictionError("burn only while REDEEMABLE")
            if self.result is None:
                raise PredictionError("missing result")
            yes_num, no_num = payout_numerators(self.result)
            num = yes_num if side is Outcome.YES else no_num
            if num != 0:
                raise PredictionError("side is not worthless")
            quantity = self._amt(amount)
            if quantity <= self.zero:
                raise PredictionError("burn quantity must be positive")
            bal = self._bal(account)
            if bal[side] < quantity:
                raise PredictionError("burn exceeds balance")
            bal[side] -= quantity
            if side is Outcome.YES:
                self.yes_supply -= quantity
            else:
                self.no_supply -= quantity
            check_market(self)
        finally:
            self._leave()

    def archive(self) -> Amount:
        self._enter()
        try:
            if self.yes_supply != self.zero or self.no_supply != self.zero:
                raise PredictionError("archive requires zero outcome supply")
            if self.liability() != self.zero:
                raise PredictionError("archive requires zero liability")
            residual = self.collateral_locked
            self.collateral_locked = self.zero
            self.residual_to_sink += residual
            self.state = transition(self.state, MarketState.ARCHIVED)
            check_market(self)
            return residual
        finally:
            self._leave()

    def try_replace_spec(self, spec: ResolutionSpec) -> None:
        raise PredictionError("resolution spec is immutable after activation")

    def admin_mint(self, account: str, side: Outcome, amount: Amount) -> None:
        raise PredictionError("no admin mint")

    def admin_withdraw(self, amount: Amount) -> None:
        raise PredictionError("no admin withdrawal of collateral")

    def pause_redemption(self) -> None:
        raise PredictionError("Phase-1 has no redemption pause")


def create_market(
    *,
    integer: bool,
    collateral: str,
    dust_sink: str,
    collateral_class: CollateralClass = CollateralClass.STANDARD,
    max_amount: int = UINT256_MAX,
    position_cap: int | None = None,
) -> PredictionMarket:
    return PredictionMarket(
        integer=integer,
        collateral=collateral,
        dust_sink=dust_sink,
        collateral_class=collateral_class,
        max_amount=max_amount,
        position_cap=position_cap,
    )


def activate_binary(
    market: PredictionMarket,
    *,
    market_id: str,
    resolver: str,
    spec_hash: str,
) -> None:
    market.activate(
        ResolutionSpec(
            market_id=market_id,
            collateral=market.collateral,
            resolver=resolver,
            spec_hash=spec_hash,
        )
    )
