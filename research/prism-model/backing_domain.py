"""Bounded exhaustive checks on PrismSeries mint and in-kind redeem.

Weights are {0, 1, 2}/2. PrismSeries stores them as Fractions, so that set is
0, 1/2, and 1. This file does not add a backing rule.
"""

from __future__ import annotations

import time
from fractions import Fraction
from typing import Any

from model import ModelError, PrismSeries


WEIGHTS = (Fraction(0), Fraction(1, 2), Fraction(1))
SUPPLY_MAX = 8
QUANTITY_MAX = 8
PAYOFF = [[0, 0], [1, 1]]


def _open(weights: tuple[Fraction, Fraction], supply: int) -> PrismSeries:
    series = PrismSeries(PAYOFF, weights)
    series.activate()
    if supply:
        series.mint_with_exact_backing(supply)
    return series


def _snap(series: PrismSeries) -> tuple[Any, ...]:
    return (series.state, series.supply, tuple(series.backing))


def _backed(series: PrismSeries) -> bool:
    return all(series.backing[index] >= series.supply * weight for index, weight in enumerate(series.weights))


def run_backing_domain() -> dict[str, Any]:
    started = time.perf_counter()
    states = 0
    transitions = 0
    accepted = 0
    rejected = 0
    failures: list[dict[str, Any]] = []

    def _fail(**fields: Any) -> None:
        if len(failures) < 8:
            failures.append(fields)

    for left in WEIGHTS:
        for right in WEIGHTS:
            weights = (left, right)
            for supply in range(0, SUPPLY_MAX + 1):
                states += 1
                start = _open(weights, supply)
                if not _backed(start):
                    _fail(kind="setup", supply=supply, weights=[str(left), str(right)])
                for quantity in range(0, QUANTITY_MAX + 1):
                    for name, call in (
                        ("mint", lambda book, amount: book.mint(amount)),
                        ("mint_with_exact_backing", lambda book, amount: book.mint_with_exact_backing(amount)),
                        ("redeem_in_kind", lambda book, amount: book.redeem_in_kind(amount)),
                    ):
                        book = _open(weights, supply)
                        before = _snap(book)
                        transitions += 1
                        try:
                            call(book, quantity)
                        except ModelError:
                            rejected += 1
                            if _snap(book) != before:
                                _fail(
                                    kind="rejected-mutated",
                                    operation=name,
                                    supply=supply,
                                    quantity=quantity,
                                    weights=[str(left), str(right)],
                                )
                            continue
                        accepted += 1
                        if not _backed(book):
                            _fail(
                                kind="underbacked",
                                operation=name,
                                supply=supply,
                                quantity=quantity,
                                weights=[str(left), str(right)],
                                ended_supply=str(book.supply),
                                backing=[str(value) for value in book.backing],
                            )

    elapsed = time.perf_counter() - started
    minimal = None
    if failures:
        minimal = min(
            failures,
            key=lambda row: (
                row.get("supply", 0),
                row.get("quantity", 0),
                row.get("operation", ""),
                tuple(row.get("weights", [])),
            ),
        )
    return {
        "model": "PrismSeries",
        "components": 2,
        "weights": ["0", "1/2", "1"],
        "weight_note": "{0, 1, 2}/2. PrismSeries accepts these Fractions. Wad scaling was not required.",
        "supply_max": SUPPLY_MAX,
        "quantity_max": QUANTITY_MAX,
        "quantity_domain": "every pair of supply and quantity in 0..8, for mint, mint_with_exact_backing, and redeem_in_kind",
        "states": states,
        "transitions": transitions,
        "accepted": accepted,
        "rejected": rejected,
        "runtime_seconds": round(elapsed, 6),
        "failure_count": len(failures),
        "failures": failures,
        "minimal_counterexample": minimal,
        "domain_check": "EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN" if not failures else "COUNTEREXAMPLE_FOUND",
        "invariant": "B_i >= S * x_i after an accepted transition; a rejected transition leaves supply and backing unchanged",
    }
