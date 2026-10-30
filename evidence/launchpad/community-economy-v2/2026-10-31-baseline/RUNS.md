# Baseline commands and provenance

Frozen source HEAD: 28a4744dcc8005da285f9e924ba7841073daee0b. Execution root for Foundry runs below: original retropick-protocol/contracts checkout. This source tree was verified unchanged; the sibling experiment worktree receives logs only. Fresh temporary out/cache directories prevent existing artifacts from influencing these results. No RPC, signing or broadcast arguments were supplied.

## Inventory

From the experiment worktree root:

```sh
python3 research/launchpad/community-economy-v2/tools/baseline.py --check > evidence/launchpad/community-economy-v2/2026-10-31-baseline/inventory.json
```

Result: exit 0; 31 pairs, 30 byte-identical, 890 lexical declarations across both lanes, 17 Solidity test files, zero protected changes. Compiler ABI review remains pending.

## Initial exclusion attempt — FAILED

```sh
ce_check_dir=$(mktemp -d /tmp/retropick-ce-canonical.XXXXXX)
forge test --skip v2-research-experiment --match-contract '(GraduationCoordinatorV2AuthorityTest|GraduationCoordinatorV2InvariantTest)' --chain-id 10143 --code-size-limit 1048576 --out "$ce_check_dir/out" --cache-path "$ce_check_dir/cache"
```

Result: exit 1; zero passed, two failed during setUp with ambiguous artifacts. The experiment directory was still compiled. Raw log: canonical-graduation.log. This is a tooling/setup failure, not a graduation exploit, and cannot qualify graduation invariants.

## Canonical source scope — follow-up

```sh
ce_check_dir=$(mktemp -d /tmp/retropick-ce-canonical-scope.XXXXXX)
forge test --contracts src/v2 --match-contract '(GraduationCoordinatorV2AuthorityTest|GraduationCoordinatorV2InvariantTest)' --chain-id 10143 --code-size-limit 1048576 --out "$ce_check_dir/out" --cache-path "$ce_check_dir/cache"
```

Raw log: canonical-scoped-graduation.log. Final outcome is recorded in results.json after completion. No absent/incomplete run is PASS. Harness size allowance does not relax EIP-170 runtime limits.
