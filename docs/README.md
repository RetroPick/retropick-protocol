# RetroPick Documentation

RetroPick documentation is organized around one platform with independently qualified financial modules.

~~~text
docs/
├── platform/     umbrella product/platform architecture
├── launchpad/    established Launchpad Core
└── prism/        incubating Prediction + PRISM module
~~~

## Platform

Start with:
- platform/README.md
- platform/PRODUCT_ARCHITECTURE.md
- platform/MODULE_MODEL.md
- platform/MODULE_PROMOTION.md

Platform docs define shared product identity, shared infrastructure and module admission. They do not replace module financial specifications.

## Launchpad Core

Canonical WHAT/WHY:
- launchpad/README.md
- launchpad/PRODUCT.md
- launchpad/PROTOCOL.md
- launchpad/INVARIANTS.md
- launchpad/SYSTEM_ARCHITECTURE.md
- launchpad/KURU.md

Engineering HOW:
- ../development/launchpad/README.md

## Prediction + PRISM

PRISM belongs to the RetroPick Launchpad roadmap but remains independently qualified.

Canonical entry:
- prism/README.md
- prism/00-context/EXECUTIVE_SUMMARY.md
- prism/protocol/PRISM_PROTOCOL_SPEC.md
- prism/math/README.md
- ../research/prism-model/README.md

## Boundary rule

One product does not imply one accounting model.

Shared infrastructure may converge. Contract economics, collateral rules, lifecycle invariants and security proofs remain module-specific unless an accepted ADR explicitly changes that boundary.
