# Security Test Plan

**Status:** ACTIVE  
**Owner:** Security

## Smart contracts

Run Forge unit/fuzz/invariant, Slither, Aderyn, Solhint and manual review. Triage reentrancy, external-call ordering, access control, reserve accounting, malicious ERC-20s, fee bounds, CREATE2, graduation DoS/retry/recovery and venue interactions.

## Full stack

Review wallet transaction construction, untrusted metadata rendering, API input validation, authorization, rate limits, dependency/supply-chain exposure, secret handling and RPC/indexer trust assumptions.

## Operations

Review deployer/owner/fee/recovery keys, role transfer, environment variables, CI secrets and incident procedures.

## Findings

Each finding records severity, affected version/component, exploit preconditions, evidence, disposition and regression test. Existing findings are not automatically safe because they are old.

## Gate

Unresolved critical findings or material high findings without accepted mitigation block LP-SECURITY-1.
