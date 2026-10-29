# Phase 0 Baseline — RETROPICK-RETRO-UI-EXAMPLE-INTEGRATION-V1

**Date:** 2026-10-29 (UTC 17:11–17:19) · **Branch:** `feat/retro-ui-terminal-renovation-v1` · **Baseline SHA:** `9f1be121` (pre-renovation `main`)

## Test baseline (verbatim outcomes)

| Command | Result |
|---|---|
| `pnpm typecheck` | PASS (no output) |
| `pnpm build` | PASS (built in 4.01s) |
| `pnpm test` (domain + launchpad-taxonomy) | PASS 17/17 (node --test) |
| `pnpm test:terminal` | PASS (exit 0) |
| `pnpm test:liquidity` | PASS (exit 0) |
| `pnpm e2e:fixture` | **300 passed, 8 flaky (passed on retry), 40 skipped, 0 failed** (7.2m) |

Pre-existing classification (not caused by renovation):

- **8 flaky** (each passed on retry; config allows 1 retry for host network-interface events): a11y theme matrix (desktop-1440); liquidity paused/rpc-error distinct-from-zero (desktop-1280, tablet-834); liquidity empty CLOB (tablet-834); terminal GRADUATED render + ACTIVE ticket + GRADUATED ticket (tablet-834); earn referral tabs (tablet-768).
- **40 skipped**: tests gated to other targets (live/research) or project-level skips — by design.

Fixture e2e evidence: `../20261029T171103Z-fixture/` (results.json, RUN.json; html-report/test-output gitignored by policy).

## Screenshot baseline

`node e2e/tools/renovation-shots.mjs <this-dir> --target fixture` — 84 viewport shots
(6 viewports × dark/light × 7 routes) + 7 full-page 1440/dark. Zero console
errors observed. Demo-fixture mode (VITE_DATA_MODE=mock, offline).

Routes: `/launchpad`, `/launchpad/token/demo-active`, `/launchpad/token/demo-graduated`,
`/launchpad/create`, `/liquidity`, `/liquidity/market-making`, `/earn`.

## Workspace collision fix (pre-existing CI breakage)

Donor `apps/example-ui-ux` duplicated the canonical package name
`@retropick/retro-ui` while absent from `pnpm-lock.yaml` (committed 2026-10-29
at `9f1be121`) — every PR would fail `pnpm install --frozen-lockfile` in CI.
Fixed in commit `ed76fe9d`: donor renamed `@retropick/example-ui-ux`
(name field only), lockfile regenerated (+110 lines), `apps/README.md` maps
the donor. Verified: `pnpm --filter @retropick/retro-ui exec pwd` →
`apps/retro-ui` only.

## See also

- `MIGRATION_MATRIX.md` — file-by-file ADOPT/ADAPT/REJECT/KEEP with the P0 hazard sweep.
- Goal: `goals/active/RETROPICK-RETRO-UI-EXAMPLE-INTEGRATION-V1.md`.
