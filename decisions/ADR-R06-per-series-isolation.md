# ADR-R06: Prefer per-market and per-series isolation

**Status:** PROPOSED  
**Date:** 2026-09-26

## Decision

Keep prediction collateral inside each market and PRISM backing inside series-scoped accounting. Do not use one global vault as the default.

## Options

Global vault. Per-market and per-series isolation.

## Evidence

Monad's optimistic parallel execution is a reason to avoid unrelated series sharing one hot contract. This program did not measure Monad conflict rates. The sentence is an architectural hypothesis, not a benchmark. The existing reservation ledger already exists to stop two series from using one unit of a shared balance. Isolation makes that ledger unnecessary for assets that are not shared.

## Benchmark

No Monad trace was collected. BLOCKED for a performance claim. Do not describe Monad as fast from this ADR.

## Security implications

A global vault is a shared reentrancy and insolvency domain. Isolation limits a bug to one series. It complicates a user who backs many series with one inventory.

## Tradeoffs

More contracts. Clearer invariants.

## Recommendation

Default to isolation unless a measured conflict study says a shared vault is required.

## Confidence

Low on Monad performance. Medium on the security locality argument.

## What would falsify this

A measured Monad schedule where per-series contracts conflict more than a sharded global design, plus a reservation proof that matches today's ledger.
