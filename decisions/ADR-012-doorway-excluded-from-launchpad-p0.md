# ADR-012: Doorway Excluded from Launchpad P0

**Status:** PROPOSED  
**Date:** 2026-09-20  
**Scope:** RetroPick Launchpad V2

## Proposal

Classify RetroPickDoorwayV1/V2 as EXPERIMENTAL, OUT_OF_SCOPE_P0 and NOT_DEPLOYED_BY_DEFAULT.

## Rationale

The Launchpad critical path is create -> bonding trade -> graduation -> Kuru. Doorway introduces a separate cross-chain migration trust model and already dominates existing test coverage without qualifying the Launchpad core.

## Consequence

Doorway remains in source/reference but is removed from P0 dependency, deployment, demo and acceptance paths unless a later ADR promotes it.

