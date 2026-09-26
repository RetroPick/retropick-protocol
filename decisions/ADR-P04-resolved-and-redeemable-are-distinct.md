# ADR-P04: Prediction RESOLVED and REDEEMABLE stay distinct

**Status:** PROPOSED  
**Date:** 2026-09-26

## Decision

Use the canonical names DRAFT, OPEN, LOCKED, RESOLUTION_PENDING, RESOLVED, REDEEMABLE, ARCHIVED. OPEN is the alias of ACTIVE. LOCKED is the alias of MINT_CLOSED. Redeem only in REDEEMABLE.

## Options

Collapse RESOLVED into REDEEMABLE, as `native_market.py` does. Or keep ADR-006's distinction for the prediction market too.

## Evidence

ADR-006 is accepted for PRISM funding. The prediction kernel's `redeemYes` reverts in RESOLVED. `openRedemption` checks liability first.

## Benchmark

None. This is a state-machine choice.

## Security implications

A resolver cannot move funds by resolving. Opening redemption does not pay anyone; it only enables holder redemption when the locked collateral covers liability.

## Tradeoffs

One extra transaction, or a permissionless call, before the first redemption.

## Recommendation

Keep the split. Do not treat `native_market.py` as the lifecycle oracle.

## Confidence

High relative to ADR-006. The alias names are documentation, not a second machine.

## What would falsify this

A proof that fully collateralized YES/NO redemption can never need a funding check distinct from the result, including INVALID dust and donated collateral. Even then the extra state is conservative.
