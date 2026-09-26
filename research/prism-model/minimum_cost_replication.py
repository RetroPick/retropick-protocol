"""Exact minimum-cost nonnegative replication for a declared rational matrix.

This is not a Kuru price, not a solvency theorem, and not MATH-1 PASS.
No float LP is called. A returned weight vector is kept only after ``Gx = h``
is recomputed with :class:`fractions.Fraction`.
"""

from __future__ import annotations

import time
from dataclasses import dataclass
from fractions import Fraction
from itertools import combinations
from typing import Sequence

from replication import F, ReplicationError

MAX_STATES = 16
MAX_COMPONENTS = 8

PRODUCT_NOT_REPLICABLE = "PRODUCT_NOT_REPLICABLE"
COST_UNBOUNDED = "COST_UNBOUNDED"
EXACT = "EXACT"

CLASSIFICATION = "EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN"
DOMAIN = (
    f"rational G, h, and c with 1..{MAX_STATES} states and 1..{MAX_COMPONENTS} components; "
    "every column subset of size rank(G) is solved over Fractions"
)


class DomainError(ReplicationError):
    pass


@dataclass(frozen=True)
class ReplicationCertificate:
    """One declared instance. ``x`` is present only when ``status`` is EXACT."""

    status: str
    x: tuple[Fraction, ...] | None
    cost: Fraction | None
    rechecked_equal: bool
    reason: str
    bases_checked: int
    rays_checked: int
    runtime_seconds: float
    classification: str
    domain: str

    def as_dict(self) -> dict[str, str | int | bool]:
        return {
            "status": self.status,
            "x": "" if self.x is None else _fmt_vector(self.x),
            "cost": "" if self.cost is None else _fmt(self.cost),
            "rechecked_equal": self.rechecked_equal,
            "reason": self.reason,
            "bases_checked": self.bases_checked,
            "rays_checked": self.rays_checked,
            "runtime_seconds": f"{self.runtime_seconds:.6f}",
            "classification": self.classification,
            "domain": self.domain,
            "float_lp_used": False,
            "not_kuru": True,
            "not_solvency": True,
        }


def minimum_cost_exact_replication(
    matrix: Sequence[Sequence],
    target: Sequence,
    cost: Sequence,
) -> ReplicationCertificate:
    """Return a minimum of ``c·x`` over ``x >= 0`` with ``Gx = h``, or a refusal.

    ``PRODUCT_NOT_REPLICABLE`` means no exact nonnegative ``x`` exists.
    ``COST_UNBOUNDED`` means exact nonnegative solutions exist and ``c·x`` has
    no lower bound. Several exact optima return the lexicographically smallest
    basic solution.
    """

    started = time.perf_counter()
    G = _matrix(matrix)
    h = tuple(F(v) for v in target)
    c = tuple(F(v) for v in cost)
    m, n = len(G), len(G[0])
    if len(h) != m:
        raise ReplicationError("target dimension must equal number of states")
    if len(c) != n:
        raise ReplicationError("cost dimension must equal number of components")

    consistent, rank = _equality_consistent(G, h)
    if not consistent:
        return _finish(
            status=PRODUCT_NOT_REPLICABLE,
            x=None,
            cost=None,
            rechecked_equal=False,
            reason="equality_inconsistent",
            bases_checked=0,
            rays_checked=0,
            started=started,
        )

    feasible: list[tuple[Fraction, ...]] = []
    bases_checked = 0
    for basis in combinations(range(n), rank):
        bases_checked += 1
        solved = _solve_columns(G, h, basis)
        if solved is None:
            continue
        weights = _embed(n, basis, solved)
        if any(v < 0 for v in weights):
            continue
        if _apply(G, weights) != h:
            raise ReplicationError("basic solution failed exact re-check")
        feasible.append(weights)

    rays_checked, negative_ray = _negative_cost_ray(G, c, rank)
    if negative_ray:
        return _finish(
            status=COST_UNBOUNDED,
            x=None,
            cost=None,
            rechecked_equal=False,
            reason="negative_cost_ray",
            bases_checked=bases_checked,
            rays_checked=rays_checked,
            started=started,
        )
    if not feasible:
        return _finish(
            status=PRODUCT_NOT_REPLICABLE,
            x=None,
            cost=None,
            rechecked_equal=False,
            reason="no_nonnegative_basic_feasible_solution",
            bases_checked=bases_checked,
            rays_checked=rays_checked,
            started=started,
        )

    def objective(weights: tuple[Fraction, ...]) -> Fraction:
        return sum((c[j] * weights[j] for j in range(n)), Fraction(0))

    chosen = min(feasible, key=lambda weights: (objective(weights), weights))
    paid = objective(chosen)
    if _apply(G, chosen) != h or any(v < 0 for v in chosen):
        raise ReplicationError("minimum-cost vector failed exact re-check")
    return _finish(
        status=EXACT,
        x=chosen,
        cost=paid,
        rechecked_equal=True,
        reason="exact_basic_minimum",
        bases_checked=bases_checked,
        rays_checked=rays_checked,
        started=started,
    )


def declared_record() -> dict[str, object]:
    """Run the declared examples used as evidence. Not a protocol theorem."""

    and_matrix = ((0, 0, 1), (0, 1, 1), (1, 0, 1), (1, 1, 1))
    and_target = (0, 0, 0, 1)
    and_cost = (1, 1, 1)
    and_result = minimum_cost_exact_replication(and_matrix, and_target, and_cost)

    cheaper = minimum_cost_exact_replication(
        ((1, 1), (2, 2)),
        (1, 2),
        (3, 1),
    )
    three = minimum_cost_exact_replication(
        ((1, 0, 1), (0, 1, 1)),
        (1, 1),
        (2, 2, 1),
    )
    return {
        "classification": CLASSIFICATION,
        "domain": DOMAIN,
        "float_lp_used": False,
        "not_kuru": True,
        "not_solvency": True,
        "not_math1_pass": True,
        "and_with_constant": and_result.as_dict(),
        "cheaper_duplicate_column": cheaper.as_dict(),
        "three_column_minimum": three.as_dict(),
    }


def _matrix(matrix: Sequence[Sequence]) -> tuple[tuple[Fraction, ...], ...]:
    rows = tuple(tuple(F(value) for value in row) for row in matrix)
    if not rows:
        raise ReplicationError("payoff matrix must have at least one state")
    width = len(rows[0])
    if width == 0 or any(len(row) != width for row in rows):
        raise ReplicationError("payoff matrix must be rectangular and non-empty")
    if len(rows) > MAX_STATES or width > MAX_COMPONENTS:
        raise DomainError(
            f"enumeration domain is at most {MAX_STATES} states and {MAX_COMPONENTS} components"
        )
    return rows


def _apply(matrix: Sequence[Sequence[Fraction]], weights: Sequence[Fraction]) -> tuple[Fraction, ...]:
    return tuple(
        sum((row[j] * weights[j] for j in range(len(weights))), Fraction(0)) for row in matrix
    )


def _rref(rows: list[list[Fraction]]) -> tuple[list[list[Fraction]], list[int]]:
    reduced = [list(row) for row in rows]
    if not reduced:
        return reduced, []
    height = len(reduced)
    width = len(reduced[0])
    pivot_row = 0
    pivots: list[int] = []
    for col in range(width):
        pivot = next((row for row in range(pivot_row, height) if reduced[row][col] != 0), None)
        if pivot is None:
            continue
        reduced[pivot_row], reduced[pivot] = reduced[pivot], reduced[pivot_row]
        scale = reduced[pivot_row][col]
        reduced[pivot_row] = [value / scale for value in reduced[pivot_row]]
        for row in range(height):
            if row == pivot_row:
                continue
            factor = reduced[row][col]
            if factor != 0:
                reduced[row] = [
                    reduced[row][col_index] - factor * reduced[pivot_row][col_index]
                    for col_index in range(width)
                ]
        pivots.append(col)
        pivot_row += 1
        if pivot_row == height:
            break
    return reduced, pivots


def _equality_consistent(matrix: Sequence[Sequence[Fraction]], target: Sequence[Fraction]) -> tuple[bool, int]:
    augmented = [list(row) + [target[index]] for index, row in enumerate(matrix)]
    _reduced, pivots = _rref(augmented)
    width = len(matrix[0])
    if any(pivot == width for pivot in pivots):
        return False, 0
    return True, len(pivots)


def _solve_columns(
    matrix: Sequence[Sequence[Fraction]],
    target: Sequence[Fraction],
    columns: tuple[int, ...],
) -> tuple[Fraction, ...] | None:
    width = len(columns)
    augmented = [[row[col] for col in columns] + [target[index]] for index, row in enumerate(matrix)]
    reduced, pivots = _rref(augmented)
    if any(pivot == width for pivot in pivots):
        return None
    if len(pivots) != width:
        return None
    solved = [Fraction(0) for _ in range(width)]
    for row in reduced:
        nonzero = [col for col in range(width) if row[col] != 0]
        if not nonzero:
            if row[width] != 0:
                return None
            continue
        solved[nonzero[0]] = row[width]
    return tuple(solved)


def _embed(width: int, columns: tuple[int, ...], values: Sequence[Fraction]) -> tuple[Fraction, ...]:
    weights = [Fraction(0) for _ in range(width)]
    for index, column in enumerate(columns):
        weights[column] = values[index]
    return tuple(weights)


def _negative_cost_ray(
    matrix: Sequence[Sequence[Fraction]],
    cost: Sequence[Fraction],
    rank: int,
) -> tuple[int, bool]:
    """Return how many candidate rays were built, and whether one has negative cost.

    A nonempty ``{x >= 0 | Gx = h}`` is pointed. Its recession rays are the
    nonnegative nullspace directions. Each extreme ray uses one independent
    column basis and one extra column.
    """

    states = len(matrix)
    components = len(matrix[0])
    zero = tuple(Fraction(0) for _ in range(states))
    checked = 0
    for basis in combinations(range(components), rank):
        if rank and _solve_columns(matrix, [matrix[row][basis[0]] for row in range(states)], basis) is None:
            continue
        for extra in range(components):
            if extra in basis:
                continue
            checked += 1
            rhs = tuple(-matrix[row][extra] for row in range(states))
            solved = _solve_columns(matrix, rhs, basis)
            if solved is None or any(value < 0 for value in solved):
                continue
            direction = _embed(components, basis, solved)
            direction_list = list(direction)
            direction_list[extra] = Fraction(1)
            direction = tuple(direction_list)
            if _apply(matrix, direction) != zero:
                raise ReplicationError("nullspace ray failed exact re-check")
            ray_cost = sum((cost[j] * direction[j] for j in range(components)), Fraction(0))
            if ray_cost < 0:
                return checked, True
    return checked, False


def _finish(
    *,
    status: str,
    x: tuple[Fraction, ...] | None,
    cost: Fraction | None,
    rechecked_equal: bool,
    reason: str,
    bases_checked: int,
    rays_checked: int,
    started: float,
) -> ReplicationCertificate:
    return ReplicationCertificate(
        status=status,
        x=x,
        cost=cost,
        rechecked_equal=rechecked_equal,
        reason=reason,
        bases_checked=bases_checked,
        rays_checked=rays_checked,
        runtime_seconds=time.perf_counter() - started,
        classification=CLASSIFICATION,
        domain=DOMAIN,
    )


def _fmt(value: Fraction) -> str:
    return f"{value.numerator}/{value.denominator}"


def _fmt_vector(values: Sequence[Fraction]) -> str:
    return "(" + ", ".join(_fmt(value) for value in values) + ")"
