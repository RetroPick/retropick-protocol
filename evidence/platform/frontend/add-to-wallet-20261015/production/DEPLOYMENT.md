# PRODUCTION RELEASE — Add to Wallet (EIP-747)

Date: 2026-10-15 · Result: **DEPLOYED AND VERIFIED** (one item PENDING MANUAL VERIFICATION, see end)

## Release chain

| Item | Value |
| --- | --- |
| Fix commit (dev branch) | `01935466f52ac76d037fff450307e1eb28b3480d` on `dev/continue-live-20261014` |
| Release branch | `release/add-to-wallet-20261015` (clean cherry-pick of the fix onto `origin/main`; no other dev-branch content) |
| Cherry-pick SHA | `55b4fd7e…` (tree `b39f5414…`) |
| Pull request | https://github.com/RetroPick/retropick-protocol/pull/36 |
| PR check | Vercel build **SUCCESS** (repo has no CI workflows — local gates are the qualification, per runbook) |
| Merge commit (main) | `94d08047df9fae4c283203e751531481f61fd61f` — merge-tree equals the validated tree (`b39f5414…`, verified by identical tree hashes) |
| Deployed deployment | `dpl_7vqjDWSGg8br5mQ9MC3DXQaWhaTB` (candidate URL `retropick-metropolis-retro-ui-staging-9opkveq9r-asyams-projects.vercel.app`) |
| Apex | https://retropick.xyz → `dpl_7vqjDWSGg8br5mQ9MC3DXQaWhaTB`, READY, production |
| Public marker | `https://retropick.xyz/release.json` → `{"sourceSha":"94d08047df9fae4c283203e751531481f61fd61f","chainId":10143}` |
| Rollback reference | `dpl_9UxVr1rWTC2cunBLdUaX4jRiDLtA` (prior production, source `865e3a49` bonding-picker release) — `vercel rollback dpl_9UxVr1rWTC2cunBLdUaX4jRiDLtA --scope asyams-projects` |

## Deployment method (runbook `PRODUCTION_REFRESH_2026-10-14.md`, unchanged)

Detached SHA-pinned worktree `/tmp/retropick-production-addtowallet-94d08047` → project-link
identity verified (`retropick-metropolis-retro-ui-staging` / `prj_dKwt5xQUlhZg6shbOWyFvZbZXSIO`) →
`vercel.json` rendered from the repo template against backend `https://api-staging.retropick.xyz` →
public `release.json` marker written → `vercel deploy --prod --skip-domain` with
`VITE_DATA_MODE=live`, `VITE_INDEXER_URL=same-origin`, Ankr fallback RPC, git meta → candidate
verified (READY, exact marker via authenticated `vercel curl`, indexer data through its rewrites) →
apex confirmed unchanged → `vercel promote`. Receipt updated in `.staging/production-deploy.json`.

**Note:** the PR merge also triggered Vercel's Git integration, which auto-deployed the same SHA
(`dpl_H6Un94x4…`) to production without the public marker — the scenario the runbook documents.
Promoting the marker-carrying candidate of the identical SHA restored public provenance; no
content difference existed between the two deployments.

## Release gates (all on the release branch before merge)

| Gate | Result |
| --- | --- |
| Launchpad SDK suite | 69 tests, 0 fail · `tsc --noEmit` clean |
| retro-ui typecheck / production build | clean / success |
| retro-ui unit suites (add-to-wallet 4, media 5, terminal 14, runner 17) | all pass |
| Fixture token-terminal e2e (desktop-1440 + mobile-390) | 31 pass / 0 fail |
| Live add-to-wallet e2e (real CIS page, real RPC, desktop + mobile) | 8 pass / 0 fail |
| Backend readiness gate | chain 10143, projection 2/2, lag 8 |

## Post-promotion verification on https://retropick.xyz

| Check | Result |
| --- | --- |
| Public staging suite (`e2e/staging.config.ts`, 8 tests × 2 viewports) incl. quote-assets | **24 passed / 0 failed** (with the 2 prod specs below: 26 total, all green) |
| CIS page loads, live mode, name/symbol/logo | PASS (desktop; mobile PASS with 1 retry — Pinata gateway decode latency ~10s, documented) |
| Add to Wallet button visible (desktop + mobile) | PASS |
| watchAsset payload on production | PASS — exactly `{type:'ERC20', address:'0xc399…e50f', symbol:'CIS', decimals:18, image:'https://gateway.pinata.cloud/ipfs/QmSHM…'}` |
| Buy/sell surface | PASS — desktop rail ticket renders; mobile sticky Trade bar opens the bottom-sheet ticket |
| Earn hub / portfolio surface | PASS — renders, connect picker opens, zero page errors, no overflow (desktop + mobile) |
| JS errors / overflow | none on any checked page/viewport |
| Financial state | zero signing/broadcast attempts across every test (mock wallet + network guard); read-only release |
| Staleness | apex serves `94d08047` via marker AND deployment id — not a stale deployment |

Verification spec preserved at `production/prod-verification.spec.ts` (temporary name in the
release worktree; run with `STAGING_URL`/`STAGING_SOURCE_SHA` against any deployment).

## PENDING MANUAL VERIFICATION

Automated EIP-1193 tests do **not** prove that MetaMask renders the token icon. Per
`METAMASK_MANUAL_PROTOCOL.md`: (A) new import through the button should show the CIS artwork;
(B) an already-imported token keeps its generic icon (upstream metamask-extension#7360) — remedy:
remove the token in MetaMask and re-import via the button. Portfolio logo rows likewise require
a wallet with actual holdings. These need a human-controlled MetaMask pass on
https://retropick.xyz/launchpad/token/0xc399c1a37d1d202d315f7f4c1a24e34c8e50e50f.
