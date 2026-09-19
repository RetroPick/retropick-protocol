# Quote Asset Research

**Status:** DRAFT  
**Owner:** Protocol + Security  
**Authority:** Research input

## Purpose

Evaluate candidate quote assets for primary bonding and post-graduation markets.

## Requirements

- Assess decimals, liquidity, issuer/freeze risk, rebasing, fee-on-transfer, callback behavior, blacklist behavior, Kuru compatibility and operational availability.
- Recommend a minimal P0 allowlist: native MON plus one qualified stable asset when available.
- Treat arbitrary ERC-20 support as unsafe until qualified.

## Non-goals

- No assumption that IERC20 compliance implies economic compatibility.

## Acceptance criteria

- Every P0 quote asset has an explicit compatibility profile.

## Evidence required

- Onchain metadata, token docs and integration tests.
