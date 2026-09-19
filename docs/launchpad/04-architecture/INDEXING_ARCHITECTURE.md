# Indexing Architecture

**Status:** DRAFT  
**Owner:** Integrations + Data  
**Authority:** System architecture

## Purpose

Define event-to-read-model indexing with reorg and lag handling.

## Requirements

- Map lifecycle/trade/fee/admin events to entities.
- Use deterministic IDs from chain/tx/log or contract identifiers.
- Handle replay/backfill idempotently and define reorg rollback behavior.
- Expose last indexed block/time and frontend stale-state UX.
- Critical operations can fall back to direct RPC reads.

## Non-goals

- Indexer does not authorize writes or graduation.

## Acceptance criteria

- Rebuild from chain produces the same logical read model.

## Evidence required

- Indexer integration tests and lag/reorg scenarios.
