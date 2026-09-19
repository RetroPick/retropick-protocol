---
id: LP-SC-TOKEN
type: normative_implementation
status: ready
owner: launchpad-solidity
product: launchpad
version: v2
---

# Token and Supply

## CURRENT
RetroPickLauncherTokenV2 is a fixed-supply ERC20. Current constructor mints the declared supply to the launch curve. Metadata/social fields are stored with bounded input enforced by deployer/factory.

## TARGET
Preserve fixed/capped P0 semantics. No hidden arbitrary mint authority. Any future allocation split requires an explicit protocol change.

## Requirements
- supply >= protocol minimum;
- supply fits downstream accounting limits;
- minted supply reconciles exactly;
- decimals are stable and explicit;
- burn behavior cannot create a hidden reserve deficit;
- creator reference metadata grants no token privilege.

## Tests
Constructor, supply bounds, metadata bounds, burn behavior and ownership/privilege absence.
