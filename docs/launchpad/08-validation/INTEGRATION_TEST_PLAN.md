# Integration Test Plan

**Status:** DRAFT  
**Owner:** Validation + Integrations  
**Authority:** Integration gate

## Purpose

Define success/failure tests for every external dependency.

## Requirements

- For each integration pin capability/version/network/auth/test environment.
- Test normal success, relevant error, retry/fallback and evidence collection.
- Prioritize Monad, wallet, RPC, Kuru and indexer.

## Non-goals

- Importing an SDK is not a test.

## Acceptance criteria

- P0 integrations have real target-environment evidence.

## Evidence required

- API logs, receipts, IDs and E2E assertions.
