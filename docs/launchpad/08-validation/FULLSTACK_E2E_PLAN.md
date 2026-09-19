# Full-Stack E2E Plan

**Status:** DRAFT  
**Owner:** Validation + Frontend  
**Authority:** E2E gate

## Purpose

Exercise real user journeys across browser, wallet, contracts, indexing and Kuru.

## Requirements

- Test wallet connect/network switching/create/native quote buy/ERC20 approval+buy/sell/wallet rejection/revert/indexer lag/RPC outage/graduation/Kuru handoff/page refresh/multi-user consistency.
- Assert receipts, balances, contract state and indexed entities rather than screenshots alone.
- Run locally and in the target staging environment.

## Non-goals

- Do not mock the final LP-E2E-1 Kuru proof.

## Acceptance criteria

- Golden path is deterministic and rerunnable.

## Evidence required

- Playwright or equivalent report plus tx hashes.
