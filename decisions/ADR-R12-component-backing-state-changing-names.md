# ADR-R12: Component-backing state-changing names differ

**Status:** PROPOSED  
**Date:** 2026-09-26

Acceptance is not granted. This file does not authorize an edit to `CandidateComponentBacking.deposit`, `CandidateComponentBacking.mint`, `CandidateComponentBacking.redeem`, `FixedPointSeries.deposit_raw`, `FixedPointSeries.mint`, `FixedPointSeries.mint_with_minimum_backing`, `FixedPointSeries.redeem`, or `FixedPointSeries.sweep_dust`. Neither implementation may be edited to add or rename a state-changing function until this ADR is explicitly accepted.

ADR-R10 and ADR-R11 stay PROPOSED. They are different decisions. This file does not edit them.

## Decision

Propose that the measured name lists stay recorded and that neither side is edited until a human accepts one rule. The open decision is whether Phase-1 must add the one-sided names to the kernel, or the kernel stays at `deposit`, `mint`, and `redeem`. This proposal does not choose that winner and does not change code.

## Options

Leave both sides as measured. Python `FixedPointSeries` state-changing names are `deposit_raw`, `mint`, `mint_with_minimum_backing`, `redeem`, and `sweep_dust`. `CandidateComponentBacking` state-changing names are `deposit`, `mint`, and `redeem`.

Or, after acceptance, add `mint_with_minimum_backing` and `sweep_dust` to the kernel and align `deposit` with `deposit_raw`. This proposal does not choose that option.

Or, after acceptance, keep the kernel at `deposit`, `mint`, and `redeem`. This proposal does not choose that option.

## Evidence

`research/prism-model/fixed_point_model.py`.  
`research/contract-kernels/src/prism/CandidateComponentBacking.sol`.

Views and constructors are omitted. Python views omitted from the state-changing list are `required_backing_raw`, `assert_backed`, `minimum_incremental_backing`, `terminal_backing_value_normalized`, `terminal_solvency_binary`, and `sweepable_dust`. Solidity views omitted are `componentToken`, `weightWad`, `componentDecimals`, `requiredRaw`, `_requiredAt`, and `_assertBacked`.

Python `FixedPointSeries` state-changing names: `deposit_raw`, `mint`, `mint_with_minimum_backing`, `redeem`, `sweep_dust`.

Solidity `CandidateComponentBacking` state-changing names: `deposit`, `mint`, `redeem`.

Names on both sides: `mint`, `redeem`.

Names only on Python: `deposit_raw`, `mint_with_minimum_backing`, `sweep_dust`.

Name only on Solidity: `deposit`. The contract comment maps `deposit` to `FixedPointSeries.deposit_raw`. The strings differ. The contract does not declare `deposit_raw`. The contract does not declare `mint_with_minimum_backing`. The contract does not declare `sweep_dust`. No function was added.

This comparison is not CONTRACT-1 and not MATH-1 PASS. MATH-1 stays FAIL.

## Benchmark

Not a gas study. No function was added, so no gas was measured for `mint_with_minimum_backing` or `sweep_dust`.

## Security implications

Python can deposit the mint delta and mint in one call through `mint_with_minimum_backing`. Python can zero component backing through `sweep_dust` when supply is 0. The Solidity kernel exposes `deposit`, `mint`, and `redeem` only. Adding either Python-only name before acceptance would replace that measured list. Renaming `deposit` to `deposit_raw` before acceptance would replace the measured Solidity name.

## Tradeoffs

The shared names are `mint` and `redeem`. The deposit operation is present on both sides under different names. Two Python names have no Solidity declaration. Matching every Python name requires an edit. Leaving both sides unchanged preserves the measured lists. The open decision stays open until a human accepts one rule.

## Recommendation

Do not edit `CandidateComponentBacking.deposit`, `mint`, or `redeem`. Do not edit `FixedPointSeries`. Do not add `sweep_dust`. Do not add `mint_with_minimum_backing`. Acceptance is not granted. The open decision stays open until a human accepts one of the two rules above.

## Confidence

High for this draft. The Python class and the Solidity contract were read for state-changing names, excluding views and constructors. That does not measure a later edit.

## What would falsify this

A later reading where the two state-changing name sets are the same. Or a later reading that adds `sweep_dust` or `mint_with_minimum_backing` to `CandidateComponentBacking`, or removes one of those names from `FixedPointSeries`. Or an explicit acceptance of one rule together with an edit of an implementation. Either result replaces this proposal. Silence does not accept it.
