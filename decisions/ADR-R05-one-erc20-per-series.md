# ADR-R05: One ERC-20 per PRISM series is the candidate shape

**Status:** PROPOSED  
**Date:** 2026-09-26

## Decision

Prefer one transferable ERC-20 per series over a multi-token plus wrapper, because Kuru's documented path lists ERC-20s. Do not treat this as measured.

## Options

One ERC-20. A shared multi-token with an ERC-20 wrapper for Kuru.

## Evidence

Kuru router docs retrieved 2026-09-26 describe ERC-20 markets. No wrapper and no series token were compiled here, so there is no bytecode or gas comparison.

## Benchmark

Not run. Classification: NOT_YET_VALIDATED.

## Security implications

The ERC-20 is a liability container. Value is the backing vault, not the token bytecode. A wrapper adds an extra mint authority.

## Tradeoffs

One deployment per series costs more gas than an ERC-1155 id and was not priced.

## Recommendation

Keep the candidate. Do not implement it while MATH-1D is FAIL.

## Confidence

Low. The recommendation is composability, not a measurement.

## What would falsify this

A measured wrapper that is cheaper and has no additional mint path, or a Kuru interface that lists ERC-1155 directly and is accepted for RetroPick.
