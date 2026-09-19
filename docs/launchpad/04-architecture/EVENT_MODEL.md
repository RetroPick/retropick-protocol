# Event Model

**Status:** DRAFT  
**Owner:** Smart Contracts + Data  
**Authority:** Architecture contract

## Purpose

Define the observable event model required for indexing, UX and operations.

## Requirements

- Cover launch creation, trades, fees, role/config changes, graduation readiness/execution/retry/recovery and destination market identification.
- Choose indexed fields for efficient launch/token/user queries.
- Document event ordering assumptions inside a transaction.

## Non-goals

- Events are evidence/read inputs, not replacements for storage invariants.

## Acceptance criteria

- Indexer can reconstruct required lifecycle read models.

## Evidence required

- Event ABI and indexing tests.
