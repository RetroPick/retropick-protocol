# ADR-R17: The candidate has no terminal-state solvency check

**Status:** PROPOSED  
**Date:** 2026-09-26

Acceptance is not granted. This file does not authorize an edit to `PrismSeries.terminal_solvency`, `PrismSeries.mint_with_exact_backing`, `CandidateComponentBacking.mint`, `CandidateCumulativeSettlement.redeem`, or any payout. Neither implementation may be edited to add terminal states until this ADR is explicitly accepted.

This ADR does not supersede ADR-R15 or ADR-R16. ADR-R15 records the missing lifecycle reopen. ADR-R16 records the missing final-resolution commit. Neither states this solvency gap. This file does not edit them. ADR-R09 through ADR-R16 stay PROPOSED.

The witness `evidence/research/prism/terminal-solvency-2026-09-26.json` stays `recorded_gap`. This file does not reclassify it.

## Decision

Propose that the measured terminal-solvency gap stays recorded and that no terminal-state function is added until a human accepts one rule. The open decision is whether Phase-1 must add the Python terminal-state check to the candidate, or that check stays only on `PrismSeries.terminal_solvency`. This proposal does not choose that winner and does not change code.

## Options

Leave both sides as measured. Python `mint_with_exact_backing(1000)` leaves supply 1000, backing 600 and 400, and required backing 600 and 400. `terminal_solvency` passes on states 0, 1, 2, and 3. `CandidateComponentBacking` and `CandidateCumulativeSettlement` have no payoff matrix and no terminal states, so that check was not executed.

Or, after acceptance, add the Python terminal-state check to the candidate. This proposal does not choose that option.

Or, after acceptance, leave that check only on `PrismSeries.terminal_solvency`. This proposal does not choose that option.

## Evidence

`evidence/research/prism/terminal-solvency-2026-09-26.json`.  
`research/prism-model/model.py`.  
`research/prism-model/tests/test_model.py`.  
`research/contract-kernels/src/prism/CandidateComponentBacking.sol`.  
`research/contract-kernels/src/prism/CandidateCumulativeSettlement.sol`.

The Python book is payoff rows `[[0, 1], [0, 0], [1, 1], [1, 0]]` and weights `3/5` and `2/5`. After activation and `mint_with_exact_backing(1000)`, supply is 1000, backing is 600 and 400, and `required_backing` is 600 and 400. The terminal payoff vector is `2/5`, `0`, `1`, and `3/5`. The four solvency rows are backing value and liability `(400, 400)`, `(0, 0)`, `(1000, 1000)`, and `(600, 600)`. Each backing value is at least the liability.

`CandidateComponentBacking` checks `requiredRaw` per component. `CandidateCumulativeSettlement` checks `ceilFunding` and a `redeemable` bool. Neither stores the four terminal states. No function was added.

Classification of that witness is `recorded_gap`. R-I06 has no Foundry edge. MATH-1 stays FAIL.

## Benchmark

Not a gas study of a new function. The recorded absence log passed 1 and failed 0, gas 7605. No terminal-state function was added.

## Security implications

Python checks every still-possible terminal world. The named candidates cannot run that check because they have no such states. Adding the states before acceptance would replace the measured kernels.

## Tradeoffs

Adding the check would let the candidate compare terminal backing value with terminal liability. Leaving it on `PrismSeries` preserves the measured kernels. The open decision stays open until a human accepts one rule.

## Recommendation

Do not add terminal states. Do not edit `mint`, `redeem`, or any payout. Acceptance is not granted. The open decision stays open until a human accepts one of the two rules above. This ADR does not supersede ADR-R15 or ADR-R16.

## Confidence

High for this draft. The Python rows were executed and the two candidate sources have no terminal states. That does not choose a later design.

## What would falsify this

A later reading of `CandidateComponentBacking` or `CandidateCumulativeSettlement` that stores these four terminal states and checks backing value against liability. Or a later Python run of this book where a terminal row has backing value below liability. Or an explicit acceptance of one rule together with an edit of an implementation. Either result replaces this proposal. Silence does not accept it.
