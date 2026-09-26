# Qualification matrices

Every row points at evidence from this program. Status words are the program's classifications, not marketing.

## PREDICTION_REQUIREMENT_MATRIX

| Requirement | Status | Evidence |
|---|---|---|
| 1 collateral splits into 1 YES + 1 NO | PROVEN for the zero-fee model | `research/prediction-model/theorems.py` P-THEOREM-1, fixture `prediction_split` |
| Merge is the inverse before resolution | PROVEN | P-THEOREM-2, fixture `prediction_merge` |
| YES_WIN / NO_WIN payouts | PROVEN on the integer path | P-THEOREM-4, Foundry `test_yes_redemption_matches_fixture` |
| INVALID not automatic | RECOMMENDATION plus explicit enum | ADR-P05, Polymarket resolution page retrieved 2026-09-26 |
| Cumulative INVALID floor | PROVEN on tested amounts; half-up is a counterexample | `docs/prediction/07_ROUNDING.md` |
| Separate RESOLVED and REDEEMABLE | implemented in kernel | `test_yes_redemption_matches_fixture` expects revert before open |
| No admin mint | tested | `test_user_cannot_mint_outcome` |
| Standard collateral only | tested for fee-on-transfer | `test_fee_on_transfer_split_reverts` |
| Kuru listing | BLOCKED | `research/integration/kuru/KURU_TOKEN_COMPATIBILITY.md` |
| PRED-CONTRACT-1 PASS | not met | `docs/prediction/13_PRED_GATE.md` |

## PRISM_REQUIREMENT_MATRIX

| Requirement | Status | Evidence |
|---|---|---|
| `h=Gx`, `x>=0` | REPRODUCED | existing replication tests; ADR-002 |
| AND is not replicated by A, B, and 1 | COUNTEREXAMPLE_FOUND | `math1_probe.py` Z3 and solver |
| Backing before mint | REPRODUCED | `test_model.py` |
| Component requirement delta round trip | PROVEN by construction; 200 samples, 0 mismatches | `math1_probe.component_round_trip_samples` |
| Per-call settlement floor | COUNTEREXAMPLE_FOUND | `CX-FP-SETTLEMENT-001` |
| MATH-1 PASS | FAIL | `research/prism/reports/PRISM_REPRODUCTION_REPORT.md` |
| PRISM Solidity | not written | `research/contract-kernels/README.md`, ADR-R07 |

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
| P-THEOREM-7 | PROVEN | supplies differ after burn, liability holds |
| T-FP-003 funding guard | PROVEN_UNDER_ASSUMPTIONS for funding only | addendum in `docs/prism/math/17_THEOREMS.md` |
| CX-FP-SETTLEMENT-001 | COUNTEREXAMPLE_FOUND | probe JSON |
| T-FP-CUM-001 | PROVEN_UNDER_ASSUMPTIONS | integer ceil/floor identity; 240-case grid |
| Z3 two-component solvency | PROVEN_UNDER_ASSUMPTIONS | Z3 5.1.0 unsat |
| Market demand hypotheses | NOT_YET_VALIDATED | unchanged |

## COUNTEREXAMPLE_MATRIX

| ID | What fails | Minimal case | Evidence |
|---|---|---|---|
| CX-PRED-HALF-UP | both sides ceil(q/2) | q=1 pays 2 | `complete_set.naive_half_up` |
| CX-PRED-FRAGMENT | per-call floor(q/2) | 1-unit stream pays 0 | `fixed_point.fragmentation_gap` |
| CX-PRED-FEE-NAIVE | credit nominal amount | received 90, credit 100 | `theorems.fee_on_transfer_naive_credit_is_insolvent` |
| CX-REPL-001 | AND from marginals | target (0,0,0,1) | existing test plus Z3 |
| CX-FP-SETTLEMENT-001 | per-call settlement floor | supply 2, payout 1e18-1, dust 2, holders 0 | `test_math1_probe.py` |

## INVARIANT_COVERAGE_MATRIX

| ID | Python | Foundry | Gap |
|---|---|---|---|
| P-I01..P-I10 | `invariants.check_market` | partial | resolution not inside the issuance invariant |
| Foundry issuance conservation | n/a | 256 runs, 128000 calls, 0 reverts | split/merge only |
| R-I01..R-I12 | existing PRISM oracle for the subset already modeled | none | settlement fairness fails R-style holder payment even though funding holds |
| X-I01..X-I07 | not modeled jointly | not built | BLOCKED |

R-I01..R-I12 in the task sense are the PRISM backing, admission, lifecycle, and settlement invariants already numbered INV-P01.. in `docs/prism/math/16_INVARIANTS.md`. This program does not renumber them. Cross-module X-invariants are not claimed.

## BENCHMARK_MATRIX

| Benchmark | Result | Evidence |
|---|---|---|
| Payoff 2/4 .. 16/16 | 0.0028s .. 0.0531s for 200 iterations | `research/benchmarks/README.md` |
| Prediction exhaustive max_unit 3 | 208 states, 0 failures, 0.087s | `outputs/exhaustive_summary.json` |
| Foundry test gas | snapshot file | `.gas-snapshot` |
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

Source: `research/contract-kernels/.gas-snapshot`. Isolated function gas was not traced.

## SECURITY_COVERAGE_MATRIX

| Tool | Result |
|---|---|
| forge test | 10 passed, Foundry 1.8.3 |
| forge fuzz | 256 runs, two tests |
| forge invariant | 256 runs, depth 500, 0 reverts |
| forge coverage | not run |
| slither 0.11.6 | exit 255, IR incomplete, detectors listed in `docs/prediction/10_SECURITY.md` |
| echidna, medusa, halmos, mythril, semgrep, solhint | BLOCKED_TOOL |

## KURU_COMPATIBILITY_MATRIX

| Check | Status | Evidence |
|---|---|---|
| ERC-20 type-0 market shape | documented | Kuru router page, 2026-09-26 |
| Decimals must be 18 | not established | deployer example uses 18 for its own token; router reads token decimals |
| Deployment equals liquidity | false in the docs | deploy-market page separates vault deposit |
| Live RetroPick market | BLOCKED | no router address accepted, no tx |

## CROSS_MODULE_DEPENDENCY_MATRIX

| Edge | Status |
|---|---|
| Prediction outcome ERC-20 -> PRISM backing | not wired. ADR-R04 says plain ERC-20 after prediction qualification |
| PRISM settlement -> prediction resolution | source resolution is not PRISM funding. Settlement rule itself FAILs |
| Either module -> Kuru | secondary only. Not required for redemption |
| Either module -> Launchpad token | forbidden. Launcher token was not reused |
| SOURCE-ASSET INTERFACE FREEZE | not frozen. PRED-CONTRACT-ARCH-1 is proposed, not accepted |

## PROMOTION_GATE_MATRIX

| Gate | Status |
|---|---|
| PRED-CONTRACT-1 | NOT PASS |
| PRISM MATH-1 | FAIL |
| PRISM CONTRACT-1 | not started |
| MODULE-ADMISSION-FINANCE-1 | not met |
| Move into `contracts/src/v2` | not done |
| Mainnet | not authorized |

## OPEN_RISK_REGISTER

| Risk | Severity | Disposition |
|---|---|---|
| Resolver can report a false YES/NO/INVALID | High trust assumption | accepted for this kernel, blocks trustless claims |
| PRISM per-call settlement dust capture | High accounting defect | MATH-1D FAIL, no Solidity |
| Slither IR incomplete | Medium evidence gap | PRED-CONTRACT-1 not PASS |
| Kuru parameters unknown | Medium | BLOCKED |
| CompleteSetVault diagram versus kernel | process risk | ADR-P03 proposed, diagram not silently edited |
| `native_market.py` lifecycle is narrower than canonical | spec drift | recorded, new model does not pretend otherwise |
| Clone gas unknown | Low | schema A chosen without a gas horse-race |
| Monad parallel-execution benefit | unmeasured | ADR-R06 is a hypothesis |
