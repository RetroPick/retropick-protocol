# ADR-R01: Exact non-negative replication still stands

**Status:** PROPOSED confirmation. ADR-002 remains the accepted rule.  
**Date:** 2026-09-26

## Decision

Do not weaken `h = Gx`, `x >= 0`. This note confirms the fresh run did not falsify that rule.

## Options

Keep ADR-002. Or allow approximate or negative weights.

## Evidence

Existing replication tests passed. AND with columns A, B, and 1 is still unreplicable. Z3 5.1.0 reported unsat.

## Benchmark

Payoff shapes 2/4 through 16/16 were timed for 200 iterations. See the benchmark report. That is not a solvency benchmark.

## Security implications

Negative weights would be leverage. Approximate fit would mint a claim the basket does not pay.

## Tradeoffs

Some products, including conjunctions, stay `PRODUCT_NOT_REPLICABLE`.

## Recommendation

Leave ADR-002 accepted. Do not open approximate replication in this program.

## Confidence

High for the AND counterexample. The general cone is still the accepted mathematical definition, not a new proof artifact for every matrix size.

## What would falsify this

A non-negative exact solution for the canonical AND target, or a solvent accounting rule for negative weights that this run did not find.
