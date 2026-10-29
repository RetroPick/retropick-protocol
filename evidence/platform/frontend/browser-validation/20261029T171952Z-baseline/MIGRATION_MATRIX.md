# Migration Matrix — RETROPICK-RETRO-UI-EXAMPLE-INTEGRATION-V1

Baseline: `main` @ `9f1be121` · donor audited at same revision (local tree verified).
Verdicts: **ADOPT** (port visually as-is) · **ADAPT** (port design, rebuild on canonical real data) · **REJECT** (do not port) · **KEEP** (canonical unchanged; byte-identical in donor).
Risk: P0 = fabricated economics / data-authority breach, P1 = functional regression risk, P2 = visual/consistency, P3 = cosmetic.

## Workspace / governance

| Canonical | Reference | Delta | Data-authority impact | Verdict | Risk | QA proof |
|---|---|---|---|---|---|---|
| `package.json` (name) | donor duplicated `@retropick/retro-ui` + adds `react-icons`, `@radix-ui/react-icons` | duplicate name broke CI frozen-lockfile | none (build identity) | ADOPT rename donor → `@retropick/example-ui-ux`; **REJECT** both icon deps | P0 | `pnpm --filter @retropick/retro-ui exec pwd` → canonical only; lockfile diff +110 |
| `apps/README.md` | (absent) | donor unmapped | none | ADOPT row added | P3 | README table |
| `docs/architecture/RETRO_UI_V2_INTEGRATION.md` | (absent) | "no UI redesign" clause conflicts | none | KEEP text + dated pointer note | P3 | goal file records supersession |

## Shell

| Canonical | Reference | Visual delta | Interaction delta | Data impact | Verdict | Risk |
|---|---|---|---|---|---|---|
| `components/shell/shell.tsx` | revised | adds TopNavbar above demo strip; 260px sidebar offset | wallet/theme move to navbar | wallet logic must stay canonical | ADAPT | P1 |
| `components/shell/sidebar.tsx` | revised | IA grouping (primary Launchpad/Liquidity/Earn&Stake + secondary Prediction/My Positions/Docs), logo-toggle collapse | research entries must gate on mock mode | nav reachability | ADAPT | P1 |
| `components/shell/mobile-nav.tsx` | icon swap only | none | none | ADOPT styling w/ lucide | P3 | |
| — | NEW `top-navbar.tsx` | sticky 56px header, breadcrumb, ⌘K pill, network pill, Launch CTA, wallet, theme | **static** "Monad Testnet" pill not chain-derived; fake demo addr `0x71C...39a`; literal `#836ef9` hexes | network pill must derive from `wallet.chainId`/DATA_MODE | ADAPT (rewrite states, keep layout) | P0 |
| `command-palette.tsx`, `theme.ts` | identical | — | — | — | KEEP | — |

## Trading shared

| Canonical | Reference | Visual delta | Interaction delta | Data impact | Verdict | Risk |
|---|---|---|---|---|---|---|
| `components/trading/primitives.tsx` | icon swap (lucide→radix-icons) | minor | none | none | ADOPT icon-consistency pass w/ **lucide** (no new dep) | P3 |
| `components/trading/trading.css` | +`.rp-head-stats`/`.rp-stat-pill`, 3-col `.rp-grid-3col`+`.rp-orderbook-col`, depth bars | stat pill strip; orderbook own column | none (presentational) | **hardcoded retired rgba** in depth bars → tokenize | ADAPT | P2 |
| `features/trading/ticket-shell.tsx` | Buy/Sell segmented control moved above header | minor | none — validation/tx semantics identical | none | ADOPT | P3 |

## Launchpad

| Canonical | Reference | Visual delta | Interaction delta | Data impact | Verdict | Risk |
|---|---|---|---|---|---|---|
| `features/launchpad/discovery.tsx` | reformatted + `O1LaunchpadHeader` mounted in live+demo | hero header w/ stat boxes | same query/refetch path retained | header stats **hardcoded** ($804.86M etc.) | ADAPT (header from real snapshot counts only; drop unverifiable stats) | **P0** |
| `features/launchpad/launch-table.tsx` (65→737) | o1.exchange redesign: trending leaderboard, rank medals, favorites, list/grid | rich | favorites local-state | **fabricated fallbacks**: `$79.07K`/`$111.12K`/`$11.45K`, `$` on quote values, liquidity from bonding %, `trades24h ?? '253'`, lifetime vol = 24h×3.8 | ADAPT (full visual port, zero fabrication; quote symbol + `—`) | **P0** |
| `features/launchpad/token-detail.tsx` | live route unchanged; demo adds synthetic depth ladder for GRADUATION_READY | orderbook pre-graduation | none | synthetic depth presented as real | REJECT synthetic ladder (keep honest no-book) | **P0** |
| `features/launchpad/terminal/token-terminal.tsx` | Kuru-DEX aesthetic: market ribbon, 3-col grid, timeframe quick-select, favorite star | major | `1m/5m/15m/1h` wired to existing interval API | values stay vm-driven, quote units preserved | ADAPT | P1 |
| `trading-chart.tsx`, `chart-data.ts`, `quote-picker.*`, `kuru-ticket.tsx`, `live-trading-ticket.tsx`, `create-launch.tsx`, `add-to-wallet-button.tsx`, `feed.css`, `launch-table.css` | identical | — | — | — | KEEP | — |

## Liquidity

| Canonical | Reference | Visual delta | Interaction delta | Data impact | Verdict | Risk |
|---|---|---|---|---|---|---|
| `features/liquidity/liquidity.tsx` (108→462) | real Pools/LPPositions **replaced** by `KuruLiquidityOverview` | vault/pool grid dashboard | withdraw = local array filter | **`INITIAL_USER_POSITIONS`**, `KURU_VAULTS`/`KURU_POOLS` fabricated; dead live query | REJECT data layer; ADAPT visual language onto canonical Pools/Positions | **P0** |
| — | NEW `kuru-data.ts` | tokens/vaults/pools constants (APR 536.4%, TVLs, USD prices) | — | pure fabrication | REJECT | **P0** |
| — | NEW `liquidity-math.ts` | strategy ranges, depth distribution, deposit allocation | — | synthetic math on fabricated prices | REJECT | **P0** |
| — | NEW `liquidity-modals.tsx` (522) | two-step Add-Liquidity + Vault detail modals, distribution visualizer | deposit = `setTimeout` → local position, no tx; hardcoded `Bal: 12.45` | fake execution | REJECT handlers; ADAPT modal shell for tx-pipeline-bound flows or disabled-with-reason | **P0** |
| `market-liquidity.tsx` (36→198) | card restyle w/ icon header, refresh, error banner | moderate | none | same `view` prop (real `liquidityView`) | ADOPT restyle | P2 |
| `market-making.tsx` (104→501) | redesigned desk UI, prefilled drafts | moderate | live branch intact | demo branch adds `toast.success('Simulated order confirmed')` + hardcoded capital rows | ADAPT (desk UI; demo toast/capital REJECT) | **P0**/P1 |
| `liquidity.css` (25→1082) | full dashboard styling | major | none | hardcoded retired palette values → tokenize | ADAPT | P2 |

## Earn

| Canonical | Reference | Visual delta | Interaction delta | Data impact | Verdict | Risk |
|---|---|---|---|---|---|---|
| `earn.tsx` | LiveHub kept + 3 regressions | performance/protection tabs restyled | performance tab live = `<EarnPerformanceView isPopulated>` | **fabricated panels in live mode**; DemoHub populated sample | ADAPT styling; fabricated live panels REJECT; demo samples allowed w/ DemoBadge in mock only | **P0** |
| `earn-hero.tsx` | unit/subValue/icon slots; hide-values eye moved; live "Review claims" button **removed** | moderate | — | **`≈ $ (MON × 12.80 || 1593.60)`** | ADAPT (subValue = honest text); REJECT USD math; RESTORE review-claims CTA | **P0** |
| — | NEW `EarnPerformanceView.tsx` | profile/PnL/rank/net-worth chart | copy card toast | 100% fabricated ($5,550.20 etc.) | REJECT for live; at most demo-only w/ badge | **P0** |
| — | NEW `EarnPortfolioDashboard.tsx` | 6-token portfolio, activities w/ fake tx hashes, heatmap | funding toast | fabricated totals/PnL/win-rate | REJECT for live; visual shell may inform LivePortfolio styling | **P0** |
| — | NEW `EarnProtectionView.tsx` | security theater (enclave, timelock "172,800 Blocks", audit button) | "Handoff verified" toast | zero verification behind it | REJECT (canonical `protected-earn.tsx` is the real protection surface) | **P0** |
| `live-earn.tsx`, `claim-sheet.tsx`, `amount.tsx`, `fund-wallet.tsx`, `send-to-wallet.tsx`, `referrals.tsx`, `strategy-vault.tsx`, `protected-earn.tsx`, `earn-hub.css` | icon swaps/reformats; vault drops PRF/AES disclosure; FundWallet default `open` true→false | minor-moderate | none | same real hooks | ADAPT styling only; KEEP disclosure text; KEEP FundWallet default `true` | P2 |
| `use-claims.ts` | identical | — | — | — | KEEP | — |

## Identical trees (KEEP, never duplicated)

`src/hooks/`, `src/lib/` (incl. `lib/live/*`, view-models), `src/wallet/`, `src/services/` (incl. `tx-pipeline.ts`), `src/components/product/`, `src/features/portfolio/`, `src/features/prism/`, `routes.tsx`, `main.tsx`.

## Hazard sweep summary (donor, must not cross over)

1. `launch-table.tsx:265,270,654-695` fabricated `$` fallbacks; `:127-179` hardcoded protocol stats — P0.
2. `earn.tsx:140` `MON*12.80`; `earn-hero.tsx:94` `|| 1593.60` — P0.
3. `earn.tsx:210,255` simulated claim toasts — P0.
4. `liquidity.tsx:91,116-118` INITIAL_USER_POSITIONS + fake withdraw; dead query `:97-102` — P0.
5. `liquidity-modals.tsx:83-115,291,369-394` fake deposits, hardcoded balance — P0.
6. `kuru-data.ts` APR 536.4%/TVL/prices — P0.
7. `market-making.tsx:203,472-478` demo success toast + hardcoded capital — P0.
8. `earn.tsx:161,166` fabricated panels in live tabs — P0.
9. `token-detail.tsx:58-86` synthetic demo orderbook — P0.
10. `top-navbar.tsx:34,107-110` fake address + static network pill — P0.
11. Legit hash-backed toasts (keep): `live-trading-ticket.tsx:61`, `kuru-ticket.tsx:93`, `live-orders.tsx:52`, `use-claims.ts:80,139`, `send-to-wallet.tsx:54`, `protected-earn.tsx:114`, `add-to-wallet-button.tsx:31`.
