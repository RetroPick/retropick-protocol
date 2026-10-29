# RETROPICK — CANONICAL RETRO-UI RENOVATION
## Creative Director + Principal Web3 Frontend Engineer + Trading UX Lead + Independent QA

**GOAL ID:** RETROPICK-RETRO-UI-EXAMPLE-INTEGRATION-V1  
**Repository:** https://github.com/RetroPick/retropick-protocol  
**Canonical implementation:** `apps/retro-ui`  
**Read-only design reference:** `apps/example-ui-ux`  
**Forbidden historical implementation:** `apps/web` (zero-write guard)  
**Product:** RetroPick Launchpad on Monad Testnet, with independent research-only prediction and PRISM modules.

## ROLE, MISSION, AND STANDARD

Act as an elite multidisciplinary team: creative director, principal frontend architect, senior React/TypeScript engineer, Web3 trading UX specialist, expert chart/market-data engineer, accessible design-system architect, specialist in motion/performance, and adversarial browser QA lead.

Your assignment is to **renovate `apps/retro-ui` in place**, adopting **all suitable visual design, navigation, presentation components and UX patterns** from `apps/example-ui-ux`, then improving the result substantially. Produce a coherent, distinctive, compact, professional trading product—not a generic SaaS dashboard, a copied marketing template, a visually appealing but nonfunctional mockup, or an AI-generated collage of component libraries.

**Canonical rule:** `apps/retro-ui` stays the main production frontend and owns routes, actual data, wallet, transaction and economic behavior. `apps/example-ui-ux` is a design donor, not a new app to deploy. Do not wholesale overwrite the canonical app. Preserve and improve behavior rather than porting simulated behavior.

**Execution expectation:** Audit, plan, implement, run and inspect in the browser, repair, regression-test, and produce an evidence-backed delivery. Do not stop after writing a plan unless a genuine safety or infrastructure blocker makes implementation impossible. Do not falsely claim to have run tests or verified screenshots. Do not deploy to mainnet, change contracts/economics, submit transactions, or cut over production without existing repository authority and release gates.

## 0 — MANDATORY REPOSITORY BOOTSTRAP AND SAFETY

Read, in this order, as applicable:

1. `AGENT_GUIDE.md`, `AGENTS.md`, `.agent/README.md`, `.agent/STATE.json`, `.agent/CURRENT_GOAL.md`, `.agent/ROUTING.md` and nearest applicable local `AGENTS.md`.
2. `apps/README.md` and `docs/metropolis/execution/FRONTEND_SOURCE_OF_TRUTH.md`.
3. `docs/architecture/RETRO_UI_V2_INTEGRATION.md` and current accepted relevant decisions/ADRs.
4. `docs/launchpad/PRODUCT.md`, `PRODUCT_SCOPE.md`, `USER_FLOWS.md` and `development/launchpad/frontend/` when they exist.
5. `apps/retro-ui/e2e/README.md`, `playwright.config.ts`, `src/routes.tsx`, `src/main.tsx`, `src/lib/live/`, `src/wallet/`, `src/services/tx-pipeline.ts`.
6. Reference files from `apps/example-ui-ux` that correspond to each canonical UI feature.

Declare the task contract: GOAL, WHY, CURRENT, TARGET, DELTA, OWN, READ, READ-ONLY, DO-NOT, ACCEPTANCE, VERIFY, EVIDENCE, HANDOFF, BLOCKERS. This is a new, explicitly user-directed *visual renovation goal*. If a historical integration document says “no UI redesign” because it scoped an older integration campaign, do not silently rewrite that document or broaden the financial goal; record the new UI scope and any decision conflict in the current control-plane process.

Before modifying anything:

- Inspect `pwd`, `git remote -v`, `git branch --show-current`, `git status --short`, `git rev-parse HEAD`, `git rev-parse origin/main` (after safe fetch where appropriate), active worktrees, and uncommitted files.
- Treat user-local uncommitted/untracked changes as valuable. **Never** `git reset --hard`, `git clean`, force checkout, destructive replacement, blanket stash, or force push. Do not overwrite concurrent agent work. If useful, use a safe isolated feature branch/worktree without destroying local changes.
- Record starting SHA and a reproducible file/manifest comparison. Do not claim local checkout matches remote until verified.
- Limit writes to `apps/retro-ui`, the narrowly required workspace config if necessary, UI-focused tests, and task-owned design/evidence/goal documents. Do not edit `apps/web`, contracts, deployed ABI artifacts, SDK economic math, indexer source, referral/media service, private keys, or production deployment settings.
- Preserve `VITE_DATA_MODE` fail-closed semantics, Monad Testnet chain ID `10143`, EIP-6963 wallet discovery, transaction prep/simulation/approval/receipt flow, accurate bigint amounts, authoritative chain state, indexer freshness envelopes, and research-only module gates.

## 1 — AUDIT THE TWO ACTUAL APPS; DO NOT ASSUME THE REFERENCE IS FUNCTIONALLY CORRECT

The GitHub `main` tree has been inspected as of 2026-10-29. At that revision, **most root entries are identical** between the two apps. Differences are primarily `package.json` and `src`; inside `src`, most `hooks`, `lib`, `services`, `wallet` are identical. Focus on the changes below and reverify against the **local current HEAD**, which may differ:

- `src/index.css`: redesigned dark theme in example; reference background `#090a10`, panels around `#13151f`, purple accent around `#8b5cf6`, emerald positive and rose negative. Existing canonical tokens differ (`#000000`, `#836ef9`, mint positive). Both already share light-mode tokens and shadcn token bridge. Do not paste the reference token block blindly; produce a unified brand-driven token system.
- `src/components/shell/shell.tsx`, `sidebar.tsx`, `mobile-nav.tsx`: revised shell/sidebar/mobile layout; reference adds **`top-navbar.tsx`**. Preserve original real-wallet mode logic, skip link, command palette, route semantics, theme persistence, and keyboard shortcuts.
- `src/components/trading/primitives.tsx`, `trading.css`: changed shared primitives/styling.
- `src/features/launchpad/discovery.tsx`, `launch-table.tsx`, `token-detail.tsx`, `terminal/token-terminal.tsx`: redesigned launchpad discovery and advanced token terminal. Related chart and quote-picker modules may be byte-identical; retain functional components, do not duplicate.
- `src/features/liquidity/liquidity.tsx`, `liquidity.css`, `market-liquidity.tsx`, `market-making.tsx`: redesigned liquidity interface. Reference introduces `kuru-data.ts`, `liquidity-math.ts`, `liquidity-modals.tsx`—review whether each is mock-only, exact, and compatible with actual contract/indexer state before importing.
- `src/features/earn/*`: many changed surfaces; reference adds `components/EarnPerformanceView.tsx`, `EarnPortfolioDashboard.tsx`, `EarnProtectionView.tsx`.
- `src/features/trading/ticket-shell.tsx`: redesigned order-ticket framing; preserve validation and transaction semantics.
- `apps/example-ui-ux/package.json` currently declares the same workspace name `@retropick/retro-ui` as canonical, with extra `react-icons` and `@radix-ui/react-icons`. Ensure unambiguous builds and lockfile consistency: reference-app package renaming or exclusion from workspace is a separately reviewed narrow change; do not alter the canonical package name.

**Known real-data hazards in the example app (treat as P0 requirements):**

1. `launch-table.tsx` can render fabricated fallback `$79.07K` market cap and `$111.12K` 24h volume. It prefixes `$` to values formatted in the launch's quote denomination. Eliminate fabricated values and unverified USD conversions. Distinguish `0` from unavailable/null, use quote symbol and correct decimals, and format from bigint/string safely.
2. `earn/earn.tsx` computes approximate USD wallet valuation using a hardcoded `MON * 12.80`. Remove; show `—` / quote-denominated balance unless a verified USD rate with source/freshness is actually available.
3. `earn/earn.tsx` has a simulated “Claim All Escrow” toast claiming success, while `liquidity/liquidity.tsx` initializes `INITIAL_USER_POSITIONS` and operates example-data mutations. These must **never** appear as genuine economic state or successful transactions in `live` mode. Either integrate with qualified real hooks/actions or show an accurate disabled/unsupported state. Keep clearly labeled demo behavior only inside mock mode.
4. Inspect every other new `toast.success`, mock vault, “add liquidity”, withdraw, deposit, order, claim, APY/yield, APR, TVL, creator revenue, referral and price display for the same issue. No fabricated metrics, disabled CTA masquerading as functional, or fake “executed” outcome.
5. Do not accidentally drop canonical real-data subscriptions, query key invalidation, retries, authorization gates or wallet execution code during refactoring. In `discovery.tsx`, for example, reference and canonical imports differ; trace actual query/refetch behavior, not just visual output.

Create a **file-by-file migration matrix** with columns: canonical file, reference file, visual delta, interaction delta, data authority impact, recommendation `ADOPT/ADAPT/REJECT/KEEP`, risk P0–P3, owner, QA proof. Inventory every route in `src/routes.tsx` and every visible component state. Show an actual before/after screenshot baseline from a locally launched app rather than claiming aesthetic superiority from reading CSS alone.

## 2 — CREATIVE DIRECTION: RETROPICK TERMINAL, NOT GENERIC SaaS

Design north star: **“The precision of a professional trading desk, the speed of a token launchpad, and the clarity of a trustworthy onchain protocol.”**

Benchmark the ergonomics of Kuru order books, professional trading terminals, efficient token discovery, and crypto portfolio interfaces. Learn from patterns but do not clone competitor branding, textures, charts, protected assets, or trade flows.

Visual identity:

- Default dark mode: distinctive midnight-charcoal, crisp slate typography, RetroPick/Monad purple as **scarce functional emphasis**, restrained mint/teal for positive values, rose/coral for negative values, amber for stale/risk/attention. Light mode must remain coherent and fully legible.
- Treat color as information, not decoration. No random glow, glass overlays over financial text, gradient flooding, neon buttons everywhere, excessive shadows, emoji as core navigation, or generic bento marketing cards in the trading workspace.
- Maintain a clear brand voice and identifiable icon style; choose a consistent icon library, not a random mixture. Reference uses `lucide-react`, `react-icons`, and `@radix-ui/react-icons`; standardize visual weight where possible without discarding required icons.
- Preserve the established use of Plus Jakarta Sans and JetBrains Mono unless measured typography tests demonstrate a better combination. Use text numerals with `font-variant-numeric: tabular-nums`; numeric columns right-align. Align decimal units, signs, percentages, and timestamps consistently.
- Define primitive → semantic → component tokens; radius, border, spacing, elevation, motion, sizes, type; edit semantic tokens rather than inserting hardcoded hex values through 100 components. Example of sensible spacing scale: 4 / 8 / 12 / 16 / 20 / 24 / 32 / 40 px; vary density by context (compact terminal vs spacious educational/creation forms).
- Grid discipline: consistent gutters; optical alignment; even card padding; meaningful hierarchy; stable table row heights; layouts that do not jump when values update; no accidental horizontal page scroll.
- Use motion sparingly: 120–200ms for most navigation/feedback, CSS transforms/opacity where sensible, obey `prefers-reduced-motion`, avoid animated prices or distracting chart overlays. No unmeasured GSAP dependency just for spectacle.

Produce design artifacts: `DESIGN.md` scoped to this frontend or approved location, component inventory, tokens table, page hierarchy, responsive breakpoints, interaction states, accessibility states, screenshot comparison board, and a short “anti-slop” critique listing concrete removed inconsistencies.

## 3 — PAGE-BY-PAGE UX CONTRACTS

### A. Global shell/navigation
- Use the reference's new navbar/sidebar visual language where it improves discoverability. Preserve canonical `Shell`, command palette, wallet context, theme toggle, demo/live indicator, network, referral routing, and skip-to-content behavior.
- Desktop: coherent collapsible navigation, subtle section grouping, obvious active state, no duplicate wallet/connect CTAs. Sidebar must not dominate 1280px screens; collapse state persists correctly.
- Header: market search with keyboard shortcut, wallet/network state, context-specific actions. Keep layout stable during wallet connect/disconnect, theme changes, and route navigation.
- Mobile: primary product actions visible and reachable; navigation does not obstruct order forms or account modals; bottom safe-area accommodation; keyboard-open state stable.

### B. Launchpad discovery `/launchpad`
- Integrate the reference's header, discovery table/cards, segmented lifecycle/category filters, sorting, and search *where backed by existing data*. Do not add meaningless categories or placeholder metrics.
- Trader scan path: token identity → quote asset → live price → market cap / liquidity / volume (accurately denominated) → progress/phase → token detail. Prioritize what the user needs to decide, not vanity “trending” ornaments.
- Preserve query parameters, browser back/forward, deep links, pagination identity, debounced search, data freshness, retry states, and prefetch behavior. Test that navigating from token detail and back does **not** reset prior filters, scroll, search, category, or selected view unexpectedly.
- Loading/skeleton, empty, stale, offline, error, zero-data, unsupported feature and new-launch states all get designed versions.

### C. Token detail + professional trading terminal `/launchpad/token/:id`
- Three priority layers: (1) token and market identity + network/phase/verification, (2) **large usable chart and live market information**, (3) clear, trustworthy execution ticket.
- Build desktop grid respecting usable widths. At 1440px test a primary chart that has real visual priority, with a consistently sized ticket (~300–360px if feasible), optional order book/recent-trades rail; adapt at 1280px without squashing the chart. At 834/768px simplify; at 390/375px use intentional tabs/stacked panels and reachable buy/sell CTA.
- Preserve source-bound OHLC from `lightweight-charts` 5.2.1, proper `ResizeObserver` management, realtime streaming, cleanup, timeframe/range, tooltip/crosshair, meaningful no-data state, price precision based on quote decimals. Do not fabricate candles, synthetic price paths, artificial depth, or volume.
- Contextually separate bonding curve from graduated Kuru trading: phase, route/execution source, available order types, slippage, estimated receive, price impact, allowances, gas, min-out, trading risks, current balances and transaction state. Never imply a limit-order feature works unless actual Kuru integration supports it.
- Support skeleton, stale indexer, halted/unavailable market, disconnected/wrong-network/unsupported wallet, insufficient balance/allowance, simulation rejected, user rejected, pending receipt, confirmed/onchain but indexer lagging, reverted, replaced/cancelled, unsupported functionality.
- Mobile chart and ticket must remain usable without nested-scrolling traps; minimum usable chart height, reachable controls, scroll-safe sticky CTA, no hidden fees or confirmation states.

### D. Liquidity `/liquidity`, pools, market making
- Take the reference's more complete LP dashboard and modals as **visual reference**, but validate semantic meaning: pool token/quote denomination, APY vs APR vs no verified estimate, fee yield vs projected rewards, TVL, wallet owned position, pending state, Kuru vault versus AMM pool.
- Keep real indexer-backed pool/position paths and wallet actions. Segregate “Explore” and “My Positions” only when backed by source; never populate real wallet positions with `INITIAL_USER_POSITIONS`.
- Distinct deposit/withdraw/remove-liquidity slippage, balance and allowance states, preview, quote expiry, tx receipt, retries; disable unsupported/unqualified actions with explicit reason. Do not turn mock state updates into fake deposits/withdrawals.

### E. Earn and portfolio `/earn`
- Merge the strongest layout of `EarnHero`, performance/protection/portfolio components, claims, wallet funding, margin, owned launches, referrals, recent positions; show exactly what is actually supported in live mode.
- Distinguish wallet balance, Kuru margin, claimable escrow, referrals, realized reward, pending claim and illustrative APY. No hardcoded USD valuation, aggregate claims, pretend royalties or fake success toast.
- Implement privacy mask consistently: hide balances in cards, tables and tooltips. Maintain numerical precision and avoid converting onchain large amounts to JavaScript `Number` for authoritative math.

### F. Launch/create `/launchpad/create`
- Preserve existing wallet and issuance pipeline. Improve form hierarchy, helpful field-level errors, assets/quote selection, transaction preview, costs and irreversible action warnings. No contract-level new functionality.

### G. Other routes
- Inspect `/docs`, `/activity`, `/creator/:address`, `/prism*`, prediction routes, research and legacy redirects; update shell/theme/style consistently while retaining live-mode research/unsupported gates. PRISM is not live merely because the design exists. Avoid scope explosion into protocol or speculative financial features.

## 4 — FINANCIAL TRUST & INTERACTION INVARIANTS (NON-NEGOTIABLE)

- The chain is economic authority; indexer is a read model, not a signer. All standard user economic writes remain wallet → chain. Do not change `services/tx-pipeline.ts` behavior except a separately justified and tested UI-safe fix.
- Preserve `VITE_DATA_MODE=mock|live` fail-closed choice; live requires `VITE_INDEXER_URL`. Mock data is visibly labeled demo. No mix of mock rows and live rows on the same financial surface without unmistakable labeling; preferably no mixing at all.
- Use correct `bigint`/decimal representations, asset-specific decimals/units. `0` ≠ `unavailable`. `$` requires a verified USD conversion source; quote-denominated amounts show quote units. Avoid fake precision, stale-as-live values, imaginary APY.
- Apply appropriate freshness and chain/market phase visibility; do not bury stale, paused, halted, indexed-vs-onchain lag, Kuru identity limitations, unverified yields, graduation transitions.
- Every clickable economic CTA must map to a valid source-backed action, well-labeled disabled state, or explicitly DEMO-only interaction. Never use `toast.success()` as proof of an onchain transaction.
- Preserve the current deployed Monad V2 ABI/SDK contracts, route guards, wallet picker, RPC environment restrictions, quote asset behavior and contract safety policies.

## 5 — AGENT SKILLS AND PLUGIN ORCHESTRATION

**First inventory actual locally installed skills/plugins with their canonical paths, current documentation, and available MCP tools.** Do not hallucinate invocations or assume every skill is available. Use a bounded expert pipeline; do **not** load every design skill simultaneously or let one plugin override the repository's design decisions.

Recommended roles/workflows, subject to availability:

| Lane | Preferred installed skills (read their actual SKILL.md) | Deliverable |
|---|---|---|
| Product/visual direction | `design-consultation` (gstack), `frontend-design`, `design-taste-frontend`, `high-end-visual-design`, `redesign-existing-projects` | One coherent DESIGN.md and examples of differentiated screens |
| Plan adversarial review | `plan-design-review`, `inherit-legacy-style` | Critiqued plan; compatible legacy/style rules |
| React/code quality | `react-patterns`, `frontend-engineering-edho-ferdian`, `react-performance`, `vercel-react-best-practices` | Component boundaries, render and state architecture |
| Design implementation | `design-system`, `tailwind-design-system`, `shadcn`, `ui-styling`, `21st-ui-build` **selectively**, not as defaults | Reusable tokens and accessible primitives |
| Trading layout | `industrial-brutalist-ui` as a reference for dense layouts, `ui-ux-pro-max`, `make-interfaces-feel-better` | Precision chart/table/ticket UX |
| Motion | `emil-design-eng`, `motion-foundations`, `review-animations`, `animation-performance` | Refined, non-distracting motion |
| Browser verification | `webapp-testing`, `e2e-testing-edho-ferdian`, `playwright-cli`, `browser-use:web-gui-tester`, `click-path-audit`, `break-ui` | Reproducible before-after screenshots and E2E scenarios |
| Final design critique | `design-review` (gstack), `21st-ui-review`, `gan-style-harness` or visual judge if available | Independent fail/fix/reshoot loop |
| Performance | `performance-audit-edho-ferdian`, `browser-qa` | Actual measurements, prioritized improvements |

Optional inspiration exploration: `21st-ui-explore`, `design-shotgun`, `prototype`, `21st-cli-use`. Use them only if needed to resolve competing design directions; never paste 21st.dev components with inconsistent visual language. `video2code` is unnecessary when both React codebases already exist, unless a specific observed interaction must be replicated from a recording. `next-best-practices`/`nextjs-turbopack` are **not** appropriate to migrate the Vite+React app to Next.js. Figma/Canva are optional presentation tools, not a substitute for shipping code.

Parallelism rules: delegate *read-only audits* in parallel; give implementation agents mutually exclusive owned files; integrate sequentially; one agent owns design tokens; one agent owns the canonical master branch/worktree; QA judges the rendered application independently. Avoid duplicate conflicting edits by multiple agents to `index.css`/`shell.tsx`.

## 6 — IMPLEMENTATION PHASES AND GATES

**Phase 0 — Baseline:** Snapshot SHA/status, both-app tree/hash diff, local safe preview, all critical route screenshots in dark and light, initial Playwright baseline and console/network observations. Record current failures separately from new regressions. Check pnpm duplicate-name ambiguity.

**Phase 1 — Art direction & migration matrix:** Write DESIGN.md, UI inventory, state/route matrix, adopt/adapt/reject map, page responsive layouts, tokens and typography rules, initial visual mock/preview. Record compatibility with accepted docs; no product capability claims without source.

**Phase 2 — Core shell + primitives:** Token layer, type, dark/light theme, top navbar, sidebar/mobile nav, wallet/network, command palette, focus and global status. Keep styles tokenized, not hardcoded.

**Phase 3 — Launchpad discovery:** Bring reference layout and sorting/filter patterns; migrate to canonical live query, precision, pagination and freshness. Prove 0 invented numeric values in live output.

**Phase 4 — Trading terminal:** Integrate chart, depth, recent trades, order ticket, token identity, bonding/graduation, desktop-to-mobile transitions. Verify lifecycle and wallet/tx safety before visual polish.

**Phase 5 — Liquidity, Earn, Portfolio:** Bring reference dashboards/modals with real-data contracts and qualified actions; segregate demo fixtures. Do not ship unimplemented financial features as interactive live actions.

**Phase 6 — Route polish, failure states & accessible interaction:** Search, deep links, creation, portfolio/account, docs/research states; improve error, empty, loading, toast behavior and all keyboard/touch paths.

**Phase 7 — Browser QA & adversarial design review:** Side-by-side screenshot comparisons and actual browser interactions at all existing Playwright viewports, live read-only mode and fixture mode. Review screenshots, critique, fix, rerun. Repeat until acceptance gate met; do not self-declare visual perfection.

**Phase 8 — Evidence & handoff:** Exact commands, pass/fail, baseline vs target SHA, before/after images, changed files, migrations, data integrity notes, actual screenshots, residual blockers, rollback recipe, and draft PR. No automatic production cutover.

Commit in reviewable, functionally isolated increments. Preserve `apps/example-ui-ux` as read-only reference; no blanket copying. If agent can create a PR, prefer a draft PR with transparent failures/blockers over an unqualified claim of done.

## 7 — REQUIRED PLAYWRIGHT / UI QA

Use the repository's existing `@playwright/test` configuration and helper scripts before introducing another automation framework. `apps/retro-ui/playwright.config.ts` currently defines six viewports: 1440×960, 1280×860, 834×1112, 768×1024, 390×844, 375×740. Fixture mode runs offline on port 4317; live mode is read-only on 4318 with signing bridge disabled. E2E stores evidence in `evidence/platform/frontend/browser-validation/<timestamp>-<target>/`. Respect its network and wallet signing guards.

Run applicable commands from `apps/retro-ui` after verifying the local workspace:

```sh
pnpm typecheck
pnpm build
pnpm test
pnpm test:terminal
pnpm test:liquidity
pnpm e2e:fixture
pnpm e2e:smoke
pnpm e2e:live     # read-only, only if environment permits
```

Do not assume green results. Test terminal with active bonding, graduation-ready, graduating, graduated/Kuru, slow RPC, stale indexer, no holders, no orders, margin shortfall, rejected deposit/order, network mismatch, wallet rejection, zero values, giant values, long token names/symbols, differing quote decimals, malformed logos and media failures. Test mobile keyboard, touch targets, focus traps, reduced motion and text scaling. Preserve the default browser back/filter/scroll state. Compare screens for alignment, density, chart visibility, sidebar overlay, responsive tabs and order ticket clarity.

Use WCAG 2.2 AA as the baseline. Aim for 44px comfortable touch targets on mobile where practical; the WCAG 2.2 AA minimum target is 24px subject to its specified exceptions. Keyboard focus must remain visible and not hidden. Contrast, screen reader labels and modal focus management must be verified, not inferred from colors.

Performance: measure LCP, CLS, responsiveness/INP where tooling allows, bundle size, render commits, chart resize/cleanup, long lists and WebSocket updates. Treat LCP ≤2.5s, CLS ≤0.1 and INP ≤200ms as *targets*, not as verified results or strict universal laboratory pass/fail without appropriate measurement context. No blocking code-split regressions or runaway subscriptions.

## 8 — FINAL ACCEPTANCE: HARD GATES + TASTE GATE

**Hard safety gates (must all pass, or explicitly remain BLOCKED):**

1. Canonical frontend remains `apps/retro-ui`; `apps/web` untouched; all economic semantics and deployed contract interaction intact.
2. Typecheck/build/unit and existing mandatory E2E pass; any pre-existing failure is clearly classified against baseline.
3. All live financial numbers source-backed, correctly denominated and stale-aware. Zero fabricated USD values, mock orders, simulated earnings/positions or fake trade success in `live` mode.
4. Launchpad discovery, token detail, create flow, wallet connection, trade preview/approval/receipt, Kuru lifecycle, liquidity paths, earn/portfolio, navigation, theme and deeplinks function wherever actually supported.
5. Read-only live QA does not sign. Fixture QA rejects economic writes. No secrets, contracts, ABI/economic changes, mainnet deployment or production cutover.
6. Screenshots and interaction traces attached for required viewports, dark/light and key states.
7. No major regressions in accessibility, overflow, chart performance, route stability or bundle size.

**Taste gate:** Independent creative-direction review evaluates hierarchy, readability, rhythm/spacing, compositional precision, iconic consistency, typography, chart legibility, speed, interaction predictability and brand distinctiveness. Each screen should score ≥9/10 on the team's explicit rubric **with screenshot-linked evidence**; this is a subjective design benchmark, not a replacement for hard QA. Fail and fix generic cards, ornamental gradient pollution, unbalanced whitespace, competing purples/greens, cryptic metric units, unreadable dense tables, repetitive button styles, incorrect empty states and ineffective mobile trading paths.

**Output this exact final handoff:**
- Current baseline SHA / target SHA / branch / dirty status.
- Source comparison and adopt/adapt/reject summary.
- Completed pages and file inventory.
- Before/after browser screenshots and evidence paths.
- Full tests run with real results, including skipped/blocked tests.
- Verified live financial truth checks, including USD/quote units and mock/live separation.
- Quantitative or measured performance findings and accessible UI audit.
- Residual risks and required operator approvals.
- Draft PR URL if created, with no claim of merged/deployed unless independently confirmed.

**START NOW:** inspect the local repo and installed skills, establish baseline and migration matrix, then perform the actual renovation and verification in the current session as far as tooling allows. Do not merely copy the reference app. Deliver the best version of RetroPick's canonical trading frontend without sacrificing the truthfulness of its financial data or wallet actions.
