# ADR-P02: Outcome decimals match the approved collateral

**Status:** PROPOSED  
**Date:** 2026-09-26

## Decision

Phase 1 approves one standard ERC-20 collateral. Outcome tokens use that token's decimals. Do not normalize prediction payouts through a second 18-decimal unit.

## Options

Match collateral decimals. Or always use 18 and convert at the vault.

## Evidence

`compare_scales(48)` found 0 mismatches for scales 1e6, 1e12, and 1e18 against collateral-native half-floor. Winner payout is a 1:1 integer identity only when units match.

## Benchmark

The scale grid is a rounding check, not a gas benchmark.

## Security implications

A second rounding boundary is a place to pay zero or to mis-count dust. One unit system removes it for YES_WIN and NO_WIN.

## Tradeoffs

Wallets that assume 18 decimals will display 6-decimal collateral correctly only if they read `decimals()`.

## Recommendation

Copy `decimals()` in the market constructor. The kernel does this.

## Confidence

Medium. The grid is bounded. Kuru has not been shown to reject non-18 ERC-20s; its router documents token-specific decimals.

## What would falsify this

A qualified venue rejects the collateral's decimals, and a specified conversion is proven not to change YES_WIN payouts or INVALID dust bounds.
