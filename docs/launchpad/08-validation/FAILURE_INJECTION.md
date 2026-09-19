# Failure Injection

**Status:** DRAFT  
**Owner:** Validation + Operations  
**Authority:** Resilience validation

## Purpose

Deliberately exercise expected dependency failures.

## Requirements

- RPC timeout/unavailability, indexer lag/offline, backend errors, wallet rejection, stale allowance, Kuru call failure, token transfer anomaly and transaction replacement/reorg where practical.
- Verify no failure causes false graduated/success state or lost protocol assets.
- Verify user/operator recovery instructions.

## Non-goals

- Does not waive higher-authority safety requirements.

## Acceptance criteria

- Failure states match protocol/product docs.

## Evidence required

- Automated/manual fault scenarios.
