"""Integer-only PRISM reference model for MATH-1D theorem transfer.

Scope:
- series token scale is WAD (1e18);
- component ERC-20 decimals must be in [0, 18];
- component payoff states are binary (0 or 1 settlement unit), matching
  Phase-1 native outcome assets;
- backing requirements round UP in raw component units;
- redeemable component release is computed from the decrease in conservative
  post-redemption requirement, never from optimistic rounding.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Sequence

from fixed_point import WAD, mul_div_ceil


class FixedPointModelError(ValueError):
    pass


def decimal_factor(decimals: int) -> int:
    if not isinstance(decimals, int) or decimals < 0 or decimals > 18:
        raise FixedPointModelError("Phase-1 normalized component decimals must be 0..18")
    return 10 ** (18 - decimals)


def normalize_raw(raw_units: int, decimals: int) -> int:
    if raw_units < 0:
        raise FixedPointModelError("negative raw amount")
    return raw_units * decimal_factor(decimals)


def required_component_raw(
    series_quantity_units: int,
    weight_wad: int,
    token_decimals: int,
) -> int:
    if series_quantity_units < 0 or weight_wad < 0:
        raise FixedPointModelError("negative quantity/weight")
    factor = decimal_factor(token_decimals)
    return mul_div_ceil(series_quantity_units, weight_wad, WAD * factor)


def terminal_liability_normalized(
    series_supply_units: int,
    weights_wad: Sequence[int],
    winning_bits: Sequence[int],
) -> int:
    if len(weights_wad) != len(winning_bits):
        raise FixedPointModelError("dimension mismatch")
    if any(w < 0 for w in weights_wad):
        raise FixedPointModelError("negative weight")
    if any(bit not in (0, 1) for bit in winning_bits):
        raise FixedPointModelError("binary component payoff must be 0 or 1")
    payoff_wad = sum(w for w, bit in zip(weights_wad, winning_bits) if bit)
    return mul_div_ceil(series_supply_units, payoff_wad, WAD)


@dataclass
class FixedPointSeries:
    weights_wad: Sequence[int]
    component_decimals: Sequence[int]
    supply_units: int = 0
    backing_raw: list[int] = field(default_factory=list)

    def __post_init__(self):
        self.weights_wad = tuple(int(w) for w in self.weights_wad)
        self.component_decimals = tuple(int(d) for d in self.component_decimals)
        if not self.weights_wad or len(self.weights_wad) != len(self.component_decimals):
            raise FixedPointModelError("component dimension mismatch")
        if any(w < 0 for w in self.weights_wad):
            raise FixedPointModelError("negative weight")
        for d in self.component_decimals:
            decimal_factor(d)
        if self.supply_units < 0:
            raise FixedPointModelError("negative supply")
        if not self.backing_raw:
            self.backing_raw = [0 for _ in self.weights_wad]
        if len(self.backing_raw) != len(self.weights_wad) or any(v < 0 for v in self.backing_raw):
            raise FixedPointModelError("invalid backing vector")

    def required_backing_raw(self, supply_units: int | None = None) -> tuple[int, ...]:
        s = self.supply_units if supply_units is None else int(supply_units)
        if s < 0:
            raise FixedPointModelError("negative supply")
        return tuple(
            required_component_raw(s, self.weights_wad[i], self.component_decimals[i])
            for i in range(len(self.weights_wad))
        )

    def assert_backed(self) -> bool:
        req = self.required_backing_raw()
        if any(self.backing_raw[i] < req[i] for i in range(len(req))):
            raise FixedPointModelError("fixed-point component backing invariant violated")
        return True

    def deposit_raw(self, amounts: Sequence[int]) -> None:
        if len(amounts) != len(self.backing_raw) or any(int(v) < 0 for v in amounts):
            raise FixedPointModelError("invalid deposit vector")
        for i, value in enumerate(amounts):
            self.backing_raw[i] += int(value)
        if self.supply_units:
            self.assert_backed()

    def minimum_incremental_backing(self, mint_quantity_units: int) -> tuple[int, ...]:
        q = int(mint_quantity_units)
        if q <= 0:
            raise FixedPointModelError("mint quantity must be positive")
        old_req = self.required_backing_raw()
        new_req = self.required_backing_raw(self.supply_units + q)
        return tuple(new_req[i] - old_req[i] for i in range(len(old_req)))

    def mint(self, quantity_units: int) -> None:
        q = int(quantity_units)
        if q <= 0:
            raise FixedPointModelError("mint quantity must be positive")
        new_supply = self.supply_units + q
        req = self.required_backing_raw(new_supply)
        if any(self.backing_raw[i] < req[i] for i in range(len(req))):
            raise FixedPointModelError("insufficient fixed-point backing for mint")
        self.supply_units = new_supply
        self.assert_backed()

    def mint_with_minimum_backing(self, quantity_units: int) -> tuple[int, ...]:
        delta = self.minimum_incremental_backing(quantity_units)
        self.deposit_raw(delta)
        self.mint(quantity_units)
        return delta

    def redeem(self, quantity_units: int) -> tuple[int, ...]:
        q = int(quantity_units)
        if q <= 0 or q > self.supply_units:
            raise FixedPointModelError("invalid redemption quantity")
        old_req = self.required_backing_raw()
        new_supply = self.supply_units - q
        new_req = self.required_backing_raw(new_supply)
        released = tuple(old_req[i] - new_req[i] for i in range(len(old_req)))
        self.supply_units = new_supply
        for i, value in enumerate(released):
            if value > self.backing_raw[i]:
                raise FixedPointModelError("release exceeds backing")
            self.backing_raw[i] -= value
        self.assert_backed()
        return released

    def terminal_backing_value_normalized(self, winning_bits: Sequence[int]) -> int:
        if len(winning_bits) != len(self.backing_raw):
            raise FixedPointModelError("dimension mismatch")
        if any(bit not in (0, 1) for bit in winning_bits):
            raise FixedPointModelError("binary component payoff must be 0 or 1")
        return sum(
            normalize_raw(self.backing_raw[i], self.component_decimals[i])
            for i, bit in enumerate(winning_bits)
            if bit
        )

    def terminal_solvency_binary(self, winning_bits: Sequence[int]) -> tuple[int, int, bool]:
        backing_value = self.terminal_backing_value_normalized(winning_bits)
        liability = terminal_liability_normalized(
            self.supply_units, self.weights_wad, winning_bits
        )
        return backing_value, liability, backing_value >= liability

    def sweepable_dust(self) -> tuple[int, ...]:
        if self.supply_units != 0:
            raise FixedPointModelError("dust cannot be swept while liability remains")
        return tuple(self.backing_raw)

    def sweep_dust(self) -> tuple[int, ...]:
        dust = self.sweepable_dust()
        self.backing_raw = [0 for _ in self.backing_raw]
        return dust


def required_settlement_raw(
    series_supply_units: int,
    payout_wad: int,
    settlement_decimals: int,
) -> int:
    if series_supply_units < 0 or payout_wad < 0:
        raise FixedPointModelError("negative supply/payout")
    factor = decimal_factor(settlement_decimals)
    return mul_div_ceil(series_supply_units, payout_wad, WAD * factor)


def redemption_payout_raw_floor(
    quantity_units: int,
    payout_wad: int,
    settlement_decimals: int,
) -> int:
    if quantity_units < 0 or payout_wad < 0:
        raise FixedPointModelError("negative quantity/payout")
    factor = decimal_factor(settlement_decimals)
    return (quantity_units * payout_wad) // (WAD * factor)


@dataclass
class FixedPointSettlement:
    supply_units: int
    payout_wad: int
    settlement_decimals: int
    balance_raw: int = 0
    redeemable: bool = False

    def __post_init__(self):
        if self.supply_units < 0 or self.payout_wad < 0 or self.balance_raw < 0:
            raise FixedPointModelError("negative settlement state")
        decimal_factor(self.settlement_decimals)

    def required_balance_raw(self, supply_units: int | None = None) -> int:
        s = self.supply_units if supply_units is None else int(supply_units)
        return required_settlement_raw(s, self.payout_wad, self.settlement_decimals)

    def fund(self, amount_raw: int) -> None:
        if amount_raw < 0:
            raise FixedPointModelError("negative settlement funding")
        self.balance_raw += int(amount_raw)

    def make_redeemable(self) -> None:
        if self.balance_raw < self.required_balance_raw():
            raise FixedPointModelError("fixed-point settlement underfunded")
        self.redeemable = True

    def redeem(self, quantity_units: int) -> int:
        q = int(quantity_units)
        if not self.redeemable:
            raise FixedPointModelError("settlement not redeemable")
        if q <= 0 or q > self.supply_units:
            raise FixedPointModelError("invalid settlement redemption quantity")
        payout_raw = redemption_payout_raw_floor(
            q, self.payout_wad, self.settlement_decimals
        )
        if payout_raw > self.balance_raw:
            raise FixedPointModelError("insufficient settlement balance")
        new_supply = self.supply_units - q
        new_balance = self.balance_raw - payout_raw
        if new_balance < self.required_balance_raw(new_supply):
            raise FixedPointModelError("redemption would underfund remaining liability")
        self.supply_units = new_supply
        self.balance_raw = new_balance
        return payout_raw

    def sweepable_dust(self) -> int:
        if self.supply_units != 0:
            raise FixedPointModelError("settlement dust cannot be swept with live liability")
        return self.balance_raw
