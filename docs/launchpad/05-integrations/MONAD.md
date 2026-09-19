# Monad Integration

**Status:** DRAFT  
**Owner:** Integrations  
**Authority:** Integration specification

## Purpose

Define network-specific deployment and runtime behavior.

## Requirements

- Pin chain ID, RPCs and explorer only in environment/production docs after current verification.
- Document gas/transaction assumptions based on measured target environment.
- Ensure wallet/network configuration and contract deployment scripts use the same environment registry.

## Non-goals

- No unverified performance claims.

## Acceptance criteria

- Local/staging/production configuration is consistent.

## Evidence required

- RPC smoke tests and deployment receipts.
