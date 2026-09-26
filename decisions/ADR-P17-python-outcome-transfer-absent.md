# ADR-P17: Python has no outcome-token transfer

**Status:** PROPOSED  
**Date:** 2026-09-26

Acceptance is not granted. This file does not authorize an edit to `OutcomeToken.transfer`, `PredictionMarket.redeemYes`, `PredictionMarket.redeemNo`, the Python `redeem` function, liability, or any payout formula. Neither implementation may be edited to add a transfer function until this ADR is explicitly accepted.

ADR-P09 stays PROPOSED. It records that `collateralLocked` is not the rebasing collateral token balance. It does not state that the Python reference has no outcome-token transfer, and it does not authorize a book edit before redeem. This file does not edit ADR-P09 and does not supersede it.

ADR-P15 and ADR-P16 stay PROPOSED. ADR-P15 stays the redeem entry-point name list. ERC-20 `transfer` is not one of those market names. ADR-P16 stays the four Python admin stubs. This file does not edit them.

## Decision

Propose that the measured absence stay recorded and that neither side is edited until a human accepts one rule. The open decision is whether Phase-1 Python must expose an outcome-token transfer, or a differential witness may edit outcome books before redeem. This proposal does not choose that winner and does not change code.

The book edit in the cited witness is not a payout contradiction. The witness stays `existing_rule`.

## Options

Leave both sides as measured. Python `PredictionMarket` has no transfer function and stores no per-account collateral balance. Solidity `OutcomeToken` is an ERC-20, so `transfer` moves a holder balance. A differential witness may move units on the Python outcome books before redeem. After that edit, the redeem integers in the cited witness matched.

Or, after acceptance, add a transfer function to the Python model. This proposal does not choose that option.

Or, after acceptance, treat the book edit as a payout disagreement and reclassify the witness. This proposal does not choose that option.

## Evidence

`evidence/research/prediction/transferred-yes-redeem-2026-09-26.json`.  
`research/prediction-model/market.py`.  
`research/contract-kernels/src/prediction/OutcomeToken.sol`.

Account A splits 4 and transfers 1 YES to account B. The market resolves `YES_WIN`. B redeems 1 YES.

Python has no transfer function. The witness moves 1 YES from alice to bob on the outcome balance books, then calls `redeem` of the YES side from bob. Python stores no per-account collateral balance. The redeem return is 1, and the account argument is bob.

Solidity `OutcomeToken` inherits ERC-20 `transfer`. The witness calls `yesToken.transfer` for 1 YES from A to B, then `redeemYes(1)` from B. The payout is 1 collateral unit to B. A's collateral balance stays 999996. B's collateral balance moves from 0 to 1.

Before the redeem, both sides have liability 4, collateral locked 4, YES supply 4, NO supply 4, YES redeemed cursor 0, and NO redeemed cursor 0. After it, both sides have liability 3, collateral locked 3, YES supply 3, NO supply 4, YES redeemed cursor 1, and NO redeemed cursor 0. Liability stays equal to collateral locked. Those redeem integers matched after the book edit.

Classification stays `existing_rule`. The book edit is not a payout contradiction. Transfer, liability, and redeem were not edited. This is not PRED-CONTRACT-1 PASS and not MATH-1 PASS. MATH-1 stays FAIL. S-P16 stays open.

## Benchmark

Not a gas study. No transfer function was added, so no gas was measured for a new Python transfer.

## Security implications

Solidity pays the holder who redeems the transferred YES token. The Python redeem pays the named account after the witness has already moved that YES balance. The matched integers are the payout, liability, collateral locked, both supplies, and both redeemed cursors. Adding a Python transfer before acceptance would replace the measured absence. Reclassifying the witness before acceptance would treat a book edit as a payout disagreement the redeem integers do not show.

## Tradeoffs

The reference model keeps outcome balances as the books a transfer would update, and it has no transfer function. The kernel's outcome token is transferable. A witness can edit those books and then compare redeem. Matching the function names requires an edit. Leaving both sides unchanged preserves the measured redeem. The open decision stays open until a human accepts one rule.

## Recommendation

Do not add a transfer function to the Python model. Do not edit `OutcomeToken.transfer` or redeem. Do not reclassify `transferred-yes-redeem-2026-09-26.json`. The book edit is not a payout contradiction. Acceptance is not granted. The open decision stays open until a human accepts one of the rules above.

## Confidence

High for this draft. The cited witness already recorded the book edit, the Solidity transfer, and the matching redeem integers. Python `market.py` was read and has no `transfer`. `OutcomeToken` inherits ERC-20. That does not measure a later edit.

## What would falsify this

A later reading where Python `PredictionMarket` declares a transfer function. Or a later reading where `OutcomeToken` is not transferable. Or a later redeem of this same path whose payout, liability, collateral locked, supplies, or redeemed cursors differ between the two sides. Or an explicit acceptance of one rule together with an edit of an implementation. Either result replaces this proposal. Silence does not accept it.
