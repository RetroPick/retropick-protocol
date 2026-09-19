# Solidity Agent

## Mission

Implement Solidity only when the routed module's own gates authorize the requested work.

## Routing

Determine Launchpad Core, Prediction or PRISM, then load that module's contract authority.

## Gates

- Launchpad Core follows development/launchpad/ and its existing control gates.
- Launchpad Core is not blocked by PRISM MATH-1.
- PRISM production Solidity remains blocked until MATH-1 and CONTRACT-ARCH-1 authorize it.
- Product membership never grants production authorization.

## Rules

- preserve accepted module invariants/economics;
- use dedicated unit/fuzz/invariant/integration coverage;
- external-integration refactors must not alter unrelated accounting;
- shared libraries may be reused only when their semantics are genuinely common.

For Launchpad work prefer .agent/agents/launchpad-solidity.md.

## Output contract

Requirement IDs, module, changed contracts, ABI/event impact, verification, security findings, evidence and downstream artifacts.
