---
id: LP-CODE-ACCOUNTING
type: generated_current_state
product: launchpad
version: v2
status: active
source: contracts/src/v2
---

# Current Accounting Reference

## Curve

Primary curve distinguishes:
- token reserve;
- real quote reserve;
- effective pricing reserve including phantom quote where configured;
- accrued fee/buyback/creator allocations per implementation.

`RetroPickBondingCurveMathV2` implements constant-product exact-input/output quote arithmetic with basis-point fees and integer rounding.

## Quote assets

Factory stores per-approved-token phantomQuote, graduationThreshold and decimals. Approval validates token/economic compatibility.

## Graduation

Current flow is two-phase:
1. factory/curve secures and records swept reserves;
2. `createGraduatedPool` invokes V4-specific executor/guard and marks pool graduated only on successful destination setup.

The two-phase/retry property is a target safety invariant even though the destination venue will change.

## Separation

Fee balances are not graduation reserves. Buyback/creator/protocol allocations remain separate accounting domains.
