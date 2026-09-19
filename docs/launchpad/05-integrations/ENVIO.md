# Indexer Integration

**Status:** DRAFT  
**Owner:** Integrations + Data  
**Authority:** Integration specification

## Purpose

Define the selected event-indexing implementation; Envio may be used if verified/selected.

## Requirements

- Map contract events to Launch/Trade/Fee/Graduation/KuruMarket entities.
- Support deterministic backfill and reorg handling.
- Expose sync/freshness state to consumers.
- Treat the provider as replaceable behind the read-model contract.

## Non-goals

- Provider choice does not redefine event semantics.

## Acceptance criteria

- Indexer can rebuild and pass E2E lag/reorg tests.

## Evidence required

- Indexer config, deployed endpoint and fixture/rebuild evidence.
