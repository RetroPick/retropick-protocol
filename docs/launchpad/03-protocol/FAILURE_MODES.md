# Failure Modes

**Status:** DRAFT  
**Owner:** Protocol + Security  
**Authority:** Canonical protocol specification

## Purpose

Specify safe behavior when dependencies or calls fail.

## Requirements

- Cover quote transfer failure, insufficient reserves, slippage, deployment collision, graduation failure, Kuru failure, RPC/indexer outage and admin-key loss.
- State whether each failure reverts, retries, pauses or requires recovery.

## Non-goals

- Does not redefine Prediction/PRISM.

## Acceptance criteria

- Requirements are testable and consistent with PROTOCOL_SPEC.

## Evidence required

- Requirement-to-test traceability.
