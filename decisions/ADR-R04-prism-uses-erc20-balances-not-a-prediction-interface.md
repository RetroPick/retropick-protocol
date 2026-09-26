# ADR-R04: PRISM consumes ERC-20 balances, not a prediction interface

**Status:** PROPOSED  
**Date:** 2026-09-26

## Decision

Do not require source assets to implement RetroPick methods. A registry may record which ERC-20s are allowed backing. PRISM does not call `market()` or `outcomeIndex()`.

## Options

Force `IOutcomeToken` on every component. Or accept any registry-listed ERC-20.

## Evidence

PRED-CONTRACT-ARCH-1 is only proposed, so a prediction interface is not frozen. The user program forbids PRISM Solidity from assuming that interface before the freeze. No PRISM contract was written in this program.

## Benchmark

None.

## Security implications

A registry is an admin-like admission surface. It must not be able to mark an already-active series' components as unbacked. Admission freezes the component list.

## Tradeoffs

PRISM cannot ask a token for its payout vector on-chain unless a later adapter is specified. Phase-1 payouts are stored on the series from admission data.

## Recommendation

Keep the boundary. Prediction tokens are usable as backing only because they are ERC-20s, after their own economics are qualified.

## Confidence

Medium. The cross-module harness was not built because PRISM settlement failed.

## What would falsify this

A required on-chain payout read that cannot be represented by frozen admission data, with an interface that PRED-CONTRACT-ARCH-1 has actually frozen.
