"""Fixtures for the payoff-equivalent transform. Integers come from partial_resolution.py."""

from __future__ import annotations

import json
import sys
from fractions import Fraction
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from model import PrismSeries  # noqa: E402
from partial_resolution import (  # noqa: E402
    PartialResolutionError,
    apply_transform,
    mismatched_portfolio,
    portfolio_preserves,
)

OUT = Path(__file__).resolve().parent / "fixtures" / "partial_resolution.json"
G = [[0, 1], [0, 0], [1, 1], [1, 0]]
WEIGHTS = [Fraction(3, 5), Fraction(2, 5)]
WAD = 10**18


def _fresh() -> PrismSeries:
    series = PrismSeries(G, WEIGHTS)
    series.activate()
    series.mint_with_exact_backing(1000)
    return series


def _mask(states) -> int:
    mask = 0
    for state in states:
        mask |= 1 << int(state)
    return mask


def _ints(values) -> list[str]:
    return [str(int(value)) for value in values]


def _state(series: PrismSeries) -> dict:
    return {
        "supply": str(int(series.supply)),
        "backing": _ints(series.backing),
        "transformed": str(int(series.transformed_settlement)),
        "possible_mask": str(_mask(series.possible_states)),
        "resolved_mask": str(_mask(series.resolved_components)),
        "weights_wad": [str(int(weight * WAD)) for weight in series.weights],
    }


def _step_ok(series: PrismSeries, index: int, payout: int) -> dict:
    planned = apply_transform(series, index, payout)
    return {
        "op": "transform",
        "expect": "ok",
        "index": index,
        "payout": str(payout),
        "cash_added": str(int(planned["cash_added"])),
        **_state(series),
    }


def _step_reject(series: PrismSeries, index: int, payout: int, error: str) -> dict:
    before = _state(series)
    try:
        apply_transform(series, index, payout)
    except PartialResolutionError as exc:
        message = str(exc)
    else:
        raise SystemExit(f"expected reject for {(index, payout)}")
    if error == "bad_component" and "invalid component" not in message:
        raise SystemExit(message)
    if error == "nonequivalent" and "inconsistent" not in message and "changes payoff" not in message:
        raise SystemExit(message)
    if error == "already_resolved" and "already resolved" not in message:
        raise SystemExit(message)
    after = _state(series)
    if after != before:
        raise SystemExit("rejected transform changed state")
    return {
        "op": "transform",
        "expect": "reject",
        "error": error,
        "index": index,
        "payout": str(payout),
        **after,
    }


def build() -> dict:
    success = _fresh()
    success_steps = [_step_ok(success, 1, 1)]
    zero_payout = _fresh()
    zero_steps = [_step_ok(zero_payout, 1, 0)]
    bad_index = _fresh()
    bad_steps = [_step_reject(bad_index, 2, 1, "bad_component")]
    nonequivalent = _fresh()
    nonequivalent_steps = [_step_reject(nonequivalent, 1, 2, "nonequivalent")]
    repeat = _fresh()
    repeat_steps = [_step_ok(repeat, 1, 1), _step_reject(repeat, 1, 1, "already_resolved")]
    forward = _fresh()
    forward_steps = [_step_ok(forward, 0, 1), _step_ok(forward, 1, 1)]
    backward = _fresh()
    backward_steps = [_step_ok(backward, 1, 1), _step_ok(backward, 0, 1)]
    if _state(forward) != _state(backward):
        raise SystemExit("COUNTEREXAMPLE_FOUND: reorder changed the terminal portfolio")

    control_series = _fresh()
    control = mismatched_portfolio(control_series, 1, 1)
    if control["equivalent"]:
        raise SystemExit("COUNTEREXAMPLE_FOUND: wrong-component portfolio was accepted")
    good = portfolio_preserves(
        G, [600, 400], 0, [600, 0], 400, [0, 2]
    )
    if not good:
        raise SystemExit("COUNTEREXAMPLE_FOUND: the component-1 transform is not equivalent on states 0 and 2")

    initial = _fresh()
    payload = {
        "schema": "partial_resolution_transform_fixtures_v1",
        "source": "research/prism-model/partial_resolution.py",
        "candidate": True,
        "canonical_oracle": False,
        "math_1": "FAIL",
        "contract_1": "not_met",
        "wired_to_prediction_tokens": False,
        "component_count": 2,
        "state_count": 4,
        "payoff": G,
        "initial": _state(initial),
        "case_count": 6,
        "cases": [
            {"id": "transform_component_1_pays_1", "step_count": len(success_steps), "steps": success_steps},
            {"id": "transform_component_1_pays_0", "step_count": len(zero_steps), "steps": zero_steps},
            {"id": "wrong_component", "step_count": len(bad_steps), "steps": bad_steps},
            {"id": "nonequivalent_payout", "step_count": len(nonequivalent_steps), "steps": nonequivalent_steps},
            {"id": "already_resolved", "step_count": len(repeat_steps), "steps": repeat_steps},
            {"id": "reorder_forward", "step_count": len(forward_steps), "steps": forward_steps},
        ],
        "reorder_backward": {"step_count": len(backward_steps), "steps": backward_steps},
        "negative_control": {
            "equivalent": False,
            "intended_index": control["intended_index"],
            "wrong_index": control["wrong_index"],
            "old_backing": _ints(control["old_backing"]),
            "old_cash": str(int(control["old_cash"])),
            "new_backing": _ints(control["new_backing"]),
            "new_cash": str(int(control["new_cash"])),
            "remaining_mask": str(_mask(control["remaining"])),
        },
        "positive_control": {
            "equivalent": True,
            "old_backing": ["600", "400"],
            "old_cash": "0",
            "new_backing": ["600", "0"],
            "new_cash": "400",
            "remaining_mask": str(_mask([0, 2])),
        },
    }
    return payload


def main() -> None:
    payload = build()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    print(f"wrote {OUT}")
    for case in payload["cases"]:
        last = case["steps"][-1]
        print(
            f"{case['id']} expect={last['expect']} transformed={last['transformed']} "
            f"backing={','.join(last['backing'])} mask={last['possible_mask']}"
        )
    print(
        "negative_control equivalent="
        f"{payload['negative_control']['equivalent']} new_cash={payload['negative_control']['new_cash']}"
    )


if __name__ == "__main__":
    main()
