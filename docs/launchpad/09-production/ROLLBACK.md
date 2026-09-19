# Rollback and Redeploy

**Status:** DRAFT  
**Owner:** Release + Operations  
**Authority:** Operational specification

## Purpose

Define what can and cannot be rolled back.

## Requirements

- Onchain immutable deployments are not 'rolled back' like web code; use pause/recovery/redeploy only if supported and authorized.
- Frontend/backend/indexer can be rolled back independently.
- Address registry must reflect any redeployment.

## Non-goals

- No undocumented privileged workaround.

## Acceptance criteria

- Procedure is reproducible by another operator.

## Evidence required

- Deployment/smoke/monitoring evidence.
