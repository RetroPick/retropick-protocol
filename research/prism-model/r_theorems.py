"""R-THEOREM-1 through R-THEOREM-6, mapped to the first six canonical PRISM theorems.

Those R-THEOREM ids are not strings in the canonical docs. The order is the
core registry in docs/prism/math/17_THEOREMS.md:

    R-THEOREM-1  T-REPL-001
    R-THEOREM-2  T-BS-001
    R-THEOREM-3  T-BS-002
    R-THEOREM-4  T-BS-003
    R-THEOREM-5  T-BS-004
    R-THEOREM-6  T-ALLOC-001

R-THEOREM-1, R-THEOREM-5, and R-THEOREM-6 are checked here. This module
does not change a settlement, backing, or reservation rule.
"""

from __future__ import annotations

import time
from fractions import Fraction
from typing import Any

import sympy
import z3

from fixed_point import WAD
from fixed_point_model import FixedPointSettlement
from replication import payoff
from reservation_ledger import ReservationError, ReservationLedger


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


def discharge_r_theorem_5() -> dict[str, Any]:
    """T-BS-004. If C >= S*R and the redemption pays exactly Q*R, then C' >= S'*R.

    The written row is T-BS-004, not T-ALLOC-001. Double use of reserved units
    is R-THEOREM-6 and is not run here.
    """

    started = time.perf_counter()
    balance, supply, payout, quantity = sympy.symbols("C S R Q", real=True, nonnegative=True)
    remaining_gap = sympy.expand((balance - quantity * payout) - (supply - quantity) * payout)
    funded_gap = sympy.expand(balance - supply * payout)
    identity = sympy.simplify(remaining_gap - funded_gap) == 0

    solver = z3.Solver()
    c, s, r, q = z3.Reals("C S R Q")
    solver.add(c >= 0, s >= 0, r >= 0, q >= 0, q <= s, c >= s * r)
    solver.add(c - q * r < (s - q) * r)
    negation = solver.check()

    overpay = z3.Solver()
    paid = z3.Real("P")
    overpay.add(c >= 0, s >= 0, r >= 0, q >= 0, q <= s, c >= s * r, paid > q * r)
    overpay.add(c - paid < (s - q) * r)
    overpay_status = overpay.check()

    book = FixedPointSettlement(2, WAD - 1, 18, 2)
    book.make_redeemable()
    fragmented = book.redeem(1) + book.redeem(1)
    per_call = {
        "paid_raw": fragmented,
        "remaining_supply": book.supply_units,
        "remaining_balance": book.balance_raw,
        "remaining_required": book.required_balance_raw(),
        "funding_still_holds": book.balance_raw >= book.required_balance_raw(),
        "pays_exact_qr": fragmented == 1,
    }
    elapsed = time.perf_counter() - started
    discharged = identity and negation == z3.unsat
    return {
        "id": "R-THEOREM-5",
        "canonical_id": "T-BS-004",
        "written_claim": "funded final redemption preserves remaining settlement funding",
        "statement": "If C >= S*R and the redemption pays Q*R, then C - Q*R >= (S - Q)*R",
        "checker": "sympy_and_z3",
        "sympy_version": sympy.__version__,
        "z3_version": str(z3.get_version_string()),
        "residual_equals_initial_surplus": identity,
        "negation": str(negation),
        "overpayment_can_break_funding": overpay_status == z3.sat,
        "per_call_rule": per_call,
        "reservation_negative_control": "not_run",
        "reservation_note": "Reserving the same units for two series is T-ALLOC-001, R-THEOREM-6. Not started.",
        "classification": "PROVEN_UNDER_ASSUMPTIONS" if discharged else "COUNTEREXAMPLE_FOUND",
        "counterexample": None,
        "canonical_math1": "FAIL",
        "runtime_seconds": round(elapsed, 6),
    }


def _reservation_violation(name: str, constraint) -> str:
    balance, reserved, other, quantity = z3.Reals("B R O q")
    solver = z3.Solver()
    solver.add(balance >= 0, reserved >= 0, other >= 0, quantity >= 0)
    solver.add(reserved + other <= balance)
    solver.add(constraint(balance, reserved, other, quantity))
    return str(solver.check())


def _ledger_view(ledger: ReservationLedger, asset: str) -> tuple[Fraction, Fraction, Fraction, Fraction, Fraction]:
    return (
        ledger.balance(asset),
        ledger.total_reserved(asset),
        ledger.available(asset),
        ledger.reserved_for("A", asset),
        ledger.reserved_for("B", asset),
    )


def discharge_r_theorem_6() -> dict[str, Any]:
    """T-ALLOC-001. Sum of reservations stays within the physical balance.

    Other series are one nonnegative total, so the check is not limited to two
    series ids. The ledger itself is not modified.
    """

    started = time.perf_counter()
    transitions = {
        "deposit": lambda balance, reserved, other, quantity: reserved + other > balance + quantity,
        "reserve": lambda balance, reserved, other, quantity: z3.And(
            quantity <= balance - reserved - other,
            reserved + quantity + other > balance,
        ),
        "release": lambda balance, reserved, other, quantity: z3.And(
            quantity <= reserved,
            reserved - quantity + other > balance,
        ),
        "withdraw": lambda balance, reserved, other, quantity: z3.And(
            quantity <= balance - reserved - other,
            reserved + other > balance - quantity,
        ),
    }
    negation = {name: _reservation_violation(name, constraint) for name, constraint in transitions.items()}

    fitting = ReservationLedger()
    fitting.deposit("ASSET", 100)
    fitting.reserve("A", {"ASSET": 60})
    fitting.reserve("B", {"ASSET": 25})
    available_after_fit = fitting.available("ASSET")

    exclusive = ReservationLedger()
    exclusive.deposit("ASSET", 100)
    exclusive.reserve("A", {"ASSET": 60})
    before = _ledger_view(exclusive, "ASSET")
    rejected = False
    try:
        exclusive.reserve("B", {"ASSET": 50})
    except ReservationError:
        rejected = True
    after = _ledger_view(exclusive, "ASSET")
    elapsed = time.perf_counter() - started
    discharged = all(status == "unsat" for status in negation.values()) and rejected and before == after
    discharged = discharged and available_after_fit == Fraction(15)
    return {
        "id": "R-THEOREM-6",
        "canonical_id": "T-ALLOC-001",
        "written_claim": "sum_s Reserved[s,a] <= PhysicalBalance[a] is preserved by deposit, reserve, release, and withdraw",
        "checker": "z3_and_reservation_ledger",
        "z3_version": str(z3.get_version_string()),
        "negation": negation,
        "assumptions": [
            "one asset",
            "nonnegative balance, series reservation, other-series total, and quantity",
            "the invariant holds before the transition",
            "other series are their summed reservation",
        ],
        "fitting_reservations": {"first": 60, "second": 25, "balance": 100, "available": str(available_after_fit)},
        "negative_control": {
            "balance": 100,
            "first": 60,
            "second": 50,
            "rejected": rejected,
            "unchanged": before == after,
            "available_after_reject": str(after[2]),
        },
        "double_use_rejected": rejected and before == after,
        "classification": "PROVEN_UNDER_ASSUMPTIONS" if discharged else "COUNTEREXAMPLE_FOUND",
        "counterexample": None if discharged else {"negation": negation, "negative_control_rejected": rejected, "unchanged": before == after},
        "canonical_math1": "FAIL",
        "runtime_seconds": round(elapsed, 6),
    }
