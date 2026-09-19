# ADR-011: Launchpad Quote Asset Policy

**Status:** PROPOSED  
**Date:** 2026-09-20  
**Scope:** RetroPick Launchpad V2

## Decision proposed

Use an explicit allowlist/policy for trusted quote assets rather than arbitrary ERC-20 acceptance.

P0 should target native MON plus one qualified canonical stable asset where available. Additional assets require compatibility testing for decimals, transfer behavior, callbacks, rebasing/fees, freeze/blacklist risk and Kuru support.
