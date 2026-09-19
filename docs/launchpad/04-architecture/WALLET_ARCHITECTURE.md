# Wallet Architecture

**Status:** DRAFT  
**Owner:** Frontend + Security  
**Authority:** System architecture

## Purpose

Define wallet connection, chain selection, signing and transaction lifecycle.

## Requirements

- Support explicit Monad network detection/switching.
- Never request approvals beyond the amount/scope required by the current flow when avoidable.
- Decode simulation/revert errors into product errors.
- Track submitted/replaced/confirmed/failed transactions by hash.

## Non-goals

- No custody of user private keys.
- No silent transaction submission.

## Acceptance criteria

- All write flows visibly require user authorization.

## Evidence required

- E2E wallet tests and transaction receipts.
