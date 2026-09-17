"""Bounded exhaustive verification helpers for PRISM MATH-1B.

These checks do not replace universal proofs. They enumerate declared finite
integer/rational domains and return counts or raise with a minimal local
counterexample context.
"""
from __future__ import annotations

from fractions import Fraction
from typing import Sequence

from replication import F, normalize_matrix, payoff
from settlement import terminal_backing_value


class BoundedVerificationError(AssertionError):
    pass


def verify_mint_redeem_grid(
    weights: Sequence,
    *,
    max_supply: int = 8,
    max_extra: int = 3,
    max_quantity: int = 5,
) -> dict[str, int]:
    """Exhaustively check algebraic backing preservation in a bounded grid.

    Backing states are constructed as exact required backing plus a non-negative
    integer surplus per component. Mint is tested with exact new backing Q*x.
    Redemption is tested for every Q<=S.
    """
    x = tuple(F(v) for v in weights)
    if not x or any(v < 0 for v in x):
        raise ValueError("weights must be non-empty and non-negative")

    mint_cases = 0
    redeem_cases = 0

    # Use a shared scalar extra margin for deterministic compact enumeration.
    # Separate-component surplus enumeration can be added if needed.
    for s_int in range(max_supply + 1):
        S = Fraction(s_int)
        for extra_int in range(max_extra + 1):
            extra = Fraction(extra_int)
            B = tuple(S * w + extra for w in x)

            if any(B[i] < S * x[i] for i in range(len(x))):
                raise BoundedVerificationError(
                    f"invalid generated backing state S={S}, B={B}"
                )

            for q_int in range(1, max_quantity + 1):
                Q = Fraction(q_int)
                S2 = S + Q
                B2 = tuple(B[i] + Q * x[i] for i in range(len(x)))
                if any(B2[i] < S2 * x[i] for i in range(len(x))):
                    raise BoundedVerificationError(
                        f"mint counterexample S={S}, Q={Q}, B={B}, B2={B2}"
                    )
                mint_cases += 1

            for q_int in range(1, min(s_int, max_quantity) + 1):
                Q = Fraction(q_int)
                S2 = S - Q
                B2 = tuple(B[i] - Q * x[i] for i in range(len(x)))
                if any(B2[i] < S2 * x[i] for i in range(len(x))):
                    raise BoundedVerificationError(
                        f"redeem counterexample S={S}, Q={Q}, B={B}, B2={B2}"
                    )
                redeem_cases += 1

    return {"mint_cases": mint_cases, "redeem_cases": redeem_cases}


def verify_terminal_solvency_grid(
    matrix: Sequence[Sequence],
    weights: Sequence,
    *,
    max_supply: int = 8,
    max_extra: int = 3,
) -> dict[str, int]:
    """Enumerate bounded supplies/surpluses and every terminal world."""
    G = normalize_matrix(matrix)
    x = tuple(F(v) for v in weights)
    h = payoff(G, x)
    if len(x) != len(G[0]):
        raise ValueError("weight dimension mismatch")

    cases = 0
    for s_int in range(max_supply + 1):
        S = Fraction(s_int)
        for extra_int in range(max_extra + 1):
            extra = Fraction(extra_int)
            B = tuple(S * w + extra for w in x)
            for state_idx, row in enumerate(G):
                vb = terminal_backing_value(B, row)
                liability = S * h[state_idx]
                if vb < liability:
                    raise BoundedVerificationError(
                        "terminal insolvency counterexample "
                        f"S={S}, B={B}, state={state_idx}, "
                        f"backing={vb}, liability={liability}"
                    )
                cases += 1
    return {"terminal_cases": cases}


def verify_settlement_redemption_grid(
    final_payout,
    *,
    max_supply: int = 8,
    max_extra: int = 3,
) -> dict[str, int]:
    """Check that funded final redemption preserves funding in bounded states."""
    R = F(final_payout)
    if R < 0:
        raise ValueError("final payout must be non-negative")

    cases = 0
    for s_int in range(max_supply + 1):
        S = Fraction(s_int)
        for extra_int in range(max_extra + 1):
            balance = S * R + Fraction(extra_int)
            for q_int in range(0, s_int + 1):
                Q = Fraction(q_int)
                S2 = S - Q
                B2 = balance - Q * R
                if B2 < S2 * R:
                    raise BoundedVerificationError(
                        f"settlement counterexample S={S}, Q={Q}, R={R}, "
                        f"balance={balance}, balance2={B2}"
                    )
                cases += 1
    return {"settlement_cases": cases}


def run_phase1_bounded_suite(
    matrix: Sequence[Sequence],
    weights: Sequence,
    *,
    final_payout,
    max_supply: int = 8,
    max_extra: int = 3,
    max_quantity: int = 5,
) -> dict[str, int]:
    """Run the standard dependency-free bounded verification suite."""
    report = {}
    report.update(
        verify_mint_redeem_grid(
            weights,
            max_supply=max_supply,
            max_extra=max_extra,
            max_quantity=max_quantity,
        )
    )
    report.update(
        verify_terminal_solvency_grid(
            matrix,
            weights,
            max_supply=max_supply,
            max_extra=max_extra,
        )
    )
    report.update(
        verify_settlement_redemption_grid(
            final_payout,
            max_supply=max_supply,
            max_extra=max_extra,
        )
    )
    return report
