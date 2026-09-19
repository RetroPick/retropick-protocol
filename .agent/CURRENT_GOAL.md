# Active Goal Index

This file indexes current platform/module goals. It is not a substitute for the owning goal/specification.

## Platform research

**Goal:** RETROPICK-PLATFORM-RESEARCH-AND-PRODUCTION-OS-V2
**Status:** ACTIVE
**Scope:** shared RetroPick platform + Launchpad Core production research, with PRISM treated as an incubating consumer of shared infrastructure research.

See:
goals/active/RETROPICK-PLATFORM-RESEARCH-AND-PRODUCTION-OS-V2.md
research/production/README.md
docs/platform/README.md

## Launchpad Core V2

**Control-plane goal:** COMPLETE
**Next development objective:** resolve DEVELOPMENT_READY blockers.

Current blockers:
1. dedicated core V2 Factory/Token/Curve/Fee/Graduation qualification suite;
2. verified target Kuru Monad deployment/API and accepted market-parameter policy;
3. proposed full-stack/admin/indexer architecture ADRs not yet accepted;
4. web/API/indexer/shared runtime not implemented.

Status source:
development/launchpad/control/status.yaml

## Prediction + PRISM incubation

**Goal:** METROPOLIS-P1-MATH-1
**Status:** ACTIVE
**Gate:** MATH-1
**Module state:** RESEARCH
**Production track:** false

Production PRISM Solidity remains unauthorized until MATH-1 closes and CONTRACT-ARCH-1 translates accepted semantics into implementation responsibilities.

See:
goals/active/METROPOLIS-P1-MATH-1.md
research/prism/README.md
research/prism-model/README.md

## Independence rule

Platform research and Launchpad-Core production engineering may proceed while PRISM remains in research.

A PRISM research failure does not block Launchpad Core.

A Launchpad-Core release gate does not automatically promote PRISM.
