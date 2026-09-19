---
id: LP-SC-KURU-GRAD
type: normative_implementation
status: blocked_external_verification
owner: launchpad-solidity
product: launchpad
version: v2
---

# Graduation to Kuru

## CURRENT
Factory uses a two-phase V4 process: secure/sweep curve assets, then retryable pool creation. This safety property is valuable even though the venue is changing.

## TARGET
```text
ACTIVE
 -> GRADUATION_READY
 -> secure assets / freeze primary market
 -> GRADUATING
 -> call validated Kuru market creation/configuration
 -> verify market identifier/address
 -> GRADUATED
```

## Failure rule
If Kuru creation/configuration fails, secured assets remain accounted and the destination step is retryable. No normal bonding trade resumes after the curve has entered the secured graduation phase unless an explicitly designed recovery state authorizes it.

## External verification pin
Verified public references on 2026-09-20:
- Kuru SDK `main`: `636509c2eafd63479d3f399703354e0d09f51e18` (package version commit message 0.0.97).
- Kuru contracts public `main`: `2060bb2736080c175d80d568bfdb6226bb5abd04`.

The integration agent must inspect the concrete router/market deployment ABI and target Monad deployment addresses before this document can become READY.

## Required test
Destination revert, duplicate call, wrong parameter, wrong quote, partial transfer, and retry success.
