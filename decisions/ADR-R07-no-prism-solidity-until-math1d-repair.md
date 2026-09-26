# ADR-R07: No PRISM settlement Solidity while MATH-1D is FAIL

**Status:** PROPOSED operational stop. Consistent with accepted ADR-001 and ADR-007.  
**Date:** 2026-09-26

## Decision

Do not add PRISM mint, redeem, or settlement contracts to `contracts/src/v2` or to the research kernel until a settlement rounding rule is accepted that has no repeatable holder-to-dust extraction.

## Options

Ship the current per-call floor. Ship the unaccepted cumulative repair. Ship nothing.

## Evidence

`CX-FP-SETTLEMENT-001` in `research/prism/reports/PRISM_REPRODUCTION_REPORT.md`. Component requirement-delta was not the failing rule, and it is still not production Solidity.

## Benchmark

Not applicable.

## Security implications

Shipping the counterexample would let fragmented redemptions zero out holders and leave the balance sweepable.

## Tradeoffs

The hackathon cannot demo on-chain PRISM settlement from this branch.

## Recommendation

Stop. Record the repair as a proposal only.

## Confidence

High.

## What would falsify this

An accepted replacement rule with a differential test against a fixed oracle, plus a human acceptance of that ADR. This program does not grant that acceptance.
