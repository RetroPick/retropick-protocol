---
id: LP-FE-STATE
type: normative_implementation
status: ready
owner: launchpad-frontend
product: launchpad
version: v2
---

# State and Cache

Separate:
- wallet/session state;
- server/app metadata queries;
- indexed event queries;
- critical RPC reads;
- transaction lifecycle state.

Invalidate/reconcile launch queries after receipts/events. Display stale indexer state explicitly rather than presenting old data as current.