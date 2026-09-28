"""Adversarial holder-allocation probe for the proposed global settlement cursor.

This does not change the aggregate telescoping theorem or the canonical failing
per-call oracle. It tests a different claim: whether each holder receives the
floor of that holder's independently valued units despite call ordering.
"""

from __future__ import annotations

import json
from typing import Any

import z3

from cumulative_settlement import CumulativeFloorSettlement, ceil_funding, one_shot_floor
from fixed_point import WAD
from fixed_point_model import decimal_factor


PAYOUT_WAD = WAD // 2 + 1
MAX_FORMAL_PAIRS = WAD // 4


def alternating_witness(decimals: int, pairs: int) -> dict[str, Any]:
    """A redeems before B in each pair; both initially own ``pairs`` chunks."""

    if pairs < 1 or pairs > 1_000:
        raise ValueError("executable witness domain is 1..1000 pairs")
    chunk = decimal_factor(decimals)
    each = pairs * chunk
    supply = 2 * each
    funded = ceil_funding(supply, PAYOUT_WAD, decimals)
    book = CumulativeFloorSettlement(supply, PAYOUT_WAD, decimals, funded, {"A": each, "B": each})
    book.make_redeemable()
    for _ in range(pairs):
        book.redeem("A", chunk)
        book.redeem("B", chunk)

    isolated_floor = one_shot_floor(each, PAYOUT_WAD, decimals)
    aggregate_floor = one_shot_floor(supply, PAYOUT_WAD, decimals)
    assert book.supply_units == 0
    assert book.paid_raw == aggregate_floor
    assert book.receipts == {"A": 0, "B": pairs}
    assert isolated_floor == pairs // 2
    assert funded == pairs + 1
    assert book.balance_raw == 1
    return {
        "decimals": decimals,
        "pairs": pairs,
        "chunk_units": str(chunk),
        "initial_units_per_holder": str(each),
        "supply_units": str(supply),
        "payout_wad": str(PAYOUT_WAD),
        "exact_ceil_funding_raw": str(funded),
        "aggregate_paid_raw": str(book.paid_raw),
        "aggregate_one_shot_floor_raw": str(aggregate_floor),
        "holder_a_paid_raw": str(book.receipts["A"]),
        "holder_b_paid_raw": str(book.receipts["B"]),
        "isolated_holder_floor_raw": str(isolated_floor),
        "holder_a_shortfall_raw": str(isolated_floor - book.receipts["A"]),
        "holder_b_surplus_over_isolated_floor_raw": str(book.receipts["B"] - isolated_floor),
        "residual_raw": str(book.balance_raw),
    }


def prove_alternating_family() -> dict[str, Any]:
    """Prove the witness family over all 1 <= n <= WAD/4 and 0 <= j < n.

    For a decimal factor f, each call redeems f units and D = WAD*f, so the
    quotient at the k-th call is floor(k*(WAD/2+1)/WAD). The same proof applies
    to every admitted decimal value 0..18 without multiplying huge bitvectors.
    """

    n, j = z3.Ints("n j")
    payout = PAYOUT_WAD

    def paid(k: z3.ArithRef) -> z3.ArithRef:
        return (k * payout) / WAD

    checks = {
        "A_step_is_zero": (paid(2 * j + 1) - paid(2 * j)) != 0,
        "B_step_is_one": (paid(2 * j + 2) - paid(2 * j + 1)) != 1,
        "aggregate_floor_is_n": paid(2 * n) != n,
        "isolated_floor_is_n_div_2": paid(n) != n / 2,
        "exact_ceil_funding_is_n_plus_one": ((2 * n * payout + WAD - 1) / WAD) != n + 1,
    }
    results: dict[str, str] = {}
    for name, negation in checks.items():
        solver = z3.Solver()
        solver.add(n >= 1, n <= MAX_FORMAL_PAIRS, j >= 0, j < n, negation)
        result = solver.check()
        results[name] = str(result)
    return {
        "z3_version": z3.get_version_string(),
        "domain": f"1 <= n <= {MAX_FORMAL_PAIRS}; 0 <= j < n; decimals 0..18",
        "negated_claim_results": results,
        "classification": (
            "PROVEN_UNDER_ASSUMPTIONS" if all(result == "unsat" for result in results.values()) else "NOT_YET_VALIDATED"
        ),
    }


def run() -> dict[str, Any]:
    formal = prove_alternating_family()
    cases = [alternating_witness(decimals, pairs) for decimals in (6, 8, 18) for pairs in (2, 10, 1_000)]
    return {
        "id": "CX-FP-CUM-HOLDER-001",
        "candidate": "global cumulative redeemed cursor",
        "classification": "COUNTEREXAMPLE_FOUND",
        "falsified_claim": "each holder receives at least floor(holder units * payout_wad / D) under arbitrary fragmentation and ordering",
        "aggregate_telescope": "PROVEN_UNDER_ASSUMPTIONS and unchanged",
        "canonical_per_call_MATH_1D": "FAIL and unchanged",
        "ordering": "A then B, each redeeming one decimal-factor-sized chunk, repeated n times",
        "formal_family": formal,
        "executable_cases": cases,
        "interpretation": "The unpaid amount for A is paid to B; exact-ceil residual remains one raw unit. The per-holder deviation grows with the number of alternating calls within the stated domain. Economic exploitability depends on call costs and settlement-token value.",
    }


if __name__ == "__main__":
    print(json.dumps(run(), indent=2, sort_keys=True))
