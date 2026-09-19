---
id: LP-FE-ERROR
type: normative_implementation
status: ready
owner: launchpad-frontend
product: launchpad
version: v2
---

# Error UX

Consume the shared error catalog. User-facing errors must identify actionability: change input/slippage, approve asset, switch network, retry after RPC/indexer failure, or stop because launch state changed.

Do not show raw revert data when a safe decoded message exists; preserve diagnostics for developer logs.