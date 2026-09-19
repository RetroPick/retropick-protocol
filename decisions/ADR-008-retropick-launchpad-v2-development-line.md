# ADR-008: RetroPick Launchpad V2 Development Line

**Status:** ACCEPTED  
**Date:** 2026-09-20  
**Scope:** Modern Launchpad

## Context

RetroPick maintains two launchpad contract generations under `contracts/src/`. Engineering needs an unambiguous feature-development target while preserving a stable reference generation.

## Decision

- V1 is the stable/reference RetroPick launchpad generation.
- V1 receives security maintenance and critical correctness fixes only.
- V2 is the active modern-launchpad generation.
- New launchpad features, Monad-specific integration work and the Kuru graduation path belong to V2.
- Any V2 behavior change requires an owning specification and V2-specific tests.
- Prediction and PRISM financial kernels are outside this ADR.

## Consequences

V2 may diverge intentionally from V1 only through accepted RetroPick specifications and, for architectural changes, ADRs. V1 passing tests do not qualify V2 once V2 diverges.
