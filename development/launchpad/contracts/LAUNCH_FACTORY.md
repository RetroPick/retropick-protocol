---
id: LP-SC-FACTORY
type: normative_implementation
status: ready
owner: launchpad-solidity
product: launchpad
version: v2
---

# Launch Factory

## CURRENT
Factory owns launch configs, fees, quote approvals/economics, launch records, CREATE2 orchestration and V4-specific graduation dependencies.

## TARGET
Retain launch/config/record authority but move venue-specific Kuru execution behind the smallest concrete graduation boundary required by P0.

## Required invariants
- disabled config cannot launch;
- total fee limits remain bounded;
- quote token must be approved and match stored decimals/economics;
- launch economics pin prevents owner changes underneath an in-flight launch;
- duplicate deterministic deployment reverts;
- launch record becomes immutable except explicitly mutable creator/admin fields;
- one launch cannot graduate twice.

## Security
Owner-controlled config changes apply only as defined; snapshotted per-launch economics cannot be retroactively changed.

## Verification
Unit tests for every config/admin path, launch creation, exact event contents, CREATE2 predict/deploy relation and unauthorized callers.
