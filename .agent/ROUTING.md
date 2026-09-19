# Universal Agent Routing

## Launchpad

| Work | Role file | Canonical implementation lane |
|---|---|---|
| planning/control | `.agent/agents/launchpad-planner.md` | `development/launchpad/` |
| Solidity | `.agent/agents/launchpad-solidity.md` | `development/launchpad/contracts/` |
| integrations/Kuru | `.agent/agents/launchpad-integrations.md` | `development/launchpad/integrations/` |
| indexer | `.agent/agents/launchpad-indexer.md` | `development/launchpad/indexing/` |
| backend | `.agent/agents/launchpad-backend.md` | `development/launchpad/backend/` |
| frontend | `.agent/agents/launchpad-frontend.md` | `development/launchpad/frontend/` |
| security | `.agent/agents/launchpad-security.md` | `development/launchpad/security/` |
| QA/E2E | `.agent/agents/launchpad-qa.md` | `development/launchpad/testing/` |
| CI/deploy/ops | `.agent/agents/launchpad-devops.md` | `development/launchpad/devops/` |

Launchpad canonical reading starts at `docs/launchpad/README.md`.

## Prediction + PRISM

Use existing generic roles under `.agent/agents/` and route through:
- `docs/prism/README.md`;
- protocol/math docs;
- PRISM phase gates;
- `research/prism-model/`.

## Shared rule

No specialist silently redefines another specialist's canonical interface. Cross-product changes require explicit scope and usually an ADR.
