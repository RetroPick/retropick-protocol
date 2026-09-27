"""T-PARTIAL-001. Partial-resolution NAV splits linearly across the two sets.

The written identity is NAV_t = sum_{i in R} x_i r_i + sum_{j in U} x_j P_j(t).
Marks are inputs. This is not an exchange-price claim.

The oracle is partial_resolution_nav. This module does not change it.
"""

from __future__ import annotations

import time
from fractions import Fraction
from typing import Any

import sympy
import z3

from market_math import MarketMathError, partial_resolution_nav


def _subset_gap(components: int, mask: int) -> bool:
    weights = sympy.symbols(f"x0:{components}")
    resolved_values = sympy.symbols(f"r0:{components}")
    marks = sympy.symbols(f"p0:{components}")
    resolved_sum = sum(
        weights[i] * resolved_values[i]
        for i in range(components)
        if mask & (1 << i)
    )
    unresolved_sum = sum(
        weights[i] * marks[i]
        for i in range(components)
        if not mask & (1 << i)
    )
    combined = sum(
        weights[i] * (resolved_values[i] if mask & (1 << i) else marks[i])
        for i in range(components)
    )
    scale, shift = sympy.symbols("a b")
    other = sympy.symbols(f"y0:{components}")
    left = sum(
        (scale * weights[i] + shift * other[i])
        * (resolved_values[i] if mask & (1 << i) else marks[i])
        for i in range(components)
    )
    right = scale * combined + shift * sum(
        other[i] * (resolved_values[i] if mask & (1 << i) else marks[i])
        for i in range(components)
    )
    gap = sympy.expand(combined - resolved_sum - unresolved_sum)
    linear = sympy.expand(left - right)
    return gap == 0 and linear == 0


def _identity_negation(components: int) -> str:
    weights = [z3.Real(f"x{i}") for i in range(components)]
    resolved_values = [z3.Real(f"r{i}") for i in range(components)]
    marks = [z3.Real(f"p{i}") for i in range(components)]
    in_resolved = [z3.Bool(f"m{i}") for i in range(components)]
    resolved_sum = z3.Sum(
        [z3.If(in_resolved[i], weights[i] * resolved_values[i], z3.RealVal(0)) for i in range(components)]
    )
    unresolved_sum = z3.Sum(
        [z3.If(in_resolved[i], z3.RealVal(0), weights[i] * marks[i]) for i in range(components)]
    )
    combined = z3.Sum(
        [
            z3.If(in_resolved[i], weights[i] * resolved_values[i], weights[i] * marks[i])
            for i in range(components)
        ]
    )
    solver = z3.Solver()
    for i in range(components):
        solver.add(weights[i] >= 0, resolved_values[i] >= 0, marks[i] >= 0)
    solver.add(combined != resolved_sum + unresolved_sum)
    return str(solver.check())


def _linearity_negation(components: int) -> str:
    weights = [z3.Real(f"x{i}") for i in range(components)]
    other = [z3.Real(f"y{i}") for i in range(components)]
    values = [z3.Real(f"v{i}") for i in range(components)]
    scale = z3.Real("a")
    shift = z3.Real("b")

    def nav(coeffs: list[z3.ArithRef]) -> z3.ArithRef:
        return z3.Sum([coeffs[i] * values[i] for i in range(components)])

    scaled = [scale * weights[i] + shift * other[i] for i in range(components)]
    solver = z3.Solver()
    solver.add(scale >= 0, shift >= 0)
    for i in range(components):
        solver.add(weights[i] >= 0, other[i] >= 0, values[i] >= 0)
    solver.add(nav(scaled) != scale * nav(weights) + shift * nav(other))
    return str(solver.check())


def _formula(weights: tuple[Fraction, ...], resolved: dict[int, Fraction], marks: dict[int, Fraction]) -> Fraction:
    total = Fraction(0)
    for index, weight in enumerate(weights):
        value = resolved[index] if index in resolved else marks[index]
        total += weight * value
    return total


def _oracle_partitions() -> list[dict[str, Any]]:
    mismatches = []
    checked = 0
    for components in range(1, 5):
        weights = tuple(Fraction(index + 1, components + 1) for index in range(components))
        for mask in range(1 << components):
            resolved = {
                index: Fraction(index + 1, 3)
                for index in range(components)
                if mask & (1 << index)
            }
            marks = {
                index: Fraction(1, index + 2)
                for index in range(components)
                if not mask & (1 << index)
            }
            got = partial_resolution_nav(weights, resolved=resolved, unresolved_marks=marks)
            expected = _formula(weights, resolved, marks)
            checked += 1
            if got != expected:
                mismatches.append(
                    {
                        "components": components,
                        "mask": mask,
                        "got": str(got),
                        "expected": str(expected),
                    }
                )
    return [{"checked": checked, "mismatches": mismatches}]


def _documented_basket() -> dict[str, str]:
    weights = (Fraction(3, 5), Fraction(2, 5))
    nav = partial_resolution_nav(
        weights,
        resolved={0: 1},
        unresolved_marks={1: Fraction(3, 10)},
    )
    return {"weights": "3/5,2/5", "nav": str(nav), "expected": str(Fraction(72, 100))}


def _rejected(call) -> bool:
    try:
        call()
    except MarketMathError:
        return True
    return False


def discharge_t_partial_001() -> dict[str, Any]:
    """NAV equals the resolved sum plus the unresolved sum, and that map is linear."""

    started = time.perf_counter()
    shapes = [
        (components, mask)
        for components in range(1, 5)
        for mask in range(1 << components)
    ]
    failed_shapes = [shape for shape in shapes if not _subset_gap(*shape)]
    identity = _identity_negation(4)
    linearity = _linearity_negation(4)
    oracle = _oracle_partitions()
    documented = _documented_basket()
    gap_rejected = _rejected(
        lambda: partial_resolution_nav((1, 1), resolved={0: 1}, unresolved_marks={})
    )
    overlap_rejected = _rejected(
        lambda: partial_resolution_nav(
            (1, 1),
            resolved={0: 1},
            unresolved_marks={0: 1, 1: 1},
        )
    )
    negative_rejected = _rejected(
        lambda: partial_resolution_nav((1,), resolved={0: -1}, unresolved_marks={})
    )
    elapsed = time.perf_counter() - started

    oracle_clean = oracle[0]["mismatches"] == []
    documented_ok = documented["nav"] == documented["expected"]
    discharged = (
        not failed_shapes
        and identity == "unsat"
        and linearity == "unsat"
        and oracle_clean
        and documented_ok
        and gap_rejected
        and overlap_rejected
        and negative_rejected
    )
    counterexample = None
    if not discharged:
        counterexample = {
            "failed_shapes": failed_shapes,
            "identity_negation": identity,
            "linearity_negation": linearity,
            "oracle_mismatches": oracle[0]["mismatches"],
            "documented": documented,
            "gap_rejected": gap_rejected,
            "overlap_rejected": overlap_rejected,
            "negative_rejected": negative_rejected,
        }
    return {
        "id": "T-PARTIAL-001",
        "written_claim": "partial-resolution NAV decomposes linearly by resolved/unresolved sets",
        "statement": (
            "For a partition of the components into resolved and unresolved sets, "
            "NAV equals the sum of weight times resolved payout plus weight times supplied mark, "
            "and that value is linear in the weights"
        ),
        "checker": "sympy_z3_and_partial_resolution_nav",
        "oracle": "partial_resolution_nav",
        "sympy_version": sympy.__version__,
        "z3_version": str(z3.get_version_string()),
        "shapes_checked": len(shapes),
        "failed_shapes": failed_shapes,
        "identity_negation": identity,
        "linearity_negation": linearity,
        "oracle_partitions": oracle[0]["checked"],
        "oracle_mismatches": oracle[0]["mismatches"],
        "documented_basket": documented,
        "non_partition": {"gap_rejected": gap_rejected, "overlap_rejected": overlap_rejected},
        "negative_mark": "rejected_outside_nonnegative_domain" if negative_rejected else "returned",
        "assumptions": [
            "R and U partition the component indices",
            "weights, resolved payouts, and supplied marks are nonnegative",
            "marks are inputs under A-M04 and are not exchange prices",
            "partial_resolution_nav is the executable oracle and is not modified",
        ],
        "classification": "PROVEN_UNDER_ASSUMPTIONS" if discharged else "COUNTEREXAMPLE_FOUND",
        "counterexample": counterexample,
        "canonical_math1": "FAIL",
        "runtime_seconds": round(elapsed, 6),
    }
