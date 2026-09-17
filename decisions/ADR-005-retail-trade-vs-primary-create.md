# ADR-005 — Separate Retail PRISM Trading from Primary Creation

**Status:** ACCEPTED  
**Date:** 2026-09-17

## Context

The historical report described `BUY 1000 pFEDBTC` as a workflow that acquires every underlying leg, locks them, and mints PRISM.

That is economically a primary creation flow, similar to an ETF authorized-participant creation. It is not the correct default retail trading experience once a PRISM/quote market exists.

## Decision

Expose two separate actions.

### Retail trade

```text
User -> Kuru PRISM/quote orderbook -> existing PRISM changes owner
```

This does not change protocol backing or supply.

### Primary create/redeem

```text
Issuer / AP / market maker / arbitrageur
-> provide exact basket
-> lock backing
-> mint new PRISM
```

and inverse in-kind redemption.

## Consequences

- consumer UX stays simple;
- creation/redemption still anchors economic value when executable;
- advanced users/market makers can access primary issuance;
- backend/API contracts must not name a primary creation request as an ordinary BUY.

Recommended API/product distinction:
- `trade` for exchange execution;
- `create` for new PRISM supply;
- `redeemInKind` for primary contraction.
