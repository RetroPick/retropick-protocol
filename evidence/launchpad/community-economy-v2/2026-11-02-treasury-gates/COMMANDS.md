# Commands and evidence
Base6d9ac546; Solidity0.8.26/Cancun/viaIR/optimizer200. No deploy/broadcast. Actual tests run against original checkout core, byte-identical to new worktree; no original tracked changes.

From original contracts directory:
```
FOUNDRY_INVARIANT_RUNS=256 FOUNDRY_INVARIANT_DEPTH=128 forge test --contracts src/v2-research-experiment --match-path 'test/v2/research-experiment/Community*.t.sol' --match-test '^(testCE|testFuzzCE|testLegacy|invariantCE|testRegistry|testFuzzRegistry)' --out /tmp/ce003-out --cache-path /tmp/ce003-cache --chain-id 10143 --code-size-limit 1048576 --fuzz-runs 10000 --fuzz-seed 0xce02 -vv
forge build --contracts src/v2-research-experiment --skip test --skip script --sizes --out /tmp/ce003-build-out --cache-path /tmp/ce003-build-cache
FOUNDRY_TEST=/tmp/retropick-community-treasury-v2-20261102/contracts/test/v2/research-experiment/treasury forge test --contracts /tmp/retropick-community-treasury-v2-20261102/contracts/src/v2-research-experiment/CommunityControllerV2.sol --match-contract CommunityControllerTemporalTest --out /tmp/ce003-controller-out --cache-path /tmp/ce003-controller-cache --fuzz-runs 10000 --fuzz-seed 0xce03
```
Financial33pass, three10kproperties, invariant256x128=32768calls; controller6pass incl10kcases. Initial --test CLI failed; corrected FOUNDRY_TEST, rawfailure retained. No numerical harness limit waiver for deployable code; source metadata size gate passes.

Canonical source/reference tests/mocks/foundry.toml/remappings.txt and imported DeployV2MonadTestnet.s.sol materialized from frozen28a4744 via git archive/show into /tmp/ce003-canonical-reference; libs symlink original pinned dependencies. First two setup failures (missing remappings, missing imported script) preserved. No original test edited. From original repo:
```
forge test --root /tmp/ce003-canonical-reference/contracts --contracts src/v2 --match-path 'test/v2/*.t.sol' --no-match-contract '^(FullV4StackV2ForkTest|KuruV2EndToEndForkTest)$' --out /tmp/ce003-canonical-out --cache-path /tmp/ce003-canonical-cache --chain-id 10143 --code-size-limit 1048576 --fuzz-runs 256 --fuzz-seed 0xce03
```
64pass/0fail/10forkskips. RPC-only classes explicitly excluded; none count as pass. No fork qualification.

Binding-precondition test: materialize committed CommunityTreasuryBindingPreconditions.t.sol into /tmp/ce003-binding-test, rebase only its three imports to root-relative original test/v2/research-experiment/CommunityCurveFlow.t.sol and src/v2-research-experiment contract paths. Body unchanged. This allows original dependency resolution without modifying checkout files or submodules. Absolute-import attempt failed and is retained.
```
FOUNDRY_TEST=/tmp/ce003-binding-test forge test --contracts src/v2-research-experiment --match-contract CommunityTreasuryBindingPreconditionsTest --out /tmp/ce003-out --cache-path /tmp/ce003-cache --chain-id 10143 --code-size-limit 1048576
```
One passing real-two-launch/trade/settlement precondition test. Not an implemented helper exploit.

From isolated worktree: baseline.py --check and four unittest protector tests pass; forge fmt --check from contracts passes. Corefinancial/V3/protected diffs empty. XERJ helper unexpectedly selected entire repository; stopped own indexing processes, then direct bounded autoindex of experimental source completed37files/589records, exit0. No whole-repo coverage claimed. Dependency manifest fetched at exact accepted commit; no code imported. New treasury gas/static/custody/invariant campaigns NOT_RUN because G2 blocks implementation.
