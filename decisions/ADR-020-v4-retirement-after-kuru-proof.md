# ADR-020: V4 Retirement After Kuru Proof

**Status:** PROPOSED  
**Date:** 2026-09-20  
**Scope:** RetroPick Launchpad V2

## Proposal

Do not remove current V4-specific graduation code before the Kuru target path has independent tests, live target-environment evidence and safe migration/deployment architecture.

After Kuru is proven, classify obsolete V4-specific runtime components as compatibility/reference or remove them through a scoped change.

## Constraint

Kuru migration cannot silently change bonding arithmetic or accepted fee/reserve semantics.

