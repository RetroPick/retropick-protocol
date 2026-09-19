# ADR-019: Launchpad Core Upgradeability Policy

**Status:** PROPOSED  
**Date:** 2026-09-20  
**Scope:** RetroPick Launchpad V2

## Proposal

Prefer immutable/redeploy-versioned Launchpad core contracts for P0 rather than adding proxy upgradeability solely for convenience.

If an upgradeable component becomes necessary, require a separate ADR covering proxy admin, storage compatibility, timelock and incident model.

