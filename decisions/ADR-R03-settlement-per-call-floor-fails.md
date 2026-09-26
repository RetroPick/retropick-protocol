# ADR-R03: Per-call settlement floor fails MATH-1D

**Status:** PROPOSED. It does not replace code.  
**Date:** 2026-09-26

## Decision

Mark the current `FixedPointSettlement.redeem` per-call floor as FAIL for MATH-1D. Propose, without implementing in the oracle, a cumulative floor whose total equals `floor(supply * payout / D)` and whose dust against ceil funding is 0 or 1.

## Options

Keep per-call floor. Switch to cumulative floor. Forbid fragmented redemption and redeem only full balances.

## Evidence

Supply 2, payout `10^18-1`, 18 decimals: required 2, one-shot floor 1, two 1-unit redemptions pay 0, sweepable dust 2. `FixedPointSettlement.redeem` still does that. A separate `CumulativeFloorSettlement` pays 1 on the same case and leaves residual 1. A per-holder cursor pays 0 and is not the candidate.

The candidate bound is PROVEN_UNDER_ASSUMPTIONS: any partition sums to `floor(supply * payout / D)`, and exact ceil funding leaves a residual of 0 or 1. The Python search is EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN: 378530 states, 2542061 transitions, 2.973316 seconds, no new counterexample. Evidence: `evidence/research/prism/cumulative-floor-attack-2026-09-26.json`.

## Benchmark

The counterexample is a single exact state, not a timing benchmark.

## Security implications

A dust sweep after fragmented redemptions captures holder value. The funding guard still holds, so this is not an under-collateralized mint. It is still an accounting failure under the release-blocking rounding rule.

## Tradeoffs

Changing the oracle without an accepted ADR would hide the counterexample. Leaving the bug in a Solidity port would ship it.

## Recommendation

The cumulative candidate is ready for acceptance or rejection. Accepting it would not, by itself, authorize settlement Solidity. Canonical MATH-1 stays FAIL until a human accepts the repair.

## Confidence

High for the measured counterexample.

## What would falsify this

A proof that every holder can redeem their exact floor share in one call and that partial balances cannot arise, plus removal of sweep-to-treasury. Fragmented secondary transfers make that assumption false for transferable ERC-20s.
