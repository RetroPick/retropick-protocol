# Contributing to RetroPick

RetroPick is one product platform with separately qualified financial modules. This repository contains current implementation code, historical deployment snapshots, research, and evidence; treat these lifecycles differently.

## Start here

Read `AGENT_GUIDE.md` and `AGENTS.md` (also applicable to human maintainers), then `apps/README.md` and `docs/platform/README.md`. A scoped change must follow the relevant accepted ADR, current goal/gate and nearest local instructions.

**Canonical frontend:** `apps/retro-ui` (`@retropick/retro-ui`).
**Read-only legacy frontend:** `apps/web` (`@retropick/web`), protected by a zero-write rule.
**Design reference:** `apps/example-ui-ux`, not a second production frontend.

The workspace uses pnpm **11.25.0**. Node **24+ is recommended** when working across the entire workspace because the indexer and service packages require it; the frontend itself supports the root minimum Node 22.13.

```bash
corepack enable
pnpm install --frozen-lockfile
pnpm dev               # canonical apps/retro-ui (Vite)
pnpm check:app         # canonical UI lint/typecheck, tests, build
pnpm check:services    # SDK + indexer + media + referral checks (Node 24+)
pnpm check             # the two checks above
```

The `dev:web`, `build:web`, `lint:web`, `typecheck:web`, and `test:web` convenience aliases now target **retro-ui**. The historical Next.js app remains accessible through explicitly named `*:legacy-web` commands for read-only local reproduction; it must not receive new commits.

## Which files belong where?

| Change | First stop |
| --- | --- |
| Canonical product UI | `apps/retro-ui/` |
| Typed contract interaction | `packages/launchpad-sdk/`, `apps/abi/` |
| Read models / services | `apps/indexer/`, `apps/media-service/`, `apps/referral-service/` |
| Active V2 contracts | `contracts/src/v2/` + `contracts/AGENTS.md` |
| Deployed hackathon V2 source | `contracts/legacy-v2/` (**immutable historical snapshot**) |
| Launchpad specification | `docs/launchpad/` |
| Prediction/PRISM incubation | `docs/prism/`, `research/prism-model/`, `research/prism/` |
| Accepted architectural decisions | `decisions/` |
| Reproducible qualification evidence | `evidence/` |
| Active goals and agent control | `goals/`, `.agent/` |

For a fuller lifecycle inventory, see `docs/engineering/REPOSITORY_HYGIENE_AUDIT.md`.

## Reproduce the tracked-tree audit

With a full local checkout, use the dependency-free, read-only inventory generator:

```bash
python3 scripts/maintenance/git_inventory.py --revision main --out-dir /tmp/retropick-census
```

It writes a full tracked-path TSV, workspace manifest graph and JSON summary. It does **not** prove whether a file is unused or authorize deletion. The immutable [November 9 GitHub census](docs/maintenance/TRACKED_FILE_CENSUS.tsv), [cleanup decisions](docs/maintenance/CLEANUP_DECISIONS.md), and [validation status](docs/maintenance/VALIDATION_REPORT.md) are the reference points for this rehabilitation. The current branch must be qualified separately from the recorded `main§ baseline.

## Verification

Run `pnpm check:app` for UI changes and the relevant `pnpm --filter <package> typecheck` / `pnpm --filter <package> test` for services. For Solidity changes, follow `contracts/README.md` and `contracts/AGENTS.md` and use Foundry's required unit, fuzz, invariant and fork gates. Do **not** treat `forge test` without required fork infrastructure as proof of release readiness.

Before proposing a PR:

1. Specify exact base SHA, intended owner/module, accepted ADR or active goal, changed paths, and excluded paths.
2. State whether the change affects contract bytecode, deployment configuration, ABI/SDK, onchain addresses, user balances, indexing or transaction semantics.
3. Include exact commands and results; mark unexecuted checks **NOT RUN** instead of inventing a PASS.
4. Preserve source-verification manifests, historical evidence, third-party notices, deployed addresses and release snapshots.
5. Confirm any renamed/moved path has been checked in scripts, import graphs, workspace locks, CI, submodules, hosting/deploy build roots and reproduction commands.
6. Keep cleanup PRs incremental and reversible; do not combine cleanup with financial logic or unrestricted deployment.

Do not commit `.env` files, private keys, secrets, wallet mnemonics, sensitive logs, build outputs, browser recordings or cache directories. If such material is already tracked, escalate for sensitive history remediation instead of treating a normal delete as sufficient.

This repository is unaudited testnet-stage work, not automatically mainnet-authorized. Module promotion requires separate evidence and explicit governance/maintainer approval.
