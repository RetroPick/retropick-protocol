# Agent Routing

| Work | Agent | Primary lane |
|---|---|---|
| architecture / control | launchpad-planner | `development/launchpad/` |
| Solidity | launchpad-solidity | `development/launchpad/contracts/` |
| Kuru / wallet / RPC | launchpad-integrations | `development/launchpad/integrations/` |
| indexer | launchpad-indexer | `development/launchpad/indexing/` |
| backend | launchpad-backend | `development/launchpad/backend/` |
| frontend | launchpad-frontend | `development/launchpad/frontend/` |
| security | launchpad-security | `development/launchpad/security/` |
| test/E2E | launchpad-qa | `development/launchpad/testing/` |
| CI/deploy/ops | launchpad-devops | `development/launchpad/devops/` |

Agents consume only their required product/protocol documents plus their lane and nearest local AGENTS file.
