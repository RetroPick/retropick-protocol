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

## Second primary-source pass, 2026-09-26

The docs index at https://docs.kuru.io/llms.txt was read again. It has no page titled precision calculator. Precision still comes from `ParamCreator.calculatePrecisions` on the deploy-market page and in `@kuru-labs/kuru-sdk` 0.0.97. No RetroPick market was deployed. No RPC read of a live book was performed. Official market addresses are not RetroPick markets.

| Source | URL | Retrieved | Version / date | Classification | Uncertainty |
|---|---|---|---|---|---|
| Docs index | https://docs.kuru.io/llms.txt | 2026-09-26 | docs index, no semver | SUPPORTED_BY_LIVE_EVIDENCE | No precision-calculator page is listed |
| Router | https://docs.kuru.io/contracts/Router | 2026-09-26 | docs page, no semver | SUPPORTED_BY_LIVE_EVIDENCE | Call shape only. No RetroPick values |
| Deploy a market | https://docs.kuru.io/sdk/deploy-market | 2026-09-26 | docs page, no semver | SUPPORTED_BY_LIVE_EVIDENCE | `calculatePrecisions` examples are not a RetroPick book |
| OrderBook SDK | https://docs.kuru.io/sdk/orderbook-sdk | 2026-09-26 | docs page, no semver | SUPPORTED_BY_LIVE_EVIDENCE | Reads params from a caller-supplied market |
| SDK quick start | https://docs.kuru.io/sdk/quickstart-sdk | 2026-09-26 | docs page, no semver | SUPPORTED_BY_LIVE_EVIDENCE | Price and size in the sample are empty placeholders |
| Python SDK quick start | https://docs.kuru.io/sdk/py-sdk-quickstart | 2026-09-26 | docs page, no semver | SUPPORTED_BY_LIVE_EVIDENCE | Says `load_all_configs()` fetches on-chain params. It does not print them |
| Architecture | https://docs.kuru.io/contracts/Architecture-overview | 2026-09-26 | docs page, no semver | SUPPORTED_BY_LIVE_EVIDENCE | Warns about low `sizePrecision` and wrong `pricePrecision`. No numeric policy |
| OrderBook | https://docs.kuru.io/contracts/OrderBook | 2026-09-26 | docs page, no semver | SUPPORTED_BY_LIVE_EVIDENCE | `addBuyOrder(uint32 _price, uint96 _size, bool _postOnly)` is a type signature |
| MarginAccount | https://docs.kuru.io/contracts/MarginAccount | 2026-09-26 | docs page, no semver | SUPPORTED_BY_LIVE_EVIDENCE | `deposit` transfers ERC-20 from the caller. Spender for RetroPick is not chosen |
| KuruAMMVault | https://docs.kuru.io/contracts/KuruAMMVault | 2026-09-26 | docs page, no semver | SUPPORTED_BY_LIVE_EVIDENCE | Vault formulas below. Not a RetroPick market |
| Vaults technical | https://docs.kuru.io/contracts/Vaults-technical | 2026-09-26 | docs page, no semver | SUPPORTED_BY_LIVE_EVIDENCE | 30 bps is a worked example of the curve |
| Integration | https://docs.kuru.io/contracts/Integration | 2026-09-26 | docs page, no semver | SUPPORTED_BY_LIVE_EVIDENCE | Indexer events only |
| How fees work | https://docs.kuru.io/liquidity/how-fees-work | 2026-09-26 | docs page, no semver | SUPPORTED_BY_LIVE_EVIDENCE | LP spread examples, not RetroPick maker/taker bps |
| Contract addresses | https://docs.kuru.io/contracts/Contract-addresses | 2026-09-26 | docs page, no semver | SUPPORTED_BY_LIVE_EVIDENCE | Addresses without price, size, tick, min, max, or fees |
| Monad Kuru Flow guide | https://docs.monad.xyz/guides/kuru-flow | 2026-09-26 | docs page, no semver | SUPPORTED_BY_LIVE_EVIDENCE | MON and USDC decimals for that guide's mainnet. Not a RetroPick book |

### Quotations that do not fill a RetroPick row

KuruAMMVault: "SPREAD_CONSTANT - Spread between bid/ask prices (e.g., 100 = 1% spread)." "For first deposit, mints minimum liquidity (10^3 shares) to margin account." Ask size `(SPREAD_CONSTANT * baseAmount) / (20000 + SPREAD_CONSTANT)`. Bid size `(SPREAD_CONSTANT * baseAmount) / 20000`. The vault initialize text says it approves the margin account for unlimited transfers. That is the vault's own approval, not a RetroPick user spender.

How fees work: "When you set a fee tier (like 0.05% or 0.30%), you're setting how far apart your bid and ask orders are spaced." Those are LP spread examples. The page does not set `takerFeeBps` or `makerFeeBps` for a RetroPick market.

Contract addresses lists mainnet MON-USDC `0x065C9d28E428A0db40191a54d33d5b7c71a9C394` and MON-AUSD `0x131a2e70a5b31a517a74b8c567149bc294470da9`, plus router `0xd651346d7c789536ebf06dc72aE3C8502cd695CC`. The page does not publish price precision, size precision, tick, min size, max size, or maker/taker fees for those markets.

Monad Kuru Flow guide, token table: MON native `0x0000000000000000000000000000000000000000` decimals 18; USDC `0x754704Bc059F8C67012fEd69BC8A327a5aafb603` decimals 6. "Native MON does not require approval." For an ERC-20 Flow swap the guide checks allowance against `quote.transaction.to`. The sample sets `REFERRER_FEE_BPS = 50`. That is an integrator example on the aggregator path, not a RetroPick order-book fee and not a chosen allowance spender.

Python SDK: "`load_all_configs()` automatically loads `config.toml`, fetches the market's on-chain params, and sets `price_precision`, `size_precision`, `tick_size`, and token addresses/decimals/symbols." The page does not print a market's numbers. `deposit_base(..., auto_approve=True)` does not name the spender.

### RetroPick rows after this pass

Decimals, price precision, size precision, tick, min size, max size, maker fee, taker fee, and allowance spender stay BLOCKED. The sources above were checked so that block is not a missed page. Documentation examples were not copied into the RetroPick rows.
