# Qualification checkpoint

Status: PARTIAL / NOT RELEASE QUALIFIED.

## Current iteration 002 — real curve financial slice

Source-scoped local financial result: 22 tests passed, zero failures/skips in all-final.log. This includes 21 scenario/fuzz tests and one stateful property; no inherited duplicates remain. Two critical fuzz properties ran 10,000 cases each at seed 0xce02: actual trade funding conservation and randomized policy/beneficiary epoch rights. The stateful property ran 256 runs × 128 depth = 32,768 calls. All ten selectors were exercised; no outer handler reverts. Caught economic failures are separate. Final-sequence snapshot (including seed actions): 12 successful trades, 14 settlements, 22 claims, 12 proposals, 4 cancellations, 8 activations, 12 controller rotations, 11 donations, 17 unauthorized attempts, 11 invalid settlements and 18 caught economic rejections. These are not aggregate success counts across all runs.

Actual experimental factory/curve buy/sell feeds pre-separated community C into an immutable-source per-launch router. MON and USDC-like exact six-decimal tokens at the Circle address are tested; actual deployed USDC is not fork-qualified. Protocol P retains original escrow. Old pending fees settle under old policy before new epoch activation. Explicit beneficiary rotation and controller handoff preserve existing claims; independent failed/reentrant payout, partial/full claims, two-launch isolation, unsupported transfer behavior, negative backing, one-unit rounding, zero-fee trade, donation and real source-guard callback sequences are covered.

Source-only forge build --sizes passes. Metadata compilationTarget gate rejects the mixed build's canonical curve artifact. Experimental runtime bytes: registry 5679; router 6487; controller 1494; builder 19332; curve 13805; deployer 23942; factory 24486; v4 executor 16036. All measured runtime/initcode sizes pass EIP-170/EIP-3860; factory margin is only 90 bytes under optimizer 200/via-IR/Cancun. Other compiler profiles are not qualified. Source/input hashes, ABIs and exact settings are captured.

Gas report and snapshot are recorded. Mixed-case observed ranges: factory community launch 7,569,665–7,614,801 gas; router claim 36,579–83,308; permissionless settlement 45,754–456,538. These include differing/warm/failing paths, not controlled per-operation benchmarks or current network costs. Router fund statistics include rejected direct calls and must not be advertised as successful funding cost. Contributor count and epoch-history gas campaigns remain incomplete.

Global forge fmt --check and protected-path checker pass. Slither 0.11.6 analyzed router/dependencies with 102 detectors and produced 49 results, all preserved with individual dispositions; its exit 255 indicates findings, not a clean scan. Initial Foundry importer failed on missing build-info output JSON; direct-solc fallback completed. Semgrep ran 50 rules on 36 files, 123 performance suggestions, no parse errors. Independent agent static review found no remaining critical/high issue in the narrow curve slice, with explicit limitations; it is not an external audit.

Broad mixed-tree run: 97 passed, 9 failed, 2 skipped. Failures included missing RPC, basename artifact collisions and two seeded-invariant-fixture inherited tests. Reusable fixture separation fixed the latter; final scoped 22-test run passes without altering financial semantics. Failed logs and counterexample are retained. Merely filtering test execution did not remove duplicate artifacts from compilation; intermediate attempts were stopped and are not PASS. A detached frozen-baseline reference run is recorded separately. Broad default mixed-tree qualification is not claimed.

Additional completed checks: registry rerun 11 passed/0 failed/0 skipped, including 10,000 creator-cap fuzz cases at seed 0xce02; four protection-check regression tests passed. Frozen canonical reference at 28a4744dcc8005da285f9e924ba7841073daee0b: full run 64 passed/2 RPC-setup failures/10 skipped. Explicit local-only rerun excludes only the two RPC-required classes: 64 passed/0 failed/10 skipped. All 31 canonical Solidity files match the experiment checkout; shared compiled dependency hashes have zero differences. Reference setup initialized pinned dependencies only in the disposable detached worktree. No fork test is counted as passed. This gives 33 distinct current experimental/registry tests passing, including three 10,000-case fuzz properties; it does not remove the release blockers above.

Fork: NOT RUN; MONAD_TESTNET_RPC_URL and pinned block absent. Real v4 registration test uses actual hook/executor with stateful mocked destinations and test-only hook-address validation override; it is not a full-v4 or fork PASS. CE v4 hook fee/tax snapshot is zero and buyback disabled; continuous Kuru creator/community fees remain BLOCKED_EXTERNAL_CAPABILITY. CE new launch currently explicitly selects v4. No existing pool identity is mutated.

M2 authenticated funding, M3 curve integration and M4 independent claims are locally TESTED. M4 treasury vault remains DEFERRED (vendored OpenZeppelin subset lacks TimelockController/AccessControl); M5 rewards/M6 execution strategies remain DEFERRED; M7 real noncustodial controller is implemented with partial sequence qualification; M8 graduation has local seams only; M9 remains PARTIAL. Full G0/G1/G2, every LP/CE temporal property, deployed venue identities, product demand and calibrated economics remain open. Candidate ADR-CE01 is PROPOSED. Main-branch research delivery is not production economic promotion. No deploy/broadcast occurred.

## Historical baseline checkpoint

- Created isolated branch/worktree at the frozen baseline.
- Preserved supplied report and its digest.
- Added read-only reproducible inventory/protected-path checker.
- Indexed 31/31 canonical V2 files through XERJ: exit 0, 506 records, no skipped/junked source files.
- No economic Solidity changes, production mutations, deployments, broadcasts or new-module tests.

## Prior planning measurements (not new captured execution evidence)

Formatting passed. Fresh temporary build: escrow 8 passed, zero failures/skips. Broader run reported 32 passed / 2 setup failures / zero skipped. Both failures were ambiguous deployCode artifact selection. Curve invariant properties ran 64 runs and 4096 handler calls. Two math fuzz properties ran 256 cases each. Factory runtime measured 23423 bytes. These observations are context, not a substitute for raw campaign evidence.

## Captured campaign evidence

inventory.json is generated by tools/baseline.py --check. canonical-graduation.log captures an attempted canonical-only rerun from the original checkout at the same source baseline, with experiment source excluded, a fresh temporary output/cache directory, chain ID 10143 and increased harness size limit. The exclusion attempt failed: both tests still fail during setup with ambiguous artifacts. canonical-scoped-graduation.log records the follow-up using --contracts src/v2. See RUNS.md and results.json for exact commands and completed outcomes; an absent or incomplete log is not PASS. Runtime contract limits remain EIP-170 strict.

No RPC/fork campaign, static analysis, gas campaign, economic simulation, compiler-ABI coverage reconciliation or community-economics qualification has completed. Never report mock or skipped tests as fork success.

## Completed scoped rerun

Using --contracts src/v2 resolves artifact ambiguity without source changes: runner reports 3 passed, 0 failed, 0 skipped. This includes two authority unit tests and the grouped coordinator invariant suite (two properties, 64 runs, 4096 handler calls). This is local mocked-destination evidence, not a live Kuru or fork result. Four protection-check regression tests also pass.

## Iteration 001 — actual Solidity prototype

Noncustodial registry prototype implemented. Final targeted run: 14 passed, zero failures/skips, including 11 registry tests (one fuzz property at 10000 cases), two new canonical financial-rights reproductions and one inherited reference admission test. Runtime 5679 bytes; EIP-170 passes for this prototype. Registry source/test formatting and protected paths checked separately. Evidence: evidence/launchpad/community-economy-v2/2026-10-31-policy-prototype/.

G0 manual authority reconciliation, full G1/G2 and real checkpoint integration remain open. Checkpoint/controller mocks are explicit. No real fee router, strategy, reward or integrated community economy has been implemented. No independent external audit, stateful CE campaign, fork or static-analysis qualification. The declared creator-category cap cannot identify hidden beneficial ownership. Module pins do not prove safe implementations. Prototype retained on isolated branch; no main milestone promotion or deployment.
