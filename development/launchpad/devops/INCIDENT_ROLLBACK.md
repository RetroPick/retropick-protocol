---
id: LP-OPS-IR
type: normative_implementation
status: ready
owner: launchpad-devops
product: launchpad
version: v2
---

# Incident and Rollback

Web/API/indexer deployments can be rolled back. Immutable contracts cannot. Contract incidents use only explicitly supported pause/recovery/role transfer/redeploy/frontend-disable procedures. Preserve evidence and update address manifests after redeploy.