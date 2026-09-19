# Smart Contract Test Plan

**Status:** ACTIVE  
**Owner:** Smart Contracts + Validation

## Unit

Token creation/supply/metadata, curve initialization, buy, sell, slippage, fees, creator/buyback accounting, quote admission, anti-snipe behavior, graduation readiness, sweep/create/retry/rescue and access control.

## Fuzz

`amountIn`, `amountOut`, reserves, fee BPS, quote decimals, threshold boundaries, near-terminal inventory and integer rounding.

## Stateful invariants

- total supply follows token model;
- actual reserves/fees reconcile all transfers;
- no unauthorized mint/reserve seizure;
- total fee bounds hold;
- graduation assets cannot disappear;
- graduation cannot execute twice;
- terminal state does not reopen primary trading;
- quote policy cannot be bypassed.

## Adversarial

Malicious ERC-20, fee-on-transfer, rebasing/callback behavior, reentrancy attempts, front-running threshold crossing, slippage/sandwich conditions, CREATE2 collision, admin misuse and destination-market failure.

## V2

Create dedicated `test/v2/` coverage or an equivalent convention before V2 semantic divergence is release-qualified.
