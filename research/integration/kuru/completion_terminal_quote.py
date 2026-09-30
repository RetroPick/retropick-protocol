"""Venue-agnostic exact-integer immediate-graduation research oracle.

This mirrors the current Curve's clamped final buy and graduate fee sweep.
It is NOT production policy and does not assume that the next buy is funded,
that an external venue succeeds, or that an accepted quote asset stays live.
"""

from dataclasses import dataclass

from launchpad_seed_model import BPS, UINT256_MAX


def _u256(value: int, name: str) -> int:
    if not 0 <= value <= UINT256_MAX:
        raise OverflowError(f"{name} outside uint256")
    return value


def terminal_quote_lower_bound(
    *, initial_tokens: int, phantom_quote: int, reserved_tokens: int,
) -> int:
    """Exact terminal Q floor if the tradeable reserve product never falls.

    Assumes initial virtual quote is phantom_quote, initial token reserve is
    initial_tokens, and every accepted buy/sell/buyback preserves or raises
    their product. This says nothing about an upper Q or external token loss.
    """
    if min(initial_tokens, phantom_quote, reserved_tokens) <= 0:
        raise ValueError("positive initial reserves and token floor required")
    if reserved_tokens > initial_tokens:
        raise ValueError("token floor exceeds initial supply")
    _u256(initial_tokens, "initial tokens")
    _u256(phantom_quote, "phantom quote")
    _u256(reserved_tokens, "reserved tokens")
    return (initial_tokens * phantom_quote + reserved_tokens - 1) // reserved_tokens - phantom_quote


@dataclass(frozen=True)
class CurveCompletionState:
    phantom_quote: int
    tracked_quote: int
    quote_fee_balance: int
    creator_tax_balance: int
    tracked_tokens: int
    reserved_tokens: int
    curve_fee_bps: int
    creator_tax_bps: int


@dataclass(frozen=True)
class CompletionQuote:
    real_quote_before: int
    remaining_sellable_tokens: int
    required_net_quote: int
    gross_quote_in: int
    final_buy_fee: int
    final_buy_tax: int
    terminal_real_quote: int


def completion_terminal_quote(state: CurveCompletionState) -> CompletionQuote:
    """Return actual terminal real quote if the next buy exhausts sellable tokens.

    The final buy is submitted with exactly the Curve's ceil-grossed
    getAmountIn amount, minTokensOut=0. The current graduate path skips
    buyback, pays pending fee/tax buckets, and sweeps the tradeable remainder.
    Every checked intermediate that this execution reaches is uint256-tested.
    """
    for name in (
        "phantom_quote", "tracked_quote", "quote_fee_balance",
        "creator_tax_balance", "tracked_tokens", "reserved_tokens",
    ):
        _u256(getattr(state, name), name)
    if state.phantom_quote <= 0 or state.reserved_tokens <= 0:
        raise ValueError("positive phantom and reserved token floor required")
    if state.tracked_tokens < state.reserved_tokens:
        raise ValueError("token reserve below graduation floor")
    if state.quote_fee_balance + state.creator_tax_balance > state.tracked_quote:
        raise ValueError("fee buckets exceed tracked quote")
    if not 0 <= state.curve_fee_bps <= BPS or not 0 <= state.creator_tax_bps <= BPS:
        raise ValueError("invalid fee basis points")
    if state.curve_fee_bps + state.creator_tax_bps > 2_000:
        raise ValueError("current Curve total fee ceiling exceeded")

    real = state.tracked_quote - state.quote_fee_balance - state.creator_tax_balance
    virtual = _u256(state.phantom_quote + real, "virtual quote reserve")
    remaining = state.tracked_tokens - state.reserved_tokens
    if remaining == 0:
        return CompletionQuote(real, 0, 0, 0, 0, 0, real)

    # Production getAmountIn(out, virtual, trackedTokens, 0) first evaluates
    # out * virtual * 10_000, then (trackedTokens-out) * 10_000.
    numerator = _u256(_u256(remaining * virtual, "getAmountIn product") * BPS,
                      "getAmountIn numerator")
    denominator = _u256(state.reserved_tokens * BPS, "getAmountIn denominator")
    net = _u256(numerator // denominator + 1, "required net quote")
    fee_denominator = BPS - state.curve_fee_bps - state.creator_tax_bps
    gross = _u256((net * BPS + fee_denominator - 1) // fee_denominator,
                  "ceil-grossed final input")
    fee = _u256(gross * state.curve_fee_bps, "final buy fee product") // BPS
    tax = _u256(gross * state.creator_tax_bps, "final buy tax product") // BPS
    actual_net = gross - fee - tax
    _u256(state.tracked_quote + gross, "tracked quote after buy")
    _u256(state.quote_fee_balance + fee, "fee bucket after buy")
    _u256(state.creator_tax_balance + tax, "tax bucket after buy")

    # buy() quotes getAmountOut before deciding to clamp. A mathematically
    # adequate gross is not executable if that checked multiplication fails.
    amount_in_with_fee = _u256(actual_net * BPS, "getAmountOut input")
    amount_out_numerator = _u256(amount_in_with_fee * state.tracked_tokens,
                                 "getAmountOut numerator")
    amount_out_denominator = _u256(virtual * BPS + amount_in_with_fee,
                                   "getAmountOut denominator")
    quoted_tokens = amount_out_numerator // amount_out_denominator
    if quoted_tokens < remaining:
        raise ValueError("ceil-grossed input does not reach graduation floor")
    _u256(gross * remaining, "buy slippage RHS")
    terminal = _u256(real + actual_net, "terminal real quote")
    return CompletionQuote(real, remaining, net, gross, fee, tax, terminal)
