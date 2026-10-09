# Tooling qualification — 2026-10-09

Recorded for the focused verification/ABI-catalog execution on branch
`codex/v2-abi-catalog-verification`.

## Foundry — QUALIFIED

- `forge`/`cast` 1.8.4 (commit `50af4efe189dc64bad2b75ed6990b835de66c4ae`), used for
  build, standard-json generation, `cast code` runtime reads and constructor-arg
  ABI encoding.
- `forge build` green in the preserved deployed worktree
  (`codex/v2-monad-testnet-e2e` @ `a8a81f5`); artifacts pinned to
  `0.8.26+commit.8a97fa7a`, optimizer/200, viaIR, cancun.
- `forge verify-contract --verifier sourcify --verifier-url
  'https://sourcify-api-monad.blockvision.org/'` submits successfully (trailing
  slash required; no conflicting `etherscan_api_key` present). Known limitation
  recorded in `source-verification-foundry.md`: forge's standard-json remappings
  differ from the historical deployment build, yielding partial `match`; exact
  matches require replaying the original `settings.remappings` via the Sourcify
  v2 API.

## Endpoints — QUALIFIED

- `https://testnet-rpc.monad.xyz` — live (JSON-RPC via POST).
- `https://sourcify-api-monad.blockvision.org/` — live; `/health` 200; v2 verify
  and contract APIs functional. Direct POSTs require a browser-like User-Agent
  (default tool UA receives Cloudflare 1010).
- `https://sourcify.dev/server/` + `https://repo.sourcify.dev` — live public
  Sourcify store; holds the prior seven exact-match verifications and the new
  ones from this run.
- `https://testnet.monadscan.com` — Cloudflare-gated for automated browsers in
  this environment (challenge re-loops); explorer publication confirmed via the
  Sourcify v2 contract APIs instead.

## gstack — BLOCKED (not installed)

- gstack skills (`gstack`, `gstack-browse`, `gstack-setup-browser-cookies`,
  `gstack-upgrade`, ~57 `gstack-*`) are present as **text-only** SKILL.md
  installs under `~/.agents/skills/`: no `browse/dist/browse` binary, no
  `$GSTACK_BROWSE`, no `setup` script, no `$GSTACK_ROOT/bin/gstack-paths`, no
  Aside. The cookie-import flow (`$B cookie-import-browser`) therefore cannot
  run; no authenticated cookie import was performed and no cookie state exists
  in this session or repository. Remediation: install/upgrade gstack
  (`/gstack-upgrade` after a real gstack install) and rerun
  `/setup-browser-cookies`.
- Browser QA used the harness-installed Chrome DevTools MCP browser instead
  (public pages only): retro-ui preview smoke PASS (renders unchanged, zero
  console errors); Monadscan blocked by Cloudflare as noted above.

## Skills referenced

Read before use per their instructions: `gstack`, `gstack-browse`,
`gstack-setup-browser-cookies`, `chain-monad` (pins no chain constants —
network facts taken from the task brief and live endpoint checks),
`contract-verification`, `solidity-foundry`, `evm-foundry` conventions.
