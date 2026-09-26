# ADR-R08: backingRaw is not the rebasing component token balance

**Status:** PROPOSED  
**Date:** 2026-09-26

Acceptance is not granted. This file does not authorize a rebase guard, a new balance check, a change to `requiredRaw`, or any other edit to `CandidateComponentBacking`. The kernel must not be edited to implement this recommendation until this ADR is explicitly accepted.

ADR-R02 remains the proposal that mint and redeem use the requirement delta. ADR-R02 does not cite a post-mint balance decrease and does not record that `backingRaw` can stay at the credited amount while the token balance falls. This record does not supersede ADR-R02. ADR-P09 stays the prediction collateral record and is not changed by this file.

## Decision

Propose that the kernel must not treat `backingRaw` as equal to the component token balance for a rebasing token. Until acceptance, leave the measured kernel as it is: after `deposit` of 100 and `mint` of 100, a later balance decrease of 1 leaves `backingRaw` at 100.

## Options

Leave the kernel as measured. `CandidateComponentBacking` credits `backingRaw` from the deposit receipt and later reads that stored amount in `mint` and `redeem`. It has no rebase function.

Or, after acceptance, stop treating `backingRaw` as equal to the live token balance for a rebasing token. That recommendation does not choose a repair. It does not add a guard in this proposal.

## Evidence

`evidence/research/prism/rebasing-component-backing-2026-09-26.json`.

The kernel has no rebase function. A test-only token completed `deposit` of 100 and `mint` of 100 on one component with weight `10^18` and 18 decimals. Token balance, `backingRaw`, supply, and `requiredRaw(100)` were 100. `rebaseDown` of 1 then changed the token balance without `transfer` or `transferFrom`. Token balance became 99. `backingRaw` stayed 100. Supply stayed 100. `requiredRaw(supply)` stayed 100. Default profile, forge 1.8.3, solc 0.8.26, optimizer 200, via IR off. The focused test passed 1 and failed 0, gas 663233. Classification `COUNTEREXAMPLE_FOUND`. The kernel was not edited.

## Benchmark

Not a gas study. The figure above is the recorded test gas for construction, deposit, mint, and the balance decrease. No separate cost was measured for a rebase guard.

## Security implications

After the decrease, the token balance is below both the recorded backing and `requiredRaw`, while the kernel still reports `backingRaw` of 100. The series supply stays 100. This is an insolvent divergence between the live token balance and the amount the kernel records. It is not a change to the payout formula and it is not MATH-1 PASS.

## Tradeoffs

The deposit path already checks the balance delta at the moment of `transferFrom`. A later rebase does not call that path. A continuous balance check, a ban on rebasing components, and an explicit "backing is not balance" invariant are different repairs. None of them is authorized here. Adding a check before acceptance would change the counterexample instead of recording it.

## Recommendation

The kernel must not treat `backingRaw` as equal to the component token balance for a rebasing token. Acceptance is not granted. Do not edit the kernel until this ADR is accepted. The counterexample stays `COUNTEREXAMPLE_FOUND`.

## Confidence

Medium. One test-only token, one `deposit` of 100, one `mint` of 100, and one `rebaseDown` of 1 were measured. That shows the divergence. It does not classify every weight, decimal, or rebase schedule.

## What would falsify this

A later measurement on this kernel where the same `rebaseDown` of 1 moves `backingRaw` or `requiredRaw` with the token balance. Or an explicit acceptance of another option, including a named repair that keeps the token balance at least equal to the recorded backing and to `requiredRaw`. Silence does not accept this proposal.
