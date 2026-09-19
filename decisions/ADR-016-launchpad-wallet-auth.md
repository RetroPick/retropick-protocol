# ADR-016: Launchpad Wallet Authentication

**Status:** PROPOSED  
**Date:** 2026-09-20  
**Scope:** RetroPick Launchpad V2

## Proposal

Use a wallet challenge / SIWE-style ownership proof for offchain profile and metadata mutations with nonce replay protection, domain/chain/expiry binding and short-lived sessions.

Trading remains direct wallet/onchain and does not require backend custody.

