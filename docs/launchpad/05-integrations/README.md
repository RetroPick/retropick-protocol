# Launchpad Integrations

**Status:** DRAFT  
**Owner:** Integrations  
**Authority:** Integration layer

## Purpose

Own explicit boundaries with Monad, Kuru, indexer, RPC, wallets, V4 and metadata services.

## Requirements

- Every integration pins environment/version before implementation.
- Every integration defines success, failure, retry/fallback and evidence.
- Protocol requirements remain separate from provider-specific APIs.

## Non-goals

- Does not override protocol semantics.

## Acceptance criteria

- No integration is marked complete solely because an SDK imports.

## Evidence required

- Live/testnet transaction or API evidence as appropriate.
