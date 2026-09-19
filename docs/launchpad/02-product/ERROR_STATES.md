# Product Error States

**Status:** DRAFT  
**Owner:** Product  
**Authority:** Product specification

## Purpose

Make failures explicit and recoverable.

## Requirements

- Cover wallet rejection, wrong chain, allowance, slippage, revert, RPC failure, indexer lag, graduation retry and Kuru unavailability.
- Every error has user action and technical diagnostic path.

## Non-goals

- Does not override protocol math or contract truth.

## Acceptance criteria

- Reviewed against PRODUCT_SPEC and E2E plan.

## Evidence required

- Browser tests, transaction evidence and UX review.
