# ADR-P08: Reject false-return collateral before activation

**Status:** PROPOSED  
**Date:** 2026-09-26

Acceptance is not granted. This file does not authorize an edit to the Python admission check, the Solidity constructor, `activate`, `split`, or any payout formula. The research kernel must not be edited to implement this recommendation until this ADR is explicitly accepted.

ADR-P06 remains the general proposal that Phase-1 collateral is one standard ERC-20. ADR-P06 does not decide when a token whose `transfer` returns false is rejected. This record does not supersede ADR-P06.

## Decision

Propose that the research kernel reject false-return collateral before `activate`, matching `create_market` for `CollateralClass.FALSE_RETURN`. Until acceptance, keep the measured kernel behavior: the market constructs and activates, and `split` reverts when `transferFrom` returns false.

## Options

Leave the kernel as measured. `PredictionMarket` constructs and activates any token that exposes `decimals`. `split` then uses `SafeERC20.safeTransferFrom`. A false return reverts `SafeERC20FailedOperation` and credits no supply.

Or, after acceptance, reject that collateral before activation so an `OPEN` market is not created for it. That is the Python rule: `create_market` raises and calls no transfer.

Or treat the `split` revert as the admission check and change the Python model so `FALSE_RETURN` can construct. That would move the reference model toward the kernel. This proposal does not choose that option.

## Evidence

`evidence/research/prediction/false-return-collateral-2026-09-26.json`.

Python `create_market` with `CollateralClass.FALSE_RETURN` raises `Phase-1 admits only standard ERC-20 collateral, got FALSE_RETURN`. No transfer runs.

The Solidity research kernel still constructs and activates that market. `transfer` and `transferFrom` return false. `split(1)` reverts `SafeERC20FailedOperation`. `collateralLocked`, `yesSupply`, and `noSupply` stay 0. The state stays `OPEN`. Default profile, forge 1.8.3, solc 0.8.26, optimizer 200, via IR off. The focused test passed 1 and failed 0, gas 343471. Neither implementation was changed.

## Benchmark

Not a gas study. The figure above is the recorded test gas for construction, activation, and the reverting `split`. No separate cost was measured for a pre-activation probe.

## Security implications

The recorded `split` does not mint outcome tokens and does not lock collateral. The open gap is admission timing. An activated market can exist while its collateral `transfer` returns false. Later `merge`, `redeem`, and `archive` also send collateral through `SafeERC20`. This witness does not show a credited split, a changed payout, or an insolvent liability. It shows a market that reaches `OPEN` after Python has already refused to construct.

## Tradeoffs

Python rejects a declared class at construction. Solidity does not receive that class. A constructor probe that calls `transfer` can be fooled by a token that returns true only during the probe, and it spends gas before `activate`. Matching the Python rule exactly needs an admission check the current kernel does not have. Leaving the `SafeERC20` revert in place avoids a new probe and still stops the recorded `split` from crediting supply. The contradiction stays open either way until a human accepts one option.

## Recommendation

The research kernel should reject false-return collateral before activation, matching the Python rule. Acceptance is not granted. Do not edit the kernel, the Python admission check, or a payout formula on the strength of this proposal.

## Confidence

Medium. One false-return token and one `split(1)` were measured. That is enough to show the admission points differ. It is not a classification of every ERC-20 that returns false from `transfer` or `transferFrom`.

## What would falsify this

A later measurement where this kernel credits `yesSupply` or `collateralLocked` after `transferFrom` returns false. Or an explicit acceptance of the other option: that `SafeERC20` at `split` is the admission check, together with a Python change that allows `FALSE_RETURN` to construct. Either result replaces this proposal. Silence does not accept it.
