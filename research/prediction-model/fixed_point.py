"""Integer rounding comparison for prediction redemption.

Phase-1 binary payouts are 1, 0, or 1/2 of a collateral unit. Matching outcome
decimals to collateral decimals keeps YES_WIN and NO_WIN as exact integer
identities. A second 18-decimal normalization does not pay more collateral
than the collateral-native floor for the power-of-ten scales below, and it
adds a second rounding boundary.
"""

from __future__ import annotations

from complete_set import integer_payout_delta, naive_half_up, per_call_floor_half


SCALES = (10**6, 10**12, 10**18)


def collateral_native_half_total(supply: int) -> int:
    """Both sides fully redeemed with cumulative floor(q/2), supplies equal."""

    paid = 0
    cursor = 0
    for _ in range(supply):
        paid += integer_payout_delta(cursor, 1, 1, 2)
        cursor += 1
    return paid * 2


def normalized_half_collateral_out(supply_raw: int, token_scale: int) -> int:
    """Pay floor on token units, then convert back to collateral units.

    token_supply = supply_raw * token_scale. One side's full redemption pays
    floor(token_supply / 2) token units, converted by floor(token / token_scale).
    """

    if token_scale <= 0:
        raise ValueError("token scale must be positive")
    token_supply = supply_raw * token_scale
    token_paid = integer_payout_delta(0, token_supply, 1, 2)
    return token_paid // token_scale


def dust_bound(collateral: int) -> int:
    """Dust left when both sides of an equal complete set are fully redeemed."""

    return collateral - collateral_native_half_total(collateral)


def compare_scales(max_supply: int = 64) -> dict[str, int | bool]:
    mismatches = 0
    checked = 0
    for supply in range(0, max_supply + 1):
        native_one_side = 0
        cursor = 0
        for _ in range(supply):
            native_one_side += integer_payout_delta(cursor, 1, 1, 2)
            cursor += 1
        batched = integer_payout_delta(0, supply, 1, 2)
        if native_one_side != batched:
            mismatches += 1
        for scale in SCALES:
            converted = normalized_half_collateral_out(supply, scale)
            checked += 1
            if converted != batched:
                mismatches += 1
    return {
        "max_supply": max_supply,
        "scales": len(SCALES),
        "checked_conversions": checked,
        "mismatches": mismatches,
        "identity": mismatches == 0,
    }


def fragmentation_gap(supply: int) -> int:
    """How much per-call floor(q/2) underpays a 1-unit stream versus cumulative floor.

    per-call floor(1/2) is always 0, so the gap equals the cumulative total.
    """

    per_call = sum(per_call_floor_half(1) for _ in range(supply))
    cumulative = integer_payout_delta(0, supply, 1, 2)
    return cumulative - per_call


def half_up_both_sides(quantity: int) -> int:
    return naive_half_up(quantity) + naive_half_up(quantity)
