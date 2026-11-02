# Canonical candidate commands

Worktree: retropick-community-economy-v2-20261031; base main7bad742b; source bytes qualified atff7540ba. No broadcasts. Original untracked user inputs remain in original checkout.

```sh
FOUNDRY_TEST=test/v2/community-economy FOUNDRY_INVARIANT_RUNS=256 FOUNDRY_INVARIANT_DEPTH=128 forge test --contracts src/v2 --match-contract '^CanonicalCommunity' --out /tmp/ce005-out --cache-path /tmp/ce005-cache --chain-id 10143 --code-size-limit 1048576 --fuzz-runs 10000 --fuzz-seed 0xce05 -vv
forge build --contracts src/v2 --skip test --skip script --sizes --out /tmp/ce005-source-out --cache-path /tmp/ce005-source-cache
forge fmt --check
python3 research/launchpad/community-economy-v2/tools/canonical_adoption.py
python3 -m unittest discover -s research/launchpad/community-economy-v2/tools -p 'test_*.py'
python3 research/launchpad/community-economy-v2/tools/baseline.py --check
```

Community87PASS/0FAIL/0SKIP; build/format/stagechecker pass. Historical baseline checker intentionally fails on approved canonical differences; no weakening. Format correction only affected four newly authored canonical test import layouts after the test campaign; candidate Solidity source bytes unchanged.

Original regression isolation: create unique temporary contracts root; copy candidate canonical source, exact original test/v2 (excluding experimental/newcommunity trees) and mocks from7bad742b; symlink same repository dependencies; copy unchanged foundry/remappings and the imported DeployV2MonadTestnet script solely for compilation (no script invocation/broadcast). Initial missing-script parse failure retained. Run:

```sh
forge test --root "$qualifier_root" --contracts src/v2 --match-path 'test/v2/*.t.sol' --no-match-contract '^(FullV4StackV2ForkTest|KuruV2EndToEndForkTest)$' --out /tmp/ce005-regression-out --cache-path /tmp/ce005-regression-cache --chain-id 10143 --code-size-limit 1048576 --fuzz-runs 256 --fuzz-seed 0xce05
```

Result63PASS/1FAIL/10SKIP. Smallest reproducer: same root/output/cache/chain/harness, replace match-path/exclusion with `--match-contract DEV4GraduationExtractionResearchTest --match-test testThinFactoryRuntimeIsResearchOnly -vv`; exit1 preserved. Actual research runtime25071, assertion23500. No test-body modification.

Historical import candidate was tested only in this owned temporary qualifier. Materialize just the8dependency reference closure files listed in historical-proposal-materialized-closure.txt, keeping repository's full31file snapshot unchanged; apply the proposed five-import patch to temporary fixture only. Use same regression invocation with fresh --out /tmp/ce005-proposal-clean-out and --cache-path /tmp/ce005-proposal-clean-cache:64PASS/0FAIL/10SKIP. An earlier full31file materialization generated duplicate short-basename artifacts and4setup failures; raw log retained. Clean source-specific closure/out resolves that importer collision without financial changes, test disabling or renamed original contracts. Proposed run is not current-original-test qualification until owner exception is accepted/applied.

Beads: bd prime produced no context; bd where reported no active workspace. No new database/campaign was initialized. Existing research package remains handoff source. Extended static scan invocation handoff limitation is recorded in iteration004; raw scan results retained. No actual multisig, mainnet/testnet deployment, real RPC fork or external audit qualification claimed.

Owner approval applied2026-11-03 for the exact five-import historical fixture pin. Reproducible checked-in runner executed against current repository source:

```sh
python3 -u research/launchpad/community-economy-v2/tools/qualify_canonical.py --run
```

Exit0;64PASS/0FAIL/10forkSKIP. Materialization manifest and full command retained. Only the known historical reference import closure enters this qualifier; repository full31file snapshot is unchanged. Owner exception is enforced byte-for-byte by canonical_adoption.py, not a broad original-test exemption. Final canonical community run (same earlier command) includes prefunding cases:89PASS/0FAIL/0SKIP at seed0xce05,80k targeted fuzz and65,536stateful calls. Campaign began2026-11-02 and continued2026-11-03.

Additional targeted run: FOUNDRY_TEST=test/v2/community-economy forge test --contracts src/v2 --match-contract '^CanonicalCommunityTreasuryGraduationTest$' --out /tmp/ce005-out --cache-path /tmp/ce005-cache --chain-id 10143 --code-size-limit 1048576 -vvv.2PASS/0FAIL/0SKIP. Combined distinct canonical coverage91(89+2). Initial expectation/getter harness failure retained; no financial source was changed.
