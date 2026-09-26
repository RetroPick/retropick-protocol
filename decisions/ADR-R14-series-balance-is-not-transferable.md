# ADR-R14: Series units sit in balanceOf and are not transferable

**Status:** PROPOSED  
**Date:** 2026-09-26

Acceptance is not granted. This file does not authorize an edit to `CandidateComponentBacking.mint`, `CandidateComponentBacking.redeem`, `CandidateComponentBacking.deposit`, `FixedPointSeries.mint`, `FixedPointSeries.redeem`, or `FixedPointSeries.deposit_raw`. Neither implementation may be edited to add `transfer` until this ADR is explicitly accepted.

ADR-R05, ADR-R10, and ADR-R12 stay PROPOSED. They are different decisions. This file does not edit them. The witness `evidence/research/prism/indivisible-weight-two-holders-2026-09-26.json` stays `recorded_gap`. This file does not reclassify it.

## Decision

Propose that the measured series balance stays recorded and that neither side is edited until a human accepts one rule. The open decision is whether Phase-1 series units must be transferable, or balances stay with the minter until that minter redeems. This proposal does not choose that winner and does not change code.

## Options

Leave both sides as measured. `CandidateComponentBacking` stores series units in `balanceOf`. It does not declare `transfer`. A low-level `transfer(address,uint256)` for 1 unit returns false with empty data. The minter's balance stays 2. The other account's balance stays 0. `FixedPointSeries` has no accounts and no `transfer`.

Or, after acceptance, make Phase-1 series units transferable. This proposal does not choose that option.

Or, after acceptance, leave balances with the minter until that minter redeems. This proposal does not choose that option.

## Evidence

`evidence/research/prism/indivisible-weight-two-holders-2026-09-26.json`.  
`research/contract-kernels/src/prism/CandidateComponentBacking.sol`.  
`research/prism-model/fixed_point_model.py`.

Weights are `10^18+1` and `10^18+1`. Decimals are 18 and 18. Account A deposits 3 and 3 and mints 2. A's series balance is 2. B's series balance is 0. The contract does not declare `transfer`. A's call to `transfer(address,uint256)` for 1 series unit returns false and empty data. A's series balance stays 2. B's series balance stays 0. Supply stays 2. `backingRaw` stays 3 and 3. `requiredRaw` at that supply stays 3 and 3. The holder redeems were not executed. Classification of that witness is `recorded_gap`.

Python `FixedPointSeries` has no `transfer` and no accounts. Two successive `redeem(1)` calls on that model release 1 and 1, then 2 and 2. Those tuples are not assigned to holders.

ADR-R05 prefers one transferable ERC-20 per series and says that preference was not measured. No series token was compiled for ADR-R05. ADR-R12 records state-changing names and does not state that series units sit in `balanceOf`. ADR-R10 records who is paid on redeem and does not record a transfer. None of those files states this measured storage fact.

MATH-1 stays FAIL. No function was added.

## Benchmark

The failed transfer test passed 1 and failed 0, gas 608568. Default profile. That gas is the recorded call, not a cost for a transfer that was not added.

## Security implications

A series balance can be created only by `mint` to `msg.sender` and can be reduced only by that account's `redeem`. Another account cannot take the units. Adding `transfer` before acceptance would replace that measured absence.

## Tradeoffs

Leaving the balance with the minter preserves the measured kernel. Making the units transferable would let a second account redeem a share the minter no longer holds. The open decision stays open until a human accepts one rule.

## Recommendation

Do not add `transfer`. Do not edit `balanceOf`. Do not edit `mint` or `redeem`. Acceptance is not granted. The open decision stays open until a human accepts one of the two rules above.

## Confidence

High for this draft. The contract source stores series units in `balanceOf` and does not declare `transfer`. The recorded call returns false. That does not choose a later design.

## What would falsify this

A later reading of `CandidateComponentBacking` that declares `transfer` and moves `balanceOf`. Or an explicit acceptance of one rule together with an edit of an implementation. Either result replaces this proposal. Silence does not accept it.
