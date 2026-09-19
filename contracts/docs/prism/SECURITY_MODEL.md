# PRISM Contract Security Model

**Status:** TARGET SECURITY SPECIFICATION

## Protected assets

- native prediction collateral;
- PRISM component backing;
- settlement funding;
- user outcome/PRISM supply integrity.

## Principal threats

- unbacked mint;
- backing withdrawal while liabilities exist;
- double allocation across series;
- rounding extraction;
- malicious/non-standard component ERC-20s;
- reentrancy during backing/redemption/settlement;
- duplicate or mutable resolution;
- underfunded `REDEEMABLE` transition;
- privilege abuse;
- lifecycle rollback;
- integration state treated as financial authority.

## Security rule

Kuru liquidity, market prices, indexer state, RPC output caches and offchain attestations cannot substitute for actual backing/collateral accounting.

Release qualification requires the canonical PRISM MATH-1/CONTRACT-ARCH-1 gates plus Foundry unit/fuzz/invariant/differential tests and static/manual security review.
