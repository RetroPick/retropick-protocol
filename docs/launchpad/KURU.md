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
