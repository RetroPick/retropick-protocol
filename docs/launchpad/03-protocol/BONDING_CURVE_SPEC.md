# Bonding Curve Specification

**Status:** DRAFT CANONICAL  
**Owner:** Protocol + Smart Contracts

## Model

The P0 primary market uses a deterministic constant-product-style curve with explicit real reserves and any configured virtual/phantom reserve used by pricing.

## Required definitions

- token reserve
- real quote reserve
- virtual/phantom quote reserve
- invariant input reserves
- fee ordering
- executable buy/sell quote
- actual transferred amounts
- graduation progress/threshold

## Buy

A buy receives quote asset, separates explicit fees according to the fee model, updates real accounting, computes token output with the accepted rounding direction and enforces user minimum output.

## Sell

A sell receives tokens, computes quote output under the same invariant, applies defined fees, verifies real quote solvency and enforces user minimum output.

## Edge cases

Zero input, reserve exhaustion, near-terminal inventory, threshold-crossing trades, decimals, maximum fee combination and post-graduation calls must have defined behavior.

## Acceptance

Every equation/function relation is owned by BONDING_CURVE_MATH and mapped to unit, fuzz and invariant tests.
