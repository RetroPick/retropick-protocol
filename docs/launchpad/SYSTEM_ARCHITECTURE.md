---
id: LP-SYSTEM
type: normative
product: launchpad
version: v2
status: active
---

# System Architecture

```text
User
 |
 v
apps/web
 |\
 | \ writes
 |  -> wallet -> Monad RPC -> RetroPick V2 -> Kuru
 |
 +-- reads -> indexer/query model
 |
 +-- reads -> non-custodial API (metadata/search/ranking)
```

## Authority

Contracts: token/curve/reserve/fee/lifecycle truth.
Kuru: mature-market execution after graduation.
Indexer: reconstructible derived chain read model.
Backend: metadata/search/ranking/cache, never reserve authority.
Frontend: presentation + user-signed transaction construction.

Implementation topology and package contracts live under `development/launchpad/`.
