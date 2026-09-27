# ADR-R15: The candidate has no ARCHIVED state and no lifecycle reopen

**Status:** PROPOSED  
**Date:** 2026-09-26

Acceptance is not granted. This file does not authorize an edit to `CandidateCumulativeSettlement.makeRedeemable`, `CandidateCumulativeSettlement.redeem`, `lifecycle.transition`, or any payout. Neither implementation may be edited to add a lifecycle state or a reopen function until this ADR is explicitly accepted.

This ADR does not supersede ADR-R09. ADR-R09 records that a later balance decrease does not clear `redeemable`. This file does not restate that measurement and does not edit ADR-R09. ADR-R13 records settlement function names and does not state this lifecycle gap. ADR-R09 through ADR-R14 stay PROPOSED. This file does not edit them.

The witness `evidence/research/prism/lifecycle-reopen-2026-09-26.json` stays `recorded_gap` on both edges. This file does not reclassify it.

## Decision

Propose that the measured lifecycle gap stays recorded and that no lifecycle function is added until a human accepts one rule. The open decision is whether Phase-1 must add the Python lifecycle states to the candidate, or the candidate stays a `redeemable` bool with no reopen. This proposal does not choose that winner and does not change code.

## Options

Leave both sides as measured. Python `lifecycle.transition` rejects `REDEEMABLE` to `ACTIVE` and leaves the state `REDEEMABLE`. It rejects every earlier exit from `ARCHIVED` and leaves the state `ARCHIVED`. `CandidateCumulativeSettlement` has a `redeemable` bool. `makeRedeemable` sets that bool true. No function sets it false. The candidate has no `REDEEMABLE` state, no `ARCHIVED` state, and no function that returns a redeemable book to an earlier lifecycle state.

Or, after acceptance, add the Python lifecycle states to the candidate. This proposal does not choose that option.

Or, after acceptance, leave the candidate as a `redeemable` bool with no reopen. This proposal does not choose that option.

## Evidence

`evidence/research/prism/lifecycle-reopen-2026-09-26.json`.  
`research/prism-model/lifecycle.py`.  
`research/contract-kernels/src/prism/CandidateCumulativeSettlement.sol`.

Python `transition(REDEEMABLE, ACTIVE)` raises `illegal transition: REDEEMABLE -> ACTIVE`. The state stays `REDEEMABLE`. Python `transition` from `ARCHIVED` to `DRAFT`, `ACTIVE`, `MINT_PAUSED`, `RESOLUTION_PENDING`, `RESOLVED`, and `REDEEMABLE` each raises `LifecycleError`. The state stays `ARCHIVED`.

`CandidateCumulativeSettlement` state-changing names are `makeRedeemable` and `redeem`. `makeRedeemable` sets `redeemable` from false to true. No function sets it false. After that open call the bool stays true. The contract does not declare `ARCHIVED`. `CandidateComponentBacking` has no lifecycle state. No function was added.

Classification of that witness is `recorded_gap` for the REDEEMABLE edge and `recorded_gap` for the ARCHIVED edge. R-I11 has no Foundry edge. MATH-1 stays FAIL.

## Benchmark

Not a gas study of a new function. The recorded absence test passed 1 and failed 0, gas 215895. No lifecycle function was added.

## Security implications

Python refuses to move a redeemable or archived series backward. The candidate can open a bool and cannot return that book to an earlier lifecycle state because it has no such state. Adding those states before acceptance would replace the measured kernel.

## Tradeoffs

Adding the Python states would give the candidate an `ARCHIVED` sink and a rejected reopen. Leaving the bool preserves the measured kernel. The open decision stays open until a human accepts one rule.

## Recommendation

Do not add a lifecycle function. Do not add a sweep. Do not add a transfer. Do not edit `redeem`. Acceptance is not granted. The open decision stays open until a human accepts one of the two rules above. This ADR does not supersede ADR-R09.

## Confidence

High for this draft. The Python transitions were executed and the candidate source has no `ARCHIVED` state and no reopen. That does not choose a later design.

## What would falsify this

A later reading of `CandidateCumulativeSettlement` that declares `ARCHIVED` or a function that returns a redeemable book to an earlier lifecycle state. Or a later reading of `lifecycle.transition` that accepts `REDEEMABLE` to `ACTIVE` or an earlier exit from `ARCHIVED`. Or an explicit acceptance of one rule together with an edit of an implementation. Either result replaces this proposal. Silence does not accept it.
