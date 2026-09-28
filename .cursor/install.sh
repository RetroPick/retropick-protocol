#!/usr/bin/env bash
# RetroPick Protocol - Cloud Agent install
#
# Idempotent bootstrap run after the repository is checked out. Prepares the
# three development lanes in this monorepo:
#   1. Node/TypeScript workspace (apps/web + packages) via pnpm.
#   2. Solidity contracts (Foundry toolchain + git submodules).
#   3. Core Python PRISM reference model runs on Python 3 stdlib. Formal
#      research probes use the pinned isolated environment described in
#      research/requirements-formal.txt and research/benchmarks/README.md.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

echo "==> Installing Node/TypeScript workspace dependencies (pnpm)"
pnpm install --frozen-lockfile

echo "==> Syncing Solidity git submodules (forge-std)"
git submodule update --init --recursive

echo "==> Ensuring Foundry toolchain (forge/cast/anvil) is installed"
if [ ! -x "$HOME/.foundry/bin/foundryup" ]; then
  curl -L https://foundry.paradigm.xyz | bash
fi
"$HOME/.foundry/bin/foundryup"

echo "==> Ensuring Foundry is on PATH for interactive shells"
if ! grep -q 'foundry/bin' "$HOME/.bashrc" 2>/dev/null; then
  echo 'export PATH="$HOME/.foundry/bin:$PATH"' >> "$HOME/.bashrc"
fi

echo "==> Install complete"
