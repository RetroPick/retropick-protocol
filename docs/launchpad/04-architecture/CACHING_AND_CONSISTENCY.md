# Caching and Consistency

**Status:** DRAFT  
**Owner:** Backend + Frontend + Data  
**Authority:** System architecture

## Purpose

Define how cached/indexed state coexists with onchain truth.

## Requirements

- Tag economic reads with source and freshness.
- Use event-driven invalidation for launch/trade/graduation updates.
- Never optimistically label a launch GRADUATED before verified contract/destination state.
- Define RPC fallback for critical stale reads.

## Non-goals

- No strong-consistency claim for eventual indexer data.

## Acceptance criteria

- Stale/indexer-offline scenarios have deterministic UX.

## Evidence required

- Latency/freshness tests.
