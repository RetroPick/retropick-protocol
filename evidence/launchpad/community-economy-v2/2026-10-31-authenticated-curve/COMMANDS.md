# Iteration 002 reproduction

Implementation worktree: /home/ubuntu/project/retropick/retropick-community-economy-v2-20261031, branch research/community-economy-v2-20261031. Parent origin/main was 9a80398089b70498d8f8b5c41164a6d4c17b3cf5. Frozen canonical source 28a4744dcc8005da285f9e924ba7841073daee0b. Original checkout's untracked research report was preserved. No deployment/broadcast/signing command was used. Shell commands used RTK proxy where appropriate; the reproducible underlying commands are below.

Run Foundry commands from contracts/. All outputs/caches are temporary and isolated. Tests use raised harness size allowance; source-only gate enforces deployable size separately. Solidity 0.8.26, Cancun, optimizer 200, via IR, chain 10143.

```sh
FOUNDRY_INVARIANT_RUNS=256 FOUNDRY_INVARIANT_DEPTH=128 forge test --contracts src/v2-research-experiment --match-path 'test/v2/research-experiment/Community*.t.sol' --match-test '^(testCE|testFuzzCE|testLegacy|invariantCE)' --out /tmp/retropick-ce-m2-test-out --cache-path /tmp/retropick-ce-m2-test-cache --chain-id 10143 --code-size-limit 1048576 --fuzz-runs 10000 --fuzz-seed 0xce02 -vv
forge test --contracts src/v2-research-experiment --match-path 'test/v2/research-experiment/CommunityPolicyRegistryV2.t.sol' --match-test '^test(Registry|FuzzRegistry)' --out /tmp/retropick-ce-m2-test-out --cache-path /tmp/retropick-ce-m2-test-cache --chain-id 10143 --code-size-limit 1048576 --fuzz-runs 10000 --fuzz-seed 0xce02
forge build --contracts src/v2-research-experiment --skip test --skip script --sizes --out /tmp/retropick-ce-m2-source-out --cache-path /tmp/retropick-ce-m2-source-cache
forge fmt --check
```

Results: all-final.log 22 passed/0 failed/0 skipped; registry-rerun.log 11/0/0; source-build-sizes.log exit 0; final-global-format-check.log exit 0. Three fuzz properties each ran 10,000 cases. Integrated property 256×128, 32,768 calls. Its successful-action log is one final sequence including seeded actions, not aggregate economic success counts. Handler catches inner failures and reports them separately from zero outer reverts.

From repository root:

```sh
python3 research/launchpad/community-economy-v2/tools/baseline.py --check
python3 -m unittest discover -s research/launchpad/community-economy-v2/tools -p 'test_*.py'
python3 research/launchpad/community-economy-v2/tools/qualify_artifacts.py /tmp/retropick-ce-m2-source-out
python3 research/launchpad/community-economy-v2/tools/economy_scenarios.py
git diff --check
```

Protection: exit 0, no protected paths/original tests changed. Four checker regression tests passed. qualify_artifacts verifies compiler metadata source identity, compiler version and runtime/initcode size; it rejects the mixed output's canonical curve artifact (rejected-mixed-artifact.log). Compiled input/source digests and ABIs are JSON evidence. Economic scenarios are illustrative, not market calibration or reward execution.

## Gas

```sh
forge test --contracts src/v2-research-experiment --match-contract '^CommunityCurveFlowTest$' --out /tmp/retropick-ce-m2-test-out --cache-path /tmp/retropick-ce-m2-test-cache --chain-id 10143 --code-size-limit 1048576 --fuzz-runs 10000 --gas-report
forge snapshot --contracts src/v2-research-experiment --match-contract '^CommunityCurveFlowTest$' --out /tmp/retropick-ce-m2-test-out --cache-path /tmp/retropick-ce-m2-test-cache --chain-id 10143 --code-size-limit 1048576 --fuzz-runs 256 --fuzz-seed 0xce02 --snap /tmp/retropick-ce-m2-gas.snapshot
```

Both exit 0. final-curve-gas.log and gas.snapshot measure the same production source, before reusable fixture inheritance cleanup; final post-cleanup tests in all-final.log pass. Report ranges mix successful/reverted/warm paths. Deployment cost fields of zero for nested helper-created modules are not valid zero-cost deployment claims. No market gas price estimate is asserted.

## Static analysis

```sh
slither . --compile-force-framework foundry --foundry-ignore-compile --foundry-out-directory /tmp/retropick-ce-m2-test-out --filter-paths 'lib/|test/|src/v1/|src/v2/|PRISM' --json /tmp/retropick-ce-m2-slither.json
slither src/v2-research-experiment/CommunityFeeRouterV2.sol --compile-force-framework solc --solc /home/ubuntu/.local/share/svm/0.8.26/solc-0.8.26 --solc-remaps '@openzeppelin/contracts/=lib/openzeppelin-contracts/contracts/' --solc-args '--base-path . --allow-paths . --via-ir --optimize --evm-version cancun' --exclude-dependencies --json /tmp/retropick-ce-m2-router-slither.json
semgrep scan --config p/smart-contracts --metrics off --include '*.sol' --json --output /tmp/retropick-ce-m2-semgrep.json src/v2-research-experiment
```

First Slither attempt exit 1: Foundry importer expected an absent build-info output JSON. Direct-solc fallback completed: exit 255 (49 findings, 19 contracts, 102 detectors). Every result has a contextual disposition in slither-triage.json. Semgrep exit 0: 50 rules/36 files/123 performance suggestions, zero errors, per-result dispositions preserved. No whole-protocol clean-scan claim.

## Failed and intermediate integration attempts

failed-interface-compile.log: missing explicit builder interface inheritance, fixed. failed-callback-fixture.log: prank consumed by an external getter, fixed by preloading dependency. preliminary-curve.log and integration-differential-v4.log are earlier successful runs, not additional unique coverage; inherited duplicate flow tests existed in the differential class then.

failed-broad-mixed-run.log used `forge test --contracts src/v2 --match-path 'test/v2/*.t.sol' --out /tmp/retropick-ce-m2-canonical-out --cache-path /tmp/retropick-ce-m2-canonical-cache --chain-id 10143 --code-size-limit 1048576 --fuzz-runs 256`: 97 passed/9 failed/2 skipped. Five artifact setup collisions, two absent-RPC setups and two inherited invariant-fixture assertions. The failing fuzz counterexample is retained. Abstract fixture extraction fixed the two new harness assertions; no financial calculation was changed.

aborted-run-filter-only.log adds `--no-match-path 'test/v2/research-experiment/**'` with fresh canonical-scoped output/cache; aborted-run-filter-and-skip.log also adds `--skip research-experiment` with canonical-isolated output/cache. Both still compiled 165 files; test-execution filtering did not establish artifact isolation, so own processes were stopped before completion. Neither is PASS.

## Canonical frozen-reference regression

```sh
git worktree add --detach /tmp/retropick-ce-canonical-reference-20261031 28a4744dcc8005da285f9e924ba7841073daee0b
```

After checkout finished, run from that worktree's contracts/. Foundry initialized pinned submodules in this new reference worktree; shared compiled dependencies have zero content differences from the experiment. Canonical source identity is 31/31 equal; original tests are protected and unchanged. reference-submodules.log records dependency commits.

```sh
forge test --contracts src/v2 --match-path 'test/v2/*.t.sol' --out /tmp/retropick-ce-m2-reference-out --cache-path /tmp/retropick-ce-m2-reference-cache --chain-id 10143 --code-size-limit 1048576 --fuzz-runs 256 --fuzz-seed 0xce02
forge test --contracts src/v2 --match-path 'test/v2/*.t.sol' --no-match-contract '^(FullV4StackV2ForkTest|KuruV2EndToEndForkTest)$' --out /tmp/retropick-ce-m2-reference-out --cache-path /tmp/retropick-ce-m2-reference-cache --chain-id 10143 --code-size-limit 1048576 --fuzz-runs 256 --fuzz-seed 0xce02
```

Full reference: exit 1, 64 passed/2 failed RPC setups/10 skipped. Explicit local-only reference: exit 0, 64 passed/0 failed/10 skipped. RPC-required cases are unavailable, not passed or silently repaired. Fork status NOT_RUN; no MONAD_TESTNET_RPC_URL/pinned block. Real hook/executor tests use stateful destination seams and a test-only address-validation override; they are not real v4/fork qualification.

No mainnet/testnet promotion follows these commands. Main delivery is experimental source and evidence only. Candidate ADR-CE01 remains PROPOSED; full controller, treasury, reward, strategy, venue and economic release gates remain open.
