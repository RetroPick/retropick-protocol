"""T-LC-001. The canonical PRISM lifecycle has no resurrection into issuance.

Issuance is ACTIVE, the only SeriesState that permits mint. DRAFT is the
only legal predecessor of ACTIVE. A resurrection is an implemented edge into
ACTIVE from any other source, an implemented edge into DRAFT, or a path of
positive length from a non-DRAFT state back to ACTIVE.

This module enumerates lifecycle.transition. It does not change the graph.
RESOLVED and REDEEMABLE stay distinct. cancelDraft is not added.
"""

from __future__ import annotations

import time
from typing import Any

from lifecycle import LifecycleError, SeriesState, can_transition, transition


ISSUANCE = SeriesState.ACTIVE
LEGAL_ISSUANCE_ENTRY = (SeriesState.DRAFT, SeriesState.ACTIVE)
FORBIDDEN = (
    (SeriesState.RESOLVED, SeriesState.ACTIVE),
    (SeriesState.REDEEMABLE, SeriesState.ACTIVE),
    (SeriesState.ARCHIVED, SeriesState.ACTIVE),
    (SeriesState.ARCHIVED, SeriesState.RESOLVED),
    (SeriesState.DRAFT, SeriesState.REDEEMABLE),
)


def _edge(source: SeriesState, target: SeriesState) -> str:
    return f"{source.value}->{target.value}"


def _successors(state: SeriesState) -> tuple[SeriesState, ...]:
    return tuple(target for target in SeriesState if can_transition(state, target))


def _reachable(start: SeriesState) -> tuple[str, ...]:
    seen: set[SeriesState] = set()
    stack = list(_successors(start))
    while stack:
        current = stack.pop()
        if current in seen:
            continue
        seen.add(current)
        stack.extend(target for target in _successors(current) if target not in seen)
    return tuple(sorted(state.value for state in seen))


def discharge_t_lc_001() -> dict[str, Any]:
    """Enumerate every ordered pair of SeriesState and reject resurrection."""

    started = time.perf_counter()
    states = tuple(SeriesState)
    allowed: list[str] = []
    rejected: list[str] = []
    disagreements: list[str] = []
    for source in states:
        for target in states:
            permitted = can_transition(source, target)
            if permitted:
                try:
                    result = transition(source, target)
                except LifecycleError:
                    disagreements.append(_edge(source, target))
                    continue
                if result != target:
                    disagreements.append(_edge(source, target))
                allowed.append(_edge(source, target))
            else:
                try:
                    transition(source, target)
                except LifecycleError:
                    rejected.append(_edge(source, target))
                else:
                    disagreements.append(_edge(source, target))

    resurrection_edges = [
        _edge(source, target)
        for source in states
        for target in states
        if can_transition(source, target)
        and (
            target == SeriesState.DRAFT
            or (target == ISSUANCE and (source, target) != LEGAL_ISSUANCE_ENTRY)
        )
    ]
    resurrection_paths = [
        {"from": source.value, "reaches": list(_reachable(source))}
        for source in states
        if (
            source != SeriesState.DRAFT
            and ISSUANCE.value in _reachable(source)
        )
        or SeriesState.DRAFT.value in _reachable(source)
    ]
    forbidden = []
    for source, target in FORBIDDEN:
        raised = False
        try:
            transition(source, target)
        except LifecycleError:
            raised = True
        forbidden.append(
            {
                "edge": _edge(source, target),
                "permitted": can_transition(source, target),
                "raised": raised,
            }
        )
    resolved_distinct = SeriesState.RESOLVED != SeriesState.REDEEMABLE
    redeemable_back_to_resolved = can_transition(SeriesState.REDEEMABLE, SeriesState.RESOLVED)
    draft_successors = [state.value for state in _successors(SeriesState.DRAFT)]
    archived_reaches = list(_reachable(SeriesState.ARCHIVED))
    elapsed = time.perf_counter() - started

    forbidden_hold = all(not row["permitted"] and row["raised"] for row in forbidden)
    discharged = (
        not disagreements
        and not resurrection_edges
        and not resurrection_paths
        and forbidden_hold
        and resolved_distinct
        and not redeemable_back_to_resolved
        and draft_successors == ["ACTIVE"]
        and archived_reaches == []
        and len(states) == 7
        and len(allowed) + len(rejected) == len(states) * len(states)
    )
    counterexample = None
    if not discharged:
        counterexample = {
            "disagreements": disagreements,
            "resurrection_edges": resurrection_edges,
            "resurrection_paths": resurrection_paths,
            "forbidden": forbidden,
            "resolved_distinct": resolved_distinct,
            "draft_successors": draft_successors,
            "archived_reaches": archived_reaches,
        }
    return {
        "id": "T-LC-001",
        "written_claim": "canonical PRISM lifecycle has no resurrection into issuance",
        "statement": (
            "No implemented lifecycle edge enters ACTIVE except DRAFT to ACTIVE, "
            "no edge enters DRAFT, and no non-DRAFT state can reach ACTIVE"
        ),
        "checker": "exact_enumeration",
        "oracle": "lifecycle.transition",
        "issuance_state": ISSUANCE.value,
        "states": [state.value for state in states],
        "pair_count": len(states) * len(states),
        "allowed_edges": sorted(allowed),
        "allowed_count": len(allowed),
        "rejected_count": len(rejected),
        "resurrection_edges": resurrection_edges,
        "resurrection_paths": resurrection_paths,
        "forbidden": forbidden,
        "resolved_distinct_from_redeemable": resolved_distinct,
        "redeemable_to_resolved": redeemable_back_to_resolved,
        "cancel_draft_edge": "CANCELLED" in {state.value for state in states}
        or any(edge.startswith("DRAFT->") and edge != "DRAFT->ACTIVE" for edge in allowed),
        "assumptions": [
            "the oracle is the implemented SeriesState graph in lifecycle.py",
            "ACTIVE is the only issuance state because it is the only state that permits mint",
            "DRAFT to ACTIVE is the only legal entry into issuance",
            "RESOLVED and REDEEMABLE remain distinct states",
            "cancelDraft is not a lifecycle transition and is not added",
        ],
        "classification": "PROVEN_UNDER_ASSUMPTIONS" if discharged else "COUNTEREXAMPLE_FOUND",
        "counterexample": counterexample,
        "canonical_math1": "FAIL",
        "runtime_seconds": round(elapsed, 6),
    }
