# M6 baseline CI repair qualification

Status: PARTIAL — local unit gate verified; all three following commands recorded exit0, but hostclear removed their transient final raw logs before archival. A fresh CI run with retained artifacts remains required. PR46's skipped suites have not retrospectively passed.

Baseline source: main `7ddf4dae65e11acb489be7eceb30a4846adf18cc`. Working branch: `research/v2-m6-permissionless-revenue-20261104`. Foundry1.8.4 (`50af4efe189dc64bad2b75ed6990b835de66c4ae`), Solidity0.8.26, Cancun, optimizer200, viaIR. Profile `test`, chain10143, harness code limit1048576. Source patch manifest and raw preserved evidence: `evidence/launchpad/community-economy-v2/2026-11-04-m6-baseline-ci/`.

## Cause and repair

Broad compilation contains three `RetroPickLaunchFactoryV2` artifacts: canonical24486runtime bytes, historical reference23423, experimental24486. The original shared Factory/V4 fixtures used basename-only deployment identifiers. `GraduationCoordinatorV2AuthorityTest.setUp()` therefore failed before its financial assertions ran. Source-qualified `src/v2/...:Contract` identifiers select canonical source; fork helper identifiers and imported release-script identity are explicit too. No reference source was deleted or renamed.

The newly added V4 seam contained a39hex-digit Circle address, failing Solidity error9429 when selected. It now uses the Router-admitted40digit address. Two new seam assertions verify Router/Vault fee assets match the selected asset. Existing assertions and financial implementations are unchanged.

## Actual local results and evidence retention

| Run | Observation | Retained evidence |
|---|---|---|
| Initial unit reproduction |30PASS/1FAIL/0SKIP, artifact ambiguity |baseline-unit-FAILED.log |
| Initial USDC stateful baseline |1PASS/0FAIL/0SKIP;256×128=32768calls, zero outer reverts |baseline-usdc-invariant-PASS.log |
| Initial selected V4 seam |Compiler error9429:39digit address |baseline-v4-seam-FAILED.log |
| Repaired unit gate |32PASS/0FAIL/0SKIP across8suites; Authority's2tests now execute |unit-PASS.log |
| Repaired original stateful gate |Command completed exit0;3runner-reported passes were observed in tool output |suite-runs.json; finalraw log lost |
| Repaired USDC stateful gate |Command completed exit0 at256×128 |suite-runs.json; finalraw counts/selector table not retained |
| Repaired V4 behavior seam |Command completed exit0 |suite-runs.json; finalraw counts/traces not retained |

Host date advanced to2026-11-05 and `/tmp/m6-ci-*` was cleared. `RETENTION_STATUS.json` records this limitation. Do not manufacture logs or infer final run counts from source shape. Earlier retained USDC coverage is separate from the repaired command result. These are local fixture/behavior tests, not live Circle, genuine Uniswap, Safe or fork qualification.

## Exact commands

From `contracts/`:

```sh
FOUNDRY_PROFILE=test forge test --match-path 'test/v2/unit/*.t.sol' --fuzz-seed 0x6a --out /tmp/m6-ci-out --cache-path /tmp/m6-ci-cache -vvv
FOUNDRY_PROFILE=test FOUNDRY_INVARIANT_RUNS=256 FOUNDRY_INVARIANT_DEPTH=128 forge test --match-path 'test/v2/invariant/*.t.sol' --fuzz-seed 0x6a --out /tmp/m6-ci-out --cache-path /tmp/m6-ci-cache -vvv
FOUNDRY_PROFILE=test FOUNDRY_INVARIANT_RUNS=256 FOUNDRY_INVARIANT_DEPTH=128 forge test --match-path 'test/v2/community-economy/treasury-integration/CommunityTreasuryUSDCInvariant.t.sol' --fuzz-seed 0x6a --out /tmp/m6-ci-out --cache-path /tmp/m6-ci-cache -vvv
FOUNDRY_PROFILE=test forge test --match-path 'test/v2/community-economy/treasury-integration/CommunityTreasuryV4Seam.t.sol' --fuzz-seed 0x6a --out /tmp/m6-ci-out --cache-path /tmp/m6-ci-cache -vvv
```

`suite-runs.json` contains exact argv, profile, seed, invariant parameters, source SHA, elapsed time and exit code for the final three runs. `REPAIR_SOURCE_MANIFEST.json` hashes the owned patch; `canonical-baseline-source-sha256.json` records unchanged canonical implementations at baseline.

## CI behavior

The existing `solidity-v2` required job identity and deterministic full-stack job are retained. Once Foundry setup succeeds, later independent Solidity suites execute even after an earlier suite failure. Explicit bash enables pipefail so `forge | tee` cannot hide failures. The final mandatory aggregate requires all four suite outcomes to be `success`; failure, cancellation, missing result or skip cannot yield qualification. Artifact upload runs regardless of test success, preserving versions, source SHA, filtered compiler settings, logs and outcome JSON. No `continue-on-error` was introduced.

PyYAML parsed the workflow; local evaluation checked all256combinations of success/failure/skipped/cancelled across four suites, with zero incorrect acceptances. A false pipeline remained nonzero. `workflow-validation.json` retains results. `actionlint` is unavailable; GitHub's actual workflow validation/run remains required. Source-specific builds do not waive runtime/initcode limits.

## Remaining limits

The PR46 USDC handler catches economic reverts into an aggregate counter. Its backing/conservation pass and seeded branch reachability do not prove every rejected action was expected; M6's new handler must classify rejection reasons and flag unexpected failures. No canonical venue revenue change is qualified by these baseline tests. No deployment, transaction broadcast, historical financial evidence edit or production-source mutation occurred in this repair.
