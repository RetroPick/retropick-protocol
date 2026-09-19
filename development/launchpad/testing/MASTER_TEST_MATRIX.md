---
id: LP-TEST-MATRIX
type: normative_implementation
status: ready
owner: launchpad-qa
product: launchpad
version: v2
---

# Master Test Matrix

| Requirement | Unit | Fuzz/Invariant | Integration | E2E | Evidence |
|---|---|---|---|---|---|
| LP-PROD-001 create launch | contract | boundary | factory/deployer | browser create | contracts/e2e |
| LP-PROTO-001 curve | fixtures | fuzz/invariant | trade lifecycle | buy/sell | contracts/e2e |
| LP-PROTO-002 accounting | contract | invariant | multi-trade | balance assert | contracts |
| LP-PROTO-003 safe graduation | unit | invariant | Kuru failure/retry | graduate | contracts/kuru |
| LP-IDX-001 read model | mapper | replay/reorg | live sync | UI freshness | indexing |
| LP-BE-001 non-authoritative API | service | n/a | API/indexer | degraded mode | backend |
| LP-FE-001 lifecycle UI | component | n/a | wallet/contracts | golden path | frontend |
