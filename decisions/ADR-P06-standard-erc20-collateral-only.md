# ADR-P06: Phase-1 collateral is one standard ERC-20

**Status:** PROPOSED  
**Date:** 2026-09-26

## Decision

Admit only a non-rebasing, non-fee ERC-20 that returns true and has no transfer callback the protocol must honor. The market credits a split only when its balance increases by the full amount.

## Options

Accept arbitrary ERC-20s. Or allow one approved token and revert on a shortfall.

## Evidence

The reference model rejects fee-on-transfer, rebasing, ERC-777, and false-return classes at construction. The kernel test `test_fee_on_transfer_split_reverts` expects `Shortfall` and unchanged supply.

## Benchmark

Not a gas study.

## Security implications

Naive credit of the nominal amount is insolvent when the received amount is smaller. A rebasing decrease breaks the liability check after the fact.

## Tradeoffs

The product cannot list exotic collateral in Phase 1.

## Recommendation

Keep the restriction until a token is separately proven.

## Confidence

High for the shortfall counterexample.

## What would falsify this

A specification and differential test for a named exotic token that preserves P-I08 under its actual transfer semantics.
