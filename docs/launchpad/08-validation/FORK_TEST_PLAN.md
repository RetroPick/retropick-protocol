# Fork Test Plan

**Status:** DRAFT  
**Owner:** Smart Contracts + Validation  
**Authority:** Optional environment validation

## Purpose

Use chain forks when they materially improve integration confidence.

## Requirements

- Pin chain and block number for reproducibility.
- Use forks to verify external contract assumptions, token behavior and call compatibility where supported.
- Never substitute fork-only success for a required live/testnet Kuru proof.

## Non-goals

- Do not use unpinned latest block in canonical evidence.

## Acceptance criteria

- Fork fixtures reproduce and document assumptions.

## Evidence required

- Fork command, block, addresses and results.
