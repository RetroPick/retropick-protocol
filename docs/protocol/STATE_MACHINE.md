# PRISM Series State Machine

```text
DRAFT
  |
  v
ACTIVE
  | \
  |  \ emergency/admin policy may pause new minting without confiscating backing
  v
MINT_PAUSED
  |
  v
RESOLUTION_PENDING
  |
  v
RESOLVED
  |
  | settlement funding gate
  v
REDEEMABLE
  |
  | supply == 0
  v
ARCHIVED
```

## DRAFT

Allowed:
- define components;
- validate replication;
- set immutable resolution references;
- cancel before activation.

Forbidden:
- mint user PRISM;
- final redemption.

## ACTIVE

Allowed:
- backing deposit;
- mint after backing;
- transfer;
- pre-resolution in-kind redeem.

Forbidden:
- mutate replication vector;
- release reserved backing without proportional burn.

## MINT_PAUSED

Allowed:
- transfer;
- in-kind redeem where safe;
- proceed toward resolution.

Forbidden:
- new mint.

## RESOLUTION_PENDING

Event window has closed or required source finality is pending.

Allowed:
- source/result processing according to immutable resolution rules;
- transfers unless explicitly disabled by a future accepted policy;
- safe redemption path if the protocol can still release unresolved backing.

Forbidden:
- new mint;
- changing resolution semantics.

## RESOLVED

Final payout is known.

Allowed:
- settlement funding;
- transfers.

Forbidden:
- mint;
- mutate outcome.

## REDEEMABLE

Allowed:
- burn for deterministic final settlement.

Invariant:
`settlementBalance >= supply * finalPayout`.

## ARCHIVED

Reached when outstanding supply is zero and no unresolved liability remains.

No transition may return to an earlier economic state.
