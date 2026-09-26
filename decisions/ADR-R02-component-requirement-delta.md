# ADR-R02: Component mint and redeem keep the requirement delta

**Status:** PROPOSED confirmation of the existing integer oracle.  
**Date:** 2026-09-26

## Decision

Keep backing requirements rounded up, and release the decrease in that requirement on redeem. Do not switch component redemption to a naive per-call floor.

## Options

Per-call floor. Requirement delta. Exact rationals on-chain.

## Evidence

`FixedPointSeries.mint_with_minimum_backing` followed by `redeem` returned equal vectors in 200 samples, seed 20260926. Equality is also the definition of the delta.

## Benchmark

No Solidity gas. The Python samples are the measurement.

## Security implications

The delta cannot pay out more than was reserved for the supply change. A per-call floor can, under fragmentation, pay less and leave dust.

## Tradeoffs

Users can receive one raw unit less than the exact rational on the way in, and they get that conservatism back only through the same delta on the way out.

## Recommendation

Keep the current component functions. They are not the failing settlement rule.

## Confidence

High for the round trip. Medium as a gas-feasible Solidity translation, which was not built.

## What would falsify this

A sample where the released vector exceeds the deposited minimum, or a proof that ceil introduces extractable value across two different series sharing one balance. The reservation ledger is the separate control for that second risk.
