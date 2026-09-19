# Contracts Agent Contract

## Read first

- `../docs/launchpad/PROTOCOL.md`
- `../docs/launchpad/INVARIANTS.md`
- `../development/launchpad/contracts/README.md`
- `../development/launchpad/contracts/SECURITY_INVARIANTS.md`
- `../development/launchpad/testing/CONTRACTS.md`

## Ownership

Solidity agent owns `contracts/src/v2/**`, `contracts/test/**`, and `contracts/script/**` for accepted Launchpad V2 tasks.

V1 is stable/reference; do not silently alter it as part of V2 work.

## Hard constraints

- preserve accepted bonding/economic semantics unless a protocol/ADR change authorizes otherwise;
- Kuru integration must not silently alter bonding math;
- Doorway is OUT_OF_SCOPE_P0;
- no double graduation;
- no loss of secured graduation assets on destination failure;
- quote assets must pass explicit policy;
- do not use existing Doorway tests as proof of Launchpad V2 safety.

## Verify

At minimum for contract-changing tasks, run the owning Foundry unit/fuzz/invariant/integration checks plus formatting/build/static analysis defined in development docs.

## Handoff

Produce ABI/event/deployment artifacts and test evidence for SDK/indexer consumers.
