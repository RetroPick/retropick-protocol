# Wallet Connectivity

**Status:** DRAFT  
**Owner:** Frontend + Integrations  
**Authority:** Integration specification

## Purpose

Define supported wallet connection and chain-signing behavior.

## Requirements

- Expose Monad chain mismatch clearly.
- Support connect/disconnect/account change/network change.
- Require explicit user signatures and show human-readable transaction intent.

## Non-goals

- No custody/private-key handling.

## Acceptance criteria

- Golden path works with at least one supported wallet end-to-end.

## Evidence required

- Browser E2E evidence.
