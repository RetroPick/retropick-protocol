"""Exact bounded all-Q check for a proposed Kuru launch/quote envelope.

The caller supplies an upper graduationQuoteCeiling. No ceiling, parameter
tuple, or five-bps policy is accepted by this research utility. Wide ranges
are deliberately refused until a monotonicity/breakpoint proof is supplied.
"""

from fractions import Fraction

from benchmark_launch_profiles import (
    AMM_SPREAD_BPS, BASE_DECIMALS, MAX_SIZE, MIN_SIZE,
    MAKER_FEE_BPS, PRICE_PRECISION, SIZE_PRECISION, TAKER_FEE_BPS,
    TICK_SIZE,
)
from completion_terminal_quote import terminal_quote_lower_bound
from launchpad_seed_model import (
    UINT96_MAX, UINT256_MAX, quote_first_seed, quote_opening_ticks,
    valid_router_parameters,
)


def check_terminal_q(
    *, terminal_tokens: int, phantom_quote: int, secured_quote: int,
    quote_decimals: int, candidate_error_cap_bps: int = 5,
) -> dict:
    """Check one Q using pinned reduced Kuru arithmetic and exact ratios."""
    try:
        seed = quote_first_seed(
            supply=terminal_tokens, phantom_quote=phantom_quote,
            secured_quote=secured_quote, base_decimals=BASE_DECIMALS,
            quote_decimals=quote_decimals, size_precision=SIZE_PRECISION,
            amm_spread=AMM_SPREAD_BPS,
        )
        opening = quote_opening_ticks(
            first_ask_price_scaled=seed.kuru_first_ask_price_scaled,
            price_precision=PRICE_PRECISION, tick_size=TICK_SIZE,
            amm_spread=AMM_SPREAD_BPS,
        )
    except ValueError as exc:
        return {"valid": False, "reason": str(exc)}

    seed_bps = Fraction(seed.price_error_numerator * 10_000,
                        seed.price_error_denominator)
    ask_tick_bps = Fraction(opening.ask_tick_error_numerator * 10_000,
                            opening.ask_tick_error_denominator)
    bid_tick_bps = Fraction(opening.bid_tick_error_numerator * 10_000,
                            opening.bid_tick_error_denominator)
    # Tick loss is relative to the vault price, while seed drift is relative
    # to the terminal Curve reference. The conservative triangle bound in
    # terminal-reference units includes the product of the two fractions.
    worst_tick_bps = max(ask_tick_bps, bid_tick_bps)
    combined_bps = seed_bps + worst_tick_bps + seed_bps * worst_tick_bps / 10_000
    constraints = {
        "router_tuple_matches_pinned_predicates": valid_router_parameters(
            size_precision=SIZE_PRECISION, price_precision=PRICE_PRECISION,
            tick_size=TICK_SIZE, min_size=MIN_SIZE, max_size=MAX_SIZE,
            maker_fee_bps=MAKER_FEE_BPS, taker_fee_bps=TAKER_FEE_BPS,
            amm_spread=AMM_SPREAD_BPS,
        ),
        "base_seed_positive": seed.base_seed > 0,
        "first_ask_and_bid_representable": opening.usable_limit_ticks,
        "vault_order_sizes_nonzero": seed.vault_ask_size > 0 and seed.vault_bid_size > 0,
        "vault_order_sizes_within_candidate_min_max": (
            MIN_SIZE <= seed.vault_ask_size <= MAX_SIZE
            and MIN_SIZE <= seed.vault_bid_size <= MAX_SIZE
        ),
        "vault_order_sizes_uint96": (
            seed.vault_ask_size <= UINT96_MAX and seed.vault_bid_size <= UINT96_MAX
        ),
        "positive_lp_shares": seed.lp_shares_to_receiver > 0,
        "combined_candidate_error_within_cap": combined_bps <= candidate_error_cap_bps,
        "bid_intermediate_uint256": seed.kuru_first_ask_price_scaled * 10_000 <= UINT256_MAX,
        "terminal_quote_product_uint256": (
            (phantom_quote + secured_quote) * 10**BASE_DECIMALS * 10**18
            <= UINT256_MAX
        ),
    }
    return {
        "valid": seed.seedable_in_reduced_model and all(constraints.values()),
        "base_seed_raw": seed.base_seed,
        "vault_ask_size": seed.vault_ask_size,
        "vault_bid_size": seed.vault_bid_size,
        "lp_shares": seed.lp_shares_to_receiver,
        "first_ask_1e18": seed.kuru_first_ask_price_scaled,
        "first_bid_1e18": opening.first_bid_price_scaled,
        "ask_tick": opening.ask_tick_floor,
        "bid_tick": opening.bid_tick_floor,
        "combined_error_bps_numerator": combined_bps.numerator,
        "combined_error_bps_denominator": combined_bps.denominator,
        "constraints": constraints,
    }


def check_terminal_q_interval(
    *, launch_supply: int, phantom_quote: int, graduation_threshold: int,
    quote_decimals: int, graduation_quote_ceiling: int,
    candidate_error_cap_bps: int = 5, max_cells: int = 1000,
) -> dict:
    """Enumerate every raw Q in a *bounded* candidate interval.

    B(Q), order sizes, and LP shares are monotone in Q, but floor-divided
    first price, seed residual and tick deviation are not assumed monotone.
    They are checked in every cell here; this does not scale to an arbitrary
    18-decimal quote interval without a separate breakpoint proof.
    """
    if min(launch_supply, phantom_quote, graduation_threshold) <= 0:
        raise ValueError("positive launch supply, phantom and threshold required")
    if launch_supply > 2**127 - 1:
        raise ValueError("launch supply exceeds current Factory int128 seed ceiling")
    if not 0 <= quote_decimals <= 18:
        raise ValueError("quote decimals outside 0..18")
    if max_cells <= 0:
        raise ValueError("positive exhaustive-cell budget required")
    terminal = launch_supply * phantom_quote // (phantom_quote + graduation_threshold)
    if not 0 < terminal < launch_supply:
        raise ValueError("empty terminal token allocation")
    lower = terminal_quote_lower_bound(
        initial_tokens=launch_supply, phantom_quote=phantom_quote,
        reserved_tokens=terminal,
    )
    if graduation_quote_ceiling < lower:
        raise ValueError("ceiling below proven terminal lower bound")
    cells = graduation_quote_ceiling - lower + 1
    if cells > max_cells:
        raise ValueError("interval too wide for bounded enumeration")

    first_invalid = None
    valid = 0
    previous = None
    monotone = {"base_seed": True, "vault_ask_size": True,
                "vault_bid_size": True, "lp_shares": True}
    endpoints = []
    worst_error = Fraction(0)
    for quote in range(lower, graduation_quote_ceiling + 1):
        checked = check_terminal_q(
            terminal_tokens=terminal, phantom_quote=phantom_quote,
            secured_quote=quote, quote_decimals=quote_decimals,
            candidate_error_cap_bps=candidate_error_cap_bps,
        )
        if quote in (lower, graduation_quote_ceiling):
            endpoints.append({"secured_quote_raw": quote, "result": checked})
        if checked["valid"]:
            valid += 1
        elif first_invalid is None:
            first_invalid = {"secured_quote_raw": quote, "result": checked}
        if "combined_error_bps_numerator" in checked:
            error = Fraction(checked["combined_error_bps_numerator"],
                             checked["combined_error_bps_denominator"])
            worst_error = max(worst_error, error)
            if previous is not None:
                for name, key in (
                    ("base_seed", "base_seed_raw"),
                    ("vault_ask_size", "vault_ask_size"),
                    ("vault_bid_size", "vault_bid_size"),
                    ("lp_shares", "lp_shares"),
                ):
                    monotone[name] &= checked[key] >= previous[key]
            previous = checked
    return {
        "launch_supply_raw": launch_supply,
        "terminal_tokens_raw": terminal,
        "phantom_quote_raw": phantom_quote,
        "configured_threshold_raw": graduation_threshold,
        "quote_decimals": quote_decimals,
        "proven_lower_q_raw": lower,
        "proposed_ceiling_raw": graduation_quote_ceiling,
        "checked_raw_q_cells": cells,
        "valid_cells": valid,
        "all_cells_valid_in_reduced_model": valid == cells,
        "first_invalid": first_invalid,
        "endpoints": endpoints,
        "monotone_fields_observed": monotone,
        "worst_combined_error_bps_numerator": worst_error.numerator,
        "worst_combined_error_bps_denominator": worst_error.denominator,
    }
