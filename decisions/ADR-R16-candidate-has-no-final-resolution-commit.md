# ADR-R16: The candidate has no final-resolution commit

**Status:** PROPOSED  
**Date:** 2026-09-26

Acceptance is not granted. This file does not authorize an edit to `PrismSeries.resolve`, `CandidateCumulativeSettlement.redeem`, `CandidateCumulativeSettlement.makeRedeemable`, `CandidateComponentBacking.redeem`, `CandidatePayoffTransform.transformComponent`, or any payout. Neither implementation may be edited to add a final-resolution commit until this ADR is explicitly accepted.

This ADR does not supersede ADR-R15. ADR-R15 records that the candidate has no `ARCHIVED` state and no lifecycle reopen. This file does not restate that measurement and does not edit ADR-R15. ADR-R09 through ADR-R15 stay PROPOSED. This file does not edit them.

The witness `evidence/research/prism/final-resolution-once-2026-09-26.json` stays `recorded_gap`. This file does not reclassify it.

## Decision

Propose that the measured final-resolution gap stays recorded and that no resolve function is added until a human accepts one rule. The open decision is whether Phase-1 must add a one-shot final-resolution commit to the candidate, or that commit stays only on `PrismSeries`. This proposal does not choose that winner and does not change code.

## Options

Leave both sides as measured. Python `PrismSeries.resolve(2)` from `RESOLUTION_PENDING` commits `final_payout` `1` and moves the state to `RESOLVED`. A second `resolve(0)` raises `series must be RESOLUTION_PENDING`. The payout stays `1` and the state stays `RESOLVED`. The candidate settlement and backing kernels have no final-resolution commit. `CandidatePayoffTransform.transformComponent` was not called.

Or, after acceptance, add a one-shot final-resolution commit to the candidate. This proposal does not choose that option.

Or, after acceptance, leave that commit only on `PrismSeries`. This proposal does not choose that option.

## Evidence

`evidence/research/prism/final-resolution-once-2026-09-26.json`.  
`research/prism-model/model.py`.  
`research/contract-kernels/src/prism/CandidateCumulativeSettlement.sol`.  
`research/contract-kernels/src/prism/CandidateComponentBacking.sol`.

Python setup is `activate`, `mint_with_exact_backing(1000)`, `start_resolution`, `resolve(2)`, then `resolve(0)`. Before the first resolve the state is `RESOLUTION_PENDING` and `final_payout` is unset. After it the state is `RESOLVED` and `final_payout` is `1`. The second call raises `series must be RESOLUTION_PENDING`. After that raise the state is still `RESOLVED` and `final_payout` is still `1`.

`CandidateCumulativeSettlement` state-changing names are `makeRedeemable` and `redeem`. `CandidateComponentBacking` state-changing names are `deposit`, `mint`, and `redeem`. Neither declares `resolve`. `transformComponent` replaces one component and is not a final-resolution commit. No function was added.

Classification of that witness is `recorded_gap`. R-I12 has no Foundry edge. MATH-1 stays FAIL.

## Benchmark

Not a gas study of a new function. The recorded absence log passed 1 and failed 0, gas 11168. No resolve function was added.

## Security implications

Python commits one terminal payout and refuses a second commit. The candidate cannot commit or replace that payout because it has no such function. Adding `resolve` before acceptance would replace the measured kernel.

## Tradeoffs

Adding a one-shot commit would give the candidate the Python latch. Leaving the commit on `PrismSeries` preserves the measured kernels. The open decision stays open until a human accepts one rule.

## Recommendation

Do not add `resolve`. Do not edit `redeem` or any payout. Do not call `transformComponent` as a substitute. Acceptance is not granted. The open decision stays open until a human accepts one of the two rules above. This ADR does not supersede ADR-R15.

## Confidence

High for this draft. The Python second resolve was executed and the candidate sources have no final-resolution commit. That does not choose a later design.

## What would falsify this

A later reading of a candidate kernel that declares a final-resolution commit. Or a later execution of `PrismSeries.resolve` where a second call changes `final_payout`. Or an explicit acceptance of one rule together with an edit of an implementation. Either result replaces this proposal. Silence does not accept it.
