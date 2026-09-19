---
id: LP-DOC-ROOT
type: normative
product: launchpad
version: v2
status: active
---

# RetroPick Launchpad Core V2

This directory is the canonical WHAT/WHY layer for the established RetroPick Launchpad Core. Implementation architecture is under development/launchpad/.

Launchpad Core belongs to the wider RetroPick Launchpad platform defined under ../platform/.

## Goal

~~~text
CREATE
-> fixed/capped ERC20
-> bonding primary market
-> demand/liquidity formation
-> safe graduation
-> Kuru mature market
~~~

## Authority

1. accepted ADRs;
2. these product/protocol documents;
3. development/launchpad/ implementation specifications;
4. local agent contracts/tasks;
5. implementation.

## Read by work type

- product/frontend: PRODUCT.md, USER_FLOWS.md, SYSTEM_ARCHITECTURE.md;
- Solidity: PROTOCOL.md, economic specs, STATE_MACHINE.md, INVARIANTS.md, SECURITY.md;
- integrations: INTEGRATIONS.md, KURU.md, MONAD.md;
- release: PRODUCTION_REQUIREMENTS.md, hackathon docs as applicable.

## Prediction and PRISM

Prediction and PRISM are independently qualified financial modules of the same RetroPick Launchpad platform.

They are isolated under ../prism/ during incubation so they cannot inherit Launchpad-Core production status or alter Launchpad-Core economics before their own gates pass.
