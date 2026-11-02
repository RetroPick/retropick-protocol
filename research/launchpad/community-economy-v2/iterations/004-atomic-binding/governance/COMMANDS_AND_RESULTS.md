# Governance primitive reproducible execution

Working directory: contracts/ in existing experiment worktree. No commits by governance agent. No global remapping/compiler change. New policy/vendor/test only.

```sh
FOUNDRY_TEST=test/v2/research-experiment/governance forge test --contracts src/v2-research-experiment/CommunityTimelockV2.sol --match-contract CommunityTimelockV2Test --out /tmp/ce004-governance-out --cache-path /tmp/ce004-governance-cache --chain-id 10143 --fuzz-runs 10000 --fuzz-seed 0xce04 -vv
forge fmt --check src/v2-research-experiment/CommunityTimelockV2.sol test/v2/research-experiment/governance/CommunityTimelockV2.t.sol
forge build --contracts src/v2-research-experiment/CommunityTimelockV2.sol --skip test --skip script --sizes --out /tmp/ce004-governance-size-out --cache-path /tmp/ce004-governance-size-cache
slither src/v2-research-experiment/CommunityTimelockV2.sol --compile-force-framework solc --solc /home/ubuntu/.local/share/svm/0.8.26/solc-0.8.26 --solc-args '--base-path . --allow-paths . --via-ir --optimize --evm-version cancun' --exclude-dependencies --json /tmp/ce004-governance-slither.json
semgrep scan --config p/smart-contracts --metrics off --json --output /tmp/ce004-governance-semgrep.json src/v2-research-experiment/CommunityTimelockV2.sol
```

Final standalone tests22PASS/0FAIL/0SKIP, two10000-case properties at seed0xce04; first19-test subset also passed before3additional edge tests. Both runs preserved, not added together as unique tests. Source-only build exit0; runtime5842bytes, initcode7072+32constructor bytes. Metadata compilationTarget verified to experimental CommunityTimelockV2; source identity/ABI/settings captured. Scoped format exit0.

Slither0.11.6 exit255 with26results,13contracts/102detectors, per-result contextual triage. Semgrep exit0,2performance suggestions/0errors. Neither scan is a clean audit. Versions/raw logs and hashes in evidence/launchpad/community-economy-v2/2026-11-02-atomic-governance/.

Gas report: repeat standalone test command with --fuzz-runs256 --gas-report; snapshot: same source/test flags using forge snapshot --snap /tmp/ce004-governance-gas.snapshot and --fuzz-runs256. Both exit0. These repeats are gas samples, not additional fuzz proof. Ranges contain successes/reverts/warm cases and are not network gas-price predictions.

Initial forge fmt failed because a newly authored test had been placed under an accidental duplicate contracts/ prefix. Only that new file was moved to the owned test/governance folder and empty self-created directories removed before compilation; no existing file or financial semantics altered. No failed contract test was disabled.

Unqualified global forge fmt --check initially failed on raw upstream style. Raw failure retained in global-fmt-before-vendor-exclusion.log. Do not format approved vendor files: exact upstream hashes are mandatory. Root separately owns the explicit formatter-only ignore for this exact vendor version and global rerun; this agent changed no foundry.toml settings.
