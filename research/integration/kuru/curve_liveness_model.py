"""Bounded, venue-agnostic research model for a completion-quote ceiling.

The model follows current Curve integer buy/sell/fee-sweep transitions for one
aggregate holder. It abstracts ERC20 transfers, auth, balances, and external
buyback vault behavior. It is not a production contract or a universal proof.
"""

from dataclasses import dataclass, replace

from completion_terminal_quote import CurveCompletionState, completion_terminal_quote
from launchpad_seed_model import BPS


class TradeRejected(ValueError):
    pass


class CompletionCeilingRejected(ValueError):
    pass


@dataclass(frozen=True)
class CurveState:
    phantom_quote: int
    reserved_tokens: int
    tracked_tokens: int
    tracked_quote: int = 0
    quote_fee_balance: int = 0
    creator_tax_balance: int = 0
    buyback_quote_balance: int = 0
    user_tokens: int = 0
    fee_bps: int = 100
    tax_bps: int = 50
    buyback_enabled: bool = False
    protocol_fee_share_bps: int = 3000
    buyback_burn_bps: int = 5000
    max_internal_price_impact_bps: int = 300

    @property
    def real_quote(self) -> int:
        return self.tracked_quote - self.quote_fee_balance - self.creator_tax_balance

    @property
    def sellable_tokens(self) -> int:
        return self.tracked_tokens - self.reserved_tokens

    @property
    def reserve_product(self) -> int:
        return (self.phantom_quote + self.real_quote) * self.tracked_tokens

    def completion(self) -> int:
        return completion_terminal_quote(CurveCompletionState(
            phantom_quote=self.phantom_quote,
            tracked_quote=self.tracked_quote,
            quote_fee_balance=self.quote_fee_balance,
            creator_tax_balance=self.creator_tax_balance,
            tracked_tokens=self.tracked_tokens,
            reserved_tokens=self.reserved_tokens,
            curve_fee_bps=self.fee_bps,
            creator_tax_bps=self.tax_bps,
        )).terminal_real_quote

    def _accrue(self, fee: int, tax: int) -> tuple[int, int, int]:
        earmark = self.buyback_quote_balance
        if self.buyback_enabled and fee:
            creator_slice = fee - fee * self.protocol_fee_share_bps // BPS
            earmark += creator_slice * self.buyback_burn_bps // BPS
        return self.quote_fee_balance + fee, self.creator_tax_balance + tax, earmark

    def buy(self, gross: int) -> tuple["CurveState", int, int]:
        """Exact-input buy, minTokensOut=0; returns state, tokens, spent quote."""
        if gross <= 0 or self.sellable_tokens <= 0:
            raise TradeRejected("zero buy or no sellable tokens")
        fee = gross * self.fee_bps // BPS
        tax = gross * self.tax_bps // BPS
        net = gross - fee - tax
        virtual = self.phantom_quote + self.real_quote
        if net <= 0:
            raise TradeRejected("zero net input")
        tokens = net * self.tracked_tokens // (virtual + net)
        if tokens <= 0:
            raise TradeRejected("zero token output")
        spent = gross
        if tokens > self.sellable_tokens:
            tokens = self.sellable_tokens
            required_net = tokens * virtual // self.reserved_tokens + 1
            denominator = BPS - self.fee_bps - self.tax_bps
            spent = min((required_net * BPS + denominator - 1) // denominator, gross)
            fee = spent * self.fee_bps // BPS
            tax = spent * self.tax_bps // BPS
        fee_bucket, tax_bucket, earmark = self._accrue(fee, tax)
        return replace(
            self,
            tracked_quote=self.tracked_quote + spent,
            tracked_tokens=self.tracked_tokens - tokens,
            quote_fee_balance=fee_bucket,
            creator_tax_balance=tax_bucket,
            buyback_quote_balance=earmark,
            user_tokens=self.user_tokens + tokens,
        ), tokens, spent

    def sell(self, tokens: int) -> tuple["CurveState", int]:
        """Exact-token sell, minQuoteOut=0; returns state and recipient quote."""
        if tokens <= 0 or tokens > self.user_tokens or self.sellable_tokens <= 0:
            raise TradeRejected("invalid sell quantity or closed curve")
        gross = tokens * (self.phantom_quote + self.real_quote) // (self.tracked_tokens + tokens)
        if gross <= 0:
            raise TradeRejected("zero gross quote output")
        fee = gross * self.fee_bps // BPS
        tax = gross * self.tax_bps // BPS
        payout = gross - fee - tax
        if payout > self.tracked_quote:
            raise TradeRejected("tracked quote deficit")
        fee_bucket, tax_bucket, earmark = self._accrue(fee, tax)
        return replace(
            self,
            tracked_quote=self.tracked_quote - payout,
            tracked_tokens=self.tracked_tokens + tokens,
            quote_fee_balance=fee_bucket,
            creator_tax_balance=tax_bucket,
            buyback_quote_balance=earmark,
            user_tokens=self.user_tokens - tokens,
        ), payout

    def sweep(self, min_buyback_tokens_out: int = 0) -> "CurveState":
        """Current trusted sweep arithmetic; assumes external credits/lock succeed."""
        pending = self.quote_fee_balance
        tax = self.creator_tax_balance
        if pending == 0 and tax == 0:
            return self
        protocol = pending * self.protocol_fee_share_bps // BPS
        creator_bucket = pending - protocol
        buyback_quote = min(self.buyback_quote_balance, creator_bucket)
        creator = creator_bucket - buyback_quote + tax
        tokens_locked = 0
        if buyback_quote:
            if min_buyback_tokens_out <= 0:
                raise TradeRejected("buyback requires output floor")
            virtual = self.phantom_quote + self.real_quote
            movement = buyback_quote * BPS // (virtual + buyback_quote)
            if movement <= self.max_internal_price_impact_bps:
                tokens = buyback_quote * self.tracked_tokens // (virtual + buyback_quote)
                if 0 < tokens <= self.sellable_tokens:
                    tokens_locked = tokens
            if tokens_locked == 0:
                creator += buyback_quote
                buyback_quote = 0
            elif tokens_locked < min_buyback_tokens_out:
                raise TradeRejected("buyback slippage")
        return replace(
            self,
            tracked_quote=self.tracked_quote - protocol - creator,
            tracked_tokens=self.tracked_tokens - tokens_locked,
            quote_fee_balance=0,
            creator_tax_balance=0,
            buyback_quote_balance=0,
        )


def admit_transition(candidate: CurveState, graduation_quote_ceiling: int) -> CurveState:
    """Research-only semantic guard applied after a candidate transition.

    A rejection means the *entire* candidate transition must revert onchain;
    the caller retains its previous state. No production guard exists yet.
    """
    if candidate.completion() > graduation_quote_ceiling:
        raise CompletionCeilingRejected("immediate completion exceeds immutable ceiling")
    return candidate
