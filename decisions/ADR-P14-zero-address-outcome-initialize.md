# ADR-P14: Zero-address outcome initialize

**Status:** PROPOSED  
**Date:** 2026-09-26

Acceptance is not granted. This file does not authorize an edit to `CloneableOutcomeToken.initialize`, `split`, `merge`, `redeem`, `burn`, or any payout formula. The initializer must not be edited until this ADR is explicitly accepted.

## Decision

Propose that the zero-address initialize stays recorded and that `CloneableOutcomeToken.initialize` is not edited until a human accepts one rule. The open decision is whether Phase-1 initialize must reject the zero market address, or a zero market is allowed until a later call. This proposal does not choose that winner and does not change code.

## Options

Leave initialize as measured. `initialize(address(0), 1, "No", "NO", 18)` succeeds. `_initialized` becomes true. `market` is the zero address. `outcomeIndex` is 1. `decimals` is 18. `totalSupply` stays 0.

Or, after acceptance, make initialize reject the zero market address. That would stop the call before `_initialized` becomes true.

Or, after acceptance, allow a zero market until a later call. This proposal does not choose that option.

## Evidence

`evidence/research/prediction/zero-address-initialize-2026-09-26.json`.

`CloneableOutcomeToken.initialize(address(0), 1, "No", "NO", 18)` succeeds. Before the call, `_initialized` is false, `market` is the zero address, `outcomeIndex` is 0, `decimals` is 0, and `totalSupply` is 0. After the call, `_initialized` is true, `market` is the zero address, `outcomeIndex` is 1, `decimals` is 18, and `totalSupply` stays 0. The initializer writes `_initialized`, `market`, `outcomeIndex`, `name`, `symbol`, and `_decimals`. It writes no supply field. `name` becomes `No` and `symbol` becomes `NO`.

Python has no counterpart. `research/prediction-model` has no `initialize` and no `CloneableOutcomeToken`. No split or redeem was run. Classification is `recorded_finding`. The initializer was not changed. This is not a theorem pass. MATH-1 stays FAIL. PRED-MATH-1 stays partial. PRED-CONTRACT-1 stays not_pass. S-P16 stays open. PRED-KURU-1 stays blocked. Default profile, forge 1.8.3, solc 0.8.26. The focused test passed 1 and failed 0, gas 228257.

## Benchmark

Not a gas study. The figure above is the recorded test gas for this initialize. No separate cost was measured for a zero-address guard.

## Security implications

The call stores the zero address in `market` and marks the token initialized. `totalSupply` stays 0. No split or redeem was run, so this witness does not show a payout above locked collateral. Editing the initializer before acceptance would erase the recorded finding.

## Tradeoffs

The measured function stores `address(0)` and sets `_initialized`. Python has no counterpart, so the two sides do not disagree on an integer balance. Choosing a reject-at-initialize rule or an allow-until-a-later-call rule requires an edit or an explicit acceptance. Leaving the initializer unchanged preserves the witness. The decision stays open until a human accepts one rule.

## Recommendation

Do not edit `CloneableOutcomeToken.initialize`. Acceptance is not granted. The decision stays open until a human accepts one of the two rules above.

## Confidence

High for this draft. One Solidity call was measured on a fresh `CloneableOutcomeToken`. Python has no counterpart. That does not classify initialize with a nonzero market, and it does not classify a later mint, split, or redeem.

## What would falsify this

A later measurement where `initialize(address(0), 1, "No", "NO", 18)` reverts and leaves `_initialized` false, `outcomeIndex` 0, `decimals` 0, and `totalSupply` 0. Or a later measurement where the same call stores a nonzero market. Or a later split or redeem that pays collateral that was not locked. Or an explicit acceptance of one rule together with an edit of the initializer. Either result replaces this proposal. Silence does not accept it.
