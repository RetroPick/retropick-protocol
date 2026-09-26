# ADR-R03: Per-call settlement floor fails MATH-1D

**Status:** PROPOSED. It does not replace code.  
**Date:** 2026-09-26

## Decision

Mark the current `FixedPointSettlement.redeem` per-call floor as FAIL for MATH-1D. Propose, without implementing in the oracle, a cumulative floor whose total equals `floor(supply * payout / D)` and whose dust against ceil funding is 0 or 1.

## Options

Keep per-call floor. Switch to cumulative floor. Forbid fragmented redemption and redeem only full balances.

## Evidence

Supply 2, payout `10^18-1`, 18 decimals: required 2, one-shot floor 1, two 1-unit redemptions pay 0, sweepable dust 2. Grid of 240 cumulative-floor cases: worst dust 1, paid equals one-shot.

## Benchmark

The counterexample is a single exact state, not a timing benchmark.

## Security implications

A dust sweep after fragmented redemptions captures holder value. The funding guard still holds, so this is not an under-collateralized mint. It is still an accounting failure under the release-blocking rounding rule.

## Tradeoffs

Changing the oracle without an accepted ADR would hide the counterexample. Leaving the bug in a Solidity port would ship it.

## Recommendation

Do not port settlement to Solidity. Accept or reject the cumulative repair in a later decision. Until then MATH-1 stays FAIL.

## Confidence

High for the measured counterexample.

## What would falsify this

A proof that every holder can redeem their exact floor share in one call and that partial balances cannot arise, plus removal of sweep-to-treasury. Fragmented secondary transfers make that assumption false for transferable ERC-20s.
