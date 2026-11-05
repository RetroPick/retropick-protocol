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


## 2026-11-05 current-source increment

Current canonical admission is V4-only, with no concrete Kuru files/imports/names in active Solidity or scripts. Venue wire0 remains V4 and wire1 is LEGACY_RESERVED. The recorded testnet31-source archive is independently frozen at f0363249; the39-source7dd regression closure is a separate historical artifact.

Extraction campaign `evidence/launchpad/community-economy-v2/2026-11-05-m6-kuru-extraction/scoped-run-02/manifest.json`: **286 passed, zero failed,14 skipped** across source-scoped active unit34, Factory18, V4 behavior7, canonical invariants3, canonical community94, established experimental community107, historical unit5 and historical Factory18. Skips are unqualified external/fork cases, not fork passes. Historical/existing assertions are preserved in raw originals and compared by the extraction verifier. Factory/Coordinator ABIs and executable runtime after outer metadata removal match the frozen7dd comparison; Registry admission intentionally changes. Factory runtime remains24,486bytes.

A separate FullV4Stack fork test compiled but **failed in setUp because MONAD_TESTNET_RPC_URL is absent**; its raw trace is retained. This is BLOCKED external qualification, not a mocked/fork pass. Global `forge fmt --check` still FAILS on pre-existing/frozen source formatting; the changed current/extracted paths and new prototype scope pass formatting. The original frozen baseline checker also reports differences from approved prior V2 adoption/source extraction; the unchanged checker and its failure are preserved, with task-specific byte/source protection checks separately passing.

New financial experiment: Router13 unit/adversarial tests pass with two seeds (0x6a,0x6b), each10,000 critical accounting fuzz cases. Identity/source/venue doubles are explicit in these tests. Accounting invariants pass native-only256x128 for seeds6a/6b and final native plus modeled six-decimal quote256x128 each for seed6c:131,072 handler calls total across four campaigns, zero unexpected handler reverts. Final two-asset model accounts for65,536 of those calls. Selector distributions and expected-rejection actions are retained; no catch-all suppression is used.

Genuine local V4 experiment passes2/0/0 on final formatted financial sources (`20261105T135901201409Z`). Real pinned PoolManager/PositionManager/Permit2 contracts execute both exactness modes in both directions, actual fee transfers, protocol escrow, independent creator/contributor claims, two-asset Treasury claims/spends, policy transitions, two same-creator launches and failed launch retry. No venue etch or broadcast is used. The quote token is modeled and governance proposer is an EOA; this does not qualify live Circle, a real fork or Safe governance.

Compiler/ABI/runtime handoff lives under `handoff/`; seven new deployables are under EIP-170, with RevenueDeployer23,812bytes the tightest new margin. Static evidence retains all129 Slither findings (including imported closure findings awaiting further review) and28 Semgrep performance suggestions. No external audit or production guarantee is claimed. See QUALIFICATION.json, raw command manifests and M6_FEE_SOURCE_ADR_CANDIDATE before canonical adoption.
