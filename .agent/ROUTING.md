# Universal Agent Routing

RetroPick is one Launchpad platform with shared product infrastructure and independently qualified financial modules.

## Platform work

| Work | Role | Canonical lane |
|---|---|---|
| product/platform architecture | product/orchestrator | docs/platform/ |
| current-source production research | production-research | research/production/ |
| general external research | research | research/ |
| shared validation | validation | evidence/ + owning gate |

## Launchpad Core

| Work | Role file | Canonical implementation lane |
|---|---|---|
| planning/control | .agent/agents/launchpad-planner.md | development/launchpad/ |
| Solidity | .agent/agents/launchpad-solidity.md | development/launchpad/contracts/ |
| integrations/Kuru | .agent/agents/launchpad-integrations.md | development/launchpad/integrations/ |
| indexer | .agent/agents/launchpad-indexer.md | development/launchpad/indexing/ |
| backend | .agent/agents/launchpad-backend.md | development/launchpad/backend/ |
| frontend | .agent/agents/launchpad-frontend.md | development/launchpad/frontend/ |
| security | .agent/agents/launchpad-security.md | development/launchpad/security/ |
| QA/E2E | .agent/agents/launchpad-qa.md | development/launchpad/testing/ |
| CI/deploy/ops | .agent/agents/launchpad-devops.md | development/launchpad/devops/ |

Launchpad-Core canonical reading starts at docs/launchpad/README.md.

## Prediction + PRISM incubation

Use generic protocol/research/security/validation roles and route through:
- docs/prism/README.md;
- docs/prism/protocol/;
- docs/prism/math/;
- research/prism-model/;
- research/prism/;
- PRISM phase gates.

## Shared rule

Shared product infrastructure does not make module financial models interchangeable.

No specialist silently redefines another module's canonical financial interface. Cross-module financial changes require explicit scope and normally an ADR.
