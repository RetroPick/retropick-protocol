# ADR-P15: Prediction redeem entry points differ

**Status:** PROPOSED  
**Date:** 2026-09-26

Acceptance is not granted. This file does not authorize an edit to `PredictionMarket.split`, `PredictionMarket.merge`, `PredictionMarket.redeemYes`, `PredictionMarket.redeemNo`, `PredictionMarket.archive`, the Python `PredictionMarket.redeem` function, or any payout formula. Neither implementation may be edited to add or remove a redeem entry point until this ADR is explicitly accepted.

ADR-P11, ADR-P12, ADR-P13, and ADR-P14 stay PROPOSED. This file does not edit them and does not reopen their subjects. ADR-P13 stays the archive-from-DRAFT record. ADR-P11 stays the uint256 domain. ADR-P12 stays the configured maximum. ADR-P14 stays the zero-address initialize.

## Decision

Propose that the measured name lists stay recorded and that neither redeem entry point is edited until a human accepts one rule. The open decision is whether Phase-1 must expose one `redeem` with a side, or two functions `redeemYes` and `redeemNo`. This proposal does not choose that winner and does not change code.

## Options

Leave both sides as measured. Solidity state-changing names are `activate`, `cancelDraft`, `split`, `merge`, `closeMint`, `beginResolution`, `resolve`, `openRedemption`, `redeemYes`, `redeemNo`, `burnWorthless`, and `archive`. Python state-changing names are `activate`, `cancel_draft`, `split`, `merge`, `close_mint`, `begin_resolution`, `resolve`, `open_redemption`, `redeem`, `burn_worthless`, and `archive`.

Or, after acceptance, give Python `redeemYes` and `redeemNo`. This proposal does not choose that option.

Or, after acceptance, give Solidity one `redeem` with a side. This proposal does not choose that option.

## Evidence

`research/contract-kernels/src/prediction/PredictionMarket.sol`.  
`research/prediction-model/market.py`.

Views and constructors are omitted. Solidity `liability` is a view. Python `liability`, `_amt`, `_payout`, `clone`, and `_guarded` do not write market balances. Python `try_replace_spec`, `admin_mint`, `admin_withdraw`, and `pause_redemption` raise before any assignment, so they are outside the state-changing list. `_enter` and `_leave` toggle a reentrancy flag. `_bal` can insert a zero balance. Solidity `_redeem` is the internal body of `redeemYes` and `redeemNo`. Those helpers are not extra public names.

Spelling pairs, with both spellings recorded: `activate`/`activate`, `cancelDraft`/`cancel_draft`, `split`/`split`, `merge`/`merge`, `closeMint`/`close_mint`, `beginResolution`/`begin_resolution`, `resolve`/`resolve`, `openRedemption`/`open_redemption`, `burnWorthless`/`burn_worthless`, `archive`/`archive`.

Unmatched after those pairs: Solidity `redeemYes` and `redeemNo`. Python `redeem`. Solidity does not declare `redeem`. Python does not declare `redeemYes` or `redeemNo`. No function was added.

This comparison is not PRED-CONTRACT-1 PASS and not MATH-1 PASS. MATH-1 stays FAIL. S-P16 stays open.

## Benchmark

Not a gas study. No function was added, so no gas was measured for a renamed redeem entry point.

## Security implications

Both sides can redeem YES and NO while the market is redeemable. Solidity exposes that as `redeemYes` and `redeemNo`. Python exposes it as `redeem` with a side. Adding either missing name before acceptance would replace the measured lists. The payout formula was not compared again here.

## Tradeoffs

Ten operations already have a spelling pair. The redeem operation is the remaining gap, and it is a split of one name into two entry points rather than a missing payout. Matching the names requires an edit. Leaving both sides unchanged preserves the measured lists. The open decision stays open until a human accepts one rule.

## Recommendation

Do not edit `redeemYes`, `redeemNo`, or Python `redeem`. Do not add a function. Acceptance is not granted. The open decision stays open until a human accepts one of the two rules above.

## Confidence

High for this draft. The Solidity contract and the Python class were read for state-changing names, excluding views and constructors. That does not measure a later edit.

## What would falsify this

A later reading where Solidity declares `redeem`, or where Python declares `redeemYes` and `redeemNo`, or where one of those three names is removed. Or an explicit acceptance of one rule together with an edit of an implementation. Either result replaces this proposal. Silence does not accept it.
