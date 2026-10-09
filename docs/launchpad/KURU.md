---
id: LP-KURU
type: normative
product: launchpad
version: v2
status: active
---

# Kuru

Kuru is the target mature-market venue for Launchpad V2.

Verified public-source pins used by current engineering docs:
- SDK main: `636509c2eafd63479d3f399703354e0d09f51e18`;
- public DEX contracts main: `2060bb2736080c175d80d568bfdb6226bb5abd04`.

Public Kuru material describes an onchain CLOB with backstop AMM liquidity and pair-specific market parameters including size/price precision, tick size, min/max size, maker/taker fees and AMM spread.

Normative RetroPick requirements:
- market parameters come from validated protocol policy;
- creator cannot provide unsafe arbitrary raw values;
- graduation remains same-quote by default;
- destination failure is retryable without losing secured assets;
- RetroPick is not GRADUATED until the Kuru market is verified.

Concrete target deployment addresses/ABI calls remain implementation data and must be verified before coding.

## Implemented testnet candidate — 9 October 2026

The earlier target language above describes the design requirements. The V2 delivery now implements Kuru graduation through `GraduationCoordinatorV2`, `KuruGraduationExecutorV2`, protocol-derived parameter policy and per-launch permanent LP/excess custody. Native MON lifecycle and two-wallet order/fill/cancel are recorded PASS; canonical Circle-USDC live smoke remains BLOCKED_FUNDING.

[Manifest](../../deployments/monad-testnet/v2.json) and [judge evidence](../hackathon/EVIDENCE_MAP.md) distinguish historical deployment source from current release work. Router `0x7EFbE105Ca7415dE98F96622173458ac1c054630`; MarginAccount `0xd029C2D98ff85D8F64799017fE00a59B1159CE02`. These are mutable external dependencies: fresh environment/code/getter verification is required before new graduation. The historical snapshot is not a claim that identities never change.

HACKATHON_FREEZE applies to Solidity. No production/mainnet or asset onboarding authorization follows from the testnet result.
