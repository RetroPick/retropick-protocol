"""Exact-integer candidate seed checks for Launchpad Core -> Kuru research.

This is not an accepted market-parameter policy. It mirrors the current V2
V4 seed-base relation and KuruAMMVault's first-deposit arithmetic at public
Kuru contracts commit 2060bb2736080c175d80d568bfdb6226bb5abd04.
"""

from dataclasses import dataclass
from math import isqrt


VAULT_PRICE_PRECISION = 10**18
MIN_LIQUIDITY = 10**3
DOUBLE_BPS = 20_000
UINT256_MAX = 2**256 - 1
UINT96_MAX = 2**96 - 1


@dataclass(frozen=True)
class SeedQuote:
    base_seed: int
    excess_base: int
    terminal_price_scaled: int
    kuru_first_ask_price_scaled: int
    price_difference: int
    lp_shares_to_receiver: int
    vault_ask_size: int
    vault_bid_size: int
    seedable_in_reduced_model: bool


def valid_router_parameters(
    *, size_precision: int, price_precision: int, tick_size: int,
    min_size: int, max_size: int, maker_fee_bps: int,
    taker_fee_bps: int, amm_spread: int,
) -> bool:
    """Constraints visible in Router.deployProxy and OrderBook.initialize.

    Token compatibility and many later vault/orderbook constraints are outside
    this reduced predicate; True is necessary, never sufficient for admission.
    """
    def power_of_ten(value: int) -> bool:
        if value < 1:
            return False
        while value % 10 == 0:
            value //= 10
        return value == 1

    return (
        power_of_ten(size_precision)
        and size_precision <= UINT96_MAX
        and power_of_ten(price_precision)
        and price_precision <= 2**32 - 1
        and 0 < tick_size <= 2**32 - 1
        and 0 < min_size < max_size <= UINT96_MAX
        and 0 <= maker_fee_bps <= taker_fee_bps < 10_000
        and 0 < amm_spread < 500
        and amm_spread % 10 == 0
    )


def quote_first_seed(
    *, supply: int, phantom_quote: int, secured_quote: int,
    base_decimals: int, quote_decimals: int, size_precision: int,
    amm_spread: int,
) -> SeedQuote:
    """Model the proposed price-preserving base selection and Kuru first mint.

    Terminal reference is (phantom + real) / tracked base. The caller must
    supply the actual *terminal tracked base* as ``supply``. The V4 code's
    existing seed choice floors base * real / (phantom + real), leaving excess
    base outside the vault. Kuru's first deposit instead takes physical base
    and quote, floors its 1e18-scaled ask, and locks 1000 LP shares.
    """
    if min(supply, phantom_quote, secured_quote, size_precision) <= 0:
        raise ValueError("positive terminal reserves, secured quote and precision required")
    if not (0 <= base_decimals <= 18 and 0 <= quote_decimals <= 18):
        raise ValueError("declared decimal domain is 0..18")
    if not (0 < amm_spread < 500 and amm_spread % 10 == 0):
        raise ValueError("current OrderBook spread constraint")

    base_seed = supply * secured_quote // (phantom_quote + secured_quote)
    if base_seed == 0 or base_seed >= supply:
        raise ValueError("base seed rounds to zero or leaves no excess")
    if base_seed * secured_quote > UINT256_MAX:
        raise ValueError("first-mint base*quote exceeds uint256")

    normalizer = 10**base_decimals * VAULT_PRICE_PRECISION
    quote_scale = 10**quote_decimals
    if secured_quote * normalizer > UINT256_MAX:
        raise ValueError("first-ask numerator exceeds uint256")
    if amm_spread * base_seed * size_precision > UINT256_MAX:
        raise ValueError("vault-size numerator exceeds uint256")
    terminal_price = (phantom_quote + secured_quote) * normalizer // (supply * quote_scale)
    kuru_price = secured_quote * normalizer // (base_seed * quote_scale)
    shares = isqrt(base_seed * secured_quote) - MIN_LIQUIDITY
    ask_size = amm_spread * base_seed * size_precision // ((DOUBLE_BPS + amm_spread) * 10**base_decimals)
    bid_size = amm_spread * base_seed * size_precision // (DOUBLE_BPS * 10**base_decimals)
    return SeedQuote(
        base_seed=base_seed,
        excess_base=supply - base_seed,
        terminal_price_scaled=terminal_price,
        kuru_first_ask_price_scaled=kuru_price,
        price_difference=kuru_price - terminal_price,
        lp_shares_to_receiver=shares,
        vault_ask_size=ask_size,
        vault_bid_size=bid_size,
        seedable_in_reduced_model=(
            terminal_price > 0 and kuru_price > 0 and shares > 0
            and 0 < ask_size <= UINT96_MAX and 0 < bid_size <= UINT96_MAX
        ),
    )
