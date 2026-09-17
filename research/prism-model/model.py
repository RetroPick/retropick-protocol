"""Exact PRISM series accounting reference model."""
from __future__ import annotations

from dataclasses import dataclass, field
from fractions import Fraction
from typing import Sequence

from lifecycle import SeriesState, transition
from replication import F, payoff, normalize_matrix
from settlement import settlement_is_funded


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
    transformed_settlement: Fraction = Fraction(0)
    resolved_components: dict[int, Fraction] = field(default_factory=dict)
    possible_states: set[int] = field(default_factory=set)

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
        self.transformed_settlement = F(self.transformed_settlement)
        self.settlement_balance = F(self.settlement_balance)
        self.resolved_components = {int(i): F(v) for i, v in self.resolved_components.items()}
        if not self.possible_states:
            self.possible_states = set(range(len(self.payoff_matrix)))
        else:
            self.possible_states = set(self.possible_states)
        if not self.possible_states:
            raise ModelError("series must have at least one possible terminal state")

    @property
    def terminal_payoff_vector(self):
        return payoff(self.payoff_matrix, self.weights)

    def activate(self):
        self.state = transition(self.state, SeriesState.ACTIVE)

    def required_backing(self, supply=None):
        s = self.supply if supply is None else F(supply)
        return tuple(
            Fraction(0) if i in self.resolved_components else s * w
            for i, w in enumerate(self.weights)
        )

    def required_transformed_settlement(self, supply=None):
        s = self.supply if supply is None else F(supply)
        return s * sum(
            (self.weights[i] * payout for i, payout in self.resolved_components.items()),
            Fraction(0),
        )

    def backing_margin(self):
        req = self.required_backing()
        return tuple(self.backing[i] - req[i] for i in range(len(req)))

    def transformed_margin(self):
        return self.transformed_settlement - self.required_transformed_settlement()

    def assert_component_backed(self):
        req = self.required_backing()
        if any(self.backing[i] < req[i] for i in range(len(req))):
            raise ModelError("component backing invariant violated")
        if self.transformed_settlement < self.required_transformed_settlement():
            raise ModelError("transformed settlement backing invariant violated")
        return True

    def deposit_backing(self, amounts: Sequence):
        vals = [F(v) for v in amounts]
        if len(vals) != len(self.backing) or any(v < 0 for v in vals):
            raise ModelError("invalid backing deposit")
        for i, v in enumerate(vals):
            if i in self.resolved_components and v:
                raise ModelError("cannot deposit resolved component backing")
            self.backing[i] += v

    def mint(self, quantity):
        q = F(quantity)
        if self.state != SeriesState.ACTIVE:
            raise ModelError("mint only allowed in ACTIVE")
        if self.resolved_components:
            raise ModelError("mint disabled after partial component resolution")
        if q <= 0:
            raise ModelError("mint quantity must be positive")
        new_supply = self.supply + q
        required = tuple(new_supply * w for w in self.weights)
        if any(self.backing[i] < required[i] for i in range(len(required))):
            raise ModelError("insufficient backing for mint")
        self.supply = new_supply
        self.assert_component_backed()

    def mint_with_exact_backing(self, quantity):
        q = F(quantity)
        if self.resolved_components:
            raise ModelError("mint disabled after partial component resolution")
        self.deposit_backing([q * w for w in self.weights])
        self.mint(q)

    def redeem_in_kind(self, quantity):
        if self.resolved_components:
            raise ModelError("use redeem_in_kind_mixed after partial resolution")
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

    def redeem_in_kind_mixed(self, quantity):
        q = F(quantity)
        if self.state not in {SeriesState.MINT_PAUSED, SeriesState.RESOLUTION_PENDING}:
            raise ModelError("mixed redemption requires MINT_PAUSED or RESOLUTION_PENDING")
        if not self.resolved_components:
            raise ModelError("no transformed components; use redeem_in_kind")
        if q <= 0 or q > self.supply:
            raise ModelError("invalid redemption quantity")

        released_components = [
            Fraction(0) if i in self.resolved_components else q * w
            for i, w in enumerate(self.weights)
        ]
        cash = q * sum(
            (self.weights[i] * payout for i, payout in self.resolved_components.items()),
            Fraction(0),
        )

        self.supply -= q
        for i, amount in enumerate(released_components):
            if amount:
                if self.backing[i] < amount:
                    raise ModelError("insufficient unresolved component backing")
                self.backing[i] -= amount
        if self.transformed_settlement < cash:
            raise ModelError("insufficient transformed settlement backing")
        self.transformed_settlement -= cash
        self.assert_component_backed()
        return {"components": tuple(released_components), "settlement": cash}

    def resolve_component(self, component_index: int, payout):
        i = int(component_index)
        r = F(payout)
        if i < 0 or i >= len(self.weights):
            raise ModelError("invalid component index")
        if r < 0:
            raise ModelError("negative resolved payout")
        if i in self.resolved_components:
            raise ModelError("component already resolved")
        if self.state not in {
            SeriesState.ACTIVE,
            SeriesState.MINT_PAUSED,
            SeriesState.RESOLUTION_PENDING,
        }:
            raise ModelError("component resolution not allowed in current state")

        consistent = {
            state_idx
            for state_idx in self.possible_states
            if self.payoff_matrix[state_idx][i] == r
        }
        if not consistent:
            raise ModelError("component payout inconsistent with remaining terminal states")

        if self.state == SeriesState.ACTIVE:
            self.state = transition(self.state, SeriesState.MINT_PAUSED)

        amount = self.backing[i]
        self.backing[i] = Fraction(0)
        self.transformed_settlement += amount * r
        self.resolved_components[i] = r
        self.possible_states = consistent
        self.assert_component_backed()
        return amount * r

    def terminal_solvency(self):
        h = self.terminal_payoff_vector
        results = []
        for state_idx in sorted(self.possible_states):
            row = self.payoff_matrix[state_idx]
            backing_value = self.transformed_settlement + sum(
                self.backing[i] * row[i]
                for i in range(len(self.backing))
                if i not in self.resolved_components
            )
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
        if terminal_state_index not in self.possible_states:
            raise ModelError("terminal state inconsistent with resolved components")
        self.final_payout = h[terminal_state_index]
        self.state = transition(self.state, SeriesState.RESOLVED)

    def fund_settlement(self, amount):
        if self.state != SeriesState.RESOLVED:
            raise ModelError("settlement can be funded only after resolution in Phase 1")
        a = F(amount)
        if a < 0:
            raise ModelError("negative settlement funding")
        self.settlement_balance += a

    def fund_settlement_from_transformed(self, amount=None):
        if self.state != SeriesState.RESOLVED:
            raise ModelError("series must be RESOLVED")
        a = self.transformed_settlement if amount is None else F(amount)
        if a < 0 or a > self.transformed_settlement:
            raise ModelError("invalid transformed settlement transfer")
        self.transformed_settlement -= a
        self.settlement_balance += a
        return a

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
