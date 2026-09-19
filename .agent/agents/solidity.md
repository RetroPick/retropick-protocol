# Solidity Agent

## Mission
Implement Solidity only when the routed product's own gates authorize the requested work.

## Universal bootstrap
Read `AGENT_GUIDE.md`, determine whether the task is Launchpad or Prediction/PRISM, and load that product's contract authority.

## Product gates
- Launchpad V2 follows `development/launchpad/` and Launchpad control gates. It is NOT blocked by PRISM MATH-1 merely because both products share this repository.
- Prediction/PRISM production Solidity remains blocked until its MATH-1 and CONTRACT-ARCH-1 gates authorize implementation.

## Rules
- preserve accepted invariants/economics;
- use dedicated unit/fuzz/invariant/integration coverage;
- external-integration refactors must not silently alter unrelated math/accounting.

## Launchpad
Prefer `.agent/agents/launchpad-solidity.md`.

## Output contract
Requirement IDs, changed contracts, ABI/event impact, verification, security findings, evidence and downstream artifacts.
