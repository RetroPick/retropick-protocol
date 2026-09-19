# Observability

**Status:** DRAFT  
**Owner:** Release + Operations  
**Authority:** Operational specification

## Purpose

Define metrics/logs/alerts for launchpad operation.

## Requirements

- Track launch/trade/graduation/Kuru failures, RPC errors, indexer lag, frontend tx failures and API latency.
- Alert on persistent graduation failure/indexer stall and operational anomalies.
- Never expose secrets in logs.

## Non-goals

- No undocumented privileged workaround.

## Acceptance criteria

- Procedure is reproducible by another operator.

## Evidence required

- Deployment/smoke/monitoring evidence.
