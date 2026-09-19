---
id: LP-SC-TEST
type: normative_implementation
status: ready
owner: launchpad-qa
product: launchpad
version: v2
---

# Contract Test Plan

## Unit
Factory config/launch, token supply, buy, sell, min-out, fees, creator tax, buyback, anti-snipe, quote admission, economics pin, graduation transitions, recovery and ACL.

## Fuzz
amountIn/out, reserve domains, fee boundaries, decimals, threshold crossing and integer rounding.

## Stateful invariants
Implement LP-I-001..012 with handlers that exercise buy/sell/config/graduation sequences.

## Integration
Factory -> deployer -> curve/token -> trades -> threshold -> secure graduation -> Kuru destination.

## Adversarial
fee-on-transfer/rebasing/callback token rejection, reentrancy, malicious destination revert, repeated graduation, CREATE2 collision, admin abuse and boundary overflows.

Existing Doorway tests are outside this qualification set.
