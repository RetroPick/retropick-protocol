# ADR-R18: The candidate has no exact replication check

**Status:** PROPOSED  
**Date:** 2026-09-26

Acceptance is not granted. This file does not authorize an edit to `find_exact_nonnegative_replication`, `is_exactly_replicable`, `CandidateComponentBacking.mint`, `CandidateCumulativeSettlement.redeem`, or any payout. Neither implementation may be edited to add a replication solver until this ADR is explicitly accepted.

This ADR does not supersede ADR-R17. ADR-R17 records the missing terminal-state solvency check. This file does not restate that measurement and does not edit ADR-R17. ADR-R01 stays the confirmation that exact non-negative replication still stands. This file does not weaken `h = Gx`, `x >= 0`, and it does not open approximate replication. ADR-R09 through ADR-R17 stay PROPOSED. This file does not edit them.

The witness `evidence/research/prism/replication-check-2026-09-26.json` stays `recorded_gap`. This file does not reclassify it.

## Decision

Propose that the measured replication gap stays recorded and that no solver is added until a human accepts one rule. The open decision is whether Phase-1 must add an exact non-negative replication check to the candidate, or that check stays only on the Python replication module. This proposal does not choose that winner and does not change code.

## Options

Leave both sides as measured. Python accepts the exact component target `[0, 1, 0, 1]` with weights `0` and `1`. Python rejects the known target `[0, 0, 0, 1]`. The candidate kernels have no replication check, so neither case was executed there.

Or, after acceptance, add that exact check to the candidate. This proposal does not choose that option.

Or, after acceptance, leave that check only on the Python replication module. This proposal does not choose that option.

## Evidence

`evidence/research/prism/replication-check-2026-09-26.json`.  
`research/prism-model/tests/test_replication.py`.  
`research/contract-kernels/src/prism/CandidateComponentBacking.sol`.  
`research/contract-kernels/src/prism/CandidateCumulativeSettlement.sol`.

The matrix is `[[0, 0], [0, 1], [1, 0], [1, 1]]`. `find_exact_nonnegative_replication` on `[0, 1, 0, 1]` returns `(0, 1)`. `is_exactly_replicable` is true. The same function on `[0, 0, 0, 1]` returns none. `is_exactly_replicable` is false.

No candidate function solves `h = Gx` with `x >= 0`. `CandidatePayoffTransform.payoffOf` reads a stored entry. It is not a solver and it was not called. No function was added. Approximate replication was not added.

Classification of that witness is `recorded_gap`. R-I01 has no Foundry edge. MATH-1 stays FAIL.

## Benchmark

Not a gas study of a new function. The recorded absence log passed 1 and failed 0, gas 7328. No solver was added.

## Security implications

Python refuses a target that no non-negative basket pays exactly. The candidate cannot accept or reject that target because it has no check. Adding an approximate fit before acceptance would mint a claim the basket does not pay.

## Tradeoffs

Adding the exact check would let the candidate refuse the known unreplicable target. Leaving the check in Python preserves the measured kernels. The open decision stays open until a human accepts one rule.

## Recommendation

Do not add a replication solver. Do not add a payoff matrix. Do not treat an approximate replication as Phase 1. Do not edit `mint` or any payout. Acceptance is not granted. The open decision stays open until a human accepts one of the two rules above. This ADR does not supersede ADR-R17.

## Confidence

High for this draft. The two Python cases were executed and the candidate sources have no replication check. That does not choose a later design.

## What would falsify this

A later reading of a candidate kernel that solves these two targets. Or a later Python run where the exact target is rejected or the known target returns a non-negative solution. Or an explicit acceptance of one rule together with an edit of an implementation. Either result replaces this proposal. Silence does not accept it.
