---
id: LP-SC-FEES
type: normative_implementation
status: ready
owner: launchpad-solidity
product: launchpad
version: v2
---

# Fees and Buyback

## CURRENT
V2 separates base curve fee, creator trade tax and policy-driven protocol/buyback slices. The factory snapshots fee policy per launch.

## TARGET
Retain only fee/buyback behavior accepted by P0 economics. Kuru venue fees remain separate from bonding fees.

## Accounting requirements
For every trade:
`user transfer = reserve delta + creator allocation + protocol allocation + buyback allocation + explicitly defined rounding residual`.

No fee category may be counted as graduation reserve.

## Tests
Boundary BPS, combined fee cap, disabled/enabled buyback, sweep behavior, thin-liquidity buyback fallback and claim recipient changes.
