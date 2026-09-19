# ADR-015: Launchpad Indexer Provider

**Status:** PROPOSED  
**Date:** 2026-09-20  
**Scope:** RetroPick Launchpad V2

## Proposal

Select a Monad-compatible event indexer only after proving historical backfill, live sync, reorg handling, deterministic rebuild, deployment and sync-health/freshness support.

Envio is a candidate, not yet accepted.

## Consequence

The read-model contract is provider-agnostic at the application boundary.

