"""T-LC-002. Canonical final PRISM resolution cannot be committed twice.

The oracle is PrismSeries.resolve. A commit is a call that returns and stores
a final payout. The method accepts that call only in RESOLUTION_PENDING, then
moves to RESOLVED. A later call must leave the stored payout and the state
unchanged.

This module does not change resolve, lifecycle.transition, or settlement.
RESOLVED and REDEEMABLE stay distinct. cancelDraft is not added.
"""

from __future__ import annotations

import time
from fractions import Fraction
from typing import Any

from lifecycle import LifecycleError, SeriesState
from model import ModelError, PrismSeries


MATRIX = ((0, 1), (0, 0), (1, 1), (1, 0))
WEIGHTS = (Fraction(3, 5), Fraction(2, 5))


def _series(state: SeriesState = SeriesState.DRAFT) -> PrismSeries:
    return PrismSeries(MATRIX, WEIGHTS, state=state)


def _pending_through_api() -> PrismSeries:
    series = _series()
    series.activate()
    series.start_resolution()
    return series


def _snapshot(series: PrismSeries) -> tuple[str, str | None]:
    payout = None if series.final_payout is None else str(series.final_payout)
    return series.state.value, payout


def _try_resolve(series: PrismSeries, index: int) -> dict[str, Any]:
    before = _snapshot(series)
    try:
        series.resolve(index)
    except ModelError:
        return {"accepted": False, "unchanged": _snapshot(series) == before, "error": "ModelError"}
    return {
        "accepted": True,
        "unchanged": False,
        "state": series.state.value,
        "payout": str(series.final_payout),
        "error": None,
    }


def _commit_once(series: PrismSeries, indices: tuple[int, ...]) -> dict[str, Any]:
    attempts = []
    for index in indices:
        attempts.append({"index": index, **_try_resolve(series, index)})
    accepted = [row for row in attempts if row["accepted"]]
    rejected = [row for row in attempts if not row["accepted"]]
    return {
        "accepted_count": len(accepted),
        "rejected_unchanged": all(row["unchanged"] for row in rejected),
        "accepted": [
            {"index": row["index"], "state": row["state"], "payout": row["payout"]}
            for row in accepted
        ],
        "final": {"state": series.state.value, "payout": None if series.final_payout is None else str(series.final_payout)},
    }


def discharge_t_lc_002() -> dict[str, Any]:
    """Every series accepts at most one PrismSeries.resolve commit."""

    started = time.perf_counter()
    indices = tuple(range(len(MATRIX)))
    repeated = indices + indices
    state_guard = []
    for state in SeriesState:
        series = _series(state)
        if state in {SeriesState.RESOLVED, SeriesState.REDEEMABLE, SeriesState.ARCHIVED}:
            series.final_payout = Fraction(7, 3)
        report = _commit_once(series, repeated)
        state_guard.append({"state": state.value, **report})

    api = _pending_through_api()
    expected_api = str(api.terminal_payoff_vector[2])
    api_commit = _commit_once(api, (2,) + repeated)
    api_commit["expected_payout"] = expected_api

    narrowed = _series()
    narrowed.activate()
    narrowed.resolve_component(1, 1)
    narrowed.start_resolution()
    expected_narrow = str(narrowed.terminal_payoff_vector[0])
    narrow_commit = _commit_once(narrowed, (1, 3, 0, 0, 2))
    narrow_commit["expected_payout"] = expected_narrow
    narrow_commit["state_before_commit"] = "RESOLUTION_PENDING"

    funded = _pending_through_api()
    funded.resolve(2)
    committed = str(funded.final_payout)
    resolved_state = funded.state.value
    funded.make_redeemable()
    redeemable_state = funded.state.value
    redeemable_attempt = _try_resolve(funded, 0)
    funded.archive()
    archived_state = funded.state.value
    archived_attempt = _try_resolve(funded, 2)
    reopen = _series()
    reopen.activate()
    reopen.start_resolution()
    reopen.resolve(2)
    reopen_errors = []
    for name, call in (
        ("activate", reopen.activate),
        ("start_resolution", reopen.start_resolution),
        ("resolve_component", lambda: reopen.resolve_component(0, 0)),
    ):
        before = _snapshot(reopen)
        try:
            call()
        except (ModelError, LifecycleError) as exc:
            reopen_errors.append(
                {
                    "call": name,
                    "raised": True,
                    "error": type(exc).__name__,
                    "unchanged": _snapshot(reopen) == before,
                }
            )
        else:
            reopen_errors.append({"call": name, "raised": False, "unchanged": False, "snapshot": list(_snapshot(reopen))})
    elapsed = time.perf_counter() - started

    pending = next(row for row in state_guard if row["state"] == "RESOLUTION_PENDING")
    others = [row for row in state_guard if row["state"] != "RESOLUTION_PENDING"]
    pending_ok = (
        pending["accepted_count"] == 1
        and pending["rejected_unchanged"]
        and pending["accepted"][0]["state"] == "RESOLVED"
        and pending["final"]["state"] == "RESOLVED"
        and pending["final"]["payout"] == pending["accepted"][0]["payout"]
    )
    others_ok = all(row["accepted_count"] == 0 and row["rejected_unchanged"] for row in others)
    api_ok = (
        api_commit["accepted_count"] == 1
        and api_commit["rejected_unchanged"]
        and api_commit["final"]["state"] == "RESOLVED"
        and api_commit["final"]["payout"] == expected_api
    )
    narrow_ok = (
        narrow_commit["accepted_count"] == 1
        and narrow_commit["rejected_unchanged"]
        and narrow_commit["accepted"][0]["index"] == 0
        and narrow_commit["final"]["payout"] == expected_narrow
        and narrow_commit["final"]["state"] == "RESOLVED"
    )
    later_ok = (
        resolved_state == "RESOLVED"
        and redeemable_state == "REDEEMABLE"
        and archived_state == "ARCHIVED"
        and resolved_state != redeemable_state
        and not redeemable_attempt["accepted"]
        and redeemable_attempt["unchanged"]
        and not archived_attempt["accepted"]
        and archived_attempt["unchanged"]
        and funded.final_payout is not None
        and str(funded.final_payout) == committed
        and all(row["raised"] and row["unchanged"] for row in reopen_errors)
        and reopen.state == SeriesState.RESOLVED
    )
    discharged = pending_ok and others_ok and api_ok and narrow_ok and later_ok
    counterexample = None
    if not discharged:
        counterexample = {
            "state_guard": state_guard,
            "api_commit": api_commit,
            "narrow_commit": narrow_commit,
            "resolved_state": resolved_state,
            "redeemable_state": redeemable_state,
            "archived_state": archived_state,
            "redeemable_attempt": redeemable_attempt,
            "archived_attempt": archived_attempt,
            "reopen": reopen_errors,
        }
    return {
        "id": "T-LC-002",
        "written_claim": "canonical final PRISM resolution cannot be committed twice",
        "statement": (
            "PrismSeries.resolve commits a final payout only from RESOLUTION_PENDING, "
            "and a second call leaves that payout and the resulting state unchanged"
        ),
        "checker": "exact_enumeration",
        "oracle": "PrismSeries.resolve",
        "accepting_state": "RESOLUTION_PENDING",
        "terminal_count": len(indices),
        "state_guard": state_guard,
        "api_commit": api_commit,
        "narrow_commit": narrow_commit,
        "after_commit": {
            "resolved_state": resolved_state,
            "redeemable_state": redeemable_state,
            "archived_state": archived_state,
            "payout": committed,
            "redeemable_attempt": redeemable_attempt,
            "archived_attempt": archived_attempt,
            "reopen": reopen_errors,
        },
        "resolved_distinct_from_redeemable": resolved_state != redeemable_state,
        "assumptions": [
            "the oracle is PrismSeries.resolve and is not modified",
            "a commit is a resolve call that returns",
            "the checked terminals are the four rows of the declared payoff matrix",
            "RESOLVED and REDEEMABLE remain distinct states",
            "cancelDraft is not a lifecycle transition and is not added",
        ],
        "classification": "PROVEN_UNDER_ASSUMPTIONS" if discharged else "COUNTEREXAMPLE_FOUND",
        "counterexample": counterexample,
        "canonical_math1": "FAIL",
        "runtime_seconds": round(elapsed, 6),
    }
