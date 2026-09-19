# SDK Architecture

**Status:** DRAFT  
**Owner:** Frontend + Integrations  
**Authority:** System architecture

## Purpose

Define typed client surfaces around RetroPick contracts and external venue integration.

## Requirements

- Expose typed reads, transaction builders, quote helpers that exactly match Solidity arithmetic, event parsers and deployment-address resolution.
- Separate RetroPick SDK types from Kuru SDK types behind explicit integration boundaries.
- Pin ABI/version with each deployment generation.

## Non-goals

- SDK helpers cannot invent economic semantics.

## Acceptance criteria

- SDK quote outputs match Solidity fixtures exactly.

## Evidence required

- ABI-generated types and parity tests.
