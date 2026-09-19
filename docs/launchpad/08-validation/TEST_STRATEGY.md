# Test Strategy

**Status:** CANONICAL VALIDATION STRATEGY  
**Owner:** Validation + Security

## Layers

1. Solidity unit tests for local functions/state transitions.
2. Solidity fuzz tests for arithmetic/boundaries.
3. Stateful invariants for reserve, supply, fees and graduation.
4. Contract integration tests across factory/deployer/curve/graduation.
5. Kuru integration tests on the supported target environment.
6. Indexer schema/rebuild/reorg tests.
7. Frontend unit/component tests.
8. Browser E2E for wallet transaction flows.
9. Deployment smoke tests.
10. Manual security and operational review.

## Release principle

A green UI demo does not compensate for failed invariant/security gates. A static tool finding is triaged rather than automatically suppressed. V2 changes require V2-specific coverage.

## Reproducibility

Record tool versions, environment, chain/block where applicable, seed/runs for fuzz/invariants, deployed addresses and artifact hashes/URLs.
