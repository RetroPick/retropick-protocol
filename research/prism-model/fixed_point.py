"""Candidate fixed-point helpers for PRISM MATH-1D.

This module does not finalize Solidity precision. It encodes the conservative
rounding policy being evaluated:
- backing requirements round UP;
- releasable/redemption component amounts round DOWN.

The exact Fraction model remains canonical until MATH-1D is accepted.
"""
from __future__ import annotations

from fractions import Fraction

from replication import F


class FixedPointError(ValueError):
    pass


WAD = 10**18


def mul_div_floor(a: int, b: int, denominator: int) -> int:
    if a < 0 or b < 0 or denominator <= 0:
        raise FixedPointError("mul_div_floor expects non-negative inputs and positive denominator")
    return (a * b) // denominator


def mul_div_ceil(a: int, b: int, denominator: int) -> int:
    if a < 0 or b < 0 or denominator <= 0:
        raise FixedPointError("mul_div_ceil expects non-negative inputs and positive denominator")
    product = a * b
    return (product + denominator - 1) // denominator


def encode_fraction_floor(value, *, scale: int = WAD) -> int:
    v = F(value)
    if v < 0 or scale <= 0:
        raise FixedPointError("invalid fixed-point value/scale")
    return (v.numerator * scale) // v.denominator


def encode_fraction_ceil(value, *, scale: int = WAD) -> int:
    v = F(value)
    if v < 0 or scale <= 0:
        raise FixedPointError("invalid fixed-point value/scale")
    num = v.numerator * scale
    return (num + v.denominator - 1) // v.denominator


def decode_fraction(value: int, *, scale: int = WAD) -> Fraction:
    if value < 0 or scale <= 0:
        raise FixedPointError("invalid fixed-point value/scale")
    return Fraction(value, scale)


def required_backing_units(
    series_quantity_units: int,
    units_per_share_scaled: int,
    *,
    series_scale: int = WAD,
) -> int:
    """Conservative component requirement: ceil(Q * x).

    `series_quantity_units` is quantity in series smallest units.
    `units_per_share_scaled` is normalized component units per one whole series
    share scaled by `series_scale` for this candidate model.

    Real contracts must additionally normalize component token decimals.
    """
    return mul_div_ceil(series_quantity_units, units_per_share_scaled, series_scale)


def releasable_backing_units(
    series_quantity_units: int,
    units_per_share_scaled: int,
    *,
    series_scale: int = WAD,
) -> int:
    """Conservative in-kind release: floor(Q * x)."""
    return mul_div_floor(series_quantity_units, units_per_share_scaled, series_scale)


def round_trip_dust_units(
    series_quantity_units: int,
    units_per_share_scaled: int,
    *,
    series_scale: int = WAD,
) -> int:
    """Backing retained by ceil-on-mint / floor-on-release for one component."""
    required = required_backing_units(
        series_quantity_units,
        units_per_share_scaled,
        series_scale=series_scale,
    )
    released = releasable_backing_units(
        series_quantity_units,
        units_per_share_scaled,
        series_scale=series_scale,
    )
    return required - released


def exact_required_fraction(
    series_quantity_units: int,
    units_per_share_scaled: int,
    *,
    series_scale: int = WAD,
) -> Fraction:
    if series_quantity_units < 0 or units_per_share_scaled < 0 or series_scale <= 0:
        raise FixedPointError("invalid inputs")
    return Fraction(series_quantity_units * units_per_share_scaled, series_scale)
