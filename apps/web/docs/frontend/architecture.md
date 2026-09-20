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
