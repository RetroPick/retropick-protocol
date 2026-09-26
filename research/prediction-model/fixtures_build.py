"""Machine-readable prediction fixtures. Amounts are decimal strings."""

from __future__ import annotations

import json
from pathlib import Path

from domain import Outcome, ResolutionResult, amount_to_str
from market import PredictionMarket, activate_binary, create_market
from resolution import payout_numerators


_STATE = {
    "DRAFT": "0",
    "OPEN": "1",
    "LOCKED": "2",
    "RESOLUTION_PENDING": "3",
    "RESOLVED": "4",
    "REDEEMABLE": "5",
    "ARCHIVED": "6",
}
_RESULT = {"YES_WIN": "1", "NO_WIN": "2", "INVALID": "3"}


def _numerators(market: PredictionMarket) -> tuple[str, str]:
    if market.result is None:
        return "0", "0"
    yes_num, no_num = payout_numerators(market.result)
    return str(yes_num), str(no_num)


def _snap(market: PredictionMarket, **extra: str) -> dict[str, str]:
    yes_num, no_num = _numerators(market)
    row = {
        "state": _STATE[market.state.value],
        "result": "0" if market.result is None else _RESULT[market.result.value],
        "collateral_locked": amount_to_str(market.collateral_locked),
        "yes_supply": amount_to_str(market.yes_supply),
        "no_supply": amount_to_str(market.no_supply),
        "yes_redeemed": amount_to_str(market.yes_redeemed),
        "no_redeemed": amount_to_str(market.no_redeemed),
        "liability": amount_to_str(market.liability()),
        "residual_to_sink": amount_to_str(market.residual_to_sink),
        "yes_numerator": yes_num,
        "no_numerator": no_num,
    }
    row.update(extra)
    return row


def _to_resolved(market: PredictionMarket, result: ResolutionResult) -> None:
    market.close_mint()
    market.begin_resolution()
    market.resolve("resolver", result)


def _operation_fixtures() -> dict[str, dict]:
    close = _market()
    close.split("alice", 100, 100)
    close.close_mint()

    pending = _market()
    pending.split("alice", 100, 100)
    pending.close_mint()
    pending.begin_resolution()

    yes_resolved = _market()
    yes_resolved.split("alice", 100, 100)
    _to_resolved(yes_resolved, ResolutionResult.YES_WIN)

    no_resolved = _market()
    no_resolved.split("alice", 100, 100)
    _to_resolved(no_resolved, ResolutionResult.NO_WIN)

    invalid_resolved = _market()
    invalid_resolved.split("alice", 5, 5)
    _to_resolved(invalid_resolved, ResolutionResult.INVALID)

    redeem_no = _market()
    redeem_no.split("alice", 100, 100)
    _to_resolved(redeem_no, ResolutionResult.NO_WIN)
    redeem_no.open_redemption()
    no_payout = int(redeem_no.redeem("alice", Outcome.NO, 25))

    burn = _market()
    burn.split("alice", 8, 8)
    _to_resolved(burn, ResolutionResult.YES_WIN)
    burn.open_redemption()
    yes_payout = int(burn.redeem("alice", Outcome.YES, 8))
    after_yes = _snap(burn, payout=str(yes_payout), burn_amount="8", redeem_amount="8", split_amount="8")
    burn.burn_worthless("alice", Outcome.NO, 8)
    after_burn = _snap(burn, split_amount="8")
    archive_residual = int(burn.archive())
    after_archive = _snap(burn, residual=str(archive_residual), split_amount="8")

    archived_invalid = _market()
    archived_invalid.split("alice", 5, 5)
    _to_resolved(archived_invalid, ResolutionResult.INVALID)
    archived_invalid.open_redemption()
    for side in (Outcome.YES, Outcome.NO):
        archived_invalid.redeem("alice", side, 5)
    before_archive = _snap(archived_invalid, split_amount="5")
    invalid_residual = int(archived_invalid.archive())
    after_invalid_archive = _snap(archived_invalid, residual=str(invalid_residual), split_amount="5")

    locked_merge = _market()
    locked_merge.split("alice", 5, 5)
    locked_merge.close_mint()
    released = int(locked_merge.merge("alice", 2))

    reject_close = _market()
    reject_close.split("alice", 100, 100)
    reject_close.close_mint()
    split_after_close = _snap(reject_close, status="REJECTED", split_amount="100", attempted="1")

    zero = _market()
    zero.split("alice", 10, 10)
    split_zero = _snap(zero, status="REJECTED", prior_split="10", attempted="0")

    unequal = _market()
    unequal.split("alice", 10, 10)
    merge_unequal = _snap(unequal, status="REJECTED", split_amount="10", attempted="1")

    after_resolve = _market()
    after_resolve.split("alice", 10, 10)
    _to_resolved(after_resolve, ResolutionResult.YES_WIN)
    merge_after = _snap(after_resolve, status="REJECTED", split_amount="10", attempted="1")
    redeem_before = _snap(after_resolve, status="REJECTED", split_amount="10", attempted="1")

    wrong = _market()
    wrong.split("alice", 1, 1)
    wrong.close_mint()
    wrong.begin_resolution()
    wrong_resolver = _snap(wrong, status="REJECTED", split_amount="1")

    over = _market()
    over.split("alice", 10, 10)
    _to_resolved(over, ResolutionResult.YES_WIN)
    over.open_redemption()
    partial = int(over.redeem("alice", Outcome.YES, 4))
    over_redeem = _snap(over, status="REJECTED", split_amount="10", redeemed="4", payout=str(partial), attempted="10")

    invalid_burn = _market()
    invalid_burn.split("alice", 5, 5)
    _to_resolved(invalid_burn, ResolutionResult.INVALID)
    invalid_burn.open_redemption()
    invalid_burn_row = _snap(invalid_burn, status="REJECTED", split_amount="5", attempted="1")

    return {
        "prediction_close_mint": _snap(close, split_amount="100"),
        "prediction_begin_resolution": _snap(pending, split_amount="100"),
        "prediction_resolve_yes_state": _snap(yes_resolved, split_amount="100"),
        "prediction_resolve_no": _snap(no_resolved, split_amount="100"),
        "prediction_resolve_invalid": _snap(invalid_resolved, split_amount="5"),
        "prediction_redeem_no": _snap(redeem_no, split_amount="100", redeem_amount="25", payout=str(no_payout)),
        "prediction_burn_worthless": {
            "after_redeem": after_yes,
            "after_burn": after_burn,
            "after_archive": after_archive,
        },
        "prediction_archive_invalid": {"before_archive": before_archive, "after_archive": after_invalid_archive},
        "prediction_merge_locked": _snap(locked_merge, split_amount="5", merge_amount="2", released=str(released)),
        "prediction_rejections": {
            "split_after_close": split_after_close,
            "split_zero": split_zero,
            "merge_unequal": merge_unequal,
            "merge_after_resolution": merge_after,
            "redeem_before_open": redeem_before,
            "wrong_resolver": wrong_resolver,
            "over_redeem": over_redeem,
            "invalid_burn": invalid_burn_row,
            "fee_on_transfer": {
                "status": "REJECTED",
                "split_amount": "100",
                "collateral_locked": "0",
                "yes_supply": "0",
                "no_supply": "0",
                "state": _STATE["OPEN"],
            },
        },
    }


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
        **_operation_fixtures(),
    }


def write(directory: Path) -> None:
    directory.mkdir(parents=True, exist_ok=True)
    payload = build()
    for name, body in payload.items():
        path = directory / f"{name}.json"
        path.write_text(json.dumps(body, indent=2, sort_keys=True) + "\n", encoding="utf-8")
