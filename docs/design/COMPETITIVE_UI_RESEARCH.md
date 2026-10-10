# Competitive UI Research — Pons, Bags → RetroPick trading terminal

Status: campaign Section 1 deliverable. Captured 2026-10-10, read-only browsing, no wallet connected, no signing.
Evidence (agent-invoked Playwright MCP): `evidence/platform/frontend/browser-validation/mcp-gate-b-agent/`
(`pons-launchpad-agent-mcp.png`, `pons-token-agent-mcp.png`, `bags-home-agent-mcp.png`, accessibility snapshots).

References are interaction patterns only. No source code, assets, branding, copy, fee policy or currency is taken from either product. RetroPick protocol semantics (MON / real quote asset, Curve → Kuru, actual Kuru order policy, actual creator fee) override every reference.

## Pons (trading clarity, lifecycle discovery)

Observed on `/launchpad` and a token page:

| Pattern | Observation | RetroPick adoption |
|---|---|---|
| Token identity | Logo, name, symbol, creator, age, pair, short address + copy + explorer, all in one row block | `TokenIdentity` + meta row (`LifecycleBadge`, `PairBadge`, `AddressChip`) |
| Price hierarchy | Large price with 24h change directly under it; market cap secondary at top-right | Large price + sourced 24h change; MCap secondary |
| Chart toolbar | Indicators · Line/Candles · `1m 5m 1h 6h 7D All` in **one** group | Adopted, but **range and candle interval are split** into two radiogroups. Pons' single group mixes resolutions (1m/5m/1h) with ranges (7D/All), which is ambiguous; RetroPick follows the indexer contract (`range` × `resolution`) |
| Ticket | Right rail. `Market | Limit` first, `Buy | Sell` second, Pay field with unit, 25/50/75/Max, You receive, Slippage 1.0% | Same order and controls via a shared `TicketShell`; slippage presets are the existing 0.1/0.5/2% values applied as an exact minimum |
| Metric strip | Market cap · Holders · Trades · Supply · Creator earned under the chart | Same five; values shown only when a real source exists (Creator earned per launch is not indexed → `—` + definition) |
| Discovery | Market cap / New / Active / Near graduation / Graduated, "Any pair" dropdown, List/Grid toggle, columns Token · Pair · Graph · Market cap | Same lifecycle IA over indexer filters and the real `/v1/pairs` registry |
| Trades / Holders | Tabs under the page with "Earlier trades" pagination | Dense `DataTable`, cursor pagination, never claims completeness |

## Bags (earnings / portfolio IA)

Observed: Home with Trending/Pulse tabs, sidebar with Home / Trade / Earn / Launch. Earn is a first-class destination with a claimable hero.

Adoption: one Earn & Portfolio hub with a claimable hero, breakdown by real source, wallet assets, margin, created launches, orders and claim history. Not adopted: SOL denomination, royalty percentages, implied payouts, and fiat or exchange destination logos.

## Competitor behaviour RetroPick must not copy (Section 33)

- ETH/WETH or SOL quote labels → RetroPick shows MON or the launch's real quote symbol.
- USD-denominated launch prices on testnet → quote-denominated values; MON has no implied USD value.
- Fixed limit expiry ("expires in 30 days") → Kuru orders are rendered as **Good till cancelled (GTC)**, the actual order policy.
- Fixed creator royalty percentages → the creator fee comes from the launch configuration (`economic.tax` bps).
- A single CTA implying one atomic action → "Deposit & place order" previews **two wallet signatures**.

## RetroPick identity rules (Section 2)

Keep the mint accent, black/off-white canvases, JetBrains Mono labels and Plus Jakarta Sans text. Keep the Monad network label, the Curve → Kuru lifecycle language, Launch Proof/Protocol transparency as a first-class tab, and Prediction / Crypto / PRISM navigation. Demo data is always labelled DEMO / SIMULATED.

## Zero AI-slop checklist (Section 36)

No gradient hero cards on trading screens, no glassmorphism, no decorative illustrations, no emoji, no fake metrics, no nested dashboard cards, no oversized headings outside the token name and price, motion only for state changes, and reduced-motion respected.
