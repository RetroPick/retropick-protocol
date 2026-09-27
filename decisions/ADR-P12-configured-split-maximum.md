# ADR-P12: Configured split maximum stays an open choice

**Status:** PROPOSED  
**Date:** 2026-09-26

Acceptance is not granted. This file does not authorize an edit to `PredictionMarket.split`, the Python `split` function, `max_amount`, `merge`, `redeem`, or any payout formula. Neither implementation may be edited to enforce or remove a configured maximum until this ADR is explicitly accepted.

ADR-P11 records a different disagreement: a split of `2**256-1` followed by `split(1)`. It does not decide a maximum of 1000000000. This record does not supersede ADR-P11.

## Decision

Propose that the configured-maximum disagreement stays recorded and that neither split is edited until a human accepts one rule. The open decision is whether Phase-1 split must reject an amount above 1000000000, or that figure is only a harness bound and the kernel may mint it. This proposal does not choose that winner and does not change code.

## Options

Leave both splits as measured. Python with `max_amount` 1000000000 rejects `split(1000000001)` and leaves the books at 0. Solidity `split(1000000001)` mints and leaves collateral, YES supply, and NO supply at 1000000001.

Or, after acceptance, make the kernel reject an amount above 1000000000. That would add a cap the kernel does not have.

Or, after acceptance, treat the harness cap as outside Phase 1 and stop using it as a kernel requirement. This proposal does not choose that option.

## Evidence

`evidence/research/prediction/configured-split-maximum-2026-09-26.json`.

Python `create_market` with `max_amount` 1000000000 starts at collateral 0, YES supply 0, and NO supply 0. `split(1000000001)` raises `amount exceeds configured maximum`. Those three figures stay 0. The state stays `OPEN`.

Solidity has no configured maximum. The holder is funded with 1000000001. `split(1000000001)` mints. Collateral balance, `collateralLocked`, YES supply, and NO supply become 1000000001. The state stays `OPEN`. There is no revert.

Classification `recorded_contradiction`. The contradiction stays open. This is not a theorem pass. MATH-1 stays FAIL. PRED-MATH-1 stays partial. PRED-CONTRACT-1 stays not_pass. Split was not changed. The configured maximum was not changed. Default profile, forge 1.8.3, solc 0.8.26, optimizer 200, via IR off. The focused test passed 1 and failed 0, gas 315609.

## Benchmark

Not a gas study. The figure above is the recorded test gas for the successful Solidity split. No separate cost was measured for a cap check.

## Security implications

The kernel mints a complete set for an amount the configured Python market rejects. The minted supplies equal the collateral locked, so this witness does not show an unbacked mint or a wrapped supply. Treating 1000000000 as a kernel limit before acceptance would add a rule the measured split does not have. Removing the Python check before acceptance would erase the recorded reject.

## Tradeoffs

The adversarial harness and the earlier `split(2**256)` witness set `max_amount` to 1000000000. The default Python argument is the uint256 maximum, which is a different bound and is not this measurement. Solidity `split` takes any uint256 the caller can fund. Matching either side requires an edit. Leaving both sides unchanged preserves the witness. The contradiction stays open until a human accepts one rule.

## Recommendation

Do not edit `PredictionMarket.sol` or the Python split function. Do not change the configured maximum. Acceptance is not granted. The contradiction stays open until a human accepts one of the two rules above.

## Confidence

High for this amount. One Python reject and one Solidity mint were measured at 1000000001. That does not classify every amount below 1000000000 or above it.

## What would falsify this

A later measurement where Solidity `split(1000000001)` reverts and leaves collateral, YES supply, and NO supply at 0. Or a later measurement where Python with `max_amount` 1000000000 accepts `split(1000000001)` and those figures become 1000000001. Or an explicit acceptance of one rule together with an edit of the other side. Either result replaces this proposal. Silence does not accept it.
