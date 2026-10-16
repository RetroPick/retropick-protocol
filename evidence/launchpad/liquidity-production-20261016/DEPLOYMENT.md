# Authorized public-site rollout — 2026-10-16

The user explicitly requested production deployment after merging PR #38 and supplied VPS access. This authorizes this website/backend rollout; the chain remains **Monad Testnet 10143**. Contract deployment, wallet transactions, passive LP writes and advanced maker selectors were not performed.

## Published source and services

- Merged source: `464dca136e9765d638e742a810ab58af0e911376` (PR #38).
- Public frontend: https://retropick.xyz/liquidity
- Vercel production deployment: `dpl_6fDNLWCaaeixBdC2VLr57V23cLUS`, state `READY`.
- Vercel API metadata independently confirms `githubCommitSha` equals the merged source and `githubCommitRef` is `main`. Git integration published this frontend automatically at merge; no redundant manual frontend build was submitted during this continuation.
- Backend: https://api-staging.retropick.xyz, Contabo `vmi3646941`.
- Indexer release: `/opt/retropick-staging/releases/464dca136e9765d638e742a810ab58af0e911376`; `/opt/retropick-staging/release` links to it.
- The referral, media, radar and gateway services retain their prior deployed source/runtime dependencies from `caf23208f6831b424b1cc51c0785ecf6bdeae264`. Their directories were preserved in the new release so future service restarts have valid working directories. Indexer/SDK/ABI sources use the merged source. Do not interpret the root `SOURCE_SHA` as a source upgrade of these four unchanged services.
- All five backend services reported `active`; referral `viem` and radar Hypersync dependency imports resolved successfully.

## Backup and rollback

Database: `/var/lib/retropick-staging/indexer/monad-testnet.sqlite`, WAL mode. No database or credentials are committed.

1. The previous continuation stopped the indexer, then made a logical table/row copy while its writer was stopped. Node's attempted `db.backup()` method did not exist; those attempts failed and are not successful API backups. The completed logical rollback copy is `pre-projection3-464dca13-20261016T013757Z.sqlite`, 22,646,784 bytes, integrity `ok`, projection 2, indexed block 71,407,488, 5,085 journal events. SHA-256: `d6e8db3bc770f26cc957279e0814a65d608e4f5db6bcbc178a954df4d210aedf`. Secondary indexes are recreated by the Store constructor when restoring this logical copy.
2. This continuation additionally used Python 3.12 `sqlite3.Connection.backup` with a read-only source connection while the service was running. Completed backup: `online-backup-20261016T015445Z.sqlite`, 23,638,016 bytes, integrity `ok`, SHA-256 `b7ebc189fafa5ff62216174e432fb1a7e657aff8d03e0681a9ac5c57d8b495e8`. This is a transactionally consistent SQLite API backup including committed WAL data. Mode 0640, service ownership.
3. Preserved prior release: `/opt/retropick-staging/releases/previous-caf23208f6831b424b1cc51c0785ecf6bdeae264`.
4. Rollback requires stopping the indexer, preserving the current DB/WAL/SHM together, restoring the verified projection-2 copy into a separate path with service ownership, verifying integrity, pointing the release symlink to the preserved prior release and configuring that restored DB path before starting. Never attach leftover WAL/SHM from a different database. A restore/cutback was not executed against the live service.

## Live migration and freshness

Projection 3 published successfully with the existing journal/checkpoints preserved. The default 20,000-block per-vault budget delayed publication by 404–424 seconds per pass. A systemd drop-in uses the existing supported setting:

```ini
# /etc/systemd/system/retropick-staging-indexer.service.d/catchup-budget.conf
[Service]
Environment=INDEXER_MAX_BLOCKS_PER_PASS=200
```

After `systemctl daemon-reload` and indexer restart, observed passes were approximately 14–20 seconds. This setting also bounds root catch-up, so monitor throughput/lag and per-vault progress. It prioritizes live snapshots and does not establish a historical-replay completion SLA. No checkpoints were deleted/reset. A transient HTTP 502 was observed during restart; subsequent public health/API checks returned 200.

At `2026-10-16T01:58:21.554Z`, `/health` and pools reported projection 3, indexed block **71,412,420**, hash `0x6007a69df79eae05f9f9cde08dda975158e4641837895abd2255889ad0380012`, head 71,412,428, lag 8, beneficiary cursor at the indexed block, no sync error. `health.json` and `pools.json` preserve the captured public responses. This is a qualified published snapshot, not the target of a completed historical migration.

All **seven** discovered vaults still report `historyComplete: false`. Pool list/detail return 200; history and wallet LP routes correctly return **503 LIQUIDITY_HISTORY_SYNCING**, with `no-store`. Full historical catch-up and final supply reconciliation remain **PARTIAL**, not PASS. Background replay continues under systemd after this session ends.

## Browser verification

Headless Chromium/Playwright inspected live `/liquidity`, `/liquidity?tab=positions`, `/liquidity/market-making`, and `/` (redirecting to Launchpad) at 1440×900 and 390×844. All eight page visits rendered, with Liquidity navigation, no page JavaScript errors and no horizontal overflow. Disconnected Positions prompts for a wallet.

A separate 20-second maker read settled at chain block 71,412,237: verified active Speedion market, no resting CLOB orders, AMM assets 22.457385 Speedion and 11 MON, combined bid/ask 0.48413017 / 0.48897147 MON, and the existing post-only order ticket. One transient browser RPC `ERR_NETWORK_CHANGED` occurred; the read subsequently completed. Screenshots: `pools-desktop.png`, `pools-mobile.png`, `maker-live.png`.

No wallet was connected, no transaction was signed/broadcast, and no maker lifecycle success is claimed. Public-site smoke is not exhaustive transaction regression.

## Commands and results

- `ssh ... systemctl is-active ...` — exit 0; indexer/referral/media/radar/gateway active.
- `vercel inspect https://retropick.xyz --scope asyams-projects --json` — exit 0; production deployment READY and public aliases present.
- `vercel api /v13/deployments/dpl_6fDNLWCaaeixBdC2VLr57V23cLUS --scope asyams-projects` — exit 0; selected metadata confirms merged SHA. Only non-sensitive selected fields were printed.
- Python read-only SQLite connection + `Connection.backup`, `PRAGMA integrity_check`, SHA-256 — exit 0; backup facts above.
- `systemctl daemon-reload`; `systemctl restart retropick-staging-indexer` — returned successfully; service active after restart.
- Public health, launch list, pools/detail probes — 200 after restart; history/LP readiness probes — expected 503, `no-store`.
- Two Playwright scripts (eight viewport/page visits and one settled maker read) — exit 0; screenshots captured. No transaction tests.
- `pnpm --dir apps/indexer typecheck` — exit 0. `pnpm --dir apps/indexer test` — exit 0; 55 passed, 0 failed, 0 skipped, approximately 11.4 seconds. This includes persisted cursors, rollback, duplicate events, supply mismatch, at-head block/hash provenance, provider degradation and API readiness tests.
- `git diff --quiet 36130e697eced3b98194e81a9b0d07a06d83d5e0 464dca136e9765d638e742a810ab58af0e911376 -- apps/indexer apps/retro-ui packages/launchpad-sdk` — exit 0; those deployed source trees match the previously qualified PR head.
- `node --test scripts/staging/readiness.test.mjs` — exit 0, 4 passed. **Limitation:** this historical deployment helper still expects projection 2, so these tests are not projection-3 rollout qualification. The helper was not used or bypassed to publish this release; Vercel's Git integration published the frontend, and direct checks qualified the live version-3 responses.
- `gh api .../commits/464dca.../status` — exit 0, Vercel success for the exact merged SHA. GitHub returned no check runs or workflow runs for the merge SHA; previous PR validation must not be described as newly executed merge-SHA CI.

## Remaining boundaries

Historical catch-up, all-vault supply reconciliation and final migration qualification remain pending. Maker transaction smoke remains blocked on explicit funded-signer/spend authorization. Existing passive-LP/advanced-MM write restrictions and Solidity freeze remain unchanged. No mainnet action occurred.
