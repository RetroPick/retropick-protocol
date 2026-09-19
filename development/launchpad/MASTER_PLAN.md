---
id: LP-MASTER-PLAN
type: normative_implementation
status: ready
owner: launchpad-planner
product: launchpad
version: v2
depends_on: [LP-GOAL]
---

# Master Implementation Plan

| Phase | Objective | Primary output | Exit gate |
|---|---|---|---|
| DEV-0 | control-plane/doc normalization | routed specs + machine control | DEVELOPMENT_READY |
| DEV-1 | workspace foundation | pnpm/TS/apps/packages skeleton | workspace-build |
| DEV-2 | V2 core qualification | Factory/Token/Curve tests | contract-core-qualified |
| DEV-3 | Kuru architecture | verified API + parameter policy | kuru-arch-accepted |
| DEV-4 | Kuru graduation implementation | safe retryable executor | kuru-contract-integration |
| DEV-5 | shared domain/ABI/SDK | typed packages | shared-contracts-stable |
| DEV-6 | indexer | event read model | indexer-operational |
| DEV-7 | backend | metadata/search API | backend-operational |
| DEV-8 | frontend | create/trade/graduation UX | web-operational |
| DEV-9 | cross-layer integration | coherent environment | integration-pass |
| DEV-10 | security qualification | findings + invariant evidence | security-pass |
| DEV-11 | staging | reproducible Monad deployment | staging-ready |
| DEV-12 | full E2E | golden path | e2e-pass |
| DEV-13 | hackathon release | demo/submission package | HACKATHON_READY |
| DEV-14 | mainnet candidate | hardening/ops/audit inputs | MAINNET_CANDIDATE |

No downstream phase may waive a failed reserve/accounting/security gate.
