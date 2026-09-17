"""Global backing reservation ledger for cross-series MATH-1C checks.

The local PrismSeries model proves each series is backed relative to its own
accounting. This ledger models the additional global property that the same
physical units cannot be pledged to multiple series at once.
"""
from __future__ import annotations

from collections import defaultdict
from fractions import Fraction
from typing import Mapping

from replication import F


class ReservationError(ValueError):
    pass


class ReservationLedger:
    def __init__(self):
        self._balances: dict[str, Fraction] = defaultdict(Fraction)
        self._reservations: dict[str, dict[str, Fraction]] = defaultdict(dict)

    def balance(self, asset: str) -> Fraction:
        return self._balances[asset]

    def reserved_for(self, series_id: str, asset: str) -> Fraction:
        return self._reservations.get(series_id, {}).get(asset, Fraction(0))

    def total_reserved(self, asset: str) -> Fraction:
        return sum(
            (allocations.get(asset, Fraction(0)) for allocations in self._reservations.values()),
            Fraction(0),
        )

    def available(self, asset: str) -> Fraction:
        return self.balance(asset) - self.total_reserved(asset)

    def deposit(self, asset: str, amount) -> None:
        a = F(amount)
        if a < 0:
            raise ReservationError("negative deposit")
        self._balances[asset] += a
        self.assert_globally_backed()

    def reserve(self, series_id: str, requirements: Mapping[str, object]) -> None:
        if not series_id:
            raise ReservationError("series_id required")
        normalized = {asset: F(amount) for asset, amount in requirements.items()}
        if any(amount < 0 for amount in normalized.values()):
            raise ReservationError("negative reservation")

        for asset, amount in normalized.items():
            if amount > self.available(asset):
                raise ReservationError(
                    f"insufficient unreserved balance for {asset}: "
                    f"requested={amount}, available={self.available(asset)}"
                )

        bucket = self._reservations[series_id]
        for asset, amount in normalized.items():
            bucket[asset] = bucket.get(asset, Fraction(0)) + amount
        self.assert_globally_backed()

    def release(self, series_id: str, releases: Mapping[str, object]) -> None:
        bucket = self._reservations.get(series_id)
        if bucket is None:
            raise ReservationError("unknown series reservation")
        normalized = {asset: F(amount) for asset, amount in releases.items()}
        if any(amount < 0 for amount in normalized.values()):
            raise ReservationError("negative release")
        for asset, amount in normalized.items():
            if amount > bucket.get(asset, Fraction(0)):
                raise ReservationError("release exceeds series reservation")
        for asset, amount in normalized.items():
            bucket[asset] -= amount
            if bucket[asset] == 0:
                del bucket[asset]
        if not bucket:
            self._reservations.pop(series_id, None)
        self.assert_globally_backed()

    def withdraw(self, asset: str, amount) -> None:
        a = F(amount)
        if a < 0:
            raise ReservationError("negative withdrawal")
        if a > self.available(asset):
            raise ReservationError("withdrawal would consume reserved backing")
        self._balances[asset] -= a
        self.assert_globally_backed()

    def series_snapshot(self, series_id: str) -> dict[str, Fraction]:
        return dict(self._reservations.get(series_id, {}))

    def assert_globally_backed(self) -> bool:
        assets = set(self._balances)
        for bucket in self._reservations.values():
            assets.update(bucket)
        for asset in assets:
            reserved = self.total_reserved(asset)
            balance = self.balance(asset)
            if reserved < 0 or balance < 0 or reserved > balance:
                raise ReservationError(
                    f"global reservation invariant violated for {asset}: "
                    f"reserved={reserved}, balance={balance}"
                )
        return True
