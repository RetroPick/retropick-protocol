# Handoff H2-FRONTEND-REVERSE-MAP

```text
HANDOFF_ID        H2-FRONTEND-REVERSE-MAP
FROM              FRONTEND_AGENT (capability: REACT_FRONTEND + RADIX_ACCESSIBILITY, skill: frontend-engineering-edho-ferdian)
TO                SDK_AGENT + ORCHESTRATOR
PRODUCT           RetroPick Launchpad (Launchpad Core V2)
GOAL_ID           RETROPICK-V2-FULLSTACK-INTEGRATION (campaign Phase 2 — FRONTEND_CONTRACT_MAPPING)
REQUIREMENTS      Reverse-map apps/retro-ui screen-by-screen onto deployed V2 capabilities; map the create-launch wizard onto the verified Factory ABI; build the ABI→screen inverse index; capture pre-change browser baselines. Read-only over apps/retro-ui, packages/, contracts/.
COMMIT/REF        branch codex/v2-fullstack-integration, HEAD 8d8650a (working tree: only new docs/evidence/handoff files added)
```

## Capability / skill used

`frontend-engineering-edho-ferdian` (authoring lens; its composition/state-placement references informed the seam analysis). Browser work via the repaired canonical gstack `browse` skill (`~/.claude/skills/gstack`, v1.91.12.0): Aside probe unavailable on this headless WSL2 host, so the documented `$B` headless-Chromium fallback (`~/.claude/skills/gstack/browse/dist/browse`) was used — **tool used: gstack browse fallback, noted per instruction**.

## Source files inspected (read-only)

`apps/retro-ui/src/**` in full (routes, main, all features, hooks, lib/domain, lib/liquidity, components/ui + product + shell), `apps/retro-ui/scripts/test-frontend.mjs`, `package.json`, `vite.config.ts`; `apps/abi/RetroPickLaunchFactoryV2.json`, `RetroPickQuoteAssetRegistryV2.json`, `RetroPickLauncherTokenV2.json`, `RetroPickBondingCurveV2.json`, `GraduationCoordinatorV2.json`, `KuruEnvironmentV2.json`, `MarginAccount.json`, `OrderBook.json`, `KuruLiquidityLockV2.json`, `RetroPickFeeEscrowV2.json`, `RetroPickBuybackVaultV2.json`; pinned source `contracts/src/v2/RetroPickLaunchFactoryV2.sol` (overloads, msg.value, expectedEconomics, launchTokenFor gate) and `contracts/src/v2/interfaces/IGraduationExecutorV2.sol` (venue enum); `deployments/monad-testnet/v2.json`; goal file; `.agent/*`.

## Outputs produced (files changed/added — all additions, zero modifications to app code)

1. `docs/frontend/RETRO_UI_REVERSE_MAP.md` — 16-route map, 15 screens detailed, 20 verified issues with file:line evidence and dispositions (PRESERVE-AS-DEMO / FIX-IN-LIVE-MODE / REMOVE-COPY), 8 architecture seams.
2. `docs/frontend/CREATE_FORM_ABI_MAP.md` — every wizard field/control → EXACT_SOLIDITY_ARG / DERIVED_ARG / OFFCHAIN_METADATA / DISPLAY_ONLY / UNSUPPORTED_LIVE; runtime-derived reads; hardcoded constants → LIVE replacements; validation deltas.
3. `docs/frontend/ABI_SCREEN_MAP.md` — inverse index for the 11 priority contracts incl. NOT_SURFACED dispositions and coverage summary.
4. `evidence/launchpad/fullstack-integration/baseline/` — 18 PNGs (9 routes x desktop 1440x900 / mobile 390x844).
5. `development/fullstack-integration/handoffs/H2-FRONTEND-REVERSE-MAP.md` (this file) + the P2 status rows in `development/fullstack-integration/README.md`.

## Exact ABI functions involved (form-map targets, verified against ABI JSON + Solidity)

- `RetroPickLaunchFactoryV2.launchToken(TokenParams,uint256,address)` — F1, venue UNISWAP_V4 implicit
- `RetroPickLaunchFactoryV2.launchToken(TokenParams,uint256,address,uint8 venue)` — F2; **4th-arg ABI type confirmed `uint8`**; `enum GraduationVenue { UNISWAP_V4=0, KURU=1 }` → KURU = 1
- `RetroPickLaunchFactoryV2.launchToken(TokenParams,uint256,address,address[] snipeTaxExemptions)` — F3, second 4-arg overload (selector-disambiguation warning for SDK)
- `RetroPickLaunchFactoryV2.launchTokenFor(…,address originalDeployer,…)` — forwarder-only (`revert NotLaunchForwarder`, sol:672); **no atomic opening buy on the user path** (`msg.value == launchFee` exact, sol:706)
- TokenParams fields: name, symbol, logo, description, socials{twitter,telegram,discord,website,farcaster}, creatorFeeRecipient, creatorTaxBps(uint16), buybackEnabled, expectedEconomics(bytes32, optional pin — 0 skips), salt
- Runtime reads: `launchFee()`, `launchConfigCount()`, `getLaunchConfig(id)`, `maxCreatorTaxBps()`, `canLaunch(address)`, `launchEnabled()`, `previewLaunchEconomics(id,quote)`, `previewVenueEconomics(id,quote,venue)`, `quoteRegistry()` → `admitted(quote,venue)`

## Assumptions resolved

1. Venue overload 4th-arg type is `uint8` (not e.g. an enum label) — verified in ABI JSON; KURU=1 verified in `IGraduationExecutorV2.sol`.
2. Two distinct 4-arg `launchToken` overloads exist (venue vs snipeTaxExemptions) — SDK must encode by full signature.
3. `expectedEconomics` is optional (bytes32(0) skips); when set it must equal `previewEconomics` at execution (`LaunchEconomicsMismatch`).
4. No atomic opening buy exists for users: F1/F2/F3 enforce exact `msg.value == launchFee`; the opening-buy form control is UNSUPPORTED_LIVE and its copy is false in any mode.
5. Fee destinations: only feeWallet (`buybackEnabled=false`) and buybackVest (`buybackEnabled=true` + BuybackVault vesting) map to the ABI; `holders` has no counterpart in any of the 11 ABIs.
6. `chainId: 143` in `launchpad-adapters.ts:9` is wrong for the deployed chain 10143 — with the current empty/composed registry no executable path can ever resolve; must be corrected in LIVE mode (kept untouched in this read-only phase).
7. Quote-admission is per venue (`admitted(quote, venue)` + `venueMask`); native MON is address(0); fixture pairs (ETH/WBTC/NVDAx/AAPLx) have no standing.

## Tests run

- Baseline screenshots: 18/18 captured (gstack browse fallback, dev server `pnpm dev` port 3000): `/launchpad`, `/launchpad/create`, `/launchpad/token/monad-dog`, `/launchpad/prediction/btc-150k`, `/activity`, `/earn`, `/portfolio`, `/creator/retropick-research`, `/docs` — desktop + mobile each. Fixture ids used: token `monad-dog`, market `btc-150k`.
- Console-error check per page (all 9 routes, desktop pass): **zero console errors**.
- Existing domain suite at this HEAD: `pnpm test` → **17/17 pass** (boundary of the 10 tsc-compiled workspace-free domain files intact).
- Dev server and browse daemon stopped after capture (nothing left running that this agent started).

## Security considerations (demo/live separation points)

- `VITE_DATA_MODE` fail-closed gate (`main.tsx:14` + `lib/liquidity/registry.ts:4`) must remain: unconfigured live mode throws, fixtures can never render as live.
- `DemoProvider` is the mock-mode wallet/economics engine; LIVE mode must use a separate wallet/tx store — no shared mutable state (goal invariant: demo data never mixes into LIVE state).
- The `provenance: 'DEMO'` literal type on `LaunchInstrument`/`Quote` is the type-level enforcement of that separation; widening to `'DEMO' | 'LIVE'` is a deliberate, reviewable change.
- Frontend must never originate economics: launch fee, config, admission, caps all read from chain (`docs/frontend/CREATE_FORM_ABI_MAP.md` §2); admin/forwarder functions are NOT_SURFACED and must stay off any user-reachable path (write-allowlist input for SECURITY_AGENT).
- No secrets touched; monadscan.io not contacted (Cloudflare-gated, per instruction); all browsing local.

## Open blockers / notes for SDK_AGENT + ORCHESTRATOR

1. Create form must lose or reword the opening-buy control before any LIVE build (false contract implication).
2. `holders` fee-destination radio and Earn-screen Bags/Solana/MoonPay/referral/deployer-revenue copy are REMOVE-COPY items (factually false regardless of mode).
3. `launchConfigId` has no UI selector — SDK/UX decision needed (auto-select single enabled config vs. add a control).
4. `logo` as data URL would bloat calldata — LIVE needs an offchain upload decision (no new backend exists; URI-only convention acceptable if documented).
5. Kuru venue (=1) selection implies per-venue admitted quotes and executor wiring — coordinate with CONTRACT_AGENT's capability map before enabling F2 in the form.
6. Screens emitting legacy `/markets*` hrefs add redirect hops — cheap canonicalization batch during Phase 6.
7. Cookie import (user-BLOCKED) still limits authenticated browser flows — irrelevant to these local baselines but remains a QA_AGENT constraint.

## Invariants not changed

No file under `apps/retro-ui/src`, `packages/`, `contracts/` modified; no git writes; 10-file tsc domain boundary untouched and green; ABI catalog untouched (read-only source of truth); no mainnet interaction; no dependency changes.

## Status

**HANDOFF READY** — Phase 2 FRONTEND_CONTRACT_MAPPING analysis complete for the frontend lane; awaiting CONTRACT_AGENT capability map cross-check (P1) and SECURITY_AGENT allowlist (P3) before Phase 4/6 implementation consumes these maps.
