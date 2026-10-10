# RetroPick V2 Dev Environment Readiness

Recorded 2026-10-10 by the environment-recovery campaign on branch
`codex/v2-abi-catalog-verification` (base `8a5fc1f`, prior head `dd17927`).
Machine record: `readiness.json` (same directory). Scope: developer-environment
qualification only — no protocol, contract or feature changes.

## Overall outcomes

| Outcome | Status | Notes |
| --- | --- | --- |
| CORE_DEV_ENV_READY | **PASS** | Foundry, Monad RPC, contract identity, ABI catalog, SDK, retro-ui, indexer all operational. |
| BROWSER_DEV_ENV_READY | **BLOCKED** | gstack browser runtime works (7/7). Cookie import requires the user at the one-use picker; the issued link expired unused. No manual login performed. |
| EXPLORER_PUBLICATION_READY | **PASS** | 18/18 contracts Sourcify `exact_match` (runtime) on both the BlockVision Monad endpoint and the public Sourcify repository; verified source content retrievable (78 files for the factory). Monadscan UI is an external Cloudflare casualty, recorded below, and does not affect publication. |
| FULL_DEV_ENV_READY | **NO** | Blocked only by BROWSER_DEV_ENV_READY (user interaction). |

## Gate table

| Gate | Status | Evidence |
| --- | --- | --- |
| FOUNDRY_BUILD | PASS | forge/cast 1.8.4 (50af4ef); `forge build` exit 0 in the preserved deployed worktree at pinned settings (0.8.26+commit.8a97fa7a, optimizer/200, viaIR, cancun). |
| MONAD_RPC | PASS | `cast block-number` via `https://testnet-rpc.monad.xyz` → 69600854. |
| CONTRACT_BYTECODE_IDENTITY | PASS | 18/18 runtime bytecode matches artifact (immutable-masked) + 18/18 Sourcify exact runtime matches; preserved in `evidence/launchpad/v2-monad-testnet/source-verification-foundry.{md,json}`. |
| SOURCIFY_PUBLICATION | PASS | Live recheck 2026-10-10 (no resubmission): 18/18 EXACT on both stores; 15 EXACT_MATCH_FULL + 3 EXACT_MATCH_RUNTIME_ONLY (internally-created contracts: lpLock demo, MemeHook, guard/locks at store level). Source retrieval via `GET /v2/contract/10143/{addr}?fields=sources` confirmed. |
| MONADSCAN_UI | BLOCKED | External: Cloudflare challenge — turnstile passes ("Verification successful") but the site never serves content to this environment. Not bypassed per policy. Independent Sourcify APIs are authoritative. |
| ABI_CATALOG | PASS | `apps/abi/` 27 ABI JSONs + `abi.ts` barrel + schema-v2 manifest; SHA-256/count/role-coverage/barrel-parity audit PASS. |
| ABI_REGENERATION | PASS | `python3 scripts/launchpad/export_abi_catalog.py` is deterministic (double-run → identical hashes). **Fixed this campaign:** the stale-file cleanup previously deleted `apps/abi/package.json` (glob `*.json`), which had silently dropped the workspace manifest from commit `6d9038a` and broke fresh `pnpm install` resolution; the file is restored and now exempted. |
| SDK_TYPECHECK | PASS | `@retropick/launchpad-sdk` has no build step; covered via `apps/indexer` `tsc --noEmit` (exit 0, indexer tsconfig includes SDK sources) and SDK↔catalog ABI equality (11/11 exports byte-identical to catalog JSONs). |
| RETRO_UI_TESTS | PASS | `node scripts/test-frontend.mjs` → 17/17. |
| RETRO_UI_BUILD | PASS | `vite build` exit 0. |
| INDEXER_TESTS | PASS | `pnpm --filter @retropick/indexer test` → 4/4; typecheck exit 0. (Note: indexer `engines` wants node ≥24, running on 22.23.2 — warning only.) |
| MONAD_SKILLS | PASS | `chain-monad` skill discoverable (pins no chain constants by design; network facts verified live). |
| SOLIDITY_SKILLS | PASS | `evm-foundry`, `solidity-foundry`, `contract-verification`, `evm-security`, `smart-contract-security` discoverable. |
| FULLSTACK_SKILLS | PASS | `frontend-engineering-edho-ferdian`, `backend-engineering-edho-ferdian`, `test-authoring-edho-ferdian` discoverable; pnpm workspace resolves 6 projects. |
| GSTACK_INSTALLATION | PASS | Canonical install `~/.claude/skills/gstack` @ **v1.91.12.0** (origin `https://github.com/garrytan/gstack.git`), `./setup --status` → "gstack ready (claude)". Secondary checkout `~/gstack` @ v1.87.4.0 (older; left untouched). `~/.agents/skills/gstack-*` are gstack's generated docs-only mirrors — now with `browse/dist` symlinked to the canonical binary so the documented `$B` probe resolves. Upstream v1.91.13.0 available (not applied to a working install). ZCode is not an officially supported `--host`; mirrors + symlink is the compatibility workaround, recorded here. |
| GSTACK_BROWSER | PASS | 7/7: binary exists; daemon launches (PID observed); navigates public pages (example.com 200, sourcify health 200); content inspectable; screenshot saved; session persists across separate invocations (same PID, same tab); skills visible to the agent. |
| COOKIE_IMPORT | BLOCKED | Picker launched (`http://127.0.0.1:15493/cookie-picker`, Chrome detected as source) but the five-minute one-use link expired unused. Requires user interaction; see "Remaining manual actions". |
| BROWSER_AUTH | NOT_CHECKED | No import/manual login completed, so no authenticated page was tested. `handoff` (headed sign-in via WSLg) available as fallback. |
| ZCODE_SKILL_DISCOVERY | PASS | ZCode discovers `~/.agents/skills/*` (gstack family), `~/.zcode/skills/*` (chain/engineering packs) and plugin skills; all required categories present in-session. |

## Defect found and fixed this campaign

`scripts/launchpad/export_abi_catalog.py` deleted `apps/abi/package.json` during
regeneration (stale-cleanup glob `*.json`). The file was created after the first
exporter run yesterday and destroyed by the re-run before `git add`, so commit
`6d9038a` shipped the catalog **without** the workspace manifest while
`pnpm-lock.yaml` referenced it — fresh dependency resolution failed
(`ERR_PNPM_WORKSPACE_PKG_NOT_FOUND`). The cleanup now exempts
`package.json`/`manifest.json`, the file is restored and committed, double-run
regeneration is byte-stable, and all six workspace projects resolve again.
Detected by this campaign's INDEXER gate; retro-ui/indexer gates re-run green
after the fix.

## Remaining manual actions

1. **Cookie import (user, ~2 min):** rerun
   `~/.claude/skills/gstack/browse/dist/browse cookie-import-browser`, open the
   printed `http://127.0.0.1:<port>/cookie-picker` link within five minutes
   (WSL2 localhost forwarding reaches it from the Windows browser), pick the
   Chrome profile and the three domains (`hackathon.monad.xyz`, `github.com`,
   `testnet.monadvision.com`), then confirm. Import counts never prove sign-in —
   verify an authenticated page afterwards. Alternatively use
   `.../browse handoff "<reason>"` for headed interactive sign-in (WSLg display
   available).
2. **Optional gstack upgrade:** upstream v1.91.13.0 (current 1.91.12.0) — apply
   only with the user's consent; a working install was deliberately not touched.
3. **Monadscan UI** is externally Cloudflare-gated for automated browsers; use
   the Sourcify v2 APIs (both stores) as the authoritative publication check.
