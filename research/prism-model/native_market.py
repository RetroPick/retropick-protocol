"""Stateful fully-collateralized binary complete-set reference model."""
from __future__ import annotations

from dataclasses import dataclass
from enum import Enum
from fractions import Fraction

from replication import F


class NativeMarketError(ValueError):
    pass


class NativeMarketState(str, Enum):
    ACTIVE = "ACTIVE"
    RESOLVED = "RESOLVED"
    ARCHIVED = "ARCHIVED"


@dataclass
class BinaryCompleteSetMarket:
    state: NativeMarketState = NativeMarketState.ACTIVE
    collateral_locked: Fraction = Fraction(0)
    yes_supply: Fraction = Fraction(0)
    no_supply: Fraction = Fraction(0)
    winner: str | None = None

    def split(self, quantity):
        q = F(quantity)
        if self.state != NativeMarketState.ACTIVE:
            raise NativeMarketError("split only allowed while ACTIVE")
        if q <= 0:
            raise NativeMarketError("split quantity must be positive")
        self.collateral_locked += q
        self.yes_supply += q
        self.no_supply += q
        self.assert_invariants()
        return q, q

    def merge(self, quantity):
        q = F(quantity)
        if self.state != NativeMarketState.ACTIVE:
            raise NativeMarketError("merge only allowed while ACTIVE")
        if q <= 0 or q > self.yes_supply or q > self.no_supply:
            raise NativeMarketError("invalid merge quantity")
        self.yes_supply -= q
        self.no_supply -= q
        self.collateral_locked -= q
        self.assert_invariants()
        return q

    def resolve(self, winner: str):
        if self.state != NativeMarketState.ACTIVE:
            raise NativeMarketError("market already resolved or archived")
        normalized = winner.upper()
        if normalized not in {"YES", "NO"}:
            raise NativeMarketError("winner must be YES or NO")
        self.winner = normalized
        self.state = NativeMarketState.RESOLVED
        self.assert_invariants()

    def redeem(self, outcome: str, quantity):
        if self.state != NativeMarketState.RESOLVED:
            raise NativeMarketError("redemption requires RESOLVED market")
        side = outcome.upper()
        if side not in {"YES", "NO"}:
            raise NativeMarketError("outcome must be YES or NO")
        q = F(quantity)
        if q <= 0:
            raise NativeMarketError("redemption quantity must be positive")

        if side == "YES":
            if q > self.yes_supply:
                raise NativeMarketError("redemption exceeds YES supply")
            self.yes_supply -= q
        else:
            if q > self.no_supply:
                raise NativeMarketError("redemption exceeds NO supply")
            self.no_supply -= q

        payout = q if side == self.winner else Fraction(0)
        if payout:
            if payout > self.collateral_locked:
                raise NativeMarketError("insufficient locked collateral")
            self.collateral_locked -= payout
        self.assert_invariants()
        return payout

    def open_interest(self) -> Fraction:
        if self.state == NativeMarketState.ACTIVE:
            self.assert_invariants()
            return self.collateral_locked
        return self.winning_supply()

    def winning_supply(self) -> Fraction:
        if self.winner == "YES":
            return self.yes_supply
        if self.winner == "NO":
            return self.no_supply
        return Fraction(0)

    def archive(self):
        if self.state != NativeMarketState.RESOLVED:
            raise NativeMarketError("archive requires RESOLVED market")
        if self.collateral_locked != 0 or self.yes_supply != 0 or self.no_supply != 0:
            raise NativeMarketError("archive requires all claims settled/burned")
        self.state = NativeMarketState.ARCHIVED
        self.assert_invariants()

    def assert_invariants(self) -> bool:
        if min(self.collateral_locked, self.yes_supply, self.no_supply) < 0:
            raise NativeMarketError("negative accounting state")
        if self.state == NativeMarketState.ACTIVE:
            if not (self.yes_supply == self.no_supply == self.collateral_locked):
                raise NativeMarketError("complete-set conservation violated")
        elif self.state == NativeMarketState.RESOLVED:
            if self.winner not in {"YES", "NO"}:
                raise NativeMarketError("resolved market missing winner")
            if self.collateral_locked != self.winning_supply():
                raise NativeMarketError("resolved collateral must equal remaining winning claims")
        elif self.state == NativeMarketState.ARCHIVED:
            if self.collateral_locked or self.yes_supply or self.no_supply:
                raise NativeMarketError("archived market must have zero balances")
        return True
