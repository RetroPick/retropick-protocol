# ADR-006 — `RESOLVED` and `REDEEMABLE` Are Separate States

**Status:** ACCEPTED  
**Date:** 2026-09-17

## Context

Knowing a deterministic final payout does not prove that the settlement asset required to pay every holder is currently available in the settlement domain.

Conflating final outcome knowledge with payment readiness can create an underfunded redemption state.

## Decision

`RESOLVED` means:
- all payoff-relevant sources are final;
- terminal state is fixed;
- final payout `R=h(omega*)` is immutable.

`REDEEMABLE` additionally requires:

```math
SettlementBalance \ge OutstandingSupply \times R
```

within the accepted precision policy.

Transition:

```text
RESOLUTION_PENDING
-> RESOLVED
-> transform/redeem backing into settlement asset
-> verify funding invariant
-> REDEEMABLE
```

## Consequences

- final redemption cannot rely on unfunded accounting promises;
- settlement delays become explicit product state;
- UI/indexer must distinguish result finality from payout readiness;
- final redemption proof becomes inductive: burning/paying `Q` preserves funding for remaining supply.
