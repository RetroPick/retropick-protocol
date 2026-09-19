# ADR-013: Launchpad TypeScript Workspace

**Status:** PROPOSED  
**Date:** 2026-09-20  
**Scope:** RetroPick Launchpad V2

## Proposal

Use a strict TypeScript monorepo for future full-stack runtime with `apps/web`, `apps/api`, `apps/indexer` and shared `packages/domain`, `packages/contracts`, `packages/sdk`, `packages/config`, `packages/ui`, `packages/test-utils`.

Candidate package/workspace tooling: pnpm workspace and a task orchestrator such as Turborepo.

## Acceptance before ACCEPTED

Pin current compatible framework/package versions, define root scripts/CI and prove local build/test ergonomics.

