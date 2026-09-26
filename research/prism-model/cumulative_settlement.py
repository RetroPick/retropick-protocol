"""Candidate cumulative-floor settlement. Not a replacement for FixedPointSettlement.

ADR-R03. The canonical per-call rule remains `FixedPointSettlement.redeem`.
This module is a separate candidate. It is not production Solidity and it is
not an accepted oracle change.

Global cursor, exact integer division:

    paid(R) = floor(R * payout_wad / D)
    this redemption = paid(R_before + q) - paid(R_before)
    D = 10^18 * 10^(18 - settlement_decimals)

Any partition of a fixed supply telescopes to paid(supply). Aggregate holder
receipts therefore equal the one-shot floor. They do not depend on order or
on which holder submits each chunk.

A per-holder cursor does not telescope. That variant is implemented only as a
negative control and is not the candidate.
"""

from __future__ import annotations

from dataclasses import dataclass, field

from fixed_point import WAD, mul_div_ceil, mul_div_floor
from fixed_point_model import FixedPointModelError, decimal_factor


def settlement_denominator(settlement_decimals: int) -> int:
    return WAD * decimal_factor(settlement_decimals)


def one_shot_floor(supply: int, payout_wad: int, settlement_decimals: int) -> int:
    if supply < 0 or payout_wad < 0:
        raise FixedPointModelError("negative supply/payout")
    return mul_div_floor(supply, payout_wad, settlement_denominator(settlement_decimals))


def ceil_funding(supply: int, payout_wad: int, settlement_decimals: int) -> int:
    if supply < 0 or payout_wad < 0:
        raise FixedPointModelError("negative supply/payout")
    return mul_div_ceil(supply, payout_wad, settlement_denominator(settlement_decimals))


def cumulative_delta(redeemed_before: int, quantity: int, payout_wad: int, settlement_decimals: int) -> int:
    if redeemed_before < 0 or quantity < 0 or payout_wad < 0:
        raise FixedPointModelError("negative cumulative arguments")
    denominator = settlement_denominator(settlement_decimals)
    before = mul_div_floor(redeemed_before, payout_wad, denominator)
    after = mul_div_floor(redeemed_before + quantity, payout_wad, denominator)
    return after - before


@dataclass
class CumulativeFloorSettlement:
    """Global-cursor candidate. Supply is allocated to named holders."""

    supply_units: int
    payout_wad: int
    settlement_decimals: int
    balance_raw: int
    balances: dict[str, int]
    redeemed_units: int = 0
    paid_raw: int = 0
    redeemable: bool = False
    receipts: dict[str, int] = field(default_factory=dict)

    def __post_init__(self) -> None:
        if self.supply_units < 0 or self.payout_wad < 0 or self.balance_raw < 0:
            raise FixedPointModelError("negative settlement state")
        decimal_factor(self.settlement_decimals)
        allocated = sum(self.balances.values())
        if allocated != self.supply_units or any(value < 0 for value in self.balances.values()):
            raise FixedPointModelError("holder balances must sum to supply")
        self.receipts = {holder: 0 for holder in self.balances}

    def make_redeemable(self) -> None:
        if self.balance_raw < ceil_funding(self.supply_units, self.payout_wad, self.settlement_decimals):
            raise FixedPointModelError("candidate settlement underfunded")
        self.redeemable = True

    def redeem(self, holder: str, quantity: int) -> int:
        if not self.redeemable:
            raise FixedPointModelError("candidate settlement not redeemable")
        if holder not in self.balances:
            raise FixedPointModelError("unknown holder")
        quantity = int(quantity)
        if quantity <= 0 or quantity > self.balances[holder]:
            raise FixedPointModelError("invalid candidate redemption quantity")
        payout = cumulative_delta(
            self.redeemed_units, quantity, self.payout_wad, self.settlement_decimals
        )
        if payout > self.balance_raw:
            raise FixedPointModelError("candidate payout exceeds balance")
        self.balances[holder] -= quantity
        self.supply_units -= quantity
        self.redeemed_units += quantity
        self.balance_raw -= payout
        self.paid_raw += payout
        self.receipts[holder] += payout
        return payout


def per_holder_cursor_total(chunks: list[tuple[str, int]], payout_wad: int, settlement_decimals: int) -> int:
    """Negative control. Each holder keeps a private cursor.

    This is not the candidate. Independent floors do not telescope.
    """

    cursors: dict[str, int] = {}
    paid = 0
    for holder, quantity in chunks:
        before = cursors.get(holder, 0)
        paid += cumulative_delta(before, quantity, payout_wad, settlement_decimals)
        cursors[holder] = before + quantity
    return paid
