# Frontend Deployment

**Status:** DRAFT  
**Owner:** Release + Operations  
**Authority:** Operational specification

## Purpose

Deploy the web app against an explicit environment manifest.

## Requirements

- Pin contract addresses/chain/indexer/API/Kuru environment.
- Run typecheck/build/E2E smoke before promotion.
- Expose build commit/version for diagnostics.

## Non-goals

- No undocumented privileged workaround.

## Acceptance criteria

- Procedure is reproducible by another operator.

## Evidence required

- Deployment/smoke/monitoring evidence.
