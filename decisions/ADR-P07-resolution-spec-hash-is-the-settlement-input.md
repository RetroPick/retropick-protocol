# ADR-P07: The resolution spec hash is the settlement input

**Status:** PROPOSED  
**Date:** 2026-09-26

## Decision

Freeze `resolutionSpecHash`, collateral id, and resolver at activation. Settlement reads the resolver's result enum. It does not read a URL, an HTTP response, or mutable UI copy.

## Options

Put the full criteria text on-chain. Or commit a hash and a resolver address.

## Evidence

`ResolutionSpec` in the reference model rejects empty fields and is not replaceable after activation. The kernel stores `bytes32 resolutionSpecHash` with no setter.

## Benchmark

None.

## Security implications

A hash does not make the resolver honest. It makes silent edits detectable. Calling an API from the contract would move trust to that API and to whoever can answer it.

## Tradeoffs

Users must be able to retrieve the preimage of the hash from a content system. That system is not economic authority.

## Recommendation

Keep the hash on the market. Keep criteria off the settlement path.

## Confidence

High that UI text must not settle. Medium on whether Phase 1's resolver should be a contract rather than an EOA. This ADR does not choose the oracle.

## What would falsify this

A requirement that two honest readers of the on-chain text can disagree about the result while sharing the same hash, and that disagreement is not already the resolver's job.
