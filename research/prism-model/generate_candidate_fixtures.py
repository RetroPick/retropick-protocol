"""Write machine-readable fixtures from the cumulative-floor candidate.

The integers come from `cumulative_settlement.py`. This script does not
change that module. A mismatch against the locked case results is a stop,
not a prompt to edit the candidate.
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
from fixed_point import WAD  # noqa: E402

OUT = Path(__file__).resolve().parent / "fixtures" / "candidate_cumulative_settlement.json"


def _case(case_id: str, payout: int, decimals: int, initial: list[tuple[str, int]], steps: list[tuple[str, int]]) -> dict:
    balances = {label: qty for label, qty in initial}
    supply = sum(balances.values())
    funded = ceil_funding(supply, payout, decimals)
    book = CumulativeFloorSettlement(supply, payout, decimals, funded, dict(balances))
    book.make_redeemable()
    labels = [label for label, _ in initial]
    index = {label: i for i, label in enumerate(labels)}
    holder_index: list[int] = []
    quantities: list[int] = []
    payouts: list[int] = []
    for label, qty in steps:
        paid = book.redeem(label, qty)
        holder_index.append(index[label])
        quantities.append(qty)
        payouts.append(paid)
    if book.supply_units != 0:
        raise SystemExit(f"{case_id} did not redeem the full supply")
    shot = one_shot_floor(supply, payout, decimals)
    if book.paid_raw != shot:
        raise SystemExit(f"{case_id} paid {book.paid_raw} but one-shot floor is {shot}")
    return {
        "id": case_id,
        "supply": str(supply),
        "payout_wad": str(payout),
        "decimals": decimals,
        "denominator": str(settlement_denominator(decimals)),
        "ceil_funding": str(funded),
        "one_shot_floor": str(shot),
        "holder_count": len(labels),
        "holders": labels,
        "balances": [str(balances[label]) for label in labels],
        "step_count": len(steps),
        "holder_index": holder_index,
        "quantities": [str(qty) for qty in quantities],
        "payouts": [str(paid) for paid in payouts],
        "receipts": [str(book.receipts[label]) for label in labels],
        "paid_total": str(book.paid_raw),
        "residual": str(book.balance_raw),
    }


def build() -> dict:
    payout_cx = WAD - 1
    fairness_payout = WAD // 2 + 1
    cases = [
        _case("cx_original_ab", payout_cx, 18, [("A", 1), ("B", 1)], [("A", 1), ("B", 1)]),
        _case("cx_original_ba", payout_cx, 18, [("A", 1), ("B", 1)], [("B", 1), ("A", 1)]),
        _case(
            "fairness_aba",
            fairness_payout,
            18,
            [("A", 2), ("B", 1)],
            [("A", 1), ("B", 1), ("A", 1)],
        ),
        _case("telescope_supply4_chunks_1_2_1", payout_cx, 18, [("A", 4)], [("A", 1), ("A", 2), ("A", 1)]),
        _case("telescope_supply4_oneshot", payout_cx, 18, [("A", 4)], [("A", 4)]),
        _case("telescope_supply4_chunks_2_2", payout_cx, 18, [("A", 2), ("B", 2)], [("A", 2), ("B", 2)]),
        _case("decimals6_supply2_unit_chunks", payout_cx, 6, [("A", 1), ("B", 1)], [("A", 1), ("B", 1)]),
    ]
    _lock(cases)
    return {
        "schema": "candidate_cumulative_settlement_fixtures_v1",
        "source": "research/prism-model/cumulative_settlement.py",
        "candidate": True,
        "canonical_oracle": False,
        "math_1": "FAIL",
        "math_1d": "FAIL",
        "v2_promotion": False,
        "case_count": len(cases),
        "cases": cases,
    }


def _lock(cases: list[dict]) -> None:
    by_id = {row["id"]: row for row in cases}
    ab = by_id["cx_original_ab"]
    ba = by_id["cx_original_ba"]
    fair = by_id["fairness_aba"]
    chunks = by_id["telescope_supply4_chunks_1_2_1"]
    if ab["payouts"] != ["0", "1"] or ab["paid_total"] != "1" or ab["residual"] != "1":
        raise SystemExit("CX original order AB did not pay 1 with residual 1")
    if ba["payouts"] != ["0", "1"] or ba["paid_total"] != "1" or ba["residual"] != "1":
        raise SystemExit("CX original order BA did not pay 1 with residual 1")
    if ab["receipts"] != ["0", "1"] or ba["receipts"] != ["1", "0"]:
        raise SystemExit("CX original holder orders did not match the candidate")
    if fair["payouts"] != ["0", "1", "0"] or fair["receipts"] != ["0", "1"]:
        raise SystemExit("fairness order A,B,A did not leave one holder at 0")
    if fair["paid_total"] != "1" or fair["residual"] != "1" or fair["one_shot_floor"] != "1":
        raise SystemExit("fairness case did not telescope to the one-shot floor")
    if chunks["paid_total"] != chunks["one_shot_floor"]:
        raise SystemExit("partition did not telescope")
    if chunks["one_shot_floor"] != "3" or chunks["payouts"] != ["0", "2", "1"]:
        raise SystemExit("supply-4 partition integers moved")


def main() -> None:
    payload = build()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    print(f"wrote {OUT}")
    print(f"cases {payload['case_count']}")
    for row in payload["cases"]:
        print(
            f"{row['id']} paid_total={row['paid_total']} one_shot={row['one_shot_floor']} "
            f"residual={row['residual']} payouts={','.join(row['payouts'])}"
        )


if __name__ == "__main__":
    main()
