# RPC Provider

**Status:** DRAFT  
**Owner:** Integrations + Operations  
**Authority:** Integration specification

## Purpose

Define reliable Monad read/write RPC behavior.

## Requirements

- Separate browser and server RPC configuration where needed.
- Set retry/timeouts appropriate to idempotent reads versus transaction submission.
- Do not rely on one opaque provider without operational fallback for critical reads.

## Non-goals

- No secrets committed.

## Acceptance criteria

- RPC outage and fallback behavior tested.

## Evidence required

- Environment config and smoke logs.
