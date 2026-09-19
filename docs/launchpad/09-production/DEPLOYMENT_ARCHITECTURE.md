# Deployment Architecture

**Status:** DRAFT  
**Owner:** Release + Architecture  
**Authority:** Operational architecture

## Purpose

Define how contracts, indexer, backend and frontend are promoted together.

## Requirements

- Contracts deploy/configure first; address registry becomes input to indexer/backend/frontend.
- Indexer is deployed/synced before relying on indexed UX.
- Frontend release points to one coherent environment/version registry.
- Smoke tests run after each promotion.

## Non-goals

- Do not mix addresses from environments.

## Acceptance criteria

- One environment manifest resolves all components consistently.

## Evidence required

- Deployment manifests and smoke results.
