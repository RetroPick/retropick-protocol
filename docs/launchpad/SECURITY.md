---
id: LP-SECURITY
type: normative
product: launchpad
version: v2
status: active
---

# Security

Protected values:
- launch token supply;
- real quote/token reserves;
- explicit fee balances;
- secured graduation assets;
- administrative role integrity;
- user transaction intent.

Primary threats:
malicious creator/trader/ERC20, reentrancy/callback behavior, rounding extraction, MEV/slippage, graduation DoS, external venue failure, compromised operator, stale/poisoned read data, malicious metadata and dependency compromise.

Readiness:
- hackathon requires no blocking known issue in demonstrated P0;
- mainnet candidate requires dedicated unit/fuzz/invariant/adversarial coverage, static analysis triage, manual review, role/key/deployment review, E2E/resilience/observability;
- unrestricted mainnet requires explicit human/security authorization appropriate to funds/risk.
