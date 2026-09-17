# ADR-001: Math-first protocol development

**Status:** ACCEPTED

## Context
PRISM combines financial claims; implementation-first development risks encoding an insolvent or internally inconsistent mechanism.

## Decision
Freeze protocol semantics and implement an exact Python reference model before production Solidity.

## Consequence
`contracts/` remains scaffold-only until MATH-1.
