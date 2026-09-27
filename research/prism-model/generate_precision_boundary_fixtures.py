"""Fixtures for the 6/8/18 matrix against the existing Solidity candidate.

Cells whose supply * payout product does not fit in uint256 are excluded.
Zero supply is excluded because the candidate constructor reverts.
Per-call underpayment stays a Python regression. This module does not change
either payout formula.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from cumulative_settlement import (  # noqa: E402
    CumulativeFloorSettlement,
    ceil_funding,
    one_shot_floor,
    settlement_denominator,
)
from precision_boundary import (  # noqa: E402
    DECIMALS,
    SUPPLIES,
    UINT256_MAX,
    _canonical_shape,
    _per_call,
    payouts_for,
)


OUT = Path(__file__).resolve().parent / "fixtures" / "precision_boundary_cumulative.json"


def _fits(supply: int, payout: int) -> bool:
    return supply * payout <= UINT256_MAX


def _cumulative_case(decimals: int, supply: int, payout: int) -> dict:
    if supply == 1:
        initial = [("A", 1)]
        steps = [("A", 1)]
    else:
        initial = [("A", 1), ("B", supply - 1)]
        steps = [("A", 1), ("B", supply - 1)]
    balances = {label: qty for label, qty in initial}
    funded = ceil_funding(supply, payout, decimals)
    book = CumulativeFloorSettlement(supply, payout, decimals, funded, dict(balances))
    book.make_redeemable()
    labels = [label for label, _ in initial]
    index = {label: position for position, label in enumerate(labels)}
    holder_index: list[int] = []
    quantities: list[int] = []
    payouts: list[int] = []
    for label, qty in steps:
        paid = book.redeem(label, qty)
        holder_index.append(index[label])
        quantities.append(qty)
        payouts.append(paid)
    shot = one_shot_floor(supply, payout, decimals)
    return {
        "id": f"d{decimals}_s{supply}_p{payout}",
        "supply": str(supply),
        "payout_wad": str(payout),
        "decimals": decimals,
        "denominator": str(settlement_denominator(decimals)),
        "ceil_funding": str(funded),
        "one_shot_floor": str(shot),
        "holder_count": len(labels),
        "balances": [str(balances[label]) for label in labels],
        "step_count": len(steps),
        "holder_index": holder_index,
        "quantities": [str(qty) for qty in quantities],
        "payouts": [str(paid) for paid in payouts],
        "receipts": [str(book.receipts[label]) for label in labels],
        "paid_total": str(book.paid_raw),
        "residual": str(book.balance_raw),
        "product_fits_uint256": True,
    }


def _per_call_row(decimals: int, supply: int, payout: int, result: dict) -> dict:
    return {
        "id": "CX-FP-SETTLEMENT-001",
        "decimals": decimals,
        "supply": str(supply),
        "payout_wad": str(payout),
        "per_call_receipts": [str(result["paid_one"]), str(result["paid"] - result["paid_one"])],
        "fragmented_paid_raw": str(result["paid"]),
        "one_shot_floor_raw": str(result["one_shot"]),
        "required_raw": str(result["required"]),
        "sweepable_dust_raw": str(result["dust"]),
        "solidity_domain": _fits(supply, payout),
        "solidity_implements_per_call_rule": False,
        "same_defect": True,
    }


def build() -> dict:
    solidity_cases = []
    excluded_overflow = []
    excluded_zero_supply = []
    per_call_regressions = []
    for decimals in DECIMALS:
        for supply in SUPPLIES:
            for payout in payouts_for(decimals):
                if supply == 0:
                    excluded_zero_supply.append(
                        {
                            "decimals": decimals,
                            "supply": "0",
                            "payout_wad": str(payout),
                            "reason": "CandidateCumulativeSettlement constructor reverts ZeroSupply",
                        }
                    )
                    continue
                per_call = _per_call(supply, payout, decimals)
                if per_call.get("underpay"):
                    per_call_regressions.append(_per_call_row(decimals, supply, payout, per_call))
                if not _fits(supply, payout):
                    excluded_overflow.append(
                        {
                            "decimals": decimals,
                            "supply": str(supply),
                            "payout_wad": str(payout),
                            "reason": "supply * payout_wad does not fit in uint256",
                        }
                    )
                    continue
                solidity_cases.append(_cumulative_case(decimals, supply, payout))
    canonical = []
    for decimals in DECIMALS:
        row = _canonical_shape(decimals)
        canonical.append(
            {
                "id": row["id"],
                "decimals": row["decimals"],
                "supply": str(row["supply"]),
                "payout_wad": row["payout_wad"],
                "per_call_receipts": [str(value) for value in row["per_call_receipts"]],
                "fragmented_paid_raw": str(row["fragmented_paid_raw"]),
                "one_shot_floor_raw": str(row["one_shot_floor_raw"]),
                "required_raw": str(row["required_raw"]),
                "sweepable_dust_raw": str(row["sweepable_dust_raw"]),
                "same_defect": row["same_defect"],
                "solidity_implements_per_call_rule": False,
            }
        )
    return {
        "schema": "precision_boundary_cumulative_fixtures_v1",
        "source": "research/prism-model/cumulative_settlement.py",
        "per_call_source": "research/prism-model/fixed_point_model.py FixedPointSettlement.redeem",
        "solidity_candidate": "research/contract-kernels/src/prism/CandidateCumulativeSettlement.sol",
        "per_call_rule_in_solidity": False,
        "candidate": True,
        "canonical_oracle": False,
        "math_1": "FAIL",
        "math_1d": "FAIL",
        "kernel_status": "differential_research_kernel",
        "v2_promotion": False,
        "uint256_max": str(UINT256_MAX),
        "cell_count": len(DECIMALS) * len(SUPPLIES) * 8,
        "solidity_case_count": len(solidity_cases),
        "excluded_overflow_count": len(excluded_overflow),
        "excluded_zero_supply_count": len(excluded_zero_supply),
        "per_call_regression_count": len(per_call_regressions),
        "cases": solidity_cases,
        "excluded_overflow": excluded_overflow,
        "excluded_zero_supply": excluded_zero_supply,
        "per_call_regressions": per_call_regressions,
        "cx_fp_settlement_001": canonical,
    }


def main() -> None:
    payload = build()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    print(f"wrote {OUT}")
    print(
        f"solidity {payload['solidity_case_count']} "
        f"overflow {payload['excluded_overflow_count']} "
        f"zero {payload['excluded_zero_supply_count']} "
        f"per_call {payload['per_call_regression_count']}"
    )


if __name__ == "__main__":
    main()
