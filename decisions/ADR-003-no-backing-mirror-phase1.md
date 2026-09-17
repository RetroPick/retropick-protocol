# ADR-003 — No BackingMirror for Monad-Native Phase-1 Backing

**Status:** ACCEPTED  
**Date:** 2026-09-17

## Context

The historical architecture report included a flow where Monad-native PRISM backing was locked in `BackingVault`, summarized offchain, written back to Monad through `BackingMirror`, and then consumed by `MintController`.

The same report also established that Metropolis Phase 1 uses Monad-native RetroPick outcome ERC-20s as backing and removes the external Polygon/Polymarket dependency.

For same-chain assets, the vault/accounting state is already authoritative on Monad.

## Decision

Phase-1 PRISM minting reads authoritative same-chain backing directly from `PrismBackingVault` / series-scoped accounting.

Do not introduce `BackingMirror`, Merkle backing roots, or CRE backing attestations into the Phase-1 mint path.

## Consequences

Positive:
- removes asynchronous stale-state risk;
- removes redundant trust/oracle dependency;
- smaller audit surface;
- simpler atomic backing/mint transition;
- clearer source of truth.

Tradeoff:
- this design does not solve cross-chain custody.

## Future

A future external-outcome adapter may introduce authenticated external custody/bridge state under a new ADR and explicit wrapper solvency model.

Attestation alone must never be treated as backing.
