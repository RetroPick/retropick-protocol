# ADR-004 — Separate Admission-Time Replication from Runtime Backing

**Status:** ACCEPTED  
**Date:** 2026-09-17

## Context

The generalized solvency condition can be written statewise as:

```math
V_B(\omega) \ge S h(\omega)
```

for every terminal state.

The historical report proposed checking an equivalent statewise condition inside every mint transaction.

For Phase-1 exact replication:

```math
h=Gx
```

with non-negative component payoffs and runtime component backing:

```math
B_i\ge Sx_i
```

terminal solvency follows mathematically.

## Decision

Split responsibilities:

### Admission time

Prove/verify:

```math
h=Gx,\quad x\ge0
```

or compute `h=Gx` when basket mode supplies `x` directly.

### Runtime

Enforce only the component-wise backing requirement:

```math
B_i\ge Sx_i
```

and post-mint:

```math
B_i'\ge(S+Q)x_i
```

for every component.

Do not enumerate all terminal worlds inside every Solidity mint.

## Consequences

- gas/runtime complexity scales with number of components rather than terminal-state count;
- the executable reference model and admission engine become security-critical;
- activation must freeze the replication definition;
- approximate/nonlinear products remain out of scope unless separately specified.
