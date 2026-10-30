# Goal RETROPICK-RETRO-UI-EXAMPLE-INTEGRATION-V1

Status: COMPLETE (implementation + verification; awaiting operator PR review/merge — see Evidence)

## Objective

Renovate the canonical frontend `apps/retro-ui` in place: adopt the suitable
visual design, navigation, presentation components and UX patterns from the
design donor `apps/example-ui-ux`, then improve them to production-quality
Web3 trading-terminal standards — without altering any economic semantics,
data authority, wallet behavior or deployed-contract interaction.

Task contract:

- **GOAL:** RETROPICK-RETRO-UI-EXAMPLE-INTEGRATION-V1 (visual/UX renovation).
- **WHY:** The canonical frontend works but reads as a generic SaaS sidebar app;
  the donor demonstrates a stronger trading-terminal information architecture
  but contains fabricated financial data that must never ship.
- **CURRENT:** `main` @ `9f1be121` (2026-10-29). retro-ui = sidebar-only shell,
  purple-tinted tokens, honest live data. example-ui-ux = donor with 27 changed
  + 7 new files (top navbar, o1-style table, 3-col terminal, liquidity/earn
  redesigns) including confirmed P0 fabrications.
- **TARGET:** One coherent RetroPick terminal design system (neutral
  midnight-charcoal surfaces + Monad brand accents), ported donor layouts
  de-fabricated onto canonical real-data hooks, verified by the existing
  unit + Playwright gates with before/after screenshot evidence.
- **DELTA:** Visual/UX only. No contract, economic, ABI, SDK-math, indexer,
  deployment or data-authority changes.
- **OWN:** `apps/retro-ui/**`, `goals/active/RETROPICK-RETRO-UI-EXAMPLE-INTEGRATION-V1*`,
  `evidence/platform/frontend/browser-validation/**`, narrowly required
  workspace config (donor package name dedupe + lockfile), `apps/README.md`
  donor row, `.agent/CURRENT_GOAL.md` entry, `apps/retro-ui/DESIGN.md`.
- **READ:** `.agent/**`, `docs/**`, `decisions/**`, `development/**`.
- **READ-ONLY:** `apps/example-ui-ux/**` (except its `package.json` name field).
- **DO-NOT:** Write `apps/web`, `contracts/`, `packages/launchpad-sdk/`,
  `apps/indexer/`, `apps/abi/`, `deployments/`; sign or broadcast transactions
  in QA; merge/deploy production; introduce fabricated metrics or simulated
  economic outcomes into live mode.
- **ACCEPTANCE / VERIFY / EVIDENCE / HANDOFF / BLOCKERS:** see the embedded
  master specification (same directory, `.master-prompt.md`), sections 6–8.
  Full text is authoritative.

## Dependencies

- Deployed Monad Testnet V2 contracts and ABI catalog (read-only consumer).
- Indexer read API for live mode (read-only; live e2e optional per reachability).
- Existing `@playwright/test` harness in `apps/retro-ui` (ports 4317/4318).

## Inputs

- `RETROPICK_RETRO_UI_RENOVATION_AGENT_MASTER_PROMPT.md` (user-directed,
  2026-10-29; preserved verbatim as
  `goals/active/RETROPICK-RETRO-UI-EXAMPLE-INTEGRATION-V1.master-prompt.md`).
- `apps/example-ui-ux` donor tree @ `9f1be121`.

## Outputs

- Renovated `apps/retro-ui` (tokens, shell, discovery, terminal, liquidity,
  earn, route polish) with updated e2e specs.
- `apps/retro-ui/DESIGN.md`, migration matrix + before/after screenshot
  evidence, engineering handoff, draft PR.

## Invariants

1. `apps/retro-ui` remains the canonical frontend; wallet → chain remains the
   only standard economic write path (`services/tx-pipeline.ts` unchanged
   except UI-safe, separately justified fixes).
2. `VITE_DATA_MODE` fail-closed semantics, chain 10143, EIP-6963 discovery,
   bigint-exact amounts, indexer freshness envelopes and research-module live
   gates are preserved exactly.
3. Zero fabricated financial values, mock positions, simulated transaction
   success or unverified USD conversions in live mode. `toast.success` never
   asserts an onchain outcome. Demo behavior is `DemoBadge`-labeled and
   mock-mode-only.
4. **Decision-conflict record:** `docs/architecture/RETRO_UI_V2_INTEGRATION.md`
   and the `RETROPICK-V2-FULLSTACK-INTEGRATION` goal carry a "No
   sidebar/layout/theme/flow redesign" invariant. That clause scoped the
   2026-10-10 fullstack-integration campaign (data/wallet correctness under a
   frozen UI). This goal is a new, explicitly user-directed visual renovation
   (2026-10-29) and, for its own scope, supersedes that clause. The historical
   documents are NOT rewritten; this file plus the dated pointer note added to
   `docs/architecture/RETRO_UI_V2_INTEGRATION.md` record the supersession.
   The financial-goal boundaries of those campaigns (no Solidity edits, no
   contract redeployment, no PRISM/Prediction promotion, no mainnet) remain
   fully in force here.
5. Workspace integrity: the donor package is renamed
   `@retropick/example-ui-ux` to remove the `@retropick/retro-ui` name
   collision (pre-existing CI breakage: donor absent from `pnpm-lock.yaml`
   under a duplicated name). Canonical package name is untouched.

## Acceptance criteria

Master prompt §8 hard gates 1–7 + taste gate, evaluated against rendered
screenshots, with all pre-existing failures classified against the Phase 0
baseline. Blocked items are reported BLOCKED, never glossed.

## Tests

`pnpm --filter @retropick/retro-ui typecheck build test test:terminal
test:liquidity`, `pnpm --filter @retropick/retro-ui e2e:fixture`,
`e2e:smoke`, and read-only `e2e:live` when the indexer is reachable.

## Evidence

`evidence/platform/frontend/browser-validation/<ts>-baseline/` (pre-change
screenshots + test baseline + `MIGRATION_MATRIX.md`) and
`<ts>-after/` (final screenshots, comparison board, verbatim results).

## Risks

E2E spec churn from markup changes; donor code embeds retired hex values and
fake handlers (every port is a rewrite against canonical data); live e2e
depends on indexer availability; subjective taste gate requires iteration.

## Handoff

Engineering handoff doc in the after-evidence directory + draft PR
(`feat/retro-ui-terminal-renovation-v1`). No production cutover; production
auto-deploys from `main`, so the PR must not be merged by the renovating
agent.
