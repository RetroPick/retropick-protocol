---
id: LP-TEST-RESILIENCE
type: normative_implementation
status: ready
owner: launchpad-qa
product: launchpad
version: v2
---

# Performance and Resilience

Measure web/API/indexer/RPC latency under staging load before assigning numeric SLOs. Inject RPC outage, indexer lag, backend failure, wallet rejection/replacement and Kuru destination failure. No failure may produce false success/graduated UI.