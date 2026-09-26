# Kuru parameter worksheet

**Retrieved:** 2026-09-26  
**Status:** RetroPick rows are BLOCKED. Documentation examples were computed locally. No market was deployed.

This worksheet does not set protocol solvency, redemption value, or an accepted oracle. Kuru inventory is not prediction collateral and not PRISM backing.

## Sources

| Source | URL | Retrieved | Version | Classification | Uncertainty |
|---|---|---|---|---|---|
| Router `deployProxy` | https://docs.kuru.io/contracts/Router | 2026-09-26 | docs page, no semver | SUPPORTED_BY_LIVE_EVIDENCE | Call shape only. No RetroPick router is accepted |
| Deploy a market | https://docs.kuru.io/sdk/deploy-market | 2026-09-26 | docs page, no semver | SUPPORTED_BY_LIVE_EVIDENCE | Example numbers are placeholders or recommendations, not RetroPick policy |
| MarginAccount | https://docs.kuru.io/contracts/MarginAccount | 2026-09-26 | docs page, no semver | SUPPORTED_BY_LIVE_EVIDENCE | Deposit pulls ERC-20 from the caller. Spender choice for RetroPick is not made |
| Contract addresses | https://docs.kuru.io/contracts/Contract-addresses | 2026-09-26 | docs page, no semver | SUPPORTED_BY_LIVE_EVIDENCE | Mainnet router `0xd651346d7c789536ebf06dc72aE3C8502cd695CC` is listed by Kuru. It is not a RetroPick target |
| `calculatePrecisions` | https://github.com/Kuru-Labs/kuru-sdk/blob/636509c2eafd63479d3f399703354e0d09f51e18/src/create/market.ts | 2026-09-26 | `@kuru-labs/kuru-sdk` 0.0.97, commit `636509c2eafd63479d3f399703354e0d09f51e18` | MEASURED_LOCAL for the three input tuples below | The function uses JavaScript numbers. Outputs were reproduced with Node 22.14.0 and checked against `ethers` 5.7.1 |

## Helper outputs

These rows rerun published example inputs. They are not RetroPick books.

| Example | Inputs (quote, base, maxPrice, minSize, tickBps) | pricePrecision | sizePrecision | tickSize | minSize | maxSize |
|---|---|---|---|---|---|---|
| Deploy-market first snippet | 10, 1, 10000, 1, 100 | 10000 | 100000000 | 1000 | 100000000 | 1000000000000 |
| Deploy-market router example | 10, 1, 20, 0.01, 10 | 10000 | 100000 | 100 | 1000 | 1000000000 |
| SDK README example | 1, 456789, 10, 0.01, 10 | 1000000000 | 10000000000 | 10 | 100000000 | 10000000000000000 |

Command: `node research/integration/kuru/calculate_precisions.mjs`  
Log: `evidence/research/prediction/kuru/calculate-precisions-2026-09-26.json`

## Binary outcome token

The research kernel's outcome token is an ERC-20 whose `decimals()` copy the collateral. A Kuru type-0 book would be that token against some quote ERC-20. No quote, price, or fee is accepted.

| Field | Value | Classification |
|---|---|---|
| Market type | 0, two ERC-20s, from the router page | SUPPORTED_BY_LIVE_EVIDENCE for the call shape |
| Base | outcome ERC-20. No deployed address | BLOCKED |
| Quote | not chosen | BLOCKED |
| Decimals | token decimals, copied from collateral in the kernel. The pair's quote decimals are not chosen | BLOCKED as a book parameter |
| pricePrecision, sizePrecision, tickSize, minSize, maxSize | require quote, base, maxPrice, minSize, and tick bps. Those inputs are not accepted | BLOCKED |
| takerFeeBps / makerFeeBps | docs examples use 30 and 10. One comment calls 10 a rebate and another a fee. No RetroPick fee | BLOCKED |
| kuruAmmSpread | docs recommend 100 for volatile markets and 30 for stabler ones, range 10..500, multiple of 10 | BLOCKED as a RetroPick choice. The range itself is SUPPORTED_BY_LIVE_EVIDENCE |
| Allowance | Before a vault deposit the docs approve the vault. `MarginAccount.deposit` transfers ERC-20 from the caller. Native MON needs no approval on the flow guide. Which spender a RetroPick user would approve is not chosen | BLOCKED for the integration path. The two documented spenders are SUPPORTED_BY_LIVE_EVIDENCE |

## PRISM series token

ADR-R05 proposes one ERC-20 per series and does not freeze decimals. No series token exists. The same helper cannot be run until a quote and a price policy exist.

| Field | Value | Classification |
|---|---|---|
| Market type | 0 if both legs are ERC-20 | SUPPORTED_BY_LIVE_EVIDENCE for the call shape |
| Base | series ERC-20. Not compiled | BLOCKED |
| Quote | not chosen | BLOCKED |
| Decimals | not frozen | BLOCKED |
| pricePrecision, sizePrecision, tickSize, minSize, maxSize | not derived | BLOCKED |
| takerFeeBps / makerFeeBps | not accepted | BLOCKED |
| kuruAmmSpread | not accepted | BLOCKED |
| Allowance | same documented vault and margin paths. Not selected | BLOCKED |

Evidence copy: `evidence/research/prism/kuru/worksheet-2026-09-26.json`.

## Why this is not a local market simulation

A deployment or fork simulation was not run.

- This repository does not contain Kuru router bytecode.
- The address on the Kuru contract-address page is not an accepted RetroPick router. ADR-021 remains PROPOSED.
- This slice forbids deploying a market.
- No RPC endpoint was configured, so a fork was not started.

`PRED-KURU-1` stays blocked. "Existing ERC-20 pair deployment verified" is not met.
