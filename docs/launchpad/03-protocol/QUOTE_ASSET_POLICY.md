# Quote Asset Policy

**Status:** DRAFT  
**Owner:** Protocol + Security  
**Authority:** Canonical quote admission policy

## Purpose

Define which assets may denominate launch trading and graduation.

## Requirements

- P0 targets native MON plus one qualified stable asset where supported.
- ERC-20 admission evaluates decimals, transfer semantics, callbacks, rebasing, fee-on-transfer, freeze/blacklist risk, liquidity and Kuru compatibility.
- Same-quote graduation is the default; cross-quote conversion requires a later explicit design.
- Unapproved quote assets cannot enter trusted templates.

## Non-goals

- No arbitrary-token promise.

## Acceptance criteria

- Every enabled quote has a compatibility record and integration tests.

## Evidence required

- Token metadata, malicious-token tests and venue compatibility proof.
