# Kuru token compatibility

**Retrieved:** 2026-09-26  
**Classification:** SUPPORTED_BY_LIVE_EVIDENCE for the quoted documentation pages. Not MEASURED_TESTNET. No market was deployed.

## Sources

| Source | URL | Retrieved | Uncertainty |
|---|---|---|---|
| Router `deployProxy` | https://docs.kuru.io/contracts/Router | 2026-09-26 | Page describes the call. This repo's Launchpad gate still says the RetroPick target router address and parameter policy are unresolved |
| Deploy a market | https://docs.kuru.io/sdk/deploy-market | 2026-09-26 | Examples contain empty address placeholders. Tick, fee, and spread numbers below are documentation recommendations, not RetroPick policy |
| Monad Kuru Flow decimals note | https://docs.monad.xyz/guides/kuru-flow | 2026-09-26 | Quotes MON 18 decimals and a USDC address with 6 decimals on the network that page calls mainnet. Not used as a deployment target |

Reverification trigger: Kuru changes `deployProxy`, precision math, or MarginAccount custody, or RetroPick accepts ADR-021 with concrete addresses.

## What an ERC-20 outcome or series token must provide

Kuru's router documents deployment of an order book for two ERC-20s (`OrderBookType` 0 / `NO_NATIVE`) or with native MON as base or quote (types 1 and 2). The call takes `sizePrecision`, `pricePrecision`, `tickSize`, `minSize`, `maxSize`, taker fee bps, maker fee bps, and `kuruAmmSpread`.

The SDK deploy page says:

- type 0 is two ERC-20s;
- inappropriate precision parameters can prevent limit orders;
- `calculatePrecisions` is the suggested helper;
- AMM spread minimum 10 bps, maximum 500 bps, multiple of 10;
- the page recommends spread 100 for volatile markets and 30 for stabler markets;
- after deployment, liquidity is a separate vault deposit through a margin account.

Deployment does not create liquidity. Allowance is required before an ERC-20 deposit or swap. The Monad guide says native MON does not need approval and that USDC on that network has 6 decimals, not 18.

The Kuru token-and-market deployer example parses the new token's supply with 18 decimals. That is the deployer's own token, not a rule that every ERC-20 listed through the router has 18 decimals. Router deployment reads the token addresses the caller supplies. Market params fetched later expose `quoteAssetDecimals` and `baseAssetDecimals`.

## RetroPick consequence

| Question | Answer | Classification |
|---|---|---|
| Can a normal ERC-20 be the base of a YES/quote or NO/quote book? | The documented type-0 path takes two ERC-20 addresses. Outcome tokens in the research kernel are normal ERC-20s | SUPPORTED_BY_LIVE_EVIDENCE for the interface shape. NOT_YET_VALIDATED on a live router |
| Must outcome decimals be 18? | Not according to the router page. The deployer example uses 18 for tokens it mints | INFERRED from the docs. Phase-1 recommendation remains: match the approved collateral |
| Is a deployed book a protocol market? | No. Kuru inventory is not prediction collateral and not PRISM backing | RECOMMENDATION consistent with ADR-005 / D-008 |
| MarginAccount | Documented as the account that holds vault balances for liquidity | SUPPORTED_BY_LIVE_EVIDENCE as a docs statement. No integration test was run |
| Fees and tick | Documented ranges exist. RetroPick has not accepted a prediction or PRISM parameter set. ADR-021 is PROPOSED and is a Launchpad decision | BLOCKED for a RetroPick parameter choice |

No production market was deployed. No testnet trade was executed.

## Worksheet, 2026-09-26

`research/integration/kuru/PARAMETER_WORKSHEET.md` records a second read of the router, deploy-market, MarginAccount, and contract-address pages, plus `@kuru-labs/kuru-sdk` 0.0.97 commit `636509c2eafd63479d3f399703354e0d09f51e18`. Three published `calculatePrecisions` input tuples were run locally. RetroPick book fields stay BLOCKED. The Kuru mainnet router address on the docs page is not a RetroPick target.

A later pass the same day re-read the docs index, OrderBook, OrderBook SDK, both SDK quick starts, architecture, KuruAMMVault, vaults technical, integration, how-fees-work, contract addresses, and the Monad Kuru Flow guide. No page publishes RetroPick decimals, price precision, size precision, tick, min size, max size, maker/taker fees, or a chosen allowance spender. PRED-KURU-1 stays blocked. Evidence: `evidence/research/prism/kuru/source-pass-2026-09-26.json`.
