# ADR-002: Exact long-only replication for Metropolis PRISM MVP

**Status:** ACCEPTED

## Decision

Admitted PRISM Phase-1 payoffs satisfy:

\[
Gx=h,\qquad x\ge0
\]

and active backing satisfies:

\[
B_i\ge Sx_i.
\]

Arbitrary nonlinear payoff synthesis is deferred.

## Reason

The restricted model has straightforward backing, redemption and terminal-solvency properties suitable for a hackathon protocol kernel and later audit.
