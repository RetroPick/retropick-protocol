"""Machine-readable resolution specification.

Settlement reads the frozen hash, the resolver id, and the Phase-1 result
enum. Free-text criteria are not a settlement input.
"""

from __future__ import annotations

from dataclasses import dataclass

from domain import PredictionError, ResolutionResult


@dataclass(frozen=True)
class ResolutionSpec:
    market_id: str
    collateral: str
    resolver: str
    spec_hash: str
    outcome_slot_count: int = 2

    def __post_init__(self) -> None:
        if self.outcome_slot_count != 2:
            raise PredictionError("Phase-1 resolution spec is binary")
        if not self.market_id or not self.collateral or not self.resolver or not self.spec_hash:
            raise PredictionError("resolution spec fields must be non-empty")


def payout_numerators(result: ResolutionResult) -> tuple[int, int]:
    """Return (yes_numerator, no_numerator) over denominator 2.

    YES_WIN and NO_WIN are exactly 1 and 0. INVALID is exactly 1/2 and 1/2.
    Using a common denominator makes the integer policy obvious:
    raw payout before rounding is numerator/2 per collateral unit.
    """

    if result is ResolutionResult.YES_WIN:
        return (2, 0)
    if result is ResolutionResult.NO_WIN:
        return (0, 2)
    if result is ResolutionResult.INVALID:
        return (1, 1)
    raise PredictionError(f"unsupported resolution result {result}")


def denominator() -> int:
    return 2
