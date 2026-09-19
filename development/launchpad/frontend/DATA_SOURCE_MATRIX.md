---
id: LP-FE-DATA
type: normative_implementation
status: ready
owner: launchpad-frontend
product: launchpad
version: v2
---

# Data Source Matrix

| Data | Canonical owner | Normal source | Fallback |
|---|---|---|---|
| token supply | chain | indexer/RPC | RPC |
| curve reserves/state | chain | freshness-qualified RPC/indexer | RPC |
| launch history/trades | events | indexer | limited RPC/log fallback |
| metadata/media | application/onchain field as specified | API/onchain | graceful missing media |
| trending score | backend | API | no ranking/neutral |
| wallet balance | chain | wallet/RPC/indexer | RPC |
| Kuru execution/market | Kuru | Kuru SDK/contracts | verified contract read |

Frontend never treats backend-derived values as canonical reserves.