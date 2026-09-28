# Cross-module P0 specification

Status: FROZEN_SCOPE_DRAFT

Prediction P0 and PRISM P0 do not pass independently unless their combined
solvency path is also demonstrated.

## End-to-end path

The required harness is:

1. Deploy fixed qualified collateral.
2. Deploy Prediction P0 market.
3. Split collateral into YES and NO.
4. Create exact PRISM P0 series from qualified outcome tokens.
5. Mint PRISM from outcome tokens.
6. Transfer PRISM.
7. Redeem PRISM in kind.
8. Receive outcome tokens.
9. Resolve Prediction to YES_WIN.
10. Redeem winning YES for collateral.
11. Repeat the same path for NO_WIN.

## Required properties

- Prediction collateral liability remains distinct from PRISM backing.
- PRISM physically holds source outcome tokens while PRISM supply exists.
- No source unit backs two PRISM liabilities.
- Wrong or unqualified outcome tokens are rejected.
- Source identity binds market, outcome, collateral, decimals, and P0 semantic
  version.
- Solvency and redemption do not depend on Kuru, indexer, frontend, or market
  price.

`H-X-P0` cannot pass until both YES and NO worlds have executable evidence.
