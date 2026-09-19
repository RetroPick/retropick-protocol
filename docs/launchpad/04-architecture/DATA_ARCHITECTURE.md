# Data Architecture

**Status:** DRAFT  
**Owner:** Data + Backend  
**Authority:** System architecture

## Purpose

Define canonical and derived data ownership.

## Requirements

- Onchain: launch configuration, reserves, trades, fees, roles and graduation state.
- Indexed: query-friendly Launch, Token, Creator, Trade, Fee, Graduation, KuruMarket, Activity and metrics entities.
- Backend: metadata/search/ranking/cache only.
- Every cached field has an owner, freshness policy and invalidation source.

## Non-goals

- Do not duplicate authoritative balances in mutable backend tables.

## Acceptance criteria

- Every displayed field has a source classification.

## Evidence required

- Schema and source-to-field map.
