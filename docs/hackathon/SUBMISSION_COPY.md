# Metropolis submission copy — review draft

Do not submit without founder approval. Technical demo: https://retropick-metropolis.vercel.app/launchpad/demo (2:48). Founder pitch: pending; supplied by founder later. Requirements: [portal checklist](METROPOLIS_REQUIREMENTS.md).

## Tagline — under 80 characters

The market creation layer for Monad.

## One-liner — under 160 characters

Launch a token through onchain price discovery, then graduate into protected Kuru orderbook liquidity on Monad.

## Short description

RetroPick connects token issuance to a live secondary market on Monad. Creators launch through transparent bonding-curve price discovery, then graduate to Kuru through a dedicated Coordinator and venue executor. Graduation LP shares and excess launch tokens enter permanent protected custody for the testnet candidate. The deployed demo created a real Kuru market and vault and completed a two-wallet order, fill and cancel. This is market-origination infrastructure, with a consumer interface for the same lifecycle. We are targeting creators and communities while validating demand and market quality. The contracts are a hackathon testnet candidate, not audited or mainnet-ready.

## Full description

Launching a token is straightforward. Creating a credible market—with initial discovery, liquidity and usable secondary execution—is harder. New communities face a fragmented path from issuance to a venue where traders can control their execution prices and liquidity participants can work.

RetroPick builds that market-origination layer on Monad. A creator issues a token into an onchain bonding curve. The launch commits its quote policy and graduation venue before public bonding. Once the sellable allocation is exhausted, the Factory hands assets to a dedicated Graduation Coordinator. The Coordinator maintains one authoritative conservation ledger; a Kuru executor creates and verifies the destination market, makes the initial deposit and places graduation LP shares and excess tokens into permanent custody. Completion is permissionless and retryable after a failed atomic venue transaction.

This is deployed on Monad Testnet. The canonical demo issued a token, completed bonding, graduated to a real Kuru market/vault and performed a two-wallet order, fill and cancel. The candidate's predeployment campaign passed 145 tests with no failures or skips. Architectural extraction reduced the Factory from approximately 24,565 to 23,423 runtime bytes under EIP-170. An exact integer completion constraint handles valid trading histories where terminal quote differs from the nominal threshold.

Monad's execution model supports frequent primary trading and many secondary orderbooks. Kuru supplies mature secondary execution; RetroPick supplies market origination. We are building a clear consumer journey and reusable launch infrastructure, not recreating an exchange for each asset.

Our founder reports early waitlist and social interest; supporting analytics are pending. No commercial pilots or liquidity agreements are claimed. Next comes testnet hardening, creator discovery, market-quality measurement and qualified partner integrations. External security review and asset qualification precede any mainnet candidate. Circle-USDC live smoke remains blocked by funding.

## Problem

Creators need more than token deployment: primary discovery, initial liquidity, an orderly transition and usable secondary trading. Thin liquidity and fragmented execution are product hypotheses to validate with pilots, not documented interview findings.

## Solution

Issue → bond → secure → graduate → protected Kuru liquidity → orderbook trading. Immutable launch terms and a single Coordinator make the handoff explicit and retryable.

## Why Monad

Two active market phases create frequent state changes: bonding transactions and secondary orderbook execution. Low-cost execution, fast settlement and responsive market state support many simultaneous markets. RetroPick combines asset primitives, market infrastructure and settlement within the Onchain Finance & Trading thesis.

## Why Kuru

RetroPick specializes in origination; Kuru specializes in secondary execution, limit orders and market-making workflows. Our integration creates an actual market and vault and routes real test transactions, rather than mocking an API. Depth, spreads and execution quality remain market-dependent.

## Tech stack

Solidity 0.8.26, Foundry, Monad Testnet, Kuru Router/OrderBook/AMM vault/MarginAccount, Uniswap v4 compatibility, exact-transfer quote registry, React/Next.js/TypeScript/viem frontend and wallet-direct writes. Exact bigint arithmetic; backend reads are not financial authority.

## Innovation

Two-stage market structure; Factory → Coordinator → venue-worker extraction; one secured-asset ledger; EIP-170 constraint solved architecturally; exact terminal-quote liveness; permanently protected graduation assets.

## What we built during Metropolis

The V2 delivery added quote-policy snapshots, immutable venue selection, Coordinator extraction, completion liveness, Kuru market creation/custody, V4 migration and testnet deployment/smoke tooling. The current release adds the live judge journey and evidence package. Existing V1/shared libraries and the visual prototype are foundations, not wholly new hackathon work. Verify build-window commit timestamps and disclose them in README; do not claim all repository code originated during Metropolis. AI-assisted engineering/documentation is disclosed.

## Live demo

Public frontend URL: https://retropick-metropolis.vercel.app (public reads verified; wallet E2E qualification pending).
Technical demo video ≤3 minutes: PENDING RECORDING.
Pitch video ≤2 minutes: PENDING FOUNDER RECORDING.
Canonical testnet token: `0x43e7e9b1b7d9A143573307b13D14B51580c18f15`.
[Transactions and proof](EVIDENCE_MAP.md).

## GTM / user acquisition strategy

Start with RetroPick's existing X, Telegram and Discord distribution, recruit a small creator/community pilot and observe launch and trading friction. The founder reports 30+ waitlist signups and approximately 300K X engagements; definitions/timeframe and analytics are not yet independently verified. These signal interest and distribution potential, not committed customers or trading volume. No confirmed pilot/design partners or market-maker agreements exist.

Validate creator acquisition, launch-to-graduation conversion, trader onboarding, execution quality and retention. Publish metrics with defined windows and test-traffic exclusions. Seek qualified Monad wallet/community design partners, then offer SDK/API and embedded launch flows. Prioritize credible markets and retained activity over raw launch count. Do not invent interviews or quote feedback without original evidence and consent.

## Roadmap

30 days: harden testnet, reliable frontend/feed, source verification, analytics and creator discovery. 60 days: external security review, qualified quote assets, SDK/API and partner pilots. 90 days: reviewed mainnet candidate contingent on security/asset/operational gates, plus measured ecosystem campaigns. [Partnership memo](MONAD_PARTNERSHIP.md).

## Track justification

Onchain Finance & Trading: issuance, price discovery, liquidity bootstrapping and orderbook execution are market infrastructure and asset primitives. Monad settles both lifecycle phases. Functional proof and engineering constraints support the technical case.

## Kuru new-assets bounty answers

**Asset class / customer / demand / issuance:** Creator/community-issued ERC20 markets are our actual scope. RetroPick implements issuance and onchain settlement, not a promise of issuer redemption or an unimplemented RWA category. Founder-reported audience signals are documented separately from verified contract proof. Asset-class novelty and demand remain qualification risks; no confirmed commercial commitments are claimed.

**Legal / operations / liquidity:** Testnet assets only today. Future issuers need token-rights, marketing, jurisdiction and operational review; we make no blanket compliance claim. Bonding discovers price and accumulates initial quote; deterministic graduation creates a Kuru market/vault and permanently protects initial LP/excess. Continued depth and professional liquidity participation require validation, not guarantees.

**Beyond hackathon:** Testnet hardening and creator pilots, independent security review, exact asset qualification, market-quality analytics and reusable launch APIs. Coordinate with Kuru for qualified integration and liquidity introductions without claiming a partnership exists.

## Kuru consumer bounty answers — conditional on verified live UI

**Segments:** Creator/community members discovering new tokens, early traders seeking explicit limit prices, and liquidity participants exploring new markets.

**Demand research:** Founder reports 30+ waitlist signups and ~300K X engagements, with supporting analytics pending. Community observations are hypotheses, not documented interviews. No real-user conversion, retained trading or committed market-maker claims. Functional testnet order/fill/cancel proves integration, not demand.

**Roadmap:** Reliable primary-to-secondary flow, creator pilot, defined retention and execution-quality measures, independent security review and qualified partner integration.

**Onboarding / retention:** Clear MON/Kuru launch policy, wallet-direct transactions, progress and visible Launch Proof; help users distinguish wallet balances from Kuru trading funds. Measure friction and return activity before expanding campaigns.

## Why this can become a company

Programmable market creation can serve creators, communities, apps, wallets, games, agents and qualified future issuers through a web app, SDK, API or embedded launch widget. The product links distribution and origination with existing secondary infrastructure. Potential revenue surfaces include launch/trading/graduation fees where implemented policy permits, B2B infrastructure and integrations. No revenue projections are invented. More creators → more qualified launches → more traders → more Kuru markets/activity → distribution is a proposed flywheel to validate.

## Known limitations

Testnet/hackathon candidate; unaudited; no mainnet readiness claim. Circle live smoke BLOCKED_FUNDING. Kuru is a mutable external integration, and drift fails closed for graduation. Permanent custody protects initial graduation assets but does not guarantee liquidity depth, token safety, price or scam prevention. Audience analytics, commercial demand and market-maker commitments remain unverified. Live UI/video/release verification must be complete before filing.
