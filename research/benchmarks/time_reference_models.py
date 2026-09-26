"""Time existing reference-model entry points on declared instances.

Does not change solver certificates, settlement math, or the exhaustive summary file.
A 16-component matrix is outside the minimum-cost solver domain and is not run.
"""

from __future__ import annotations

import json
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "prism-model"))

from candidate_telescope_proof import run as telescope_run  # noqa: E402
from minimum_cost_replication import (  # noqa: E402
    MAX_COMPONENTS,
    MAX_STATES,
    DomainError,
    minimum_cost_exact_replication,
)

sys.path.insert(0, str(ROOT / "prediction-model"))

from exhaustive_search import explore  # noqa: E402


def _declared_instance(components: int, states: int):
    """Binary state indicators. Target is G times the all-ones vector, so some x = 1 is exact."""

    matrix = tuple(tuple((state >> component) & 1 for component in range(components)) for state in range(states))
    target = tuple(sum(row) for row in matrix)
    cost = tuple(1 for _ in range(components))
    return matrix, target, cost


def _summarize(samples: list[float]) -> dict[str, object]:
    ordered = sorted(samples)
    count = len(ordered)
    if count == 1:
        return {
            "sample_size": 1,
            "seconds": ordered[0],
            "min": None,
            "median": None,
            "max": None,
            "note": "single measured time; not a percentile",
        }
    return {
        "sample_size": count,
        "seconds": ordered,
        "min": ordered[0],
        "median": ordered[count // 2],
        "max": ordered[-1],
        "note": "min, median, and max of one local process; not a service percentile",
    }


def _repeat(action, limit_seconds: float = 2.0) -> dict[str, object]:
    started = time.perf_counter()
    first_detail = action()
    first = time.perf_counter() - started
    if first >= limit_seconds:
        summary = _summarize([round(first, 6)])
        summary["detail"] = first_detail
        return summary
    samples = [first]
    detail = first_detail
    for _ in range(4):
        started = time.perf_counter()
        detail = action()
        samples.append(time.perf_counter() - started)
    summary = _summarize([round(sample, 6) for sample in samples])
    summary["detail"] = detail
    return summary


def _replication(components: int, states: int) -> dict[str, object]:
    if components > MAX_COMPONENTS or states > MAX_STATES:
        return {
            "status": "NOT_RUN",
            "reason": (
                f"shape {components}/{states} exceeds the solver domain "
                f"of {MAX_STATES} states and {MAX_COMPONENTS} components"
            ),
            "domain_cap_states": MAX_STATES,
            "domain_cap_components": MAX_COMPONENTS,
        }
    matrix, target, cost = _declared_instance(components, states)

    def action():
        certificate = minimum_cost_exact_replication(matrix, target, cost)
        return {
            "status": certificate.status,
            "rechecked_equal": certificate.rechecked_equal,
            "cost": "" if certificate.cost is None else f"{certificate.cost.numerator}/{certificate.cost.denominator}",
            "bases_checked": certificate.bases_checked,
            "rays_checked": certificate.rays_checked,
            "reason": certificate.reason,
        }

    timed = _repeat(action)
    timed["shape"] = f"{components}/{states}"
    timed["matrix"] = "binary indicators of state index bits; target is G times the all-ones vector; unit costs are 1"
    return timed


def main() -> dict[str, object]:
    shapes = ((2, 4), (4, 4), (4, 16), (8, 16), (16, 16))
    replication = {f"{components}/{states}": _replication(components, states) for components, states in shapes}
    exhaustive = _repeat(lambda: explore(max_unit=3))
    telescope = _repeat(telescope_run)
    return {
        "kernel_sha": "c0af8e584137fa35ef4d71b4d8a46d260798deb4",
        "not_live_markets": True,
        "not_an_slo": True,
        "replication_solve": replication,
        "prediction_exhaustive_max_unit_3": exhaustive,
        "candidate_telescope_check": telescope,
        "prior_single_exhaustive_summary": "research/prediction-model/outputs/exhaustive_summary.json",
        "prior_payoff_loops_not_rerun": "evidence/research/prism/math1-probe-2026-09-26.json",
    }


if __name__ == "__main__":
    try:
        print(json.dumps(main(), indent=2, default=str))
    except DomainError as exc:
        print(json.dumps({"status": "NOT_RUN", "reason": str(exc)}))
        raise
