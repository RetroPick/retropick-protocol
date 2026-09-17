"""Deterministic dependency-free adversarial runners for PRISM MATH-1C."""
from __future__ import annotations

import json
import random

from fixed_point_model import FixedPointSeries
from reservation_ledger import ReservationLedger, ReservationError


def run_fixed_point_stress(*, seed: int = 20260917, steps: int = 5000) -> dict[str, int]:
    rng = random.Random(seed)
    series = FixedPointSeries(
        weights_wad=[6 * 10**17, 4 * 10**17],
        component_decimals=[18, 6],
    )
    mint_ops = redeem_ops = terminal_checks = 0
    for _ in range(steps):
        if series.supply_units == 0 or rng.random() < 0.6:
            q = rng.randint(1, 10**15)
            series.mint_with_minimum_backing(q)
            mint_ops += 1
        else:
            q = rng.randint(1, min(series.supply_units, 10**15))
            series.redeem(q)
            redeem_ops += 1
        series.assert_backed()
        for bits in ((0, 1), (0, 0), (1, 1), (1, 0)):
            if not series.terminal_solvency_binary(bits)[2]:
                raise AssertionError(f"fixed-point terminal insolvency at bits={bits}")
            terminal_checks += 1
    return {
        "seed": seed,
        "steps": steps,
        "mint_ops": mint_ops,
        "redeem_ops": redeem_ops,
        "terminal_checks": terminal_checks,
    }


def run_reservation_stress(*, seed: int = 20260917, steps: int = 5000) -> dict[str, int]:
    rng = random.Random(seed)
    ledger = ReservationLedger()
    ledger.deposit("ASSET", 10_000)
    series_ids = [f"S{i}" for i in range(8)]
    reserve_ops = release_ops = rejected_overallocations = 0

    for _ in range(steps):
        sid = rng.choice(series_ids)
        current = ledger.reserved_for(sid, "ASSET")
        if current and rng.random() < 0.45:
            amount = rng.randint(1, int(current))
            ledger.release(sid, {"ASSET": amount})
            release_ops += 1
        else:
            amount = rng.randint(1, 500)
            try:
                ledger.reserve(sid, {"ASSET": amount})
                reserve_ops += 1
            except ReservationError:
                rejected_overallocations += 1
        ledger.assert_globally_backed()

    return {
        "seed": seed,
        "steps": steps,
        "reserve_ops": reserve_ops,
        "release_ops": release_ops,
        "rejected_overallocations": rejected_overallocations,
        "total_reserved": int(ledger.total_reserved("ASSET")),
        "balance": int(ledger.balance("ASSET")),
    }


def main() -> None:
    print(json.dumps({
        "fixed_point": run_fixed_point_stress(),
        "reservation": run_reservation_stress(),
    }, sort_keys=True, indent=2))


if __name__ == "__main__":
    main()
