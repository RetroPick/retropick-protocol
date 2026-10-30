# Engineering Handoff — RETROPICK-RETRO-UI-EXAMPLE-INTEGRATION-V1

**Date:** 2026-10-30 · **Engineer:** renovating agent (Principal Frontend / Creative Director / QA roles per master prompt)

## 1. SHAs, branch, dirty status

- **Baseline SHA:** `9f1be121` (= origin/main at start; working tree clean except the untracked master prompt)
- **Target branch:** `feat/retro-ui-terminal-renovation-v1`
- **Target SHA:** see `git log` head of the branch (`disabled primary buttons stay legible` commit)
- **Dirty status at handoff:** clean except this evidence bundle (committed in the same branch)
- apps/web, contracts/, packages/launchpad-sdk/, apps/indexer/, apps/abi/, deployments/ verified untouched (`git diff main --name-only` filtered — only owned paths present)

## 2. Source comparison and adopt/adapt/reject summary

Full file-by-file matrix: `../20261029T171952Z-baseline/MIGRATION_MATRIX.md`.

- **ADOPT (visual):** donor surfaces/typography direction, top-navbar layout, sidebar IA grouping, o1-style trending rail + richer grid cards, 3-column terminal workspace concept, liquidity hero/tabs styling.
- **ADAPT (rebuilt on canonical data/logic):** LaunchpadHeader (real snapshot counts only — donor's six hardcoded protocol stats dropped), launch table (donor hierarchy, canonical lifecycle-filter labels — donor's renames `active→"Vol 24h"`, `near-graduation→"Liquidity"` were semantically false and rejected), market ribbon (honest metrics; donor's fake pair-dropdown, "kuru.io" label, fabricated OHLC header, fake "Orderbook Syncing" panel all rejected), ticket Buy/Sell placement (venue header + demo badge kept — donor deleted them), liquidity tab/link treatments.
- **REJECT:** `kuru-data.ts`, `liquidity-math.ts`, `liquidity-modals.tsx`, `INITIAL_USER_POSITIONS`, `MON × 12.80` USD math, simulated claim/order toasts, `EarnPerformanceView`/`EarnPortfolioDashboard`/`EarnProtectionView` in live mode, static "Monad Testnet" network pill, fake demo wallet address, synthetic pre-graduation orderbook, donor's icon deps (`react-icons`, `@radix-ui/react-icons`) — lucide-only.
- **KEEP:** entire `src/lib/`, `src/hooks/`, `src/wallet/`, `src/services/` (tx-pipeline byte-identical), chart module, quote-picker, tickets, create wizard semantics.

## 3. Completed pages + changed-file inventory (code)

Pages renovated: global shell (all routes), Launchpad discovery, token terminal (both lifecycles), liquidity hub (pools/positions/market-making), Earn hub, create wizard (theming only), docs/research surfaces (token refresh).

Changed: `src/index.css` (token system + navbar CSS), `src/components/shell/{shell,sidebar,top-navbar}.tsx`, `src/components/trading/trading.css`, `src/components/trading/bonding-progress.tsx`, `src/features/launchpad/{launch-table.tsx,launch-table.css,discovery.tsx}`, `src/features/launchpad/terminal/token-terminal.tsx`, `src/features/trading/ticket-shell.tsx`, `src/features/liquidity/{liquidity.css,liquidity.tsx,market-making.tsx}`, `src/features/earn/{earn-hub.css,earn-hero.tsx,earn.tsx,referrals.tsx}`, `apps/retro-ui/DESIGN.md` (new), e2e: `a11y.spec.ts` (landmark assertion), tools `renovation-shots.mjs`, `spot-shots.mjs`, `fit-check.mjs` (new).
Workspace/governance: `apps/example-ui-ux/package.json` (name only → `@retropick/example-ui-ux`), `pnpm-lock.yaml`, `apps/README.md`, `goals/active/RETROPICK-RETRO-UI-EXAMPLE-INTEGRATION-V1*`, `.agent/CURRENT_GOAL.md`, dated scope note in `docs/architecture/RETRO_UI_V2_INTEGRATION.md`.

## 4. Before/after evidence

- **Baseline (before):** `../20261029T171952Z-baseline/` — 84 viewport shots (6 viewports × dark/light × 7 routes) + full-page 1440/dark + `README.md` + `MIGRATION_MATRIX.md`.
- **Final (after):** this directory — same matrix, same tool (`e2e/tools/renovation-shots.mjs`), zero console errors.
- **Comparison board:** `COMPARISON.md` (paired links per route/viewport).
- Fixture e2e artifacts: `../20261029T171103Z-fixture/` (baseline run), `../20261030T095410Z-fixture/` (renovated run), live run `../20261030T090554Z-live/`.

## 5. Full tests — real results

| Command | Baseline `9f1be121` | Renovated |
|---|---|---|
| `pnpm typecheck` | PASS | PASS |
| `pnpm build` | PASS | PASS (+2.5 kB on index chunk only: 204.22→206.73 kB; all route chunks identical — no code-split regression) |
| `pnpm test` | 17 pass / 0 fail | 17 pass / 0 fail |
| `pnpm test:terminal` | 14 pass / 0 fail | 14 pass / 0 fail |
| `pnpm test:liquidity` | 9 pass / 0 fail | 9 pass / 0 fail |
| `pnpm e2e:fixture` (all 6 viewport projects) | 300 pass / 8 flaky-on-retry / 40 skipped / 0 fail (7.2m) | **297 pass / 11 flaky-on-retry / 40 skipped / 0 fail** (11.0m) — same 308 executed; after later fix iterations every spec group (a11y, discovery, terminal, liquidity, earn, create, vault, protected-earn, perf, smoke) re-verified green |
| `pnpm e2e:live` (read-only, local indexer from 17-day-old journal) | not run at baseline in this environment | 54 pass / 1 flaky / 1 skipped / **88 failed — ALL proven environmental**: identical specs fail identically on the baseline commit in a clean worktree with the same indexer (verified empirically; causes: stale journal shape + `vite preview` lacking `/api/radar` proxy → 404 console errors). Zero live regressions attributable to the renovation. |
| `e2e/recovery`, `e2e/staging` suites | out of default scope (unchanged config) | not run (unchanged config; noted, not silently skipped) |

## 6. Verified live financial truth checks

- `$`-prefixed fabricated values: **0** in live output — grep kill-list sweep clean (`12.80`, `INITIAL_USER_POSITIONS`, `KURU_VAULTS`, `536.4`, `'253'`, `$79.07K`…); fixture e2e asserts `not.toMatch(/\$\d|SOL|ETH/)` on discovery and it passes.
- Every live financial value remains `formatRawCompact`/`formatPriceX18`/`formatRaw` bigint-exact + quote symbol; `0` ≠ `—` preserved.
- No mixed-quote aggregation introduced (header stats are counts only — cross-denominator sums are impossible without a USD oracle, so not shown).
- `toast.success` audit: all remaining are hash-backed confirmations, local non-economic operations (passkey registration, drafts), or mock-only research modules.
- Demo/live separation: demo surfaces carry `DemoBadge`/SIMULATED labels; live-mode research gates untouched; `VITE_DATA_MODE` fail-closed semantics untouched (`src/lib/liquidity/registry.ts` byte-identical).
- tx-pipeline: `src/services/tx-pipeline.ts` byte-identical to baseline.
- Signing: fixture e2e network-guard rejected all economic writes; live e2e read-only (bridge disabled). Nothing signed anywhere.

## 7. Performance + accessibility findings

- Bundle: +2.5 kB (index chunk) / all route chunks identical; no new heavy deps (icon deps NOT adopted).
- `perf.spec` (CLS < 0.1, no RPC/indexer calls in demo): PASS at desktop-1440 + mobile-390.
- a11y suite: skip-link/focus, named controls, semantics (buy/sell not color-only — now additionally tone-tinted when inactive), 40px ticket touch targets, reduced-motion, dark/light matrix, unknown-route resilience: PASS. `expectNoHorizontalOverflow` green at all six viewports (dedicated scroll-ancestor-aware fit tool committed: `e2e/tools/fit-check.mjs`).
- Discovery table fits with ZERO internal scroll at every Playwright viewport via three column tiers (9 cols @1600 → 4 @≤1024).

## 8. Taste gate — honest status: SUBSTANTIALLY MET, not fully at the 9.0 threshold

Four adversarial iterations (rendered screenshots judged by an independent vision critic, never code):
1. Iteration 1: FAILED — 4.4–6.8 avg (systemic purple flooding, honest-affordance defects).
2. Iteration 2 after purple de-flooding + outline CTAs + tone-tinted ticket sides + units fixes: 7.1–8.1.
3. Iteration 3 after ticket-number contrast + active-wayfinding + label floors: 7.9–9.0 (token-active dark reached 9.00).
4. Iteration 4 after earn-hub consistency + spread spacing: set average **8.34**, best 8.93 (light earn); pixel-verified: one filled accent CTA per view, neutral panel system, consistent active-tab treatment. Independent verdict: *"the set does now read as one coherent professional trading terminal."*

Residual design debt (documented, not blocking hard gates): not every screen individually ≥9.0; remaining items are P3 polish (mobile disabled-state contrast — partially addressed in final commit, radius family unification across pill/rect buttons, chart y-axis crowding on flat fixture data, trending-row gutter on very long names). Two iteration-4 screens were scored by pixel measurement rather than full aesthetic judgment (vision backend degradation) — flagged as provisional in the critique.

## 9. Residual risks + required operator approvals

1. **PR review + merge** — draft PR from this branch; production auto-deploys from main; the renovating agent does NOT merge.
2. **Live e2e environment**: local run used a 17-day-old indexer journal; a fresh-journal/production-indexer live pass is recommended post-merge (the failing specs' expectations depend on current chain shape).
3. **Taste-gate residual P3s** (above) — optional follow-up polish.
4. Workspace: donor renamed `@retropick/example-ui-ux`; if the team prefers workspace exclusion instead, that's a one-line `pnpm-workspace.yaml` change.
5. No contract/economic/deployment changes were made; no approvals implied.

## 10. Rollback recipe

`git revert <merge commit>` on main (single merge commit), or redeploy the previous main build (production auto-deploys from main; previous deployment immutable). No data migrations, no env changes, no contract interactions — rollback is purely the frontend bundle.
