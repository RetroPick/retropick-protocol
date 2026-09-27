# Frontend architecture and integration boundaries

## Scope and authority
Goal: PRODUCT-1 frontend prototype. Execution gate: mocks only; MATH-1 / CONTRACT-ARCH-1 / CONTRACT-1 / INTEGRATION-1 remain independent gates. This work does not close them. Input: repository accepted ADRs, canonical protocol/state-machine/math specifications, workflow §9.3 ResolutionSpec, and supplied frontend briefs. Behavior is SUPPORTED_BY_SIMULATION, not proof of deployed solvency.

## Modules

| Module | Responsibility |
|---|---|
| `app/` | Route composition, loading/error/not-found boundaries, metadata |
| `components/product/` | Shell, accessible primitives, demo session ledger, readonly WebMCP search |
| `features/markets/` | Event discovery/detail/activity and independent outcome visualization |
| `features/trading/` | Quote review, market/limit simulation, explicit failure scenarios |
| `features/create-market/` | Native event draft, resolution rules, collateral preview |
| `features/prism/` | Retail series discovery and separate issuer basket workflow |
| `features/portfolio/` | Positions, cash, reserved orders, cancellation, funded redemption |
| `lib/domain/` | Typed fixtures, lifecycle vocabulary, bounded arithmetic helpers |
| `lib/liquidity/` | Venue-independent source/quote/adapter contracts and registry |
| `features/launchpad/` | Umbrella discovery, launch-type selection, normal-token flow and token terminal |

URL parameters own discovery filters. Component state owns transient forms. DemoProvider owns session cash/positions/orders/history. Browser storage owns watchlists and drafts; it is never financial authority. Server and client share deterministic fixtures. There is no backend, wallet SDK, indexer or RPC dependency.

## Data authority

| Display / action | Current source | Required live authority |
|---|---|---|
| Prices, books, volume | Explicit fixture snapshot | Per-venue indexed observations with freshness |
| Native backing / OI | Fixture collateral | Native complete-set contract accounting |
| PRISM backing | Illustrative component vector | Admitted same-chain vault balances and supply |
| Resolution | Illustrative ResolutionSpec | Pinned spec, authorized final evidence |
| Redemption | Funded fixture flags | Final payout and sufficient settlement balance |
| Portfolio | Session simulation | Wallet balances, orders and finalized receipts |
| Creation | Local draft | Admitted deployment flow and actual receipt |

No fabricated contract addresses, transaction hashes, evidence hashes or live deployment claims. A configured live mode is rejected until adapters exist.

## Unified launch instruments

The original read path was `EventMarket`/token fixtures → separate summaries →
React URL filters → split token and prediction lists → two tables → specialized
detail routes → local demo ticket. Prediction was normalized for discovery but
split out again at render time. There is now one product read path:

`token fixtures + EventMarket fixtures + PRISM fixture → family adapters →
createInstrumentRepository → useLaunchInstruments(URL filter) → Token Feed /
featured cards / navbar search → getInstrumentRoute → existing detail routes`.

`lib/domain/instruments.ts` defines `LaunchInstrument`. Kind (`token`,
`prediction`, `prism`), reference class (`crypto`, `stock`, `event`, `macro`,
`other`), contract family, chain and collateral/quote pair are independent.
Normal token, prediction and PRISM entries can share a table without claiming
they share a contract, asset representation or settlement lifecycle. Unavailable
metrics are `null`; the table displays `—` and never substitutes open interest
or collateral for market cap. A crypto-referenced prediction qualifies for the
Crypto tab while remaining a prediction; its topic remains available only in
the Prediction topic selector. USDC collateral alone does not make every
prediction a crypto reference.

`lib/domain/launchpad-adapters.ts` owns normalization, route selection and
capabilities by contract family. The token source retains curve, lifecycle,
pair and intended Kuru venue. The prediction source retains YES/NO, resolution,
collateral and outcome price change. Its `market-engine-v1` reference does not
assert a deployed MarketEngine, template ID, epoch ID or ERC-20 outcome token.
The PRISM adapter carries component units, collateral and optional state pool,
claim, payoff, encoder, expiry and claim token identifiers. The fixture only
provides the fields shown in the existing PRISM preview. `prism-state-pool`
is a typed prospective family, not a deployed contract.

`lib/domain/contract-registry.ts` keys reviewed addresses and ABIs by chain ID
and family. It currently contains no verified deployments. Monad-selected
instruments cannot resolve Base Sepolia addresses. The checked-out frontend has
no indexed MarketEngine API, verified MarketEngine ABI/deployment, PRISM ABI or
PRISM deployment, nor a live wallet transaction path. Trades and claims remain
unavailable; local demo tickets keep their existing behavior. An integration
must bring chain-specific reviewed artifacts and indexed projections before
capabilities can be enabled. The UI must not silently poll RPC in place of an
indexer.

`/markets` and `/create` remain prediction-specific compatibility routes.
`/launchpad` is the product entry point. `/launchpad/create` keeps the existing
launch-kind selector and specialized wizards. The PRISM promotional card keeps
its existing layout but resolves to the same `pfedbtc` instrument ID that appears
in the single Explore table and navbar search.

## Liquidity extensibility
`LiquiditySource`, `Quote`, and `VenueAdapter` separate product from venue execution. Kuru is the only demo quote provider. Uniswap v4 is planned for native assets, with no pools or router configured. Polymarket is planned related-market discovery only: different contracts, chain, custody and resolution semantics; matching titles never imply fungibility. No aggregation, cross-chain custody, bridging, best-route claim or synthetic combined liquidity is implemented. `prepareTrade` rejects live execution.

A future adapter must supply admitted asset IDs, chain/venue identity, quote expiry, fees, slippage bounds, executable calldata and provenance. Execution must verify wallet account/chain and quote freshness at submission, then reconcile receipts/indexer state. Deployment addresses and admission decisions must come from reviewed configuration, never guessed values.

## Preserved invariants
- Native creation issues complete sets conceptually: 1 collateral ⇄ 1 YES + 1 NO; OI is not the sum of both supplies.
- Native OPEN and PRISM ACTIVE are distinct lifecycles.
- PRISM immutable vector x is nonnegative; payoff h=Gx; backing B_i >= S*x_i.
- pFEDBTC uses 0.60 FED_YES + 0.40 BTC_NO, with payoffs [0.4,0,1,0.6] in the displayed world order.
- Retail PRISM trades do not mint shares or alter backing.
- RESOLVED does not imply REDEEMABLE; settlement must be funded.
- Protocol backing, LP inventory, order cash and settlement funds are not conflated.

Basket creation is intentionally limited to two supported fixture components and normalized long-only weights. It is not a general payoff solver. Arbitrary nonlinear AND/OR structures require exact replication or rejection by a future admitted solver.

## Accessibility and responsive behavior
Semantic navigation/forms/tables, visible focus, skip link, labeled icon actions, Radix dialog/tab/select behavior, reduced-motion overrides and mobile trading sheet. Wide financial tables scroll within their container. The mobile featured shelf scrolls horizontally. No claim of a complete WCAG or assistive-technology audit.
