# ADR-P01: Phase-1 outcome tokens are two full ERC-20s

**Status:** PROPOSED  
**Date:** 2026-09-26

## Decision

Deploy one full ERC-20 per outcome from the market constructor. Do not use a beacon. Do not require ERC-1167 clones for Phase 1.

## Options

A. Two full ERC-20s. B. ERC-1167 clones. C. Upgradeable beacon.

## Evidence

`research/contract-kernels/src/prediction/OutcomeToken.sol` mints only from the market. Foundry tests reject a user mint.

## Benchmark

Schema A test-function gas is in `.gas-snapshot`. Schema B and C bytecode and gas were not measured.

## Security implications

A has no initializer and no upgrade. B adds initializer replay. C adds an upgrade key over financial claims.

## Tradeoffs

A duplicates bytecode. B would be smaller to deploy and was not shown to be necessary.

## Recommendation

Adopt A for the research kernel. Revisit B only with a measured gas delta and a re-initialization test.

## Confidence

Medium on the security preference. Low on gas, because B was not compiled.

## What would falsify this

A measured deployment or audit shows A cannot be listed, or a clone implementation with a disabled initializer is both cheaper and free of replay.
