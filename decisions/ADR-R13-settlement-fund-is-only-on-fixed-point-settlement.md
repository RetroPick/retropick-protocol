# ADR-R13: Settlement fund is only on FixedPointSettlement

**Status:** PROPOSED  
**Date:** 2026-09-26

Acceptance is not granted. This file does not authorize an edit to `CandidateCumulativeSettlement.redeem`, `CandidateCumulativeSettlement.makeRedeemable`, `CumulativeFloorSettlement.redeem`, `CumulativeFloorSettlement.make_redeemable`, `FixedPointSettlement.redeem`, `FixedPointSettlement.make_redeemable`, `FixedPointSettlement.fund`, or any payout formula. Neither implementation may be edited to add `fund` until this ADR is explicitly accepted.

ADR-R03 stays the record that the canonical per-call floor fails. This file does not restate that failure and does not edit ADR-R03. ADR-R11 and ADR-R12 stay PROPOSED. This file does not edit them.

## Decision

Propose that the measured name lists stay recorded and that no settlement function is added until a human accepts one rule. The open decision is whether Phase-1 must add `fund` to `CandidateCumulativeSettlement` and `CumulativeFloorSettlement`, or `fund` stays only on `FixedPointSettlement`. This proposal does not choose that winner and does not change code.

## Options

Leave both sides as measured. `FixedPointSettlement` state-changing names are `fund`, `make_redeemable`, and `redeem`. `CumulativeFloorSettlement` state-changing names are `make_redeemable` and `redeem`. `CandidateCumulativeSettlement` state-changing names are `makeRedeemable` and `redeem`.

Or, after acceptance, add `fund` to the cumulative kernel and to `CumulativeFloorSettlement`. This proposal does not choose that option.

Or, after acceptance, leave `fund` only on `FixedPointSettlement`. This proposal does not choose that option.

## Evidence

`research/contract-kernels/src/prism/CandidateCumulativeSettlement.sol`.  
`research/prism-model/cumulative_settlement.py`.  
`research/prism-model/fixed_point_model.py`.

Views and constructors are omitted. Solidity views omitted are `ceilFunding` and `oneShotFloor`. Python views omitted are `FixedPointSettlement.required_balance_raw` and `FixedPointSettlement.sweepable_dust`. `sweepable_dust` reads the balance and does not write it. None of the three types declare a state-changing sweep. The sweep policy stays NOT_YET_VALIDATED.

`CandidateCumulativeSettlement` state-changing names: `makeRedeemable`, `redeem`.

`CumulativeFloorSettlement` state-changing names: `make_redeemable`, `redeem`.

`FixedPointSettlement` state-changing names: `fund`, `make_redeemable`, `redeem`.

`redeem` is on all three. `makeRedeemable` and `make_redeemable` are the language spellings of the redeemable opener. `fund` is declared only on `FixedPointSettlement`. The cumulative kernel does not declare `fund`. `CumulativeFloorSettlement` does not declare `fund`. No function was added.

This comparison is not CONTRACT-1 and not MATH-1 PASS. MATH-1 stays FAIL. The per-call floor failure stays ADR-R03.

## Benchmark

Not a gas study. No function was added, so no gas was measured for `fund` on the cumulative kernel.

## Security implications

`FixedPointSettlement.fund` increases `balance_raw`. The cumulative kernel accounts funding as the settlement-token balance read by `makeRedeemable`. `CumulativeFloorSettlement` reads `balance_raw` in `make_redeemable` and has no `fund` method. Adding `fund` before acceptance would replace that measured list.

## Tradeoffs

The cumulative candidate and its kernel share the redeemable opener and `redeem`. The canonical type also declares `fund`. Matching that name on the other two types requires an edit. Leaving the lists unchanged preserves the measured names. The open decision stays open until a human accepts one rule.

## Recommendation

Do not edit `CandidateCumulativeSettlement.redeem` or the payout formula. Do not add `fund`. Do not add a sweep. Acceptance is not granted. The open decision stays open until a human accepts one of the two rules above.

## Confidence

High for this draft. The contract and both Python types were read for state-changing names, excluding views and constructors. That does not measure a later edit.

## What would falsify this

A later reading where `CandidateCumulativeSettlement` or `CumulativeFloorSettlement` declares `fund`, or where `FixedPointSettlement` no longer declares `fund`. Or an explicit acceptance of one rule together with an edit of an implementation. Either result replaces this proposal. Silence does not accept it.
