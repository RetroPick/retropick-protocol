# RetroPick retro-ui Reverse Map (Phase 2 — FRONTEND_CONTRACT_MAPPING)

Campaign: `RETROPICK-V2-FULLSTACK-INTEGRATION` · branch `codex/v2-fullstack-integration` · analyzed at HEAD `8d8650a`.
Scope: `apps/retro-ui` as shipped — 100% fixture/demo, fail-closed to mock (`VITE_DATA_MODE`). Every route, screen, data source and user action is mapped to the deployed V2 capability it will need, or marked `demo-only`.
Evidence convention: `file:line` refers to `apps/retro-ui/src/**` unless another root is given. ABI facts verified against `apps/abi/*.json` (frozen catalog, deployment bundle `deployments/monad-testnet/v2.json`, chain 10143).

---

## 1. Application shell and navigation model

| Aspect | Current behavior | Evidence |
|---|---|---|
| Entry | `main.tsx` → `chooseDataMode(VITE_DATA_MODE)` throws on any mode ≠ `mock` (fail-closed), then `DemoProvider > WebMCP > Shell > Routes` | `main.tsx:14,23-31`; `lib/liquidity/registry.ts:4` |
| Shell | Desktop: fixed left `Sidebar` (search ⌘K, Home, Earn, Launch button, wallet toggle, theme toggle, Docs). Mobile (<md): top `mobilebar` (logo, search, wallet) + bottom `MobileNav` (Home, Earn, Launch). Global `demo-strip`, footer with "Demo snapshot · Sep 17, 2026" | `components/shell/shell.tsx:39`; `components/shell/sidebar.tsx:29-102`; `components/shell/mobile-nav.tsx:9-39` |
| Router | `routes.tsx` `RouteSwitch` — URL read once per load; class `RouteErrorBoundary` (retry resets), `NotFound`, `RedirectTo` (window.location.replace) | `routes.tsx:25-98` |
| Navigation model | **Full-page loads via `SafeLink`** (`window.location.assign`), no SPA router interception; query-param changes inside Discovery use `next-compat` `router.replace` (History API, no reload) | `components/product/safe-link.tsx:11-34`; `lib/next-compat.tsx:23-53` |
| Search | Radix `Dialog` searching `launchInstruments` synchronously (fixture) | `components/shell/shell.tsx:38-39` |
| Theme / watchlist persistence | localStorage `retropick-theme`, `retropick-watch`, `retropick-sidebar-collapsed` | `lib/theme.ts:7`; `components/product/provider.tsx:8-10`; `components/shell/shell.tsx:19` |
| WebMCP | Registers a read-only demo search tool (`search_retropick_demo_markets`) when the host supports `modelContext` | `components/product/webmcp.tsx:5` |

## 2. Route table (complete)

Route resolution: `routes.tsx:67-94`.

| Route | Screen component | Notes |
|---|---|---|
| `/` | `RedirectTo /launchpad` | `routes.tsx:71` |
| `/launchpad` | `LaunchpadDiscovery` | §3.1 |
| `/launchpad/create` (`?type=`) | `CreateLaunch` → `TokenLaunchWizard` (crypto/stocks) or `CreateMarket` (prediction) | §3.2 |
| `/launchpad/prediction/:id` | `MarketDetail` | §3.4 |
| `/launchpad/token/:id` | `TokenDetail` | §3.3 |
| `/markets` | legacy redirect → `/launchpad?type=&predictionTopic=` (param preserving) | `routes.tsx:45-53,75` |
| `/markets/:id` | legacy redirect → `/launchpad/prediction/:id?<params>` | `routes.tsx:55-59,87` |
| `/create` | legacy redirect → `/launchpad/create?type=` (crypto/stocks/prediction, default prediction) | `routes.tsx:61-65,76` |
| `/activity` | `ActivityFeed` | §3.5 |
| `/earn` | `EarnPage` | §3.6 |
| `/portfolio` | `Portfolio` | §3.7 |
| `/prism` | `PrismDiscovery` | §3.8 |
| `/prism/create` | `PrismCreate` | §3.8 |
| `/prism/:id` | `PrismDetail` (only `pfedbtc`) | §3.8 |
| `/creator/:address` | `Creator` (only `retropick-research`) | §3.9 |
| `/docs` | `Docs` (static) | §3.10 |
| anything else | `NotFound` | `routes.tsx:30-32,93` |

Legacy-redirect caveat for LIVE mode: several shipped screens still *emit* legacy hrefs (`/markets`, `/markets/:id`, `/create`) so every navigation from them pays one extra full-page redirect hop: `features/creator/creator.tsx:5`, `features/markets/detail.tsx:14`, `features/portfolio/portfolio.tsx:12`, `features/markets/activity.tsx:11`, `features/create-market/wizard.tsx:12-13`. They resolve correctly today; LIVE wiring should update hrefs to canonical routes (cheap, no-redesign).

## 3. Screen-by-screen map

Column key — CONTRACT CAPABILITY: the deployed V2 capability the action will need in LIVE mode, or `demo-only`.

### 3.1 `/launchpad` — Launchpad discovery

- COMPONENT: `LaunchpadDiscovery` with `FeaturedCard`, `TokenFeedTable`, grid cards, PRISM feature card (`features/launchpad/discovery.tsx:61-83`).
- HOOKS: `useLaunchInstruments` (a `useMemo` over the synchronous fixture query — `hooks/use-launch-instruments.ts:6-9`), `useDemo()` (watchlist), `usePathname/useRouter/useSearchParams` for URL state.
- DATA SOURCE: `launchInstruments` — a frozen in-memory repository built **at module import** from `normalizeLaunchSources()` = `tokenLaunches` (4 demo tokens) + `markets` (8 demo prediction markets) + `prismSeries` (`lib/domain/launchpad-repository.ts:27`; `lib/domain/launchpad-adapters.ts:126-132`; fixtures at `lib/domain/launchpad-fixtures.ts:20-37`, `lib/domain/fixtures.ts:3-13`, `lib/domain/prism-fixtures.ts:2-12`). Age labels computed against `SNAPSHOT = 2026-09-17T12:00:00Z` (`discovery.tsx:41-47`, `fixtures.ts:2`).
- USER ACTION → CONTRACT CAPABILITY:

| User action | Evidence | Capability needed (LIVE) |
|---|---|---|
| Type filter (All/Prediction/Crypto/Stocks), topic segments, sort (trending/vol/new/liquidity), list/grid switch | `discovery.tsx:73-81` | indexer/RPC launch list + per-token curve reads (`getReserves`, `trackedQuote`, volume needs indexer events); URL-state only stays local |
| Watch star (prediction rows only) | `discovery.tsx:62` | demo-only (localStorage `retropick-watch`) |
| Trade / Open token / Buy YES-NO links | `discovery.tsx:62,69` | navigation to token-detail / market-detail |
| "Launch token" CTA | `discovery.tsx:82` | → `/launchpad/create` → Factory `launchToken` |
| Explore PRISM card | `discovery.tsx:80` | demo-only (PRISM not in campaign scope) |

- Loading: none (synchronous). Error: none possible (static arrays). Empty: `Empty` component when filters match nothing (`discovery.tsx:82`). Mobile: table scrolls horizontally; featured grid stacks; bottom `MobileNav`.
- Fixture footprint replaced by LIVE: entire feed (4+8+1 instruments).

### 3.2 `/launchpad/create` — create-launch wizard

- COMPONENT: `CreateLaunch` dispatches on `?type=`: `prediction` → `CreateMarket` (`features/create-market/wizard.tsx`), else `TokenLaunchWizard` (`features/launchpad/create-launch.tsx:100-104`).
- HOOKS: `useDemo()` only (fake "Sign in to launch" gate).
- DATA SOURCE: `approvedPairAssets` fixture (`lib/domain/launchpad-fixtures.ts:12-18`) + hardcoded `ETH` option (`create-launch.tsx:42`). Output is a localStorage draft `retropick-token-launch-draft` (`create-launch.tsx:79-87`).
- USER ACTION → CONTRACT CAPABILITY:

| User action | Evidence | Capability needed (LIVE) |
|---|---|---|
| Fill identity (image, name, ticker, description, X, Telegram, website) | `create-launch.tsx:95-97` | `launchToken(TokenParams…)` — string/social fields; see `docs/frontend/CREATE_FORM_ABI_MAP.md` |
| Choose pair asset | `create-launch.tsx:97` (step 1 select) | `RetroPickQuoteAssetRegistryV2.admitted(quote, venue)` (+ native MON = address(0)); `pairToken` arg |
| Creator fee wallet + creator fee % | `create-launch.tsx:97` | `TokenParams.creatorFeeRecipient`, `TokenParams.creatorTaxBps`, bounded by `maxCreatorTaxBps()` |
| Opening buy input | `create-launch.tsx:40,70,84` | **none** — no atomic opening buy exists in the deployed direct-launch path (see CREATE_FORM_ABI_MAP §4) |
| Fee-destination radio (feeWallet / buybackVest / holders) | `create-launch.tsx:19-23` | only feeWallet/buybackVest have ABI counterparts (`creatorFeeRecipient` default; `TokenParams.buybackEnabled` + BuybackVault); `holders` has none |
| Continue → Launch | `create-launch.tsx:73-90` | `Factory.launchToken` (payable `launchFee()`), gated by `canLaunch(launcher)`; economics pin via `previewLaunchEconomics` / `previewVenueEconomics` |
| "Sign in to launch" | `create-launch.tsx:97` | real wallet connect (EIP-6963/1193), Phase 5 |

- Loading: none. Error: inline `role="alert"` validation (`create-launch.tsx:97`). Success: local-draft "success page" stating no contract was created (`create-launch.tsx:92`). Mobile: single column, rail preview stacks below.
- Also: `CreateMarket` (prediction wizard, 6 steps) is **out of campaign scope** (Prediction module = RESEARCH); every action there is demo-only (draft to localStorage `retropick-market-draft`, `wizard.tsx:11`).

### 3.3 `/launchpad/token/:id` — token detail + inline ticket

- COMPONENT: `TokenDetail` (`features/launchpad/token-detail.tsx:20-34`).
- HOOKS: none — direct synchronous `getLaunchInstrument(id)` fixture lookup (`token-detail.tsx:21`).
- DATA SOURCE: the token fixture (price/change/mcap/liquidity/volume/trades24h/curveProgressBps/lifecycle, `lib/domain/launchpad-fixtures.ts:20-37`); graduation target hardcoded `compact(43_000)` (`token-detail.tsx:33`).
- USER ACTION → CONTRACT CAPABILITY:

| User action | Evidence | Capability needed (LIVE) |
|---|---|---|
| Read price/mcap/liquidity/volume stats | `token-detail.tsx:33` | `Curve.getReserves()/quoteReserve()/tokenReserve()`, price derivation, indexer volume; `LauncherToken.totalSupply()` for mcap |
| Tabs Overview/Trades/Holders/Protocol | `token-detail.tsx:33` | Overview = `LauncherToken.getTokenInfo()/socials()/logo()/description()`; Trades = indexer events (`CurveBuy/CurveSell`); Holders = indexer (explicitly not fabricated today) |
| Buy/Sell side toggle + amount input | `token-detail.tsx:33` | `Curve.buy(minTokens, deadline, recipient)` / `Curve.sell(tokenAmount, minQuote, recipient)` — currently **button disabled** |
| Press disabled "{side} unavailable" / mobile "Trade unavailable" | `token-detail.tsx:33` | replaced by live trade submission (Phase 5/6) |

- Loading: none. Error: `Empty` "Token launch not found" for unknown ids (`token-detail.tsx:25`). Mobile: `desktop-ticket` rail hidden; fixed bottom `.mobile-trade` bar with the disabled button (no Sheet).
- Transaction-UI states: none — the inline ticket is a static quote preview (estimated receive = `Number(amount)/currentPrice`, "Fees: Protocol configured", "Slippage: Unavailable").

### 3.4 `/launchpad/prediction/:id` — markets detail + TradeTicket

- COMPONENT: `MarketDetail` (`features/markets/detail.tsx:14`) + `TradeTicket` (`features/trading/ticket.tsx:13-16`).
- HOOKS: `useSearchParams` (initial outcome from `?outcome=`), `useDemo()` inside the ticket.
- DATA SOURCE: `markets` fixture (`fixtures.ts:3-13`); chart is 40 synthetic points (`detail.tsx:14`); order book tab is a fabricated ladder (`detail.tsx:14`); liquidity sources from `lib/liquidity/registry.ts:2`; `TradeTicket` quotes from `demoVenue.quote()` (`lib/liquidity/registry.ts:3`).
- USER ACTIONS: chart outcome/timeframe segments, 5 tabs, YES/NO quick-buy links (`?outcome=`), open trade Sheet (mobile). All demo-only — **Prediction module is not in the V2 campaign scope**. The screen matters to the campaign for two reusable assets: (a) `TradeTicket` phase machine (§4), (b) the bottom-Sheet mobile trade pattern.
- Loading/empty: not-found `error-page` for unknown id; no loading (sync).

### 3.5 `/activity`

- COMPONENT: `ActivityFeed` (`features/markets/activity.tsx:11`).
- HOOKS: `useDemo().events` merged with fixture `activities`.
- DATA SOURCE: session demo events + 16 fixture rows (`fixtures.ts:15`). "Source" column always "Demo fixture".
- USER ACTIONS: filter segments, text search, **demo data-availability state select** (Normal/Loading/Stale/Unavailable — a preview of indexer states: `Skeleton` loading, stale-read warning banner, unavailable error banner, `activity.tsx:11`).
- Capability needed (LIVE): indexer event journal (`TokenLaunched`, `CurveBuy/CurveSell`, `Trade`, escrow/buyback events). No contract writes.

### 3.6 `/earn`

- COMPONENT: `EarnPage` + panels (`features/earn/earn.tsx:42-124`).
- HOOKS: none (local `EARN` constant snapshot of zeros, `earn.tsx:12-19`); embeds `Portfolio` behind a view toggle.
- USER ACTIONS → CONTRACT CAPABILITY:

| User action | Evidence | Capability needed (LIVE) |
|---|---|---|
| "Claim all" (toast) | `earn.tsx:39` | `FeeEscrow.claim()/claimToken(token, max)` + `BuybackVault.release(token)` |
| Copy address / activate referral link | `earn.tsx:31-36,52-67` | demo-only (no referral contract) |
| Cash out (MoonPay bank/card, wallet) | `earn.tsx:79-96` | demo-only; **REMOVE-COPY** (see §5 I-12) |

- Reads needed (LIVE): `FeeEscrow.balanceOf(creator)/balanceOfToken`, `BuybackVault.releasable/totalLocked/totalReleased/vestedAmount/vestingStart/vestingTerms`.

### 3.7 `/portfolio`

- COMPONENT: `Portfolio` (`features/portfolio/portfolio.tsx:12`).
- HOOKS: `useDemo()` (positions/orders/events/balance/connected).
- DATA SOURCE: `initialPositions` fixture (`fixtures.ts:14`) mutated only in-session; marks computed from `markets` fixture prices (`portfolio.tsx:12`).
- USER ACTIONS: tabs (Positions/Native/PRISM/Open orders/Redeemable/History), demo-wallet connect, cancel demo order, redeem dialog (burn-and-payout simulation).
- Capability mapping: positions on launch tokens (LIVE) = wallet reads `LauncherToken.balanceOf(address)` + curve state; creator claims = FeeEscrow/BuybackVault; "Redeem" (outcome redemption) is Prediction-module semantics → demo-only. Open limit orders (LIVE, Kuru) = `OrderBook.s_orders` reads + cancels.

### 3.8 `/prism`, `/prism/create`, `/prism/:id`

- COMPONENTS: `PrismDiscovery`, `PrismDetail` (only id `pfedbtc`), `PrismCreate` (localStorage draft `retropick-prism-draft`), plus `Payoff` table and `TradeTicket prism` variant (`features/prism/prism.tsx:13-15`).
- DATA SOURCE: `prismSeries` fixture; `basketPreview()` bounded UI arithmetic (`lib/domain/math.ts:2-5`).
- PRISM is RESEARCH (MATH-1 gate FAIL per `.agent/STATE.json`); every action is demo-only and **out of campaign scope**. The screens must keep rendering unchanged; nothing in the V2 integration may implement PRISM issuance/trading.

### 3.9 `/creator/:address`

- COMPONENT: `Creator` — only `retropick-research` renders a grid of the 8 fixture prediction markets (`features/creator/creator.tsx:5`); any other address → "Creator not found".
- LIVE relevance: pattern for the creator profile (tokens by `getLaunchedToken`/creator linkage). Prediction-grid content is demo-only.

### 3.10 `/docs`

- Static guide, accurate demo disclosure ("What works in this demo?" `features/docs/docs.tsx:4`). No actions. Must be updated when LIVE mode lands (demo claim list becomes stale).

## 4. Transaction-UI states (TradeTicket phase machine)

`features/trading/ticket.tsx` — the only transaction-shaped UI in the app; it is the designated chassis for the live tx pipeline (Phases 5–6).

- Phases: `Review` → `Approval preview` → `Simulated submission` → `Confirming demo result` → `Complete` (`ticket.tsx:15`, 450 ms steps).
- Quote model: `Quote {spend, quantity, averagePrice, fee, minimumReceived, expiresAt, provenance:'DEMO'}` from `demoVenue.quote()` — spend ≤ 10,000, fee 0.10%, minimumReceived = 99.5%, 30 s validity (`lib/liquidity/registry.ts:3`).
- Failure previews (scenario select, `ticket.tsx:16`): Wrong network, Rejected signature, Venue unavailable, Stale/expired quote — each maps to a real wallet/tx failure class for LIVE.
- Guards: `running` ref blocks dialog dismissal mid-flight (`ticket.tsx:16`); quote-expiry disables confirm via 1 s ticker (`ticket.tsx:13`); sell bounded by held quantity; buy bounded by demo balance (`ticket.tsx:13`).
- Wallet gate: disconnected → "Use demo wallet" button (`demo.setConnected(true)`).
- Order types: Market (buy/sell), Limit (buy only, "Simulates an open order. No automatic fill.").
- LIVE deltas required: real quote from curve/Kuru math (bigint), real phases (wallet signature → tx hash → receipt wait → revert reason decode), `prepareTrade` currently throws `LIVE_EXECUTION_UNAVAILABLE` (`lib/liquidity/registry.ts:3`).

## 5. Verified known issues (file:line evidence)

Dispositions: **PRESERVE-AS-DEMO** (correct demo behavior, keep out of LIVE path) · **FIX-IN-LIVE-MODE** (must change when LIVE wiring lands) · **REMOVE-COPY** (factually false product reference; correct regardless of mode).

| # | Issue | Evidence | Disposition |
|---|---|---|---|
| I-01 | Create form brands the product as "Pons" on "Robinhood Chain" ("Launch a token on Pons." / "Two steps on Robinhood Chain.") | `create-launch.tsx:97` | REMOVE-COPY |
| I-02 | Hardcoded ETH launch economics: `LAUNCH_FEE='0.0005 ETH'`, `GRADUATES_AT='4.20 ETH'`, `CURVE_FEE='1.0%'`, `SUPPLY='1,000,000,000'` displayed as facts | `create-launch.tsx:14-17` (+ used at :97) | FIX-IN-LIVE-MODE (replace with `launchFee()`, `getLaunchConfig()` supply/threshold/curveFeeBps, `previewLaunchEconomics` pin — see CREATE_FORM_ABI_MAP §5) |
| I-03 | Fixture quote assets: `approvedPairAssets` = mon/usdc/wbtc/nvdax/aaplx (provenance DEMO) plus a hardcoded `ETH` first option — Monad's native is MON; ETH/WBTC/NVDAx/AAPLx are not admitted registry quotes | `lib/domain/launchpad-fixtures.ts:12-18`; `create-launch.tsx:42` | FIX-IN-LIVE-MODE (fetch `quoteRegistry.admitted(quote, venue)`; native MON = address(0); hide unadmitted) — REMOVE-COPY for the `ETH` label (see I-03a) |
| I-04 | Opening-buy input has no contract semantics: persisted to draft, never a tx arg; no atomic opening buy exists on the deployed direct path | `create-launch.tsx:40,70,84` | FIX-IN-LIVE-MODE (remove or repurpose; `launchTokenFor` is forwarder-only — `NotLaunchForwarder` error in `apps/abi/RetroPickLaunchFactoryV2.json`) |
| I-05 | Fee-destination radios exceed the deployed ABI: `holders` ("fees paid to token holders") has no counterpart in any of the 11 priority ABIs; `buybackVest` copy hardcodes "5 years" and "the protocol keeps part of every release" without reading `BuybackVault.VESTING_DURATION()`/terms | `create-launch.tsx:19-23,97` | FIX-IN-LIVE-MODE for buybackVest copy (read `vestingTerms/VESTING_DURATION`); REMOVE-COPY for `holders` option |
| I-06 | DemoProvider wallet is a boolean toggle with a fabricated 10,000 USDC balance; sidebar/mobile "Connect wallet" flips it with no wallet | `components/product/provider.tsx:7`; `components/shell/sidebar.tsx:87`; `components/shell/shell.tsx:39` | PRESERVE-AS-DEMO in mock mode; FIX-IN-LIVE-MODE (real EIP-6963/1193 provider, Phase 5; never mix into live state) |
| I-07 | Synchronous fixture discovery: repository built at module import; `useLaunchInstruments` is a `useMemo`; no loading/error path exists on the feed | `lib/domain/launchpad-repository.ts:27`; `hooks/use-launch-instruments.ts:6-9`; `discovery.tsx:78` | FIX-IN-LIVE-MODE (async indexer/RPC reads + loading/error/empty states) |
| I-08 | Token detail has no live market state: fixture snapshot only, illustrative chart (`Spark`), hardcoded 43,000 target, ticket disabled | `token-detail.tsx:25-33` | FIX-IN-LIVE-MODE (curve reads `getReserves/graduationThreshold/feeBps`, indexer history; enable ticket) |
| I-09 | `chainId: 143` for Monad — the deployed V2 chain is **10143**; any executable-path check composed with `verifiedDeployments` (keyed 10143) can never resolve | `lib/domain/launchpad-adapters.ts:9`; `lib/domain/verified-deployments.ts:33-37` | FIX-IN-LIVE-MODE (single chain descriptor = 10143) |
| I-10 | Financial values flow through `Number()`/floats everywhere (fixtures are `number`); goal invariant requires exact bigint with `Number()` only at display | `lib/domain/instruments.ts:81-88` (number-typed); `token-detail.tsx:28-29,33`; `discovery.tsx:36-38`; `lib/domain/launchpad-repository.ts:43-45`; `ticket.tsx:13-15`; `portfolio.tsx:12` | FIX-IN-LIVE-MODE (live adapters must carry bigint end-to-end; display formatters last) |
| I-11 | Kuru actions are not connected to a real wallet: `TradeTicket.simulate()` mutates session state; `demoVenue.prepareTrade` throws; venue rows show Kuru "DEMO" | `ticket.tsx:13-16`; `lib/liquidity/registry.ts:2-3` | FIX-IN-LIVE-MODE (Phase 5/6 wallet + tx engine; Kuru order path via MarginAccount/OrderBook) |
| I-12 | Earn screen copy references other products/fintechs: "Everything you've earned on **Bags**", Solana-style address `3hKz...6nPw`, "0 SOL", MoonPay bank/card cash-out, "Coinbase, Binance, Solana, or Robinhood", referral "Earn 50% of protocol fees", "Deployers earn 0.20% from every trade" | `features/earn/earn.tsx:12-19,60,74,86,91,102` | REMOVE-COPY (factually false for RetroPick; no such integrations/contracts exist) |
| I-13 | Disabled buy button in token-detail ("{side} unavailable" desktop, "Trade unavailable" mobile) — correct for demo, but is the single integration point for curve trading | `token-detail.tsx:33` | PRESERVE-AS-DEMO until Phase 5/6; then FIX-IN-LIVE-MODE |
| I-14 | Legacy hrefs emitted by live screens (`/markets`, `/markets/:id`, `/create`) cause extra full-page redirect hops | `creator.tsx:5`; `detail.tsx:14`; `portfolio.tsx:12`; `activity.tsx:11`; `wizard.tsx:12-13` | FIX-IN-LIVE-MODE (point at canonical routes) |
| I-15 | Creator-fee upper bound hardcoded "10.0%" in validation and copy, instead of reading `maxCreatorTaxBps()` | `create-launch.tsx:68,97` | FIX-IN-LIVE-MODE |
| I-16 | Discovery age labels anchored to frozen `SNAPSHOT` (Sep 17, 2026) — drifts stale over time | `discovery.tsx:41-47`; `fixtures.ts:2` | PRESERVE-AS-DEMO (fixture-only); LIVE reads use block timestamps |
| I-17 | `WebMCP` demo tool exposes `/markets/...` legacy paths in results | `components/product/webmcp.tsx:5` | FIX-IN-LIVE-MODE when routes are canonicalized |
| I-18 | Portfolio/Activity rows link to `/markets/<id>` for prediction positions — after redirect these work, but token positions (LIVE) will need `/launchpad/token/<addr>` links | `portfolio.tsx:12`; `activity.tsx:11` | FIX-IN-LIVE-MODE |
| I-19 | Quote-asset symbol `ETH` in the pair selector is factually wrong for Monad testnet (native = MON) even as a demo default | `create-launch.tsx:42` | REMOVE-COPY |
| I-20 | Success page claim "the curve does not open from this interface" remains true; but with LIVE mode the create flow WILL open curves — copy must switch with mode | `create-launch.tsx:92` | FIX-IN-LIVE-MODE (mode-aware copy) |

## 6. Architecture seams future integration must respect

1. **The 10 tsc-compiled domain files** (`apps/retro-ui/scripts/test-frontend.mjs:3`): `lib/domain/{math,types,fixtures,launchpad-types,launchpad-fixtures,prism-fixtures,instruments,contract-registry,launchpad-adapters,launchpad-repository}.ts`. They are compiled with bare `tsc --module commonjs` and executed under `node --test`, so they must **never import workspace packages** (`@retropick/*`) or anything requiring a bundler. `verified-deployments.ts` imports `@retropick/abi/abi` and is therefore deliberately *outside* this list — do not move it in. The 17 domain tests (`pnpm test`, passing at this HEAD) pin this boundary.
2. **VITE_DATA_MODE fail-closed gate**: `main.tsx:14` calls `chooseDataMode()`; `lib/liquidity/registry.ts:4` throws for any value other than `mock` ("Live adapters are not configured. Fixtures cannot be used as live data."). LIVE wiring must keep this fail-closed contract: an unconfigured live mode must throw, never render fixture data as live.
3. **contract-registry / verified-deployments composition seam**: `contract-registry.ts:11` keeps an *empty* `contractRegistry` (test-safe, no workspace imports); `verified-deployments.ts:33-37` holds the Sourcify-verified chain-10143 factory entry (address `0xa7f18b9e…682454`, commit `f0363249…`, ABI from `@retropick/abi`). The documented composition is `resolveContractDeployment(chainId, family, verifiedDeployments)` / `hasExecutableContract(...)` (`contract-registry.ts:13-24`; used at `launchpad-adapters.ts:121`). New deployments get added to `verifiedDeployments` (or a live-only registry module) — never by mutating `contractRegistry`.
4. **Provenance literal type**: `LaunchInstrument.provenance: 'DEMO'` (`lib/domain/instruments.ts:80`; the literal is asserted across fixtures and `Quote.provenance: 'DEMO'` in `lib/liquidity/types.ts:4`). Widening to `'DEMO' | 'LIVE'` is a deliberate type-contract change touching all normalizers — it is the designed single switch that lets the type system keep demo data out of live state; do not bypass with `as any`.
5. **Watchlist localStorage**: key `retropick-watch`, JSON string array, synced via `storage` + custom `retropick-watch` events through `useSyncExternalStore` (`components/product/provider.tsx:8-10`). Keep as the demo/local surface; a LIVE watchlist must not silently reuse the same key without a migration decision.
6. **DemoProvider state surface** (`components/product/provider.tsx:5`): `connected/setConnected`, `balance`, `positions`, `orders`, `events`, `trade()`, `sell()`, `addOrder()`, `cancelOrder()`, `redeem()`, `watch/toggleWatch`. Every financial mutation in the app flows through it today. LIVE mode must introduce its own wallet/tx store; DemoProvider stays the mock-mode engine (constraint: demo data never mixes into LIVE state).
7. **Component inventory**: Radix-based shadcn primitives in `components/ui/` — `button`, `checkbox`, `dialog`, `select`, `sheet`, `skeleton`, `sonner`, `table`, `tabs`; product primitives in `components/product/ui.tsx` — `Segments` (Radix Tabs), `TokenIcon`, `Status`, `Empty`, `Stat`, `Spark`; plus `safe-link.tsx`, `provider.tsx`, `webmcp.tsx`, `Icons.tsx`, shell trio (`shell/sidebar/mobile-nav`). No new UI framework dependencies are allowed (campaign constraint: viem only). Interactive-state needs (tx dialogs, wallet sheets) must be met from this inventory.
8. **Navigation contract**: full-page `SafeLink` navigation by design (embedded-browser reliability, `safe-link.tsx:26-30`); `next-compat.tsx` supplies `usePathname/useSearchParams/useRouter` over the History API. Route params remain the single source of truth (e.g. `?outcome=`, `?type=`, `?sort=`); any live integration keeps URL-driven state rather than introducing client caches of truth.

## 7. Baseline capture (companion evidence)

`evidence/launchpad/fullstack-integration/baseline/` — desktop (1440x900) + mobile (390x844) PNGs for all 9 canonical routes, captured with the gstack browse daemon against `pnpm dev` (vite, port 3000). Console-error check per page: **zero errors on all 9 routes**. Domain tests at this HEAD: **17/17 pass**.
