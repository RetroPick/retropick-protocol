"""Deterministic candidate Launchpad-to-Kuru profile matrix; emits JSON to stdout.

These are research inputs, not accepted launch configuration or market policy.
The model uses the current Curve's reserved-token formula to derive terminal
tracked tokens T from original launch supply and assumes physical Q reaches
the configured graduation threshold exactly. Live runs must use measured Q.
"""

import json
from dataclasses import asdict
from decimal import Decimal, localcontext

from launchpad_seed_model import (
    UINT96_MAX, UINT256_MAX, quote_first_seed, quote_opening_ticks,
    valid_router_parameters,
)


BASE_DECIMALS = 18
SIZE_PRECISION = 10**8
PRICE_PRECISION = 10**8
TICK_SIZE = 1
MIN_SIZE = 10**6  # 0.01 base token; candidate anti-spam floor.
MAX_SIZE = 10**16  # 100 million base tokens in size-precision units.
MAKER_FEE_BPS = 0
TAKER_FEE_BPS = 30
AMM_SPREAD_BPS = 100

# Whole-token/whole-quote units. MEDIUM reproduces the existing 1m-token,
# 100-unit phantom economics fixture except for an intentionally nondivisible
# 97-unit secured quote. No MON/USDC exchange-rate parity is asserted.
PROFILE_INPUTS = (
    ("FACTORY_MINIMUM_NEGATIVE", 1, 1, 1),
    ("MINIMUM_VALID_LAUNCH", 1_000, 1, 1),
    ("SMALL", 100_000, 10, 11),
    ("MEDIUM", 1_000_000, 100, 97),
    ("LARGE", 100_000_000, 1_000, 1_001),
    ("MAXIMUM_SUPPORTED_CANDIDATE", 1_000_000_000, 10_000, 9_500),
)


def decimal_ratio(numerator: int, denominator: int) -> str:
    with localcontext() as ctx:
        ctx.prec = 48
        return format(Decimal(numerator) / Decimal(denominator), "f")


def build_matrix() -> dict:
    tuple_candidate = {
        "size_precision": SIZE_PRECISION,
        "price_precision": PRICE_PRECISION,
        "tick_size": TICK_SIZE,
        "min_size": MIN_SIZE,
        "max_size": MAX_SIZE,
        "maker_fee_bps": MAKER_FEE_BPS,
        "taker_fee_bps": TAKER_FEE_BPS,
        "amm_spread": AMM_SPREAD_BPS,
    }
    router_predicates = valid_router_parameters(**tuple_candidate)
    rows = []
    for quote, quote_decimals in (("MON", 18), ("USDC", 6)):
        for name, whole_supply, whole_phantom, whole_threshold in PROFILE_INPUTS:
            launch_supply = whole_supply * 10**BASE_DECIMALS
            phantom = whole_phantom * 10**quote_decimals
            secured = whole_threshold * 10**quote_decimals
            terminal_tokens = launch_supply * phantom // (phantom + secured)
            seed = quote_first_seed(
                supply=terminal_tokens, phantom_quote=phantom,
                secured_quote=secured, base_decimals=BASE_DECIMALS,
                quote_decimals=quote_decimals,
                size_precision=SIZE_PRECISION, amm_spread=AMM_SPREAD_BPS,
            )
            opening = quote_opening_ticks(
                first_ask_price_scaled=seed.kuru_first_ask_price_scaled,
                price_precision=PRICE_PRECISION, tick_size=TICK_SIZE,
                amm_spread=AMM_SPREAD_BPS,
            )
            arithmetic_bounds = {
                "launch_supply_uint256": launch_supply <= UINT256_MAX,
                "launch_supply_factory_int128_seed_ceiling": launch_supply <= 2**127 - 1,
                "terminal_token_uint256": terminal_tokens <= UINT256_MAX,
                "virtual_quote_sum_uint256": phantom + secured <= UINT256_MAX,
                "base_seed_times_quote_uint256": seed.base_seed * secured <= UINT256_MAX,
                "first_ask_intermediate_uint256": secured * 10**BASE_DECIMALS * 10**18 <= UINT256_MAX,
                "vault_size_intermediate_uint256": AMM_SPREAD_BPS * seed.base_seed * SIZE_PRECISION <= UINT256_MAX,
                "first_bid_intermediate_uint256": seed.kuru_first_ask_price_scaled * 10_000 <= UINT256_MAX,
                "vault_sizes_uint96": seed.vault_ask_size <= UINT96_MAX and seed.vault_bid_size <= UINT96_MAX,
                "tick_prices_uint32": opening.ask_price_units <= 2**32 - 1 and opening.bid_price_units <= 2**32 - 1,
            }
            size_within_policy = (
                MIN_SIZE <= seed.vault_ask_size <= MAX_SIZE
                and MIN_SIZE <= seed.vault_bid_size <= MAX_SIZE
            )
            row = {
                "profile": name,
                "quote": quote,
                "launch_total_supply_raw": launch_supply,
                "terminal_tracked_token_T_raw": terminal_tokens,
                "phantom_quote_P_raw": phantom,
                "secured_quote_Q_raw": secured,
                "base_decimals": BASE_DECIMALS,
                "quote_decimals": quote_decimals,
                "terminal_reference_price_1e18": seed.terminal_price_scaled,
                "base_seed_B_raw": seed.base_seed,
                "excess_base_raw": seed.excess_base,
                "first_ask_1e18": seed.kuru_first_ask_price_scaled,
                "first_bid_1e18": opening.first_bid_price_scaled,
                "vault_ask_size": seed.vault_ask_size,
                "vault_bid_size": seed.vault_bid_size,
                "initial_lp_shares": seed.lp_shares_to_receiver,
                "absolute_seed_error_1e18": seed.price_difference,
                "relative_seed_error": {
                    "numerator": seed.price_error_numerator,
                    "denominator": seed.price_error_denominator,
                    "bps_decimal": decimal_ratio(
                        seed.price_error_numerator * 10_000,
                        seed.price_error_denominator,
                    ),
                },
                "tick_grid": asdict(opening),
                "size_within_candidate_policy": size_within_policy,
                "arithmetic_bounds": arithmetic_bounds,
                "candidate_eligible_in_reduced_model": (
                    router_predicates and seed.seedable_in_reduced_model
                    and opening.usable_limit_ticks and size_within_policy
                    and all(arithmetic_bounds.values())
                ),
                "phase2_gas": "NOT_MEASURED_FORK_PENDING",
            }
            rows.append(row)
    return {
        "schema_version": 1,
        "classification": "CANDIDATE_REDUCED_MODEL_NOT_ADR_ACCEPTANCE",
        "kuru_contracts_source_sha": "2060bb2736080c175d80d568bfdb6226bb5abd04",
        "terminal_assumption": "Q equals configured threshold; live Q must be measured",
        "candidate_tuple": tuple_candidate,
        "router_predicates_pass": router_predicates,
        "rows": rows,
    }


if __name__ == "__main__":
    print(json.dumps(build_matrix(), indent=2))
