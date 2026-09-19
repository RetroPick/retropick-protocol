---
id: LP-OPS-CI
type: normative_implementation
status: ready
owner: launchpad-devops
product: launchpad
version: v2
---

# CI/CD

Required lanes after runtime exists:
contracts format/build/unit/fuzz/invariant/static; TS lint/typecheck; backend/indexer/frontend tests/build; integration/E2E; secret/dependency scans; deployment smoke.

Merge blockers include build/unit/invariant/typecheck failures and new untriaged high/critical security findings.