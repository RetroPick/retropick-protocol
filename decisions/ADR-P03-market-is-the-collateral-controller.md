# ADR-P03: The prediction market contract is the collateral controller

**Status:** PROPOSED  
**Date:** 2026-09-26

## Decision

Colocate collateral custody, mint authority, and lifecycle in `PredictionMarket`. Do not deploy a second vault contract in the research kernel.

## Options

A. Separate CompleteSetVault, as drawn in `docs/prism/protocol/PRISM_PROTOCOL_SPEC.md`. B. Market is the controller.

## Evidence

The kernel implements B. Invariants P-I02 and P-I08 are local to one contract. No accepted ADR required a second contract. The canonical diagram still names CompleteSetVault. This ADR does not edit that diagram into acceptance.

## Benchmark

A second contract's call gas was not measured. The expected extra cost is at least one external call per split, merge, and redeem. That sentence is an inference, not a measurement.

## Security implications

B has one reentrancy surface and one balance. A adds a cross-contract trust edge. B does not isolate a token upgrade, and Phase 1 does not want that upgrade.

## Tradeoffs

Indexers read one market for balances and state. A future upgrade of custody would require a new market, which is the point.

## Recommendation

Keep B in the research harness until this ADR is accepted or rejected. Do not delete the canonical diagram in the meantime.

## Confidence

Medium.

## What would falsify this

An accepted security review shows a second contract is required to keep PRISM redemption safe, with a measured invariant that B cannot express.
