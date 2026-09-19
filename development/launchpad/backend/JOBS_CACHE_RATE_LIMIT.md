---
id: LP-BE-JOBS
type: normative_implementation
status: ready
owner: launchpad-backend
product: launchpad
version: v2
---

# Jobs, Cache and Rate Limits

Add a cache/job system only when justified by measured requirements. CANDIDATE Redis/Valkey is not automatically accepted.

Jobs are idempotent and keyed to deterministic inputs. Rate limits protect upload/auth/search endpoints without blocking wallet transactions that occur directly onchain.