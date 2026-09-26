"""Fresh MATH-1 probes. Does not change the canonical oracle semantics.

The settlement section searches for value that per-call floor can move into
sweepable dust. A positive result is a counterexample, not a failed run of
this script.
"""

from __future__ import annotations

import json
import random
import time
from fractions import Fraction

from adversarial import run_fixed_point_stress, run_reservation_stress
from fixed_point import WAD, mul_div_ceil, mul_div_floor
from fixed_point_model import (
    FixedPointSeries,
    FixedPointSettlement,
    redemption_payout_raw_floor,
    required_settlement_raw,
)
from replication import find_exact_nonnegative_replication, payoff


def settlement_fragmentation_counterexample() -> dict[str, int | str]:
    """Many 1-unit redemptions can pay 0 while one-shot floor pays the holders.

    After supply reaches 0 the model allows sweep_dust of the remainder.
    """

    decimals = 1
    # D = WAD * 10^(18-decimals) = 10^18 * 10^17 = 10^35, too coarse.
    # Use settlement decimals 18 so D = WAD * 1 = 10^18.
    # payout_wad = 10^18 - 1, supply = 10^18 is too big to loop.
    # Smaller equivalent: think in units of D. Use the raw formula directly.
    payout_wad = WAD - 1
    supply = 2
    settlement_decimals = 18
    required = required_settlement_raw(supply, payout_wad, settlement_decimals)
    one_shot = redemption_payout_raw_floor(supply, payout_wad, settlement_decimals)
    per_unit = redemption_payout_raw_floor(1, payout_wad, settlement_decimals)
    settlement = FixedPointSettlement(
        supply_units=supply,
        payout_wad=payout_wad,
        settlement_decimals=settlement_decimals,
        balance_raw=required,
    )
    settlement.make_redeemable()
    paid = 0
    for _ in range(supply):
        paid += settlement.redeem(1)
    dust = settlement.sweepable_dust()
    return {
        "supply": supply,
        "payout_wad": payout_wad,
        "required_raw": required,
        "one_shot_floor_raw": one_shot,
        "per_unit_floor_raw": per_unit,
        "fragmented_paid_raw": paid,
        "swept_dust_raw": dust,
        "classification": "COUNTEREXAMPLE_FOUND" if dust > one_shot - paid and paid < one_shot else "NOT_FOUND",
    }


def cumulative_floor_dust(supply: int, payout_wad: int, decimals: int = 18) -> dict[str, int]:
    """Candidate repair: pay the delta of floors, matching component requirement style.

    Total paid after the whole supply is redeemed equals floor(supply * payout / D).
    Dust against the ceil funding requirement is 0 or 1 raw unit when the balance
    started at exactly that ceil.
    """

    factor = 10 ** (18 - decimals)
    denominator = WAD * factor
    required = mul_div_ceil(supply, payout_wad, denominator)
    paid = 0
    cursor = 0
    for _ in range(supply):
        paid += mul_div_floor(cursor + 1, payout_wad, denominator) - mul_div_floor(cursor, payout_wad, denominator)
        cursor += 1
    one_shot = mul_div_floor(supply, payout_wad, denominator)
    return {
        "required": required,
        "paid": paid,
        "one_shot": one_shot,
        "dust": required - paid,
    }


def search_cumulative_dust(*, limit: int = 40) -> dict[str, int | bool]:
    worst = 0
    checked = 0
    for supply in range(1, limit + 1):
        for payout in (1, 2, WAD // 2, WAD - 1, WAD, WAD + 7):
            row = cumulative_floor_dust(supply, payout)
            checked += 1
            if row["paid"] != row["one_shot"]:
                raise AssertionError(row)
            if row["dust"] < 0 or row["dust"] > 1:
                raise AssertionError(row)
            worst = max(worst, row["dust"])
    return {"checked": checked, "worst_dust": worst, "bounded_by_one": worst <= 1}


def component_round_trip_samples(samples: int = 200, seed: int = 20260926) -> dict[str, int]:
    rng = random.Random(seed)
    for _ in range(samples):
        decimals = [rng.randrange(0, 19), rng.randrange(0, 19)]
        weights = [rng.randrange(0, 2 * WAD), rng.randrange(0, 2 * WAD)]
        series = FixedPointSeries(weights_wad=weights, component_decimals=decimals)
        quantity = rng.randrange(1, 10**6)
        deposited = series.mint_with_minimum_backing(quantity)
        released = series.redeem(quantity)
        if deposited != released or series.supply_units != 0:
            raise AssertionError((deposited, released, series.supply_units))
        if any(value != 0 for value in series.backing_raw):
            raise AssertionError(series.backing_raw)
    return {"samples": samples, "seed": seed, "mismatches": 0}


def multi_seed_stress() -> list[dict[str, int]]:
    rows = []
    for seed in (1, 7, 20260917, 20260926):
        started = time.perf_counter()
        fixed = run_fixed_point_stress(seed=seed, steps=200)
        reservation = run_reservation_stress(seed=seed, steps=200)
        rows.append(
            {
                "seed": seed,
                "fixed_steps": fixed["steps"],
                "reservation_rejected": reservation["rejected_overallocations"],
                "runtime_seconds": round(time.perf_counter() - started, 6),
            }
        )
    return rows


def independent_surplus_grid(max_supply: int = 3, max_extra: int = 2) -> dict[str, int]:
    """Two-component exact grid with independent surplus, not a shared scalar."""

    weights = (Fraction(1, 2), Fraction(1, 3))
    cases = 0
    for s in range(max_supply + 1):
        for extra0 in range(max_extra + 1):
            for extra1 in range(max_extra + 1):
                backing = (s * weights[0] + extra0, s * weights[1] + extra1)
                for q in range(1, max_supply + 1):
                    minted = tuple(backing[i] + q * weights[i] for i in range(2))
                    if any(minted[i] < (s + q) * weights[i] for i in range(2)):
                        raise AssertionError((s, q, backing))
                    cases += 1
                for q in range(1, s + 1):
                    redeemed = tuple(backing[i] - q * weights[i] for i in range(2))
                    if any(redeemed[i] < (s - q) * weights[i] for i in range(2)):
                        raise AssertionError((s, q, backing))
                    cases += 1
    return {"cases": cases, "max_supply": max_supply, "max_extra": max_extra}


def and_counterexample() -> dict[str, str]:
    matrix = ((0, 0, 1), (0, 1, 1), (1, 0, 1), (1, 1, 1))
    target = (0, 0, 0, 1)
    found = find_exact_nonnegative_replication(matrix, target)
    return {
        "result": "None" if found is None else str(found),
        "classification": "COUNTEREXAMPLE_FOUND" if found is None else "REPLICABLE",
    }


def z3_reports() -> dict[str, str]:
    try:
        import z3
    except ImportError:
        return {"status": "BLOCKED_TOOL", "detail": "z3 import failed"}

    solver = z3.Solver()
    x, y = z3.Reals("x y")
    # x*(0,0,1,1) + y*(0,1,0,1) + z*1 cannot hit (0,0,0,1) for z>=0 either
    # when the third column is the constant 1. Negative control uses A, B, and 1.
    z = z3.Real("z")
    solver.add(x >= 0, y >= 0, z >= 0)
    solver.add(z == 0)  # state (0,0)
    solver.add(y + z == 0)  # state (0,1) if B=(0,1,0,1) and ones=(1,1,1,1)
    solver.add(x + z == 0)
    solver.add(x + y + z == 1)
    and_status = "COUNTEREXAMPLE_FOUND" if solver.check() == z3.unsat else "SAT_UNEXPECTED"

    # Non-negative backing implies terminal solvency for one state and two components.
    proof = z3.Solver()
    S, x0, x1, B0, B1, g0, g1 = z3.Reals("S x0 x1 B0 B1 g0 g1")
    proof.add(S >= 0, x0 >= 0, x1 >= 0, g0 >= 0, g1 >= 0)
    proof.add(B0 >= S * x0, B1 >= S * x1)
    proof.add(B0 * g0 + B1 * g1 < S * (x0 * g0 + x1 * g1))
    solvency = "PROVEN_UNDER_ASSUMPTIONS" if proof.check() == z3.unsat else "COUNTEREXAMPLE_FOUND"
    return {
        "z3_version": str(z3.get_version_string()),
        "and_with_constant": and_status,
        "two_component_terminal_solvency": solvency,
    }


def sympy_identity() -> dict[str, str]:
    try:
        import sympy
    except ImportError:
        return {"status": "BLOCKED_TOOL"}
    S, x0, x1, B0, B1, g0, g1 = sympy.symbols("S x0 x1 B0 B1 g0 g1", nonnegative=True)
    gap = (B0 * g0 + B1 * g1) - S * (x0 * g0 + x1 * g1)
    rewritten = sympy.simplify(gap - ((B0 - S * x0) * g0 + (B1 - S * x1) * g1))
    return {
        "sympy_version": sympy.__version__,
        "gap_matches_margin_dot_payoff": str(rewritten == 0),
        "classification": "PROVEN_UNDER_ASSUMPTIONS" if rewritten == 0 else "COUNTEREXAMPLE_FOUND",
    }


def runtime_matrix() -> list[dict[str, int | float]]:
    """Time exact payoff evaluation. Pairs are (components, states)."""

    rows = []
    shapes = ((2, 4), (4, 4), (4, 16), (8, 16), (16, 16))
    for components, states in shapes:
        matrix = tuple(tuple(Fraction((s + c) % 2) for c in range(components)) for s in range(states))
        weights = tuple(Fraction(1, components) for _ in range(components))
        started = time.perf_counter()
        iterations = 200
        for _ in range(iterations):
            payoff(matrix, weights)
        elapsed = time.perf_counter() - started
        rows.append(
            {
                "components": components,
                "states": states,
                "iterations": iterations,
                "runtime_seconds": round(elapsed, 6),
            }
        )
    return rows


def main() -> dict:
    started = time.perf_counter()
    report = {
        "settlement_fragmentation": settlement_fragmentation_counterexample(),
        "cumulative_floor_dust": search_cumulative_dust(),
        "component_round_trip": component_round_trip_samples(),
        "multi_seed": multi_seed_stress(),
        "independent_surplus": independent_surplus_grid(),
        "and_counterexample": and_counterexample(),
        "z3": z3_reports(),
        "sympy": sympy_identity(),
        "payoff_runtimes": runtime_matrix(),
        "runtime_seconds": round(time.perf_counter() - started, 6),
    }
    print(json.dumps(report, indent=2, sort_keys=True))
    return report


if __name__ == "__main__":
    main()
