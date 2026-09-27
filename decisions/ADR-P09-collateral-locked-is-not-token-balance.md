# ADR-P09: collateralLocked is not the rebasing token balance

**Status:** PROPOSED  
**Date:** 2026-09-26

Acceptance is not granted. This file does not authorize a rebase guard, a new balance check, a payout change, or any other edit to the Python admission check or the Solidity kernel. The kernel must not be edited to implement this recommendation until this ADR is explicitly accepted.

ADR-P06 remains the general proposal that Phase-1 collateral is one non-rebasing ERC-20. ADR-P06 does not cite the post-split witness and does not record that `collateralLocked` can stay at the credited amount while the token balance falls. This record does not supersede ADR-P06.

## Decision

Propose that the kernel must not treat `collateralLocked` as equal to the collateral token balance for a rebasing token. Until acceptance, leave the measured kernel as it is: after `split(100)`, a later balance decrease of 1 leaves `collateralLocked` at 100.

## Options

Keep the measured accounting. `collateralLocked` is the amount credited at `split`. A later change to the token balance does not update it. `liability()` before resolution returns `collateralLocked`.

Or, after acceptance, stop treating those two quantities as the same figure for a rebasing token. That recommendation does not choose a repair. It does not add a guard in this proposal.

Or change Python so `CollateralClass.REBASING` can construct, and keep the kernel's credited lock. This proposal does not choose that option.

## Evidence

`evidence/research/prediction/rebasing-collateral-2026-09-26.json`.

Python `create_market` with `CollateralClass.REBASING` raises `Phase-1 admits only standard ERC-20 collateral, got REBASING`. No split runs.

The kernel has no rebase function. A test-only token completed `split(100)`. Collateral balance, `collateralLocked`, YES supply, and NO supply were 100. `liability()` was 100. `rebaseDown` of 1 then changed the token balance without `transfer` or `transferFrom`. Collateral balance became 99. `collateralLocked`, YES supply, NO supply, and `liability()` stayed 100. The state stayed `OPEN`. Default profile, forge 1.8.3, solc 0.8.26, optimizer 200, via IR off. The focused test passed 1 and failed 0, gas 787902. Classification `COUNTEREXAMPLE_FOUND`. Neither implementation was changed.

## Benchmark

Not a gas study. The figure above is the recorded test gas for construction, `split(100)`, and the test-only balance drop. No repair was measured.

## Security implications

The token balance can sit below the liability the kernel still reports. YES and NO supply stay at the credited complete set. A later redemption that pays from `collateralLocked` can ask the token for units the contract no longer holds. This witness stops at the divergence. It does not execute `redeem`. ADR-P06 stays PROPOSED and is not a repair.

## Tradeoffs

Python refuses to construct a rebasing market, so the reference model never reaches this state. The kernel will construct one and will not notice a later balance drop. A pre-activation ban, a continuous balance check, and an explicit "lock is not balance" invariant are different repairs. None of them is authorized here. Adding a check before acceptance would change the counterexample instead of recording it.

## Recommendation

The kernel must not treat `collateralLocked` as equal to the token balance for a rebasing token. Acceptance is not granted. Do not edit the kernel until this ADR is accepted. The counterexample stays `COUNTEREXAMPLE_FOUND`.

## Confidence

Medium. One test-only token, one `split(100)`, and one `rebaseDown` of 1 were measured. That shows the divergence. It does not classify every rebase schedule or a post-resolution redemption.

## What would falsify this

A later measurement on this kernel where the same `rebaseDown` of 1 moves `collateralLocked` or `liability()` with the token balance. Or an explicit acceptance of another option, including a named repair that keeps the token balance at least equal to the reported liability. Silence does not accept this proposal.
