"""Machine-readable prediction fixtures. Amounts are decimal strings."""

from __future__ import annotations

import json
from pathlib import Path

from domain import Outcome, ResolutionResult, amount_to_str
from market import PredictionMarket, activate_binary, create_market


def _view(market: PredictionMarket, payout: int | None = None) -> dict[str, str]:
    row = {
        "state": market.state.value,
        "collateral_locked": amount_to_str(market.collateral_locked),
        "yes_supply": amount_to_str(market.yes_supply),
        "no_supply": amount_to_str(market.no_supply),
        "liability": amount_to_str(market.liability()),
        "yes_redeemed": amount_to_str(market.yes_redeemed),
        "no_redeemed": amount_to_str(market.no_redeemed),
    }
    if market.result is not None:
        row["result"] = market.result.value
    if payout is not None:
        row["payout"] = str(payout)
    return row


def _market() -> PredictionMarket:
    market = create_market(integer=True, collateral="COLL", dust_sink="SINK", max_amount=10**18)
    activate_binary(market, market_id="fixture", resolver="resolver", spec_hash="fixture-hash")
    return market


def build() -> dict[str, dict]:
    split = _market()
    split.split("alice", 100, 100)
    merge = _market()
    merge.split("alice", 100, 100)
    merge.merge("alice", 40)
    yes = _market()
    yes.split("alice", 100, 100)
    yes.close_mint()
    yes.begin_resolution()
    yes.resolve("resolver", ResolutionResult.YES_WIN)
    yes.open_redemption()
    resolved_view = _view(yes)
    yes_payout = yes.redeem("alice", Outcome.YES, 25)
    after_yes = _view(yes, int(yes_payout))
    no_payout = yes.redeem("alice", Outcome.NO, 10)
    after_no = _view(yes, int(no_payout))

    invalid = _market()
    invalid.split("alice", 5, 5)
    invalid.close_mint()
    invalid.begin_resolution()
    invalid.resolve("resolver", ResolutionResult.INVALID)
    invalid.open_redemption()
    invalid_steps = []
    for side in (Outcome.YES, Outcome.NO):
        for _ in range(5):
            payout = invalid.redeem("alice", side, 1)
            invalid_steps.append({"side": side.value, **_view(invalid, int(payout))})

    return {
        "prediction_split": {"steps": [_view(split)]},
        "prediction_merge": {"steps": [_view(merge)]},
        "prediction_resolve_yes": {"steps": [resolved_view]},
        "prediction_redeem_yes": {
            "payout": str(int(yes_payout)),
            "after_yes": after_yes,
            "no_payout": str(int(no_payout)),
            "after_no": after_no,
        },
        "prediction_invalid_rounding": {"steps": invalid_steps, "residual": amount_to_str(invalid.collateral_locked)},
    }


def write(directory: Path) -> None:
    directory.mkdir(parents=True, exist_ok=True)
    payload = build()
    for name, body in payload.items():
        path = directory / f"{name}.json"
        path.write_text(json.dumps(body, indent=2, sort_keys=True) + "\n", encoding="utf-8")
