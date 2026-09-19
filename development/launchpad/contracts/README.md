---
id: LP-SC-ROOT
type: normative_implementation
status: ready
owner: launchpad-solidity
product: launchpad
version: v2
---

# Launchpad V2 Contract Development

## WHY
Qualify the current V2 launch core, then migrate only the venue-specific graduation boundary from Uniswap V4 to Kuru.

## WHERE
`contracts/src/v2/**`, `contracts/test/**`, `contracts/script/**`.

## WHAT
Factory, token, bonding curve, fee/buyback accounting, quote policy, graduation state machine and Kuru-specific destination integration.

## WHAT NOT
Do not make Doorway a P0 dependency. Do not silently change V1. Do not alter accepted bonding math while replacing the destination venue.

## VERIFY
Dedicated V2 unit, fuzz, stateful invariant and integration suites; forge format/build; Slither/Aderyn/Solhint; live Kuru integration where required.

## HANDOFF
ABI bundle, event catalog, deployment manifest and contract test report.
