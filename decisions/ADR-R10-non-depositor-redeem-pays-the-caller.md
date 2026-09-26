# ADR-R10: Non-depositor redeem pays the series caller

**Status:** PROPOSED  
**Date:** 2026-09-26

Acceptance is not granted. This file does not authorize an edit to `CandidateComponentBacking.mint`, `CandidateComponentBacking.redeem`, the Python `FixedPointSeries.mint` function, the Python `FixedPointSeries.redeem` function, or any payout formula. Neither implementation may be edited to choose a payee until this ADR is explicitly accepted.

The zero-weight mint of `2**256-1` in `evidence/research/prism/non-depositor-mint-2026-09-26.json` is a different witness. It is not this decision.

## Decision

Propose that the measured payee stays recorded and that neither `mint` nor `redeem` is edited until a human accepts one rule. The open decision is whether Phase-1 redeem must pay the series-token caller, or only the depositor may mint and redeem. This proposal does not choose that winner and does not change code.

## Options

Leave both sides as measured. Weights are `10^18` and `10^18`. Account A deposits 1 and 1. Account B, who did not deposit, mints 1. `requiredRaw` at supply 1 is 1 and 1, and `backingRaw` is 1 and 1. B redeems 1. Supply becomes 0. `backingRaw` becomes 0 and 0. B's component balances become 1 and 1. A's component balances stay 0 and 0. Python matches supply and backing and has no accounts.

Or, after acceptance, pay the series-token caller. That is the path the kernel already took. This proposal does not choose that option.

Or, after acceptance, allow only the depositor to mint and redeem. This proposal does not choose that option.

## Evidence

`evidence/research/prism/non-depositor-redeem-2026-09-26.json`.  
`evidence/research/prism/positive-weight-non-depositor-mint-2026-09-26.json`.  
`evidence/research/prism/over-mint-2026-09-26.json`.

Weights are `10^18` and `10^18`. Decimals are 18 and 18. Account A deposits 1 and 1. Account B did not deposit.

B's `mint(1)` succeeds. Supply becomes 1. `backingRaw` stays 1 and 1. `requiredRaw` at supply 1 is 1 and 1. B's series balance becomes 1. Python `FixedPointSeries.deposit_raw((1, 1))` then `mint(1)` reaches the same supply, backing, and requirement. Python has no account.

B's `redeem(1)` succeeds. Supply becomes 0. `backingRaw` becomes 0 and 0. `requiredRaw` at that supply is 0 and 0. A's component balances stay 0 and 0. B's component balances become 1 and 1. B's series balance becomes 0. The component tokens sit with B, the caller. Python `redeem(1)` leaves supply 0 and backing 0 and 0 and releases 1 and 1. Python has no accounts, so it does not name a payee. Supply and backing match. Classification of that witness is `redeem_pays_caller`.

`mint(2)` against this deposit reverts `InsufficientBacking(0, 1, 2)`. Supply stays 0. `backingRaw` stays 1 and 1. `requiredRaw` at supply 2 is 2 and 2. Python raises `insufficient fixed-point backing for mint` and leaves the same supply and backing. Classification of that witness is `existing_rule`.

MATH-1 stays FAIL. Mint was not changed. Redeem was not changed. Default profile. The redeem test passed 1 and failed 0, gas 780289. The `mint(2)` test passed 1 and failed 0, gas 549077.

## Benchmark

Not a gas study. The figures above are the recorded test gas for those two calls. No separate cost was measured for a depositor-only guard.

## Security implications

B receives the 1 and 1 component units that A deposited. After the redeem, backing is 0 and 0, so B does not receive more component tokens than `backingRaw` held. `mint(2)` reverts, so this deposit does not mint a supply whose requirement exceeds backing of 1 and 1. Editing `mint` or `redeem` before acceptance would replace the measured payee.

## Tradeoffs

The kernel credits series units to `msg.sender` and sends released component tokens to `msg.sender`. Python updates supply and backing and has no accounts. Matching a depositor-only rule requires an edit. Leaving both sides unchanged preserves the witness. The open decision stays open until a human accepts one rule.

## Recommendation

Do not edit `CandidateComponentBacking.mint` or `CandidateComponentBacking.redeem`. Do not edit `FixedPointSeries.mint` or `FixedPointSeries.redeem`. Acceptance is not granted. The open decision stays open until a human accepts one of the two rules above.

## Confidence

High for this draft. One Solidity path and one Python path were measured at weights `10^18` and `10^18`, a deposit of 1 and 1, a mint of 1, and a redeem of 1. That does not classify another weight, another deposit, or the zero-weight mint of `2**256-1`.

## What would falsify this

A later measurement at these weights where B's `redeem(1)` leaves the component tokens with A, or leaves supply above 0, or leaves `backingRaw` above 0 and 0. Or a later measurement where Python supply or backing differs from those integers. Or an explicit acceptance of one rule together with an edit of an implementation. Either result replaces this proposal. Silence does not accept it.
