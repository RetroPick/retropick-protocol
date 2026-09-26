"""Synthetic create/redeem quotes. Not a protocol theorem and not Kuru liquidity.

C(q) is the cost of lifting the asks for q * x_i of each component, plus the
declared fee and execution-cost terms. R(q) is the proceeds of hitting the
bids for those sizes, minus the same terms.

Every price in this module comes from a book whose levels are written below.
A number computed on a declared non-empty book is SUPPORTED_BY_SIMULATION.
An empty book, or a size the book cannot fill, has no executable price and is
NOT_YET_VALIDATED. Neither observation is an input to h = Gx, and neither
changes backing solvency. This module does not claim that an arbitrage trade
will happen.
"""

from __future__ import annotations

import time
from dataclasses import dataclass
from fractions import Fraction
from typing import Sequence


class MarketModelError(ValueError):
    pass


@dataclass(frozen=True)
class Level:
    price: Fraction
    size: Fraction

    def __post_init__(self) -> None:
        if self.price < 0 or self.size < 0:
            raise MarketModelError("level price and size must be non-negative")


@dataclass(frozen=True)
class CostTerms:
    fee_quote: Fraction
    execution_quote: Fraction

    def __post_init__(self) -> None:
        if self.fee_quote < 0 or self.execution_quote < 0:
            raise MarketModelError("fee and execution cost must be non-negative")


@dataclass(frozen=True)
class ComponentBook:
    """Asks are lifted from the front. Bids are hit from the front."""

    asks: tuple[Level, ...]
    bids: tuple[Level, ...]


@dataclass(frozen=True)
class Quote:
    create_cost: Fraction | None
    redeem_value: Fraction | None
    classification: str
    reason: str


def _walk(levels: Sequence[Level], quantity: Fraction) -> Fraction:
    if quantity < 0:
        raise MarketModelError("quantity must be non-negative")
    if quantity == 0:
        return Fraction(0)
    if not levels:
        raise MarketModelError("empty book")
    remaining = quantity
    total = Fraction(0)
    for level in levels:
        take = remaining if remaining < level.size else level.size
        total += take * level.price
        remaining -= take
        if remaining == 0:
            return total
    raise MarketModelError("insufficient depth")


def create_cost(books: Sequence[ComponentBook], quantity: Fraction, weights: Sequence[Fraction], terms: CostTerms) -> Fraction:
    if len(books) != len(weights):
        raise MarketModelError("one book per weight")
    notion = Fraction(0)
    for book, weight in zip(books, weights):
        notion += _walk(book.asks, quantity * weight)
    return notion + terms.fee_quote + terms.execution_quote


def redeem_value(books: Sequence[ComponentBook], quantity: Fraction, weights: Sequence[Fraction], terms: CostTerms) -> Fraction:
    if len(books) != len(weights):
        raise MarketModelError("one book per weight")
    notion = Fraction(0)
    for book, weight in zip(books, weights):
        notion += _walk(book.bids, quantity * weight)
    return notion - terms.fee_quote - terms.execution_quote


def quote(books: Sequence[ComponentBook], quantity: Fraction, weights: Sequence[Fraction], terms: CostTerms) -> Quote:
    try:
        cost = create_cost(books, quantity, weights, terms)
        value = redeem_value(books, quantity, weights, terms)
    except MarketModelError as exc:
        return Quote(None, None, "NOT_YET_VALIDATED", str(exc))
    return Quote(cost, value, "SUPPORTED_BY_SIMULATION", "declared synthetic book")


def accounting_snapshot() -> dict[str, str]:
    """h = Gx with exact backing. Market quotes are not arguments."""

    matrix = ((Fraction(1), Fraction(0)), (Fraction(0), Fraction(1)))
    weights = (Fraction(3), Fraction(4))
    payoff = (
        matrix[0][0] * weights[0] + matrix[0][1] * weights[1],
        matrix[1][0] * weights[0] + matrix[1][1] * weights[1],
    )
    backing = (Fraction(3), Fraction(4))
    solvent = backing[0] >= weights[0] and backing[1] >= weights[1]
    matches = payoff == weights
    return {
        "h_equals_gx": "true" if matches else "false",
        "backing_covers_weights": "true" if solvent else "false",
        "classification": "exact_on_declared_rationals",
    }


def normal_book() -> tuple[list[ComponentBook], Fraction, tuple[Fraction, Fraction], CostTerms]:
    books = [
        ComponentBook(
            asks=(Level(Fraction(11), Fraction(10)), Level(Fraction(13), Fraction(10))),
            bids=(Level(Fraction(9), Fraction(10)), Level(Fraction(7), Fraction(10))),
        ),
        ComponentBook(
            asks=(Level(Fraction(4), Fraction(10)),),
            bids=(Level(Fraction(3), Fraction(10)),),
        ),
    ]
    return books, Fraction(3), (Fraction(1), Fraction(2)), CostTerms(Fraction(1), Fraction(1, 2))


def crossed_book() -> tuple[list[ComponentBook], Fraction, tuple[Fraction, ...], CostTerms]:
    books = [
        ComponentBook(
            asks=(Level(Fraction(5), Fraction(10)),),
            bids=(Level(Fraction(8), Fraction(10)),),
        )
    ]
    return books, Fraction(1), (Fraction(1),), CostTerms(Fraction(0), Fraction(0))


def empty_book() -> tuple[list[ComponentBook], Fraction, tuple[Fraction, ...], CostTerms]:
    books = [ComponentBook(asks=(), bids=())]
    return books, Fraction(1), (Fraction(1),), CostTerms(Fraction(0), Fraction(0))


def depth_book() -> tuple[ComponentBook, Fraction]:
    book = ComponentBook(
        asks=(Level(Fraction(10), Fraction(2)), Level(Fraction(12), Fraction(5))),
        bids=(),
    )
    return book, Fraction(4)


def run() -> dict[str, object]:
    started = time.perf_counter()
    books, quantity, weights, terms = normal_book()
    normal = quote(books, quantity, weights, terms)
    crossed_books, crossed_q, crossed_w, crossed_terms = crossed_book()
    crossed = quote(crossed_books, crossed_q, crossed_w, crossed_terms)
    empty_books, empty_q, empty_w, empty_terms = empty_book()
    empty = quote(empty_books, empty_q, empty_w, empty_terms)
    ladder, size = depth_book()
    walked = _walk(ladder.asks, size)
    accounting = accounting_snapshot()
    elapsed = time.perf_counter() - started
    return {
        "not_a_protocol_theorem": True,
        "not_kuru_liquidity": True,
        "arbitrage_will_happen": "NOT_YET_VALIDATED",
        "normal": {
            "create_cost": str(normal.create_cost),
            "redeem_value": str(normal.redeem_value),
            "classification": normal.classification,
        },
        "crossed": {
            "create_cost": str(crossed.create_cost),
            "redeem_value": str(crossed.redeem_value),
            "redeem_exceeds_create": str(crossed.redeem_value > crossed.create_cost),
            "classification": crossed.classification,
        },
        "empty": {"classification": empty.classification, "reason": empty.reason},
        "depth_walk": {"cost": str(walked), "classification": "SUPPORTED_BY_SIMULATION"},
        "accounting_unchanged_by_quotes": accounting,
        "runtime_seconds": round(elapsed, 6),
    }


if __name__ == "__main__":
    import json

    print(json.dumps(run(), indent=2, sort_keys=True))
