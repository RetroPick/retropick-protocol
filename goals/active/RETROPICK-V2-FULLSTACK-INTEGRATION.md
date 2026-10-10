# Goal RETROPICK-V2-FULLSTACK-INTEGRATION

Status: ACTIVE

Opened: 2026-10-10
Baseline: `codex/v2-abi-catalog-verification` @ `41df325` (integration branch `codex/v2-fullstack-integration`)
Task specification: ABI-driven V2 fullstack integration campaign (Phases 0–9) — make `apps/retro-ui` operate the real deployed Monad Testnet V2 launchpad.

## Objective

The existing RetroPick V2 launchpad lifecycle — Discover → Connect Wallet → Create Token → Bonding-Curve Buy/Sell → Graduation → Kuru Trading → Portfolio/Creator Claims — works end-to-end through `apps/retro-ui` against the deployed Monad Testnet (chain 10143) contracts, with every financial write contract-correct, security-reviewed and on an explicit allowlist.

## Dependencies

- Canonical ABI catalog `apps/abi/` (27 contracts / 517 functions / 147 events / 325 errors) — DONE @ `6d9038a`/`819cb41`.
- Frozen release bundle `deployments/monad-testnet/v2.json` + Sourcify exact-match verification — DONE @ `e925a0a`.
- Dev environment readiness (19 gates) — DONE @ `41df325`; cookie import remains user-BLOCKED (non-blocking).
- Read SDK (`packages/launchpad-sdk`) + indexer candidate (`apps/indexer`) — exist; write layer does not.
- Session testnet credentials: provisioned out-of-repo password files for keystores `monad-testnet` (actor A `0xB505…913b`) and `monad-testnet-actor-b` (actor B `0x1012…8Fcd`), both funded.

## Inputs

- `apps/abi/manifest.json` + per-contract ABI JSONs; `deployments/monad-testnet/abi/function-event-map.json`.
- Pinned Solidity source `contracts/src/v2/**`; pinned Kuru source `/tmp/retropick-kuru-contracts` (re-fetch if missing).
- `apps/retro-ui` current source (fixture/demo baseline).

## Outputs

- `docs/contracts/V2_APPLICATION_CAPABILITY_MAP.md` + `development/fullstack-integration/abi-capabilities.json` (100% disposition).
- `docs/frontend/RETRO_UI_REVERSE_MAP.md`, `CREATE_FORM_ABI_MAP.md`, `ABI_SCREEN_MAP.md`.
- SDK write boundary (`wallet.ts`, `prepare.ts`, `decode.ts`, `registry.ts`) + node:test suite.
- retro-ui live integration: indexer client, live adapters, real wallet (EIP-6963/1193), transaction pipeline, flows A–F.
- Validation evidence under `evidence/launchpad/fullstack-integration/` + reports under `development/fullstack-integration/`.

## Invariants

- No UI redesign; no Solidity edits; no contract redeployment; no PRISM/Prediction implementation; no mainnet.
- 10 tsc-compiled retro-ui domain files never import workspace packages.
- ABI single-source (catalog / SDK generated `abi.ts`); no hand-copied ABIs.
- Exact bigint for all onchain values; `Number()` only at display formatting.
- Indexer/backend never canonical economics; demo data never mixed into LIVE state; mock/live fail-closed.
- No new framework dependencies (viem only); ADR-015 remains PROPOSED; indexer remains a candidate.
- Secrets (keystore passwords) never enter the repository, logs, evidence or commits.

## Acceptance criteria

Phase gates in order (task spec): ABI_SEMANTICS_MAPPED → FRONTEND_CONTRACT_MAPPING → SDK_ARCHITECTURE (+ FRONTEND_WRITE_SECURITY allowlist) → LIVE_READ_INTEGRATION → WALLET_AND_TRANSACTION_ENGINE → USER_FLOWS_INTEGRATED → ABI_APPLICATION_COVERAGE=100% → validation gates 1–7 → final report with capability matrix.

Final: `RETROPICK_V2_FULLSTACK_INTEGRATION = PASS` only when the real `apps/retro-ui` supports the deployed lifecycle with security-reviewed financial actions and independently validated critical journey.

## Tests

- SDK: node:test (encode/decode, launchToken overloads, errors, amounts, approvals, canonical tx replay).
- retro-ui: existing 17 domain tests keep passing; typecheck + build green.
- Foundry: ABI overload selector regression; fresh-pinned fork simulation of all write flows.
- Browser: gstack desktop/mobile read-only E2E, live testnet E2E via session EIP-1193 provider (Gate 5), three-way consistency.

## Evidence

- Baseline/final commit SHAs; screenshots (baseline + final, desktop/mobile); tx hashes + receipts for every live flow; freshness/consistency records; capability matrix.
- Recorded incrementally under `development/fullstack-integration/` and `evidence/launchpad/fullstack-integration/`.

## Risks

- Cookie import pending → authenticated browser tests stay BLOCKED (reported as such).
- Indexer backfill time from block 69509526; reorg handling is implemented but historical lag must be respected in consistency checks.
- Testnet MON spend is real but bounded (launch fee + trade sizes kept minimal).
- Founder/hackathon gates (video, approval, Circle funding) are outside this goal.

## Handoff

Per `.agent/HANDOFFS.md` field contract, recorded under `development/fullstack-integration/handoffs/`: CONTRACT_AGENT, FRONTEND_AGENT, SECURITY_AGENT, SDK_AGENT, INDEXER_AGENT, QA_AGENT hand to the orchestrator; orchestrator hands qualified branch + evidence to release/founder track (no auto-merge to main).
