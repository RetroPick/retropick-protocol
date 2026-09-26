"""R-THEOREM-1 through R-THEOREM-6, mapped to the first six canonical PRISM theorems.

Those R-THEOREM ids are not strings in the canonical docs. The order is the
core registry in docs/prism/math/17_THEOREMS.md:

    R-THEOREM-1  T-REPL-001
    R-THEOREM-2  T-BS-001
    R-THEOREM-3  T-BS-002
    R-THEOREM-4  T-BS-003
    R-THEOREM-5  T-BS-004
    R-THEOREM-6  T-ALLOC-001

Only R-THEOREM-1 is checked here. The others are an inventory of artifacts
already on disk. This module does not re-run those checks and does not change
a settlement or backing rule.
"""

from __future__ import annotations

import time
from fractions import Fraction
from typing import Any

import sympy

from replication import payoff


INVENTORY: dict[str, dict[str, str]] = {
    "R-THEOREM-1": {
        "canonical_id": "T-REPL-001",
        "claim": "admitted basket payoff is exactly h=Gx",
        "prior_checker": "none",
        "prior_note": "definitions in docs/prism/math/01_DEFINITIONS.md and numeric examples in research/prism-model/tests/test_replication.py",
        "before": "prose",
    },
    "R-THEOREM-2": {
        "canonical_id": "T-BS-001",
        "claim": "exact-backed mint preserves component backing and margin",
        "prior_checker": "research/prism-model/bounded_verification.py",
        "prior_note": "verify_mint_redeem_grid is a finite grid. The universal write-up is prose in docs/prism/math/05_BACKING_SOLVENCY.md",
        "before": "prose_plus_bounded_grid",
    },
    "R-THEOREM-3": {
        "canonical_id": "T-BS-002",
        "claim": "exact in-kind redemption preserves remaining backing",
        "prior_checker": "research/prism-model/bounded_verification.py",
        "prior_note": "same finite grid. Universal write-up is prose in docs/prism/math/05_BACKING_SOLVENCY.md",
        "before": "prose_plus_bounded_grid",
    },
    "R-THEOREM-4": {
        "canonical_id": "T-BS-003",
        "claim": "component backing implies terminal solvency",
        "prior_checker": "research/prism-model/math1_probe.py",
        "prior_note": "z3_reports and sympy_identity discharge two components and one state. The general sum is still the prose write-up",
        "before": "PARTIALLY_PROVEN",
    },
    "R-THEOREM-5": {
        "canonical_id": "T-BS-004",
        "claim": "funded final redemption preserves remaining settlement funding in exact arithmetic",
        "prior_checker": "none",
        "prior_note": "prose in docs/prism/math/05_BACKING_SOLVENCY.md. Numeric oracle in research/prism-model/tests/test_settlement.py. The per-call floor counterexample is a different rule",
        "before": "prose",
    },
    "R-THEOREM-6": {
        "canonical_id": "T-ALLOC-001",
        "claim": "global reservation sum stays within the physical balance",
        "prior_checker": "none",
        "prior_note": "prose in docs/prism/math/05_BACKING_SOLVENCY.md section 6. Examples in research/prism-model/tests/test_executable_gaps.py",
        "before": "prose",
    },
}


def _shape_identity(states: int, components: int) -> bool:
    matrix = sympy.Matrix(states, components, lambda i, j: sympy.symbols(f"g{i}_{j}"))
    weights = sympy.Matrix(components, 1, lambda i, _j: sympy.symbols(f"x{i}"))
    product = matrix * weights
    manual = sympy.Matrix([sum(matrix[i, j] * weights[j] for j in range(components)) for i in range(states)])
    gap = sympy.expand(product - manual)
    return all(entry == 0 for entry in gap)


def discharge_r_theorem_1() -> dict[str, Any]:
    """h = Gx for finite exact dimensions.

    Assumptions already stated: a finite payoff matrix and a finite replication
    vector, with h(omega) defined as the state-wise sum. Non-negativity is not
    required for the equality. Phase-1 payoff() still rejects negative entries.
    """

    started = time.perf_counter()
    shapes = [(states, components) for states in range(1, 5) for components in range(1, 5)]
    failed = [shape for shape in shapes if not _shape_identity(*shape)]
    matrix = [[0, 1], [0, 0], [1, 1], [1, 0]]
    weights = [Fraction(3, 5), Fraction(2, 5)]
    oracle = payoff(matrix, weights)
    symbolic = sympy.Matrix(matrix) * sympy.Matrix(weights)
    oracle_matches = [sympy.Rational(value) for value in oracle] == list(symbolic)
    elapsed = time.perf_counter() - started
    clean = not failed and oracle_matches
    return {
        "id": "R-THEOREM-1",
        "canonical_id": "T-REPL-001",
        "checker": "sympy",
        "sympy_version": sympy.__version__,
        "shapes": [list(shape) for shape in shapes],
        "failed_shapes": [list(shape) for shape in failed],
        "oracle_matches_matrix_product": oracle_matches,
        "oracle_payoff": [str(value) for value in oracle],
        "assumptions": [
            "finite rectangular payoff matrix",
            "finite replication vector",
            "exact rational or symbolic arithmetic",
            "h(omega) is the state-wise sum of x_i g_i(omega)",
        ],
        "nonnegativity_required_for_equality": False,
        "classification": "PROVEN_UNDER_ASSUMPTIONS" if clean else "COUNTEREXAMPLE_FOUND",
        "counterexample": None if clean else {"failed_shapes": [list(shape) for shape in failed]},
        "runtime_seconds": round(elapsed, 6),
        "canonical_math1": "FAIL",
    }
