# PRISM Contract Test Plan

**Status:** TARGET VALIDATION PLAN

## Required layers

- unit tests for creation, split/merge, mint/burn, resolution and settlement;
- fuzz tests for quantities, decimals, weights and rounding boundaries;
- stateful invariants for complete-set conservation and PRISM backing;
- cross-series reservation tests preventing double allocation;
- partial-resolution transformation tests;
- final-settlement funding/redemption tests;
- authorization/reentrancy/malicious-token tests;
- differential fixtures against `research/prism-model/`;
- maximum-value/overflow boundary tests.

## Hard failures

Any sequence that produces unbacked supply, over-redemption, double-pledged backing, mutable final resolution, underfunded redeemability or repeatable positive-value rounding extraction blocks implementation qualification.
