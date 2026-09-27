# ADR-P16: Python admin stubs raise and are absent from the market

**Status:** PROPOSED  
**Date:** 2026-09-26

Acceptance is not granted. This file does not authorize an edit to `PredictionMarket.split`, `PredictionMarket.merge`, `PredictionMarket.redeemYes`, `PredictionMarket.redeemNo`, `PredictionMarket.archive`, the Python `try_replace_spec` function, the Python `admin_mint` function, the Python `admin_withdraw` function, the Python `pause_redemption` function, or any payout formula. Neither implementation may be edited to add these four operations until this ADR is explicitly accepted.

ADR-P15 stays PROPOSED. Its mention of these four names is the reason they were left off the state-changing list. This file does not edit ADR-P15 and does not reopen the redeem entry-point choice.

## Decision

Propose that the measured raises stay recorded and that neither side is edited until a human accepts one rule. The open decision is whether Phase-1 must add `try_replace_spec`, `admin_mint`, `admin_withdraw`, and `pause_redemption`, or they stay Python stubs that raise. This proposal does not choose that winner and does not change code.

## Options

Leave both sides as measured. After `split` of 4 on an open market, each Python call raises and collateral, YES supply, and NO supply stay 4. `PredictionMarket.sol` declares none of the four names.

Or, after acceptance, add the four operations to the Solidity market. This proposal does not choose that option.

Or, after acceptance, keep the four names as Python stubs that raise. This proposal does not choose that option.

## Evidence

`evidence/research/prediction/python-stub-rejects-2026-09-26.json`.  
`research/prediction-model/market.py`.  
`research/contract-kernels/src/prediction/PredictionMarket.sol`.

The market is integer, collateral `COLL`, dust sink `SINK`. `activate_binary` opens it. `split` of 4 credits collateral 4, YES supply 4, and NO supply 4. The state is OPEN.

`try_replace_spec` raises `resolution spec is immutable after activation`. Collateral, YES supply, and NO supply stay 4.

`admin_mint` raises `no admin mint`. Those three figures stay 4.

`admin_withdraw` raises `no admin withdrawal of collateral`. Those three figures stay 4.

`pause_redemption` raises `Phase-1 has no redemption pause`. Those three figures stay 4.

`PredictionMarket.sol` does not declare `try_replace_spec`, `admin_mint`, `admin_withdraw`, or `pause_redemption`. No function was added.

Classification is `recorded_gap`. This is not PRED-CONTRACT-1 PASS and not MATH-1 PASS. MATH-1 stays FAIL. S-P16 stays open.

## Benchmark

Not a gas study. No Solidity function was added, so no gas was measured for these four names.

## Security implications

The Python stubs reject a spec replacement, an admin mint, an admin withdrawal, and a redemption pause. The open market keeps collateral 4 and both supplies 4. The Solidity market has no function under those names, so those calls cannot be made there. Adding any of them before acceptance would replace that measured absence.

## Tradeoffs

Python names the four operations and rejects them before assignment. Solidity omits the names. Matching the Python names on the kernel requires an edit. Leaving both sides unchanged preserves the measured raises and the missing declarations. The open decision stays open until a human accepts one rule.

## Recommendation

Do not add `try_replace_spec`, `admin_mint`, `admin_withdraw`, or `pause_redemption` to `PredictionMarket.sol`. Do not edit the Python stubs. Acceptance is not granted. The open decision stays open until a human accepts one of the two rules above.

## Confidence

High for this draft. Each of the four calls was run once after `split` of 4. The Solidity source was searched for the four names. That does not measure a later edit.

## What would falsify this

A later call where one of the four changes collateral, YES supply, or NO supply. Or a later reading of `PredictionMarket.sol` that declares one of the four names. Or an explicit acceptance of one rule together with an edit of an implementation. Either result replaces this proposal. Silence does not accept it.
