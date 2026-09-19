# Fee Model

**Status:** DRAFT  
**Owner:** Protocol  
**Authority:** Canonical fee semantics

## Purpose

Define every value transfer that is a fee rather than launch reserve or graduation capital.

## Requirements

- Document protocol fee, creator fee/tax, buyback share, launch fee and venue fee independently.
- For each define payer, asset denomination, basis, BPS maximum, receiver, collection point, mutability, snapshot behavior and event.
- Total effective trade fee must be bounded and testable.
- Fees never masquerade as launch reserves.

## Non-goals

- Future referral/interface fees are not P0 unless explicitly specified.

## Acceptance criteria

- Fee conservation and cap invariants exist.
- Frontend can calculate/display pre-signature fees.

## Evidence required

- Foundry tests and UI quote fixtures.
