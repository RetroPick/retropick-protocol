# Executed commands and evidence boundaries
Working directory: experiment worktree/contracts unless specified. Raw final logs are alongside this record. No broadcast/deployment flags.

```sh
forge build --contracts src/v2-research-experiment --skip test --skip script --sizes --out /tmp/ce004-final-source-out --cache-path /tmp/ce004-final-source-cache
FOUNDRY_INVARIANT_RUNS=256 FOUNDRY_INVARIANT_DEPTH=128 forge test --contracts src/v2-research-experiment --match-contract '^(CommunityAtomicBindingTest|CommunityCurveFlowTest|CommunityPolicyRegistryV2Test|CommunityAccountingInvariantTest|CommunityLegacyDifferentialTest|CommunityV4RegistrationTest|CommunityEpochRoundingTest|CommunityControllerTemporalTest|CommunityTreasuryBindingPreconditionsTest|CommunityTimelockV2Test|CommunityTreasuryIntegrationTest|CommunityTreasuryInvariantTest)$' --match-test '^(testCE|testFuzzCE|testRegistry|testFuzzRegistry|testLegacy|invariantCE)' --out /tmp/ce004-out --cache-path /tmp/ce004-cache --chain-id 10143 --code-size-limit 1048576 --fuzz-runs 10000 --fuzz-seed 0xce04 -vv
forge fmt --check
python3 ../research/launchpad/community-economy-v2/tools/baseline.py --check
python3 -m unittest discover -s ../research/launchpad/community-economy-v2/tools -p 'test_*.py'
```

Combined84tests pass. Final treasury17tests pass (16scenario/fuzz+1stateful) at256x128 and10kfundingfuzz; same source-scope/chain/harness parameters, match-contract selects CommunityTreasuryIntegrationTest or CommunityTreasuryInvariantTest, output/cache /tmp/ce-vault-{out,cache}. Exact worker shell invocation was not completely handed off before its session limit; raw results/selector tables are preserved, no invented command asserted.

Source-only metadata targets and byte sizes measured from /tmp/ce004-final-source-out, not ambiguous short artifact lookup. Profile compiler0.8.26/Cancun/viaIR/optimizer200. Runtime gate<=24576 independently of harness ceiling. Historical parser/expectRevert failures and initial no-test build preserved; none counted as passing tests. Governance standalone commands, dependency provenance/advisories and static scan dispositions live in iteration004/governance and corresponding raw logs. Extended treasury static commands were not fully handed off; raw results preserved and this reproducibility gap is explicit.
