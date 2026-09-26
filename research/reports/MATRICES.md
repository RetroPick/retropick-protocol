# Qualification matrices

Every row points at evidence from this program. Status words are the program's classifications, not marketing.

## PREDICTION_REQUIREMENT_MATRIX

| Requirement | Status | Evidence |
|---|---|---|
| 1 collateral splits into 1 YES + 1 NO | PROVEN for the zero-fee model | `research/prediction-model/theorems.py` P-THEOREM-1, fixture `prediction_split` |
| Merge is the inverse before resolution | PROVEN | P-THEOREM-2, fixture `prediction_merge` |
| YES_WIN / NO_WIN payouts | PROVEN on the integer path | P-THEOREM-4, Foundry `test_yes_redemption_matches_fixture` |
| INVALID not automatic | RECOMMENDATION plus explicit enum | ADR-P05, Polymarket resolution page retrieved 2026-09-26 |
| Cumulative INVALID floor | EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN on compositions 0..16; per-call and half-up stay COUNTEREXAMPLE_FOUND. PRED-MATH-1 partial | `docs/prediction/07_ROUNDING.md`. 131087 states, 2097154 transitions, 0.410255s. Solidity replay matched, 0 mismatches, 79.76s. `block_gas_limit` 600000000000 is profile `invalid_floor_compositions` only. The default suite skips the walk and still runs the supply-2 test |
| Separate RESOLVED and REDEEMABLE | implemented in kernel | `test_yes_redemption_matches_fixture` expects revert before open |
| No admin mint | tested | `test_user_cannot_mint_outcome` |
| Standard collateral only | tested for fee-on-transfer | `test_fee_on_transfer_split_reverts` |
| Kuru listing | BLOCKED | worksheet; RetroPick parameters not derived |
| Kernel operations have Python fixtures and Foundry assertions | measured | `PredictionDifferentialTest`, 14 passed. No integer mismatch |
| `Underfunded` and `LiveLiability` reachable | PROVEN_UNDER_ASSUMPTIONS unreachable | `unreachable-branches-2026-09-26.json`. Branch coverage stays 94.44% (34/36) |
| PRED-CONTRACT-1 PASS | not met | `docs/prediction/13_PRED_GATE.md` |

## PRISM_REQUIREMENT_MATRIX

| Requirement | Status | Evidence |
|---|---|---|
| `h=Gx`, `x>=0` | REPRODUCED | existing replication tests; ADR-002 |
| Minimum-cost exact `Gx=h` | EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN | `minimum_cost_replication.py`. Not Kuru. Not solvency. Not MATH-1 PASS |
| AND is not replicated by A, B, and 1 | PRODUCT_NOT_REPLICABLE | `minimum_cost_replication.py` equality inconsistency. Prior Z3 row stays COUNTEREXAMPLE_FOUND |
| Backing before mint | REPRODUCED | `test_model.py` |
| Component requirement delta round trip | PROVEN by construction; 200 samples, 0 mismatches | `math1_probe.component_round_trip_samples` |
| Per-call settlement floor | COUNTEREXAMPLE_FOUND | `CX-FP-SETTLEMENT-001` |
| Cumulative-floor candidate | PROVEN_UNDER_ASSUMPTIONS; domain check EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN | `cumulative_settlement.py`; not an oracle replacement |
| Global-cursor telescope | PROVEN_UNDER_ASSUMPTIONS for the inductive identity only | SymPy 1.14.0. Not canonical MATH-1 |
| MATH-1F synthetic quotes | measured_simulation | `market_microstructure.py`. Not solvency. Not Kuru |
| MATH-1 PASS | FAIL | canonical per-call rule remains |
| PRISM Solidity | settlement, component backing, and a payoff-transform candidate | Settlement and backing kernels are unchanged. `partial_resolution_transform` is `differential_research_kernel`. CONTRACT-1 not_met. Not MATH-1 PASS |
| Payoff-equivalent partial transform | differential_research_kernel | `partial_resolution.py` and `CandidatePayoffTransform.sol`. Wrong component, non-equivalent payoff, and reorder are tested. Not wired to prediction tokens |
| PRISM CONTRACT-ARCH-1 | proposed, not pass | `docs/prism/04-architecture/PHASE1_CANDIDATE_SERIES.md` |

## THEOREM_STATUS_MATRIX

| ID | Status | Evidence |
|---|---|---|
| P-THEOREM-1 | PROVEN | `theorems.all_theorems` |
| P-THEOREM-2 | PROVEN | same |
| P-THEOREM-3 | PROVEN | same, three results on one market |
| P-THEOREM-4 | PROVEN | same |
| P-THEOREM-5 | PROVEN | illegal operations rejected |
| P-THEOREM-6 qualified floor | PROVEN | invalid market of 5 units |
| P-THEOREM-6 half-up | COUNTEREXAMPLE_FOUND | `half_up_both_sides(1) == 2` |
| P-THEOREM-6 per-call floor | COUNTEREXAMPLE_FOUND | `fragmentation_gap(5) > 0` |
| INVALID floor compositions | EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN for the cumulative floor | supply 0..16, holders A and B, both cursors. 131087 states, 2097154 transitions, 0.410255s. `invalid-floor-compositions-2026-09-26.json` |
| INVALID per-call composition witness | COUNTEREXAMPLE_FOUND | supply 2, parts (1, 1), one-shot 1, per-call 0. 128512 gap rows. Half-up of 1 on both sides pays 2 |
| Solidity INVALID redeem | matches the cumulative floor | same 131087 states and 2097154 transitions, 0 mismatches, 79.76s. `block_gas_limit` 600000000000 is profile `invalid_floor_compositions` only. Isolated re-run 2 passed, 0 failed, same counts, 79.63s. Default suite skips the walk. Named profile still executes it: 131087 states, 2097154 transitions, 0 mismatches. Research candidate. PRED-MATH-1 stays partial |
| P-THEOREM-7 | PROVEN | supplies differ after burn, liability holds |
| T-FP-003 funding guard | PROVEN_UNDER_ASSUMPTIONS for funding only | addendum in `docs/prism/math/17_THEOREMS.md` |
| CX-FP-SETTLEMENT-001 | COUNTEREXAMPLE_FOUND | probe JSON |
| T-FP-CUM-001 | PROVEN_UNDER_ASSUMPTIONS | global-cursor identity; 378530 states, 2542061 transitions, 2.973316s |
| T-FP-CUM-001 supply 16 | EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN | compositions 0..16, decimals 18, two holders. 917612 states, 7340046 transitions, 8.02598s. Not MATH-1 PASS |
| Backing grid B >= Sx | EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN | PrismSeries weights {0, 1/2, 1}, supplies 0..8. 81 states, 2187 transitions, 0.054409s |
| Global-cursor telescope, symbolic | PROVEN_UNDER_ASSUMPTIONS | SymPy 1.14.0 inductive cancellation. `candidate-telescope-proof-2026-09-26.json` |
| Per-holder cursor telescope | COUNTEREXAMPLE_FOUND | witness gap 1. Z3 5.1.0. Not the candidate |
| MATH-1F | measured_simulation | synthetic books. Not a solvency result |
| Z3 two-component solvency | PROVEN_UNDER_ASSUMPTIONS | Z3 5.1.0 unsat. This is R-THEOREM-4 / T-BS-003 for two components and one state only |
| R-THEOREM-1 / T-REPL-001 | PROVEN_UNDER_ASSUMPTIONS | SymPy 1.14.0. h=Gx on shapes 1..4 by 1..4. `r-theorem-1-2026-09-26.json`. Not MATH-1 PASS |
| R-THEOREM-5 / T-BS-004 | PROVEN_UNDER_ASSUMPTIONS | SymPy 1.14.0 and Z3 5.1.0 unsat. Exact `QR` payment. `r-theorem-5-2026-09-26.json`. Not MATH-1 PASS |
| R-THEOREM-6 / T-ALLOC-001 | PROVEN_UNDER_ASSUMPTIONS | Z3 5.1.0 unsat on deposit, reserve, release, and withdraw. Reserve 60 then 50 against 100 rejected. `r-theorem-6-2026-09-26.json`. Not MATH-1 PASS |
| T-PARTIAL-002 | PROVEN_UNDER_ASSUMPTIONS | SymPy 1.14.0 and Z3 5.1.0. Value equality on a state iff `B_i*g_i = B_i*r_i`. `t-partial-002-2026-09-26.json`. Not MATH-1 PASS |
| T-FP-001 | PROVEN_UNDER_ASSUMPTIONS | Z3 5.1.0 unsat. Ceil mint requirement. Floor raw 0 does not cover weight 1. `t-fp-001-2026-09-26.json`. Not MATH-1 PASS |
| T-FP-002 | PROVEN_UNDER_ASSUMPTIONS | SymPy 1.14.0 margin identity. Z3 5.1.0 unsat. Supply 5 redeem 2 leaves backing 2 against requirement 2. `t-fp-002-2026-09-26.json`. Not MATH-1 PASS |
| T-FP-003 | PROVEN_UNDER_ASSUMPTIONS for funding only | Z3 5.1.0 unsat. Supply 2, payout `10^18-1` pays 0+0, one-shot floor 1, dust 2, funding holds. `t-fp-003-2026-09-26.json`. Not MATH-1 PASS |
| T-FP-004 | PROVEN_UNDER_ASSUMPTIONS | SymPy 1.14.0 and Z3 5.1.0 unsat. Mint 5 then redeem 5 moves 3 and 3 both ways. `t-fp-004-2026-09-26.json`. Not MATH-1 PASS |
| T-BS-001 | PROVEN_UNDER_ASSUMPTIONS | SymPy 1.14.0 margin identity. Z3 5.1.0 unsat. Exact mint of 1000 leaves margin 0. `t-bs-001-2026-09-26.json`. Not MATH-1 PASS |
| T-BS-002 | PROVEN_UNDER_ASSUMPTIONS | SymPy 1.14.0 margin identity. Z3 5.1.0 unsat. Redeem 250 from supply 1000 leaves margin 0. `t-bs-002-2026-09-26.json`. Not MATH-1 PASS |
| T-BS-003 | PROVEN_UNDER_ASSUMPTIONS for every finite component count | SymPy 1.14.0 sum identity. Z3 5.1.0 inductive step unsat. 3 components, 4 states solvent. `t-bs-003-2026-09-26.json`. Not MATH-1 PASS |
| T-NATIVE-001 | PROVEN_UNDER_ASSUMPTIONS | SymPy 1.14.0 gap identity. Z3 5.1.0 unsat. Split 100 merge 25 leaves 75. `t-native-001-2026-09-26.json`. Not MATH-1 PASS |
| T-NATIVE-002 | PROVEN_UNDER_ASSUMPTIONS for valid YES and NO | Z3 5.1.0 unsat. Unit payoffs 1+0 and 0+1. Invalid payout unspecified. `t-native-002-2026-09-26.json`. Not MATH-1 PASS |
| T-LC-001 | PROVEN_UNDER_ASSUMPTIONS | Exact enumeration of `lifecycle.transition`. 7 edges, 42 rejected. No path back to ACTIVE. `t-lc-001-2026-09-26.json`. Not MATH-1 PASS |
| T-LC-002 | PROVEN_UNDER_ASSUMPTIONS | Exact enumeration of `PrismSeries.resolve`. One commit from RESOLUTION_PENDING. Second call unchanged. `t-lc-002-2026-09-26.json`. Not MATH-1 PASS |
| T-PARTIAL-001 | PROVEN_UNDER_ASSUMPTIONS | SymPy 1.14.0 on 30 partitions. Z3 5.1.0 unsat. Basket 3/5 and 2/5 returns 18/25. `t-partial-001-2026-09-26.json`. Not MATH-1 PASS |
| Precision boundary 6/8/18 | EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN | 168 cells. Solidity matches 129 fitting cumulative cells. 15 overflow products and 24 zero-supply cells excluded. Per-call rule is not in Solidity. Forge 1.8.3, solc 0.8.26, optimizer 200, 1 passed. `precision-boundary-solidity-2026-09-26.json`. Not MATH-1 PASS |
| Zero-supply settlement dust | residual bound PROVEN_UNDER_ASSUMPTIONS; sweep policy NOT_YET_VALIDATED | Exact ceil funding leaves 0 or 1, and that residual sits. 24 Python zero-supply cells leave balance 0. Solidity `ZeroSupply` still reverts. No extraction witness. Forge 1.8.3, 4 passed. `zero-supply-dust-2026-09-26.json`. Not MATH-1 PASS |
| Candidate settlement stateful invariants | pass on two seeds; kernel stays differential_research_kernel | 256 runs, depth 128, 32768 calls, 0 reverts. Seeds 20260926 and 20260927. fail_on_revert false. No counterexample. `candidate-settlement-invariant-2026-09-26.json`. Not MATH-1 PASS |
| Candidate backing stateful invariants | pass on two seeds; kernel stays differential_research_kernel | deposit, mint, redeem. 256 runs, depth 128, 32768 calls, 0 reverts. Seeds 20260926 and 20260927. `candidate-backing-invariant-2026-09-26.json`. Not MATH-1 PASS |
| Candidate reservation stateful invariants | pass on two seeds; kernel stays differential_research_kernel | deposit and reserve. No withdraw was added. 256 runs, depth 128, 32768 calls, 0 reverts. Seeds 20260926 and 20260927. `candidate-reservation-invariant-2026-09-26.json`. Not MATH-1 PASS |
| Candidate payoff-transform stateful invariants | pass on two seeds; kernel stays differential_research_kernel | transformComponent. 256 runs, depth 128, 32768 calls, 0 reverts. Seeds 20260926 and 20260927. `candidate-payoff-invariant-2026-09-26.json`. Not MATH-1 PASS |
| Market demand hypotheses | NOT_YET_VALIDATED | unchanged |

## COUNTEREXAMPLE_MATRIX

| ID | What fails | Minimal case | Evidence |
|---|---|---|---|
| CX-PRED-HALF-UP | both sides ceil(q/2) | q=1 pays 2 | `complete_set.naive_half_up` |
| CX-PRED-FRAGMENT | per-call floor(q/2) | 1-unit stream pays 0 | `fixed_point.fragmentation_gap` |
| CX-PRED-FEE-NAIVE | credit nominal amount | received 90, credit 100 | `theorems.fee_on_transfer_naive_credit_is_insolvent` |
| CX-REPL-001 | AND from marginals | target (0,0,0,1) | existing test plus Z3 |
| CX-FP-SETTLEMENT-001 | per-call settlement floor | supply 2, payout D-1, dust 2, holders 0. Same defect at decimals 6, 8, and 18 | `test_math1_probe.py`, `test_cumulative_settlement.py`, and `precision-boundary-6-8-18-2026-09-26.json` |
| Candidate self-split | not a dust-sweep counterexample | A receives 0, B receives 1, sum equals one-shot, residual 1 | `cumulative_settlement_attack.py` |

## INVARIANT_COVERAGE_MATRIX

| ID | Python | Foundry | Gap |
|---|---|---|---|
| P-I01 | `invariant_ids.py` via `test_invariants.py` | `test_P_I01_supplies_match_balances` | executable |
| P-I02 | `invariant_ids.py` via `test_invariants.py` | `test_P_I02_conservation_through_resolution_pending` and `invariant_preResolutionConservation` | executable. Issuance invariant does not walk redemption |
| P-I03 | `invariant_ids.py` via `test_invariants.py` | `test_P_I03_split_only_while_open_and_equal` | executable |
| P-I04 | `invariant_ids.py` via `test_invariants.py` | `test_P_I04_merge_while_locked_releases_equal_collateral` | executable |
| P-I05 | `invariant_ids.py` via `test_invariants.py`, including `cancel_draft` | `test_P_I05_spec_hash_is_immutable` and `test_P_I05_cancel_draft_archives_without_moving_collateral` | kernel `cancelDraft` measured. Collateral does not move. Other P-I05 branch unchanged |
| P-I06 | `invariant_ids.py` via `test_invariants.py` | `test_P_I06_one_result_from_pending_by_resolver` | executable |
| P-I07 | `invariant_ids.py` via `test_invariants.py` | `test_P_I07_redeem_only_redeemable_balance` | executable |
| P-I08 | `invariant_ids.py` via `test_invariants.py` | `test_P_I08_collateral_covers_liability` | executable |
| P-I09 | `invariant_ids.py` via `test_invariants.py` | `test_P_I09_no_admin_mint` | executable |
| P-I10 | `invariant_ids.py` via `test_invariants.py` | `test_P_I10_archive_only_at_zero_supply` | executable |
| Foundry issuance conservation | n/a | 256 runs, depth 500, default profile, seeds 20260926 and 20260927. 128000 calls each, reverts 47971 and 46395, 0 discards, invariant held | split, merge, closeMint, beginResolution. Those handlers do not call `cancelDraft`. Not redemption |
| R-I01 | `test_replication.py` `test_exact_component_is_replicable` and `test_known_and_is_not_replicable` | none | executable. INV-P01 |
| R-I02 | `test_invariant_ids.py` `test_r_i02_activated_weights_and_matrix_stay_fixed` | none on `PrismSeries` | executable. INV-P02. Previously prose only |
| R-I03 | `test_model.py` `test_exact_mint_then_redeem` | `CandidateComponentBacking.t.sol` `test_matches_python_fixtures` | executable. INV-P03 |
| R-I04 | `test_model.py` `test_overmint_rejected` | backing fixtures reject an underbacked mint | executable. INV-P04 |
| R-I05 | `test_model.py` `test_exact_mint_then_redeem` | requirement-delta redeem in the backing kernel | executable. INV-P05 |
| R-I06 | `test_model.py` `test_terminal_solvency_all_states` | none | executable. INV-P06 |
| R-I07 | `test_executable_gaps.py` `test_cross_series_double_allocation_is_rejected` | `test_reservation_matches_fixture` | executable. INV-P07 |
| R-I08 | `test_partial_resolution.py` `test_component_transform_preserves_remaining_states` | `CandidatePayoffTransform.t.sol` `test_matches_python_fixtures` | executable. INV-P08 |
| R-I09 | `test_settlement.py` `test_underfunded_cannot_become_redeemable` | `test_final_supply_is_not_redeemable_until_funded` | executable. INV-P09. Gate key `R-I08_resolved_not_redeemable` still names this test and was not renamed |
| R-I10 | exact model `test_exact_final_redemption`. Canonical per-call `test_per_call_rule_remains_the_counterexample`. Candidate `test_candidate_pays_the_original_case_without_replacing_the_oracle` | candidate differential fixtures | COUNTEREXAMPLE_FOUND on `FixedPointSettlement.redeem`. Candidate asserted. Canonical MATH-1 stays FAIL. INV-P10 |
| R-I11 | `test_lifecycle.py` `test_no_resurrection`; `test_invariant_ids.py` `test_r_i11_redeemable_and_archived_do_not_reopen` | none | executable. INV-P11. RESOLVED to ACTIVE was already tested. REDEEMABLE and ARCHIVED edges were not |
| R-I12 | `test_invariant_ids.py` `test_r_i12_final_resolution_is_committed_once` | none | executable. INV-P12. Previously prose only |
| X-I01..X-I07 | not modeled jointly | not built | BLOCKED |
| X-I01 | not built | not built | NOT_YET_VALIDATED. source interface not frozen |
| X-I02 | not built | not built | NOT_YET_VALIDATED. source interface not frozen |
| X-I03 | not built | not built | NOT_YET_VALIDATED. source interface not frozen |
| X-I04 | not built | not built | NOT_YET_VALIDATED. source interface not frozen |
| X-I05 | not built | not built | NOT_YET_VALIDATED. source interface not frozen |
| X-I06 | not built | not built | NOT_YET_VALIDATED. source interface not frozen |
| X-I07 | not built | not built | NOT_YET_VALIDATED. source interface not frozen |

R-I01..R-I12 are INV-P01..INV-P12 in `docs/prism/math/16_INVARIANTS.md`. This program does not renumber them. The gate key `R-I08_resolved_not_redeemable` remains the name of the funding-refusal test. That statement is INV-P09, so its coverage row is R-I09. No cross-module deposit harness was added.

## BENCHMARK_MATRIX

| Benchmark | Result | Evidence |
|---|---|---|
| Payoff 2/4 .. 16/16 | 0.0028s .. 0.0531s for 200 iterations | `research/benchmarks/README.md`. Not rerun |
| Replication solve 2/4, 4/4, 4/16, 8/16 | five local samples, medians 0.000084s, 0.000275s, 0.000553s, 0.013973s | `reference-model-timings-2026-09-26.json`. Not an SLO |
| Replication solve 16/16 | NOT_RUN | domain cap is 8 components |
| Prediction exhaustive max_unit 3 | 208 states, 522 transitions, five samples, median 0.084142s | earlier single run 0.086862s remains in `exhaustive_summary.json` |
| Foundry test gas | snapshot file | `.gas-snapshot` |
| Outcome token deployment | full pair 1068486; clone pair 789955 | `evidence/research/prediction/outcome-token-gas-2026-09-26.txt` |
| Percentiles | not reported | sample size too small |

## GAS_MATRIX

| Test | Gas in one snapshot | Note |
|---|---|---|
| test_split_matches_fixture | 312956 | whole test |
| test_merge_matches_fixture | 349076 | whole test |
| test_yes_redemption_matches_fixture | 659504 | whole test |
| test_invalid_cumulative_floor_matches_fixture | 1262455 | whole test |
| test_fee_on_transfer_split_reverts | 145431 | whole test |
| test_user_cannot_mint_outcome | 35804 | whole test |
| full OutcomeToken CREATE | 534243 | assembly gas() around CREATE, code deposit included |
| ERC-1167 clone CREATE | 41064 | 45-byte runtime |
| storage-clone initialize | 96264 | decimals 6 and 18 |
| candidate fund transfer | 25535 | assembly `gas()` around CALL. Supply 2, payout `10^18-1`, decimals 18, ceil funding 2 |
| candidate `makeRedeemable` | 35308 | same scenario |
| candidate first 1-unit redeem | 40041 | pays 0 |
| candidate second 1-unit redeem | 52188 | pays 1 |
| candidate fund + open + two redeems | 153072 | sum of those four CALL measurements |
| `test_fund_and_redeem_gas` | 472420 | whole-test forge snapshot, includes deployment |
| prediction market deploy | 2438030 | assembly `gas()` around CREATE. Includes two internal outcome tokens. One test, both paths |
| prediction `split(100)` | 206722 | assembly `gas()` around CALL. Decimals 18 |
| prediction `merge(40)` | 37041 | after that split |
| prediction `resolve` YES | 48909 | after unmetered `closeMint` and `beginResolution` |
| prediction redeem winner | 34979 | `redeemYes(60)` pays 60 |
| prediction redeem INVALID | 37779 | `redeemYes(5)` pays 2 |
| `test_prediction_operation_gas` | 6578687 | whole test, includes deployment. Prefer the CALL rows |

The six prediction rows above the CREATE rows, and `test_fund_and_redeem_gas`, are whole-test gas from `research/contract-kernels/.gas-snapshot`. The CREATE rows for a standalone outcome token are the assembly meter in `evidence/research/prediction/outcome-token-gas-2026-09-26.txt`. The prediction CALL rows are `evidence/research/prediction/operation-gas-2026-09-26.txt`. The candidate CALL rows are the assembly meter in `evidence/research/prism/candidate-settlement-gas-2026-09-26.txt`.

## SECURITY_COVERAGE_MATRIX

| Tool | Result |
|---|---|
| forge test | Foundry 1.8.3; coverage run was 59 tests, exit 0 |
| forge fuzz | coverage command used 64 runs |
| forge invariant | coverage command: 256 runs, depth 500, 128000 calls, 47348 reverts |
| forge coverage | PredictionMarket lines 100.00% (119/119), branches 94.44% (34/36). Fuzz runs 64. Invariant runs 256. `kernel-coverage-fuzz64-2026-09-26.txt` |
| slither 0.11.6 complete IR | BLOCKED_TOOL. Fresh Foundry run at 0636686, exit 255, `_redeem` has no IR. `slither-sp16-2026-09-26.json`. `OutcomeToken.burn` is the call those functions reach. `slither-burn-lookup-2026-09-26.json`. The quote does not give `_redeem` IR. Legacy JSON logs remain `slither-legacy-ast-2026-09-26.txt` and `slither-solc-legacy-2026-09-26.txt`. S-P16 stays open |
| forge inspect ir-optimized | compiler_sees_redeem_analyzer_does_not. Default profile, forge 1.8.3, exit 0. Output contains `_redeem` and `burn`. `compiler-redeem-ir-2026-09-26.json`. Not Slither IR. S-P16 stays open. Not PRED-CONTRACT-1 |
| slither foundry target | BLOCKED_TOOL. `slither src/prediction/PredictionMarket.sol --foundry-compile-all --exclude-dependencies --filter-paths openzeppelin-contracts`, exit 255. `_redeem` has no IR. `Function not found burn`. `slither-foundry-target-2026-09-26.json`. Project-wide run remains blocked_tool. S-P16 stays open |
| `CloneableOutcomeToken.initialize(address(0))` | recorded_finding. Stores market `address(0)`. `_initialized` becomes true. `totalSupply` stays 0. Python has no counterpart. No payout. ADR-P14 PROPOSED. Acceptance not granted. `zero-address-initialize-2026-09-26.json` |
| solhint 5.2.0 | exit 0, 42 warnings, 0 errors. `solhint-2026-09-26.txt`. Style and import-path warnings. Not PRED-CONTRACT-1 |
| echidna, medusa, halmos, mythril, semgrep | BLOCKED_TOOL |

## KURU_COMPATIBILITY_MATRIX

| Check | Status | Evidence |
|---|---|---|
| ERC-20 type-0 market shape | documented | Kuru router page, 2026-09-26 |
| Decimals must be 18 | not established | deployer example uses 18 for its own token; router reads token decimals |
| Deployment equals liquidity | false in the docs | deploy-market page separates vault deposit |
| Live RetroPick market | BLOCKED | no router bytecode, no accepted router, no fork, no tx |
| Second primary-source pass | BLOCKED | router, SDK, OrderBook, vault, fees, addresses, Monad Flow. `source-pass-2026-09-26.json` |
| `calculatePrecisions` examples | MEASURED_LOCAL | Node 22.14.0 and ethers 5.7.1. Not RetroPick policy |
| Kuru orderbook liquidity as backing or redemption value | absent | No kernel or Python model reads it. PRED-KURU-1 stays blocked. `kuru-backing-claim-2026-09-26.json` |

## CROSS_MODULE_DEPENDENCY_MATRIX

| Edge | Status |
|---|---|
| Prediction outcome ERC-20 -> PRISM backing | not wired. ADR-R04 says plain ERC-20 after prediction qualification |
| PRISM settlement -> prediction resolution | source resolution is not PRISM funding. Settlement rule itself FAILs |
| Either module -> Kuru | secondary only. Not required for redemption |
| Either module -> Launchpad token | forbidden. Launcher token was not reused |
| SOURCE-ASSET INTERFACE FREEZE | proposed_not_frozen. Comparison is recorded_gap. Interface was not frozen. X-I01..X-I07 not tested. `source-interface-comparison-2026-09-26.json` |
| `CandidateComponentBacking.deposit` component walk | bounded_by_constructor. componentCount 2. backingRaw 0,0 then 1,1. Index 2 is not readable. `deposit-component-count-2026-09-26.json` |
| Unredeemed `yesRedeemed` and `noRedeemed` | existing_rule. Before redeem, cursors 0 and 0 and liability equals locked 4. After redeemYes(1), 1, 0, 3, 3. S-P16 stays open. `unredeemed-liability-2026-09-26.json` |

## PROMOTION_GATE_MATRIX

| Gate | Status |
|---|---|
| PRED-CONTRACT-1 | NOT PASS |
| PRISM MATH-1 | FAIL |
| MATH-1E | partial_z3_sympy. R-THEOREM-1, R-THEOREM-5, R-THEOREM-6, T-PARTIAL-002, T-FP-001 through T-FP-004, T-BS-001 through T-BS-003, T-NATIVE-001 through T-NATIVE-002, T-LC-001, T-LC-002, and T-PARTIAL-001 discharged. Precision boundary 6/8/18 matches the Solidity candidate on 129 uint256-fitting cumulative cells. Zero-supply settlement dust sits; sweep policy NOT_YET_VALIDATED. Candidate settlement, backing, reservation, and payoff-transform invariants: 256 runs, depth 128, two seeds, 0 reverts. Not MATH-1 PASS. Canonical per-call settlement floor still fails |
| MATH-1D candidate cumulative floor | PROVEN_UNDER_ASSUMPTIONS; ready for ADR acceptance; Solidity `differential_research_kernel` |
| MATH-1B | bounded grids only. Supply-16 compositions and the backing grid are inside the note. Not a universal proof |
| PRISM CONTRACT-ARCH-1 | proposed |
| PRISM CONTRACT-1 | not_met |
| backing_kernel_solidity | differential_research_kernel |
| partial_resolution_transform | differential_research_kernel |
| minimum_cost_replication | exhaustively_verified_within_domain. Not Kuru. Not solvency |
| storage_slot_isolation | inferred. ADR-R06 stays PROPOSED |
| R-I08 resolved supply is not redeemable | measured. Gate key unchanged. Coverage row is R-I09 / INV-P09 |
| R-I02 immutable replication | measured. `test_r_i02_activated_weights_and_matrix_stay_fixed` |
| R-I12 resolution once | measured. `test_r_i12_final_resolution_is_committed_once` |
| X-I01..X-I07 | not_yet_validated. source interface not frozen. `source-interface-comparison-2026-09-26.json` |
| Unreachable `Underfunded` / `LiveLiability` | PROVEN_UNDER_ASSUMPTIONS |
| benchmarks_measured | local_single_environment. Not admission |
| static_analysis | measured_with_findings. Slither IR still incomplete. Not PRED-CONTRACT-1 |
| slither_complete_ir | blocked_tool |
| S-P16 redeemed cursor | open analyzer gap. Fresh run 0636686 still has no IR for `_redeem`. Inspection PROVEN_UNDER_ASSUMPTIONS. Not closed |
| reproducibility_local | rerun_pass at 0f14c30. Python 3.12.3, forge 1.8.3. Prediction 15 OK, PRISM 109 OK, Foundry 76 passed, 0 failed, 1 skipped. The skip is the supply 0..16 walk. This command did not re-execute that domain. Existing interpreter and existing Foundry install. Not a clean clone or a fresh virtualenv |
| MODULE-ADMISSION-FINANCE-1 | not met |
| Move into `contracts/src/v2` | not done |
| Mainnet | not authorized |

## OPEN_RISK_REGISTER

| Risk | Severity | Disposition |
|---|---|---|
| Resolver can report a false YES/NO/INVALID | High trust assumption | accepted for this kernel, blocks trustless claims |
| PRISM per-call settlement dust capture | High accounting defect | MATH-1D FAIL. Candidate kernel matches the Python fixtures. Not an oracle pass |
| Slither IR incomplete | Medium evidence gap | PRED-CONTRACT-1 not PASS |
| Kuru parameters unknown | Medium | BLOCKED. Worksheet does not guess them |
| Prediction `cancelDraft` | Low | DRAFT to ARCHIVED measured. Collateral does not move. Not PRED-CONTRACT-1 PASS |
| CompleteSetVault diagram versus kernel | process risk | ADR-P03 proposed, diagram not silently edited |
| `native_market.py` lifecycle is narrower than canonical | spec drift | recorded_contradiction, open. ADR-P10 PROPOSED. Acceptance not granted. Native redeem pays 1 inside RESOLVED. Prediction redeem rejects before REDEEMABLE and leaves collateral at 4. Neither redeem was edited. `resolved-redeem-contradiction-2026-09-26.json` |
| False-return collateral | admission gap | recorded_contradiction, open. ADR-P08 PROPOSED, acceptance not granted. Python rejects FALSE_RETURN at construction. Solidity split reverts SafeERC20FailedOperation after activation. Supplies stay 0. `false-return-collateral-2026-09-26.json` |
| Rebasing collateral | accounting gap | COUNTEREXAMPLE_FOUND. ADR-P06 and ADR-P09 stay PROPOSED. Acceptance not granted. Python rejects REBASING at construction. Test-only rebaseDown leaves balance 99 against liability 100. Locked, YES, and NO stay 100. `rebasing-collateral-2026-09-26.json` |
| Rebasing component backing | accounting gap | COUNTEREXAMPLE_FOUND. ADR-R08 PROPOSED. Acceptance not granted. After deposit 100 and mint 100, rebaseDown of 1 leaves token balance 99, backingRaw 100, requiredRaw 100, supply 100. `rebasing-component-backing-2026-09-26.json` |
| Fee-on-transfer component deposit | accounting | existing_rule. `Shortfall` when delivery is 9 of 10. Token balance, backingRaw, requiredRaw, and supply stay 0. `fee-on-transfer-component-backing-2026-09-26.json` |
| Duplicate component token | accounting | existing_rule. Same ERC-20 in both slots. backingRaw 10 and 10 against token balance 20. `mint(11)` reverts `InsufficientBacking`. `duplicate-component-backing-2026-09-26.json` |
| Zero component weight | accounting | existing_rule. Constructor accepts weight 0. Required 0 and 4. Backing 0 and 4. Supply 4. `zero-weight-component-backing-2026-09-26.json` |
| Fee-on-transfer settlement funding | accounting | existing_rule. `Underfunded`. Transfer of ceil 2 delivers 1. Token balance 1. `redeemable` stays false and `paidRaw` stays 0. `fee-on-transfer-settlement-funding-2026-09-26.json` |
| Post-redeemable settlement rebase | accounting | existing_rule. After funding 2 and `makeRedeemable`, rebaseDown of 1 leaves balance 1. `redeem(2)` pays 1. `paidRaw` becomes 1 and the balance becomes 0. `rebasing-settlement-funding-2026-09-26.json` |
| Settlement balance below the floor | accounting | existing_rule for the `PayoutExceedsBalance` revert. ADR-R09 PROPOSED. Acceptance not granted. rebaseDown of 2 leaves balance 0 below floor 1. `redeemable` stays true. `paidRaw` stays 0. `deep-rebasing-settlement-funding-2026-09-26.json` |
| Split callback during transferFrom | reentrancy | existing_guard. `nonReentrant` reverts `ReentrancyGuardReentrantCall`. Locked, YES, NO, and token balance stay 0. `split-callback-2026-09-26.json` |
| Withdrawal while supply is outstanding | custody | existing_rule. Factory, resolver, and an arbitrary caller cannot extract live collateral. Merge and redeem burn first. `live-collateral-withdrawal-2026-09-26.json` |
| Same YES balance redeemed twice | payout | existing_rule. After YES_WIN and open redemption, redeem of YES 4 pays 4 once. The second call reverts and collateral stays 0. `double-yes-redeem-2026-09-26.json` |
| Second result after YES_WIN | resolution | existing_rule. A later NO_WIN reverts. Numerators stay 2 and 0. Collateral, YES, and NO stay 4. `second-yes-resolution-2026-09-26.json` |
| Unequal YES and NO merge | accounting | existing_rule. OPEN market. Holder YES 1 and NO 4. `merge(4)` reverts. Collateral, YES, and NO stay 4. `unequal-merge-2026-09-26.json` |
| Split at the uint256 boundary | accounting | recorded_contradiction, open. ADR-P11 PROPOSED. Acceptance not granted. Solidity `split(uint256 max)` leaves collateral, YES, and NO at `2**256-1`. `split(1)` reverts `Panic(0x11)` and those figures stay put. Python `split(1)` raises the three figures to `2**256`. Split was not edited. `uint256-split-2026-09-26.json` |
| Split of 2**256 | accounting | existing_rule. After split 10, Python raises `amount exceeds configured maximum` and collateral, YES, and NO stay 10. Solidity cannot encode the argument, so the second split is not called and those figures stay 10. `split-max-2026-09-26.json` |
| Split one past 1000000000 | accounting | recorded_contradiction, open. ADR-P12 PROPOSED. Acceptance not granted. Python rejects `split(1000000001)` and leaves collateral, YES, and NO at 0. Solidity mints and those figures become 1000000001. `configured-split-maximum-2026-09-26.json` |
| INVALID burn of NO after YES dust | accounting | existing_rule. Collateral 3, YES 0, NO 5. Python raises `side is not worthless`. Solidity reverts `NotWorthless`. `invalid-burn-rejected-2026-09-26.json` |
| Second activate while OPEN | lifecycle | existing_rule. Python raises `activate only from DRAFT`. Solidity reverts `BadState`. Collateral, YES, and NO stay 0. State stays OPEN. `repeat-activate-2026-09-26.json` |
| Split of 1 while DRAFT | lifecycle | existing_rule. Python raises `split only while OPEN`. Solidity reverts `BadState`. Collateral, YES, and NO stay 0. State stays DRAFT. `draft-split-2026-09-26.json` |
| Rejection inventory, 72 calls | lifecycle | 71 rows existing_rule. `archive` from DRAFT is recorded_contradiction. ADR-P13 PROPOSED. Acceptance not granted. Python state becomes ARCHIVED and raises `P-I05`. Solidity reverts `BadState` and stays DRAFT. Collateral, YES, and NO stay 0. `rejection-inventory-2026-09-26.json` |
| Clone cheaper, identity not independent | Medium | measured; kernel stays on full ERC-20; ADR-P01 PROPOSED |
| Monad parallel-execution benefit | unmeasured | ADR-R06 is a hypothesis |
| Two markets or two series sharing split/mint slots | INFERRED absent for these kernels | `docs/prism/04-architecture/STORAGE_ISOLATION.md`. Not a throughput measurement |
| PredictionMarket branch coverage 94.44% (34/36) | Medium testing gap | Open. The two unexecuted branches are PROVEN_UNDER_ASSUMPTIONS unreachable. Coverage was not re-run and is not 100%. `unreachable-branches-2026-09-26.json` |
