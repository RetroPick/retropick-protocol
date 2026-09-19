# Documentation Restructure Report

The existing Launchpad tree is intentionally consolidated by responsibility.

| Old area | Classification | New owner |
|---|---|---|
| `00-context/*` | MERGE_INTO | `docs/launchpad/{README,PRODUCT_SCOPE}.md` |
| `01-research/*` | MOVE / MERGE | integration/product canonical docs; mutable research remains informative |
| `02-product/*` | MERGE_INTO | `PRODUCT.md`, `PRODUCT_SCOPE.md`, `USER_FLOWS.md` |
| `03-protocol/*` | MERGE_INTO | canonical protocol/economic files |
| `04-architecture/*` | SPLIT | high-level `SYSTEM_ARCHITECTURE.md`; implementation detail -> `development/launchpad/*` |
| `05-integrations/*` | SPLIT | canonical integration boundaries + development implementation specs |
| `06-hackathon/*` | MERGE_INTO | `docs/launchpad/hackathon/*` |
| `07-execution/*` | MOVE_TO_DEVELOPMENT | `MASTER_PLAN.md`, DAG, control YAML |
| `08-validation/*` | MOVE_TO_DEVELOPMENT | testing/security lanes |
| `09-production/*` | MOVE_TO_DEVELOPMENT | devops lane + canonical production requirements |
| `10-evidence/*` | MOVE_TO_EVIDENCE | `evidence/launchpad/` |
| `11-pitch/*` | DELETE_REDUNDANT / hackathon | only operational demo/submission content retained |

Unique protocol/security facts must be migrated before old files are deleted.
