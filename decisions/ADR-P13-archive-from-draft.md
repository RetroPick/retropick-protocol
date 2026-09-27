# ADR-P13: Archive from DRAFT commits before the spec check

**Status:** PROPOSED  
**Date:** 2026-09-26

Acceptance is not granted. This file does not authorize an edit to `PredictionMarket.archive`, the Python `archive` function, `check_market`, `split`, `merge`, `redeem`, `burn`, `activate`, or any payout formula. Neither implementation may be edited to make these sides match until this ADR is explicitly accepted.

## Decision

Propose that the draft-archive disagreement stays recorded and that neither `archive` is edited until a human accepts one rule. The open decision is whether `archive` from `DRAFT` must revert with the market still `DRAFT`, or the reference may enter `ARCHIVED` before the spec invariant fails. This proposal does not choose that winner and does not change code.

## Options

Leave both archives as measured. Python `archive` on a `DRAFT` market with collateral 0, YES supply 0, and NO supply 0 raises `P-I05 resolution spec mutated or missing` after the state is already `ARCHIVED`. Those three figures stay 0. Solidity `archive` reverts `BadState`. The state stays `DRAFT`. Those three figures stay 0.

Or, after acceptance, make the Python `archive` revert while the market is still `DRAFT`. That would stop the transition that runs before the spec check.

Or, after acceptance, make the kernel archive a draft. This proposal does not choose that option.

## Evidence

`evidence/research/prediction/rejection-inventory-2026-09-26.json`.

The table has 72 rows. 71 rows reject on both sides. Collateral, YES supply, and NO supply stay at the pre-call integers, and the state stays put. The disagreeing row is `archive` from `DRAFT`.

Python starts at collateral 0, YES supply 0, NO supply 0, and state `DRAFT`. `archive` raises `P-I05 resolution spec mutated or missing`. Collateral, YES supply, and NO supply stay 0. The state after the exception is `ARCHIVED`.

Solidity starts at the same three figures and state `DRAFT`. `archive` reverts `BadState`. Collateral, YES supply, and NO supply stay 0. The state stays `DRAFT`.

Classification of that row is `recorded_contradiction`. The other 71 rows are `existing_rule`. The contradiction stays open. This is not a theorem pass. MATH-1 stays FAIL. PRED-MATH-1 stays partial. PRED-CONTRACT-1 stays not_pass. Archive was not changed. Default profile, forge 1.8.3, solc 0.8.26, optimizer 200, via IR off. The focused test passed 1 and failed 0, gas 8197908.

## Benchmark

Not a gas study. The figure above is the recorded test gas for the whole table. No separate cost was measured for an archive guard.

## Security implications

Python applies `DRAFT -> ARCHIVED` and then raises because the draft has no resolution spec. A caller that catches the exception observes an archived market. Solidity reverts the same call and the market stays a draft. Collateral, YES supply, and NO supply do not move on either side, so this witness does not show a payout above locked collateral or a wrapped supply. Editing either side before acceptance would erase the recorded disagreement.

## Tradeoffs

The lifecycle allows `DRAFT -> ARCHIVED` for cancel, and Python `archive` uses that transition before `check_market`. The kernel allows `archive` only from `REDEEMABLE`. Matching either side requires an edit. Leaving both sides unchanged preserves the witness. The contradiction stays open until a human accepts one rule.

## Recommendation

Do not edit `PredictionMarket.sol` or the Python `archive` function. Do not edit `check_market`. Acceptance is not granted. The contradiction stays open until a human accepts one of the two rules above.

## Confidence

High for this draft. One Python call and one Solidity revert were measured on an unactivated market with zero collateral and zero supplies. That does not classify `archive` from any other state. Those other states in the same table reject on both sides with the integers unchanged.

## What would falsify this

A later measurement where Solidity `archive` from `DRAFT` leaves the state `ARCHIVED` and the three figures at 0. Or a later measurement where Python `archive` from `DRAFT` leaves the state `DRAFT` and those figures at 0. Or an explicit acceptance of one rule together with an edit of the other side. Either result replaces this proposal. Silence does not accept it.
