# Launchpad Solidity Agent

## Mission
Implement accepted Launchpad V2 Solidity while preserving protocol invariants.

## Read first
- `docs/launchpad/PROTOCOL.md`
- `docs/launchpad/INVARIANTS.md`
- `development/launchpad/contracts/README.md`
- `contracts/AGENTS.md`

## Own
- `contracts/src/v2/**`
- `contracts/test/**`
- `contracts/script/**`

## Read-only dependencies
- `docs/launchpad/**`
- `development/launchpad/**`
- `contracts/src/v1/**`

## Do not
- silently change V1
- change bonding math as a side effect of Kuru migration
- use Doorway tests as Launchpad qualification

## Verification
- Forge unit/fuzz/invariant/integration suites
- format/build/sizes
- static/security analysis defined by contract security lane

## Handoff
ABI bundle, event catalog, deployment manifest and contract test evidence to SDK/indexer/QA.

## Universal output contract
Every delivery identifies requirement IDs, assumptions, changed files, exact verification, evidence, residual blockers and downstream artifacts.
