# Dual research status

**Date:** 2026-09-26  
**Branch:** `cursor/finance-qualification-bbd4`  
**Follow-on:** PR #3 is merged on `origin/main` at `cd457f8`. That merge contains this branch through `dd7bfb5`. Commits after that merge are the follow-on. This branch was not reset or rebased onto main.  
**Control plane:** `.agent/STATE.json` `prism.math_gate` is `FAIL` because of `CX-FP-SETTLEMENT-001`. Production Solidity remains unauthorized. This is not mainnet authorization and not a human acceptance of the new ADRs.

## Module statuses

| Module | Status |
|---|---|
| Prediction token / market | `CONTRACT_CANDIDATE` |
| PRISM | `FAIL` |
| Cross-module | `BLOCKED` |

`CONTRACT_CANDIDATE` means a research-harness kernel matches the integer model on the committed fixtures. It does not mean PRED-CONTRACT-1 PASS and it does not mean `READY_FOR_V2_INTEGRATION`.

## Gate summary

Machine-readable copy: `research/reports/qualification-gates.yaml`.

PRED-CONTRACT-1: NOT PASS.  
MATH-1: FAIL.  
MATH-1D: FAIL.  
MATH-1E: partial_z3_sympy. R-THEOREM-1, mapped to T-REPL-001, is PROVEN_UNDER_ASSUMPTIONS by a SymPy 1.14.0 identity: h=Gx on every shape with 1..4 states and 1..4 components, in 0.020301s. The oracle payoff on weights (3/5, 2/5) is (2/5, 0, 1, 3/5). R-THEOREM-4 stays the existing two-component Z3 and SymPy check. R-THEOREM-2, R-THEOREM-3, R-THEOREM-5, and R-THEOREM-6 were not re-run. This is not MATH-1 PASS.  
MATH-1D candidate cumulative floor: PROVEN_UNDER_ASSUMPTIONS. Domain check: EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN. Ready for ADR acceptance. Not an oracle pass.  
MATH-1B: bounded_grids_only, not a universal proof. Compositions through supply 16 on 18 decimals, two holders: 917612 states, 7340046 transitions, 8.02598s, clean. The earlier search remains 378530 states through supply 12. Backing on PrismSeries with weights {0, 1/2, 1}, supplies 0..8, quantities 0..8: 81 states, 2187 transitions, 0.054409s, clean. Canonical MATH-1 stays FAIL.  
MATH-1D candidate Solidity: `differential_research_kernel`. The kernel matches the Python fixtures. It is not MATH-1 PASS and it is not CONTRACT-1.  
Component backing Solidity: `differential_research_kernel`. `CandidateComponentBacking` matches `FixedPointSeries` deposit, mint, and requirement-delta redeem. `CandidateReservationLedger` matches the duplicate-source rejection. This is not settlement, not MATH-1 PASS, and not CONTRACT-1.  
Partial-resolution transform: `differential_research_kernel`. `CandidatePayoffTransform` matches the Python integers for a payoff-equivalent component conversion. Wrong component, non-equivalent payoff, and reorder were tested. It is not wired to prediction tokens. MATH-1 and CONTRACT-1 stay unmet.  
Prediction `Underfunded` and `LiveLiability`: PROVEN_UNDER_ASSUMPTIONS unreachable for numerators (2, 0), (0, 2), and (1, 1). Branch coverage stays 94.44% (34/36). That is not 100% coverage and not PRED-CONTRACT-1 PASS.  
MATH-1F: measured_simulation on declared synthetic books. It is not a solvency result and not Kuru liquidity. Arbitrage occurring is NOT_YET_VALIDATED.  
Minimum-cost replication: EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN for declared rational matrices of at most 16 states and 8 components. A AND B with columns A, B, and the constant 1 is PRODUCT_NOT_REPLICABLE. This is not Kuru and not a solvency theorem.  
Storage-slot isolation: INFERRED from the current kernel layouts. Two markets do not share split slots. Two series contracts do not share mint slots. Monad throughput was not measured. ADR-R06 stays PROPOSED.  
R-I08: the recorded gate `R-I08_resolved_not_redeemable` stays measured. `CandidateCumulativeSettlement.redeem` reverts `NotRedeemable` until `makeRedeemable`. The payout formula was not changed. In the INV-P numbering that test is the R-I09 funding gate. INV-P08 partial resolution already has tests.  
Invariant coverage: P-I01..P-I10 are executable. P-I05 `cancelDraft` stays not_yet_validated. R-I02 and R-I12 were prose only and now have tests in `test_invariant_ids.py`. R-I10 canonical per-call settlement stays COUNTEREXAMPLE_FOUND. X-I01..X-I07 stay not_yet_validated because the source interface is not frozen. MODULE-ADMISSION-FINANCE-1 stays not met.  
Benchmarks: `benchmarks_measured: local_single_environment`. One Foundry gas test and five-sample reference timings. Not admission. 16/16 replication solve was NOT_RUN. No percentiles.  
Static analysis: `measured_with_findings`. A complete Slither IR is `blocked_tool`. `--solc-force-legacy-json` still leaves `_redeem` without IR, and solc 0.8 rejects legacy JSON. S-P16 stays open. Inspection of the redeemed cursors is PROVEN_UNDER_ASSUMPTIONS and did not change storage. This is not PRED-CONTRACT-1 PASS.  
Local reproducibility: `rerun_pass`. Prediction unit tests 12 OK, PRISM unit tests 85 OK, Foundry 63 passed and 0 failed. Existing interpreter. No fresh virtualenv.  
MODULE-ADMISSION-FINANCE-1: not met.  
PRISM CONTRACT-ARCH-1: proposed, contingent on ADR-R03. Not a pass.  
SOURCE-ASSET-INTERFACE-FREEZE: proposed_not_frozen.  
PRED-KURU-1: blocked.

## What changed since the baseline

The baseline file remains the pre-change record. After it:

- a prediction reference model and Foundry kernel were added outside `contracts/src/v2`;
- the PRISM suite was re-run and a settlement counterexample was locked in as a test;
- proposed ADRs P01–P07 and R01–R07 were added and labeled PROPOSED.

## Contradictions still open

1. Canonical diagrams name `CompleteSetVault`. ADR-P03 proposes not to deploy one. The diagram was not rewritten as if the ADR were accepted.
2. `research/prism-model/native_market.py` still collapses RESOLVED and REDEEMABLE. The new prediction model does not.
3. Evidence note from 2026-09-17 says 51 tests. Baseline discovery saw 55. Later discovery saw 60 after new tests.
4. Launchpad `status.yaml` still says the web app is unimplemented. That lane was not edited.
5. `.agent/STATE.json` previously said MATH-1 `IN_PROGRESS`. It now says `FAIL` for the settlement rule. Accepted ADR-002 is unchanged.

## Blockers

- Human acceptance of ADR-P01..P07 and of ADR-R03's cumulative-floor repair. The candidate bound is recorded. Acceptance was not granted.
- Human acceptance before any production settlement port. A candidate kernel now exists under `research/contract-kernels/src/prism/`. CONTRACT-1 stays not_met. ADR-R07 still stops a v2 port.
- Complete Slither IR or another static-analysis pass. `PredictionMarket.sol` branch coverage was remeasured at 94.44% (34/36). `Underfunded` and `LiveLiability` remain uncovered. That is not a pass by itself.
- Kuru router address and a RetroPick parameter set. The worksheet's book rows are BLOCKED after a second primary-source pass. No fork and no deployment.
- Cross-module differential harness. The source-asset list is `proposed_not_frozen`, not frozen. X-I01..X-I07 are NOT_YET_VALIDATED. Blocker: source interface not frozen.
- Kernel `cancelDraft` for the cancelled-draft branch of P-I05.
- Echidna, Medusa, Halmos, Mythril, semgrep: not installed. solhint 5.2.0 ran locally and is not a clean-audit substitute. Slither's focused rerun still has incomplete IR.
