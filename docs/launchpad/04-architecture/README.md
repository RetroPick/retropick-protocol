# Launchpad Architecture

**Status:** DRAFT  
**Owner:** Architecture  
**Authority:** System architecture layer

## Purpose

Route system, contract, frontend, backend, data, indexer, API, wallet and transaction-flow architecture.

## Requirements

- Contracts remain the economic source of truth.
- Offchain services may improve reads and orchestration but cannot redefine launch economics.
- All write paths identify the actual wallet/contract transaction.

## Non-goals

- Does not override protocol semantics.

## Acceptance criteria

- All architecture diagrams agree on ownership/trust boundaries.

## Evidence required

- Architecture review and E2E traceability.
