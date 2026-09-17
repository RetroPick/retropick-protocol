"""Exact finite-state payoff and replication helpers."""
from __future__ import annotations

from fractions import Fraction
from itertools import combinations
from typing import Iterable, Sequence


class ReplicationError(ValueError):
    pass


def F(value) -> Fraction:
    if isinstance(value, Fraction):
        return value
    if isinstance(value, float):
        return Fraction(str(value))
    return Fraction(value)


def normalize_matrix(matrix: Sequence[Sequence]) -> tuple[tuple[Fraction, ...], ...]:
    rows = tuple(tuple(F(v) for v in row) for row in matrix)
    if not rows:
        raise ReplicationError("payoff matrix must have at least one state")
    width = len(rows[0])
    if width == 0 or any(len(row) != width for row in rows):
        raise ReplicationError("payoff matrix must be rectangular and non-empty")
    if any(v < 0 for row in rows for v in row):
        raise ReplicationError("Phase-1 component payoffs must be non-negative")
    return rows


def payoff(matrix: Sequence[Sequence], weights: Sequence) -> tuple[Fraction, ...]:
    G = normalize_matrix(matrix)
    x = tuple(F(v) for v in weights)
    if len(x) != len(G[0]):
        raise ReplicationError("weight dimension does not match component count")
    if any(v < 0 for v in x):
        raise ReplicationError("Phase-1 replication weights must be non-negative")
    return tuple(sum(row[j] * x[j] for j in range(len(x))) for row in G)


def _solve_square(A: Sequence[Sequence[Fraction]], b: Sequence[Fraction]):
    """Gaussian elimination over exact Fractions. Returns None if singular."""
    n = len(A)
    aug = [list(A[i]) + [b[i]] for i in range(n)]
    for col in range(n):
        pivot = next((r for r in range(col, n) if aug[r][col] != 0), None)
        if pivot is None:
            return None
        aug[col], aug[pivot] = aug[pivot], aug[col]
        pv = aug[col][col]
        aug[col] = [v / pv for v in aug[col]]
        for r in range(n):
            if r == col:
                continue
            factor = aug[r][col]
            if factor:
                aug[r] = [aug[r][c] - factor * aug[col][c] for c in range(n + 1)]
    return tuple(aug[i][-1] for i in range(n))


def find_exact_nonnegative_replication(matrix: Sequence[Sequence], target: Sequence):
    """
    Find one exact non-negative solution Gx=h for small Phase-1 systems.

    This bootstrap solver enumerates independent row subsets of size n and
    validates the resulting candidate against every row. It is deliberately
    dependency-free and intended for small hackathon/reference-model matrices.
    A production spanning engine may use an LP solver but must preserve these semantics.
    """
    G = normalize_matrix(matrix)
    h = tuple(F(v) for v in target)
    m, n = len(G), len(G[0])
    if len(h) != m:
        raise ReplicationError("target dimension must equal number of states")
    if n > m:
        raise ReplicationError(
            "bootstrap solver requires components <= states; use a general LP solver later"
        )
    for idx in combinations(range(m), n):
        A = tuple(G[i] for i in idx)
        b = tuple(h[i] for i in idx)
        candidate = _solve_square(A, b)
        if candidate is None or any(v < 0 for v in candidate):
            continue
        if payoff(G, candidate) == h:
            return candidate
    return None


def is_exactly_replicable(matrix: Sequence[Sequence], target: Sequence) -> bool:
    return find_exact_nonnegative_replication(matrix, target) is not None
