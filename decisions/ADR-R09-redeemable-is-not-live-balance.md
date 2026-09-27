# ADR-R09: redeemable is not proof the live balance covers the floor

**Status:** PROPOSED  
**Date:** 2026-09-26

Acceptance is not granted. This file does not authorize a rebase guard, a change to `makeRedeemable`, a change to `redeem`, a change to the cumulative-floor payout, or any other edit to `CandidateCumulativeSettlement`. The kernel must not be edited to implement this recommendation until this ADR is explicitly accepted. This change does not clear the `redeemable` flag.

ADR-R08 remains the proposal that `backingRaw` is not the rebasing component token balance. ADR-R08 does not cite the settlement witness and does not speak to `redeemable`. This record does not supersede ADR-R08.

## Decision

Propose that `redeemable` must not be treated as proof that the live settlement-token balance still covers the one-shot floor after a later balance decrease. Until acceptance, leave the measured kernel as it is: after funding of 2 and `rebaseDown` of 2, the balance is 0, the one-shot floor is 1, and `redeemable` stays true.

## Options

Leave the kernel as measured. `makeRedeemable` sets `redeemable` from the balance at that call. A later decrease does not clear the flag. `redeem` still reverts `PayoutExceedsBalance` when the computed payout exceeds the live balance, and that revert leaves `paidRaw` unchanged.

Or, after acceptance, stop treating `redeemable` as a standing promise that the live balance covers the floor. That recommendation does not choose a repair. It does not clear the flag in this proposal.

## Evidence

`evidence/research/prism/deep-rebasing-settlement-funding-2026-09-26.json`.

Supply 2, payout `10^18-1`, decimals 18, ceil funding 2, one-shot floor 1. A normal transfer funds 2 and `makeRedeemable` succeeds. `rebaseDown` of 2 then changes the token balance without `transfer` or `transferFrom`. The token balance becomes 0, which is below the floor of 1. `redeemable` stays true. `paidRaw` stays 0. `redeem(2)` reverts `PayoutExceedsBalance` with payout 1 and balance 0. After the revert the balance is still 0, `paidRaw` is still 0, and `redeemable` is still true. The redeem revert is `existing_rule`. The stuck `redeemable` flag is the open policy gap. The kernel was not edited. MATH-1 stays FAIL.

## Benchmark

Not a gas study. The recorded test gas for that witness is 584736. No separate cost was measured for clearing `redeemable`.

## Security implications

The revert stops a payout of 1 when the balance is 0, and it does not increase `paidRaw`. The open gap is the flag. A later reader can see `redeemable` true while the live balance is below the floor. That is not an overpay and it is not a debit that survives the revert. It is a stale permission bit.

## Tradeoffs

Clearing `redeemable` on a short balance, rechecking the floor inside `redeem` before the payout comparison, and documenting that the flag is only an opening latch are different repairs. None of them is authorized here. Clearing the flag in this change would hide the measured gap. ADR-R08 stays the component-backing record.

## Recommendation

Do not treat `redeemable` as proof that the live settlement balance still covers the floor after a later balance decrease. Acceptance is not granted. Do not edit the kernel until this ADR is accepted. Do not clear the flag in this change. The redeem revert stays `existing_rule`. MATH-1 stays FAIL.

## Confidence

Medium. One supply, one payout, one `rebaseDown` of 2, and one `redeem(2)` were measured. That shows the flag staying true below the floor. It does not classify every later balance decrease.

## What would falsify this

A later measurement on this kernel where the same `rebaseDown` of 2 clears `redeemable`, or where `redeem(2)` pays while the balance is 0. Or an explicit acceptance of another option, including a named repair that keeps the flag aligned with the live balance. Silence does not accept this proposal.
