# ADR-P01: Phase-1 outcome tokens are two full ERC-20s

**Status:** PROPOSED  
**Date:** 2026-09-26

## Decision

Deploy one full ERC-20 per outcome from the market constructor. Do not use a beacon. Do not require ERC-1167 clones for Phase 1.

## Options

A. Two full ERC-20s. B. ERC-1167 clones. C. Upgradeable beacon.

## Evidence

`research/contract-kernels/src/prediction/OutcomeToken.sol` mints only from the market. Foundry tests reject a user mint.

On 2026-09-26 an assembly `gas()` meter around `CREATE` measured two full `OutcomeToken` deployments at 534243 gas each (runtime 2276 bytes). A storage-based twin plus two ERC-1167 clones measured 789955 gas for the pair: implementation 515299, each clone create 41064 (45-byte runtime), each initialize 96264. The pair delta is 278531 gas in favor of the clone shape.

A clone of `OutcomeToken` itself is 45 bytes and shares the implementation's immutable `market`, `outcomeIndex`, and `decimals`. Its `name` and `symbol` are empty because those OpenZeppelin fields are storage written in the implementation constructor. Two outcomes cannot be distinct clones of that bytecode. The storage twin's second `initialize` reverts, and mint and burn revert for any caller other than the recorded market. This repository has no OpenZeppelin `Clones.sol`; the bench uses a 55-byte creation prefix.

## Benchmark

Schema A whole-test gas remains in `.gas-snapshot`. Schema B deployment gas is in `evidence/research/prediction/outcome-token-gas-2026-09-26.txt`. Schema C was not compiled.

## Security implications

A has no initializer and no upgrade. B adds initializer replay. C adds an upgrade key over financial claims.

## Tradeoffs

A duplicates bytecode. B is cheaper after the implementation exists: one more clone costs 137328 gas against 534243 for another full token. B still cannot give two immutable outcome identities from one `OutcomeToken` implementation.

## Recommendation

Keep A in the research kernel. The measured savings do not outweigh shared immutables and an initializer on a financial claim. Revisit B only if a later ADR accepts a storage token whose initializer cannot be replayed and whose market and outcome index are set once.

## Confidence

Medium. The gas delta is measured. The security preference for immutable outcome identity is unchanged.

## What would falsify this

A measured deployment or audit shows A cannot be listed, or a clone implementation with a disabled initializer is both cheaper and free of replay.
