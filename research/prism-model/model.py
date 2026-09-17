"""Exact PRISM series accounting reference model."""
from __future__ import annotations

from dataclasses import dataclass, field
from fractions import Fraction
from typing import Sequence

from lifecycle import SeriesState, transition
from replication import F, payoff, normalize_matrix
from settlement import settlement_is_funded, terminal_backing_value


class ModelError(ValueError):
    pass


@dataclass
class PrismSeries:
    payoff_matrix: Sequence[Sequence]
    weights: Sequence
    state: SeriesState = SeriesState.DRAFT
    supply: Fraction = Fraction(0)
    backing: list[Fraction] = field(default_factory=list)
    final_payout: Fraction | None = None
    settlement_balance: Fraction = Fraction(0)

    def __post_init__(self):
        self.payoff_matrix = normalize_matrix(self.payoff_matrix)
        self.weights = tuple(F(v) for v in self.weights)
        if len(self.weights) != len(self.payoff_matrix[0]):
            raise ModelError("weight dimension mismatch")
        if any(w < 0 for w in self.weights):
            raise ModelError("negative weight unsupported")
        if not self.backing:
            self.backing = [Fraction(0) for _ in self.weights]
        else:
            self.backing = [F(v) for v in self.backing]
        if len(self.backing) != len(self.weights):
            raise ModelError("backing dimension mismatch")

    @property
    def terminal_payoff_vector(self):
        return payoff(self.payoff_matrix, self.weights)

    def activate(self):
        self.state = transition(self.state, SeriesState.ACTIVE)

    def required_backing(self, supply=None):
        s = self.supply if supply is None else F(supply)
        return tuple(s * w for w in self.weights)

    def backing_margin(self):
        req = self.required_backing()
        return tuple(self.backing[i] - req[i] for i in range(len(req)))

    def assert_component_backed(self):
        req = self.required_backing()
        if any(self.backing[i] < req[i] for i in range(len(req))):
            raise ModelError("component backing invariant violated")
        return True

    def deposit_backing(self, amounts: Sequence):
        vals = [F(v) for v in amounts]
        if len(vals) != len(self.backing) or any(v < 0 for v in vals):
            raise ModelError("invalid backing deposit")
        for i, v in enumerate(vals):
            self.backing[i] += v

    def mint(self, quantity):
        q = F(quantity)
        if self.state != SeriesState.ACTIVE:
            raise ModelError("mint only allowed in ACTIVE")
        if q <= 0:
            raise ModelError("mint quantity must be positive")
        new_supply = self.supply + q
        required = self.required_backing(new_supply)
        if any(self.backing[i] < required[i] for i in range(len(required))):
            raise ModelError("insufficient backing for mint")
        self.supply = new_supply
        self.assert_component_backed()

    def mint_with_exact_backing(self, quantity):
        q = F(quantity)
        self.deposit_backing([q * w for w in self.weights])
        self.mint(q)

    def redeem_in_kind(self, quantity):
        q = F(quantity)
        if self.state not in {SeriesState.ACTIVE, SeriesState.MINT_PAUSED}:
            raise ModelError("in-kind redemption not allowed in current state")
        if q <= 0 or q > self.supply:
            raise ModelError("invalid redemption quantity")
        released = [q * w for w in self.weights]
        self.supply -= q
        for i, amount in enumerate(released):
            if self.backing[i] < amount:
                raise ModelError("insufficient backing")
            self.backing[i] -= amount
        self.assert_component_backed()
        return tuple(released)

    def terminal_solvency(self):
        h = self.terminal_payoff_vector
        results = []
        for state_idx, row in enumerate(self.payoff_matrix):
            backing_value = terminal_backing_value(self.backing, row)
            liability = self.supply * h[state_idx]
            results.append((state_idx, backing_value, liability, backing_value >= liability))
        return tuple(results)

    def start_resolution(self):
        if self.state == SeriesState.ACTIVE:
            self.state = transition(self.state, SeriesState.RESOLUTION_PENDING)
        elif self.state == SeriesState.MINT_PAUSED:
            self.state = transition(self.state, SeriesState.RESOLUTION_PENDING)
        else:
            raise ModelError("cannot start resolution from current state")

    def resolve(self, terminal_state_index: int):
        if self.state != SeriesState.RESOLUTION_PENDING:
            raise ModelError("series must be RESOLUTION_PENDING")
        h = self.terminal_payoff_vector
        if terminal_state_index < 0 or terminal_state_index >= len(h):
            raise ModelError("invalid terminal state")
        self.final_payout = h[terminal_state_index]
        self.state = transition(self.state, SeriesState.RESOLVED)

    def fund_settlement(self, amount):
        if self.state != SeriesState.RESOLVED:
            raise ModelError("settlement can be funded only after resolution in Phase 1")
        a = F(amount)
        if a < 0:
            raise ModelError("negative settlement funding")
        self.settlement_balance += a

    def make_redeemable(self):
        if self.state != SeriesState.RESOLVED or self.final_payout is None:
            raise ModelError("not resolved")
        if not settlement_is_funded(
            self.settlement_balance, self.supply, self.final_payout
        ):
            raise ModelError("settlement underfunded")
        self.state = transition(self.state, SeriesState.REDEEMABLE)

    def redeem_final(self, quantity):
        q = F(quantity)
        if self.state != SeriesState.REDEEMABLE:
            raise ModelError("final redemption only in REDEEMABLE")
        if q <= 0 or q > self.supply:
            raise ModelError("invalid final redemption quantity")
        amount = q * self.final_payout
        if self.settlement_balance < amount:
            raise ModelError("settlement insolvency")
        self.supply -= q
        self.settlement_balance -= amount
        return amount

    def archive(self):
        if self.state != SeriesState.REDEEMABLE or self.supply != 0:
            raise ModelError("archive requires zero outstanding supply")
        self.state = transition(self.state, SeriesState.ARCHIVED)
