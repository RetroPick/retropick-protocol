# Addendum — all-in sidebar + donor Liquidity integration (2026-10-30, same branch/PR #39)

## Shell (operator direction: move every navbar element to the sidebar)
- TopNavbar deleted; sidebar (>=768px) now carries brand, search, nav, Launch, wallet-derived chain pill, real wallet button, theme, and the LIVE/DEMO block ("Monad Testnet · chain 10143 · test assets." + "How it works"). Shortcuts group deleted. <768px: sticky mobile bar (banner role, LIVE/DEMO pill, search, wallet) + bottom nav. a11y/discovery/smoke: 53 passed / 0 failed.

## Liquidity (operator decisions: real data + honest em-dashes; honest modal + route to real flow)
- Donor overview rebuilt on verified sources: vault cards from IndexedLiquidityPool (status chip, AMM base/quote inventory, real 24h volume via shared discovery snapshot — `src/hooks/use-launch-stats.ts`), pools table with responsive tiers (zero clipped cells 375–1440: DOM-measured + vision-confirmed), donor subtabs/search/positions-count pill.
- REJECTED (never ported, grep sweep clean): KURU_VAULTS APR 536.4%, KURU_POOLS USD TVL/fees, INITIAL_USER_POSITIONS, formatUsd, hardcoded balances, fake deposit setTimeouts, "Position Created" toasts.
- Honest modals (`liquidity-modals.tsx`): donor 2-step Add Liquidity UI with real balances (native MON via getBalance) and a permanently-disabled CTA "Public LP deposits not enabled" + Market-Making route; VaultDetailModal shows block-pinned real vault params. `liquidity-math.ts` ported for clearly-labeled previews only.
- Positions: donor cards over verified data (role badge, shares, share-of-pool %, previewWithdraw underlying); Earned fees = "—" with reason; Withdraw disabled with reason.
- Market-liquidity card: donor visual (badges, bid/ask hero) wrapping all canonical honesty strings; 4 original specs pass unchanged.
- Capability analysis backing every mapping: indexer endpoints (/v1/liquidity/pools(+events), /v1/wallets/:w/lp-positions), SDK readKuruLiquidity (vault params, custody, position), ABI (KuruAMMVault.deposit/mint/withdraw exist upstream but are NOT exposed — no SDK prepare; app states not enabled).

## Verification (final)
- typecheck/build PASS; unit 17+14+9 PASS.
- e2e:fixture FULL: **313 passed / 0 failed / 1 flaky-retry / 40 skipped** (was 308 pre-follow-up; +5 new donor-honesty spec projects).
- Defect caught & fixed during verification: my liquidity.css leaked a global `.rp-btn-primary { min-height:38px }` shrinking the ticket CTA below the 40px touch-target gate — namespaced to `.rp-mbtn-*`; touch-target spec green again on mobile.
- Vision critique: liquidity 7.6/10 desktop after fixes (tables clean at all widths, maker card FIXED); remaining: light-mode contrast nits (DEMO banner tint, faint borders) — documented, non-blocking.

## CI fix (2026-10-30, PR #40 browser-fixture failure)
Root causes of the failing CI/local runs (20261030T152637Z: 309/2):
1. DETERMINISTIC — my ≤640px tier hid the whole Actions column, removing the
   Add-liquidity button on phones (donor spec timed out clicking it at 375/390;
   also a genuine UX regression). Fix: the affordance never hides — ≤640px it
   collapses to an icon button with the same accessible name; the AMM-quote
   column yields its width instead (table still clip-free 375–1440, verified).
2. TRANSIENT — tablet-768 'paused'/'prediction renders' failed with an EMPTY
   #root, zero console/page errors, zero failed requests, and passed on retry:
   a vite-preview stall under parallel load. Fix: CI retries 1→2
   (local stays 1); comment documents the class.
Verified: donor spec 24/24 at mobile-375/390 + tablet-768; full suite
20261030T154448Z-fixture: 313 passed / 0 unexpected / 1 flaky / 40 skipped.
