# Financial module promotion verdict

Human acceptance was not granted. Nothing in `contracts/src/v2/` was added or moved. `MODULE-ADMISSION-FINANCE-1` is not met. That gate would only mean "ready to request promotion into the V2 source tree." It would not mean mainnet-ready or legally approved. The technical conditions are not met.

## REPOSITORY BASELINE

`main` at `73d5f1e72b65cc5cdad0d940782c192aa331f5ed` matched `origin/main`. Working tree was clean. Record: `research/reports/DUAL_RESEARCH_BASELINE.md`.

## RESEARCH EXECUTED

Prediction integer and exact models, exhaustive search, adversarial rejections, PRISM suite reproduction, Z3 and SymPy checks, settlement counterexample, Kuru documentation read, Foundry kernel tests. Market-demand hypotheses were not promoted.

## PREDICTION TOKEN SCHEMA

Proposed: two full ERC-20s, decimals copied from collateral, `market()` and `outcomeIndex()` only, no owner mint. ADR-P01, ADR-P02. ERC-1167 deployment gas was measured and the kernel was not switched to clones.

## PREDICTION MARKET ARCHITECTURE

Proposed: the market contract is the collateral controller. ADR-P03. Canonical CompleteSetVault diagram left in place.

## PREDICTION PROOFS

P-THEOREM-1 through P-THEOREM-5 and P-THEOREM-7: PROVEN for the qualified model on the tests that call them. P-THEOREM-6 qualified cumulative floor: PROVEN on those tests. Half-up and per-call floor: COUNTEREXAMPLE_FOUND. Exhaustive domain `max_unit=3`: 208 states, 0 failures. This is not a universal uint256 proof.

## PRISM MODEL

Existing oracle re-ran. 55 tests on the baseline commit, 60 after the new probe tests. Adversarial JSON from 2026-09-17 reproduced. AND counterexample reproduced.

## PRISM MATH-1

**FAIL.** MATH-1D per-call settlement floor is the blocking counterexample `CX-FP-SETTLEMENT-001` (holders paid 0, sweepable dust 2, one-shot floor would have paid 1). `FixedPointSettlement.redeem` was not edited. Component requirement-delta round trip did not show extraction. Exact-fraction solvency tests did not fail. Market hypotheses stay NOT_YET_VALIDATED.

PR #3 is merged on `origin/main` at `cd457f8` and includes this branch through `dd7bfb5`. Later commits on `cursor/finance-qualification-bbd4` are the follow-on. Main was not merged into this branch.

The strings R-THEOREM-1 through R-THEOREM-6 are not in the canonical docs. They are recorded here as the first six rows of `docs/prism/math/17_THEOREMS.md`: T-REPL-001, T-BS-001, T-BS-002, T-BS-003, T-BS-004, and T-ALLOC-001. R-THEOREM-4 already has a two-component Z3 and SymPy check in `math1_probe.py`. R-THEOREM-2 and R-THEOREM-3 have the bounded mint/redeem grid. R-THEOREM-5 and R-THEOREM-6 are prose plus numeric oracles. The lowest unchecked claim was R-THEOREM-1. SymPy 1.14.0 expands `Gx` minus the state-wise sum to the zero polynomial for every shape with 1..4 states and 1..4 components. `replication.payoff` on the reference weights (3/5, 2/5) returns (2/5, 0, 1, 3/5), matching that product. Classification: **PROVEN_UNDER_ASSUMPTIONS**. No counterexample. Runtime 0.020301 seconds. Non-negativity is not required for the equality. Canonical MATH-1 stays FAIL. Log: `evidence/research/prism/r-theorem-1-2026-09-26.json`.

R-THEOREM-5 is the fifth row, `T-BS-004`: funded final redemption preserves remaining settlement funding when the redemption pays exactly `QR`. It is not the reservation theorem. SymPy 1.14.0 reduces `C - QR - (S - Q)R` to `C - SR`. Z3 5.1.0 reports the negation unsat under `C >= SR` and `0 <= Q <= S`. Paying more than `QR` can break the inequality; that is the negative control for this statement. The canonical per-call rule on supply 2, payout `10^18-1`, still pays 0 rather than 1, and the remaining balance 2 still covers the remaining required 0. That witness does not falsify `T-BS-004`. Classification: **PROVEN_UNDER_ASSUMPTIONS**. No counterexample. Runtime 0.025699 seconds. Log: `evidence/research/prism/r-theorem-5-2026-09-26.json`.

R-THEOREM-6 is the sixth row, `T-ALLOC-001`: `sum_s Reserved[s,a] <= PhysicalBalance[a]` is preserved by deposit, reserve, release, and withdraw. Z3 5.1.0 reports the negation unsat for each accepted transition when the acting series and the other-series total are nonnegative and the invariant holds beforehand. Two reservations of 60 and 25 against balance 100 succeed and leave available 15. The negative control reserves 60 and then 50 against balance 100. `ReservationLedger` rejects that second call and leaves balance, total reserved, available, and both series buckets unchanged. Double use is rejected. Classification: **PROVEN_UNDER_ASSUMPTIONS**. No counterexample. Runtime 0.009577 seconds. Canonical MATH-1 stays FAIL because the per-call settlement floor still fails. Log: `evidence/research/prism/r-theorem-6-2026-09-26.json`.

T-PARTIAL-002 is the partial-resolution row: after component `i` is replaced by cash `B_i*r_i`, backing value is unchanged on every remaining state `g_i(omega)=r_i`. SymPy 1.14.0 expands the post-transform gap to `B_i*(r_i-g_i)` for every component index in shapes of 1..4 components, and that gap is zero when `g_i=r_i`. Z3 5.1.0 reports unsat for the negation of the biconditional: on one state the old and new backing values are equal if and only if `B_i*g_i` equals the cash credit `B_i*r_i`. The same solver reports unsat for unequal values on a remaining state. `prospective_transform` on the existing series, component 1 paying 1, adds cash 400 and `portfolio_preserves` accepts states 0 and 2. State 1 is outside that set and is not preserved. `mismatched_portfolio` is not equivalent. Classification: **PROVEN_UNDER_ASSUMPTIONS**. No counterexample. Runtime 0.028305 seconds. `partial_resolution.py` was not modified. Canonical MATH-1 stays FAIL because the per-call settlement floor still fails. Log: `evidence/research/prism/t-partial-002-2026-09-26.json`.

T-FP-001 says a ceil total-supply component requirement prevents integer mint underreservation. It does not say the per-call settlement floor is fair. Z3 5.1.0 reports unsat for `ceil(n/d)*d < n` when `n >= 0` and `d > 0`, and unsat for raw backing at least that ceil whose normalized amount is below `S*x_i/WAD`. On supply 1, weight 1, and 18 decimals, the floor raw amount is 0 and `0 < 1`; the ceil raw amount is 1 and covers that numerator. `FixedPointSeries.mint(1)` with backing (1, 0) raises and leaves supply 0 and backing (1, 0). Backing (1, 1) mints supply 1 and equals `required_backing_raw()`. Classification: **PROVEN_UNDER_ASSUMPTIONS**. No counterexample. Runtime 0.013474 seconds. This does not pass MATH-1, because the canonical per-call settlement floor still fails. Log: `evidence/research/prism/t-fp-001-2026-09-26.json`.

T-FP-002 says a requirement-delta redemption cannot leave remaining supply below the conservative raw requirement. The oracle is `FixedPointSeries.redeem`, not `FixedPointSettlement.redeem`. Release is `Req(S)-Req(S-Q)`. SymPy 1.14.0 shows the remaining margin equals the margin before that release, so backing that started at least `Req(S)` stays at least `Req(S-Q)`. Z3 5.1.0 reports the negation unsat for `0 <= Q <= S` and the ceil quotient. On weights `WAD/2`, 18 decimals, supply 5, and redeem 2, the requirement moves from 3 to 2, the release is 1, and remaining backing is 2. Classification: **PROVEN_UNDER_ASSUMPTIONS**. No counterexample. Runtime 0.022174 seconds. This does not pass MATH-1, because the canonical per-call settlement floor still fails. Log: `evidence/research/prism/t-fp-002-2026-09-26.json`.

T-FP-003 says the conservative settlement requirement plus a guarded floor redemption preserves funding. The oracle is `FixedPointSettlement`. The payout is `floor(Q*R/(WAD*f))`, and an accepted call must leave the balance at least `ceil((S-Q)*R/(WAD*f))`. Z3 5.1.0 reports unsat for a funded book whose floor payout drops the balance below that remaining ceil. The supply-2 witness with payout `10^18-1` and decimals 18 still pays 0 then 0, while the one-shot floor is 1 and sweepable dust is 2. That is `CX-FP-SETTLEMENT-001`. It does not falsify the funding claim: after the first redemption the balance is 2 and the remaining requirement is 1. A separate call with balance 1, payout `10^18`, and supply 2 is rejected and leaves the book unchanged. Classification of the funding statement: **PROVEN_UNDER_ASSUMPTIONS**. No funding counterexample. Runtime 0.017595 seconds. The canonical per-call floor is not PASS. MATH-1 stays FAIL. Log: `evidence/research/prism/t-fp-003-2026-09-26.json`.

T-FP-004 says a minimum-backing mint followed by the inverse requirement-delta redemption has zero net component extraction. The mint deposits `Req(S+Q)-Req(S)`. Redeeming that same quantity releases the same delta. SymPy 1.14.0 reduces the two deltas to the same expression. Z3 5.1.0 reports unsat for a ceil cycle that releases a different amount, deposits a negative amount, or changes raw backing. On weights `WAD/2` and 18 decimals, mint 5 then redeem 5 deposits and releases 3 and 3. Supply and backing return to 0. A prior surplus of 1 and 1 remains after the same cycle. Classification: **PROVEN_UNDER_ASSUMPTIONS**. No counterexample. Runtime 0.034207 seconds. This is not the per-call settlement floor. That underpayment is still `CX-FP-SETTLEMENT-001`. MATH-1 stays FAIL. Log: `evidence/research/prism/t-fp-004-2026-09-26.json`.

T-BS-001 says an exact-backed mint preserves component backing and margin. For `Q>0`, `S'=S+Q` and `B'=B+Qx`. SymPy 1.14.0 reduces the new margin to the old margin. Z3 5.1.0 reports unsat for a positive mint that starts backed and ends below `S'x`. `PrismSeries.mint_with_exact_backing(1000)` on weights 3/5 and 2/5 ends at backing 600 and 400 with margin 0 and 0. Depositing a surplus of 1 and 0, then minting 5, leaves that margin unchanged. Classification: **PROVEN_UNDER_ASSUMPTIONS**. No counterexample. Runtime 0.022542 seconds. The earlier bounded grid is not this identity. Canonical MATH-1 stays FAIL because the per-call settlement floor still fails. Log: `evidence/research/prism/t-bs-001-2026-09-26.json`.

## Candidate cumulative settlement

This is not an oracle replacement and it is not MATH-1 PASS.

`CumulativeFloorSettlement` keeps one global redeemed cursor. For any partition of a fixed supply the payouts sum to `floor(supply * payout / D)`. Against exact ceil funding the residual is 0 or 1. A single redemption pays `floor(q * payout / D)` or one more.

That bound is **PROVEN_UNDER_ASSUMPTIONS** for exact non-negative integer division, no mint on this candidate, a starting balance at or above ceil funding, and redemption of the whole supply. The Python candidate matched the bound on the searched domain: **EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN**. The search visited 378530 states and 2542061 transitions in 2.973316 seconds. No new counterexample was found.

A later walk extended only the composition axis from supply 12 to supply 16 on 18 decimals. Parts were assigned all to holder A and alternating between A and B. The original supply-2 payout `10^18-1` orders pay 1 and leave residual 1. The supply-3 fairness order A, B, A at payout `10^18/2+1` pays 1, equal to the one-shot floor, and leaves residual 1. No partition paid more than that floor. Counts: 917612 states, 7340046 transitions, 8.02598 seconds. Classification on that grid: **EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN**. Canonical MATH-1 and MATH-1D stay FAIL. The payout formula was not changed. Log: `evidence/research/prism/cumulative-floor-supply16-2026-09-26.json`.

`PrismSeries` mint and in-kind redeem were enumerated for two components with weights {0, 1/2, 1}, which is {0, 1, 2}/2. Supplies and quantities each run through 0..8. Every accepted transition still has `B_i >= S * x_i`. Every rejected transition leaves supply and backing unchanged. Counts: 81 states, 2187 transitions, 1044 accepted, 1143 rejected, 0.054409 seconds. Classification: **EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN**. This is not a new backing rule and not a universal proof. Log: `evidence/research/prism/backing-domain-2026-09-26.json`.

The original case pays 1 and leaves residual 1. Both holder orders do that. A per-holder cursor on the same case pays 0. That negative control is not the candidate.

A holder who splits a balance can receive less than their isolated floor. Recorded example: payout `10^18/2 + 1`, supply 3, order A then B then A. A receives 0 and B receives 1. The sum is still the one-shot floor and the ceil-funded residual is 1. The unit moves to the other holder. It is not swept. Single-call redemptions in the search had shortfall 0 and surplus at most 1.

The candidate has no mint. A shared global cursor charged on mint and refunded on redeem had 0 mismatches in 1920 samples. Per-call floor mint of the original two units, followed by a one-shot redeem, extracts 1 raw unit. That extraction belongs to the per-call rule.

The candidate rule is ready for a human to accept or reject under ADR-R03. Canonical MATH-1 and MATH-1D stay FAIL until that acceptance.

`research/contract-kernels/src/prism/CandidateCumulativeSettlement.sol` is a research kernel of that candidate. Foundry differential tests matched the Python integers. Classification: `differential_research_kernel`. This is not MATH-1 PASS, not CONTRACT-1, and not a v2 promotion.

`research/contract-kernels/src/prism/CandidateComponentBacking.sol` is a separate research kernel of `FixedPointSeries.deposit_raw`, `mint`, and requirement-delta `redeem`. It is not `FixedPointSettlement.redeem` and it is not the cumulative candidate. Foundry matched the Python fixtures. A 2-unit redeem from supply 5 releases raw amounts 1 and 0, not the naive per-call ceils 2 and 1. Deposit 3 and 1 then mint 5 stays backed. Deposit 2 and 1 rejects mint 5 with supply still 0. Redeem 6 against balance 5 is rejected and the state stays at supply 5. The existing exact-model examples agree on this encoding: surplus mint of 1000 against 700 and 500 leaves margin 100 and 100; overmint against 599 and 400 is rejected; redeeming 250 from supply 1000 releases 150 and 100 and leaves supply 750. `CandidateReservationLedger` deposits 100, reserves 60, rejects a second series asking for 50, then accepts 40. Reserved is 100 and available is 0. Classification: `backing_kernel_solidity: differential_research_kernel`. No integer mismatch, so no COUNTEREXAMPLE_FOUND. CONTRACT-1 stays not_met. MATH-1 stays FAIL.

`research/prism-model/partial_resolution.py` checks that old and new backing values match on every remaining feasible terminal state, weights stay non-negative, and supply stays unchanged. A payout with no remaining state is rejected. A portfolio that clears the wrong component is rejected. Resolving components 0 then 1, and 1 then 0, both end at transformed cash 1000, zero component backing, and terminal state 2. `CandidatePayoffTransform.sol` matched those integers, including component 1 paying 1 (cash 400, backing 600 and 0, mask 5) and component 1 paying 0 (cash 0, backing 600 and 0, mask 10). Classification: `partial_resolution_transform: differential_research_kernel`. This is not MATH-1 PASS and not CONTRACT-1. Prediction tokens are not an input.

`research/prism-model/minimum_cost_replication.py` enumerates every column basis of a declared rational matrix with Fractions. No float LP is called. A returned `x` is kept only after `Gx = h` is recomputed exactly. A negative-cost nonnegative nullspace ray returns `COST_UNBOUNDED` and is not given a minimizing certificate. Inside the domain of at most 16 states and 8 components, the cheaper of two duplicate columns is `(0, 1)` at cost 1, and the three-column example returns `(0, 0, 1)` at cost 1. A AND B on columns A, B, and the constant 1 is `PRODUCT_NOT_REPLICABLE` because the equalities are inconsistent (`0 = 1` on state 11 after the other three states force every weight to 0). That run took 0.000081 seconds. Classification of these declared instances: **EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN**. This is not a Kuru price, not a solvency theorem, and not MATH-1 PASS. Log: `evidence/research/prism/minimum-cost-replication-2026-09-26.json`.

`docs/prism/04-architecture/STORAGE_ISOLATION.md` lists the slots `PredictionMarket.split` writes and the slots `CandidateComponentBacking.mint` writes. Two market contracts do not share those split slots. Two series contracts do not share those mint slots. The conclusion is **INFERRED** from the solc 0.8.26 storage layout. It is not a measured Monad conflict rate, and it does not accept ADR-R06.

R-I08 is measured on the existing candidate settlement function. The constructor allocates the final supply with `redeemable` false. `redeem` reverts `NotRedeemable` until `makeRedeemable`. A balance of 1 against ceil funding 2 reverts `Underfunded` and leaves `redeemable` false. After the balance covers ceil funding, the first 1-unit redeem still pays 0. The payout formula was not changed. Test: `test_final_supply_is_not_redeemable_until_funded` in `research/contract-kernels/test/prism/CandidateCumulativeSettlement.t.sol`. Log: `evidence/research/prism/candidate-settlement-ri08-2026-09-26.txt` (3 tests passed). The gate key `R-I08_resolved_not_redeemable` was not renamed. Under INV-P01..INV-P12 that funding refusal is R-I09. INV-P08, the partial-resolution row, already has `test_partial_resolution.py` and `CandidatePayoffTransform.t.sol`.

P-I01..P-I10 already have executable tests. No prediction invariant was prose only. `cancelDraft` was not added. R-I02 and R-I12 were prose only. `research/prism-model/tests/test_invariant_ids.py` now asserts that activated weights and the payoff matrix stay fixed, and that a second `resolve` leaves the first payout in place. `test_no_resurrection` already rejected RESOLVED to ACTIVE. The new file also rejects REDEEMABLE to ACTIVE and every transition out of ARCHIVED. R-I10 stays COUNTEREXAMPLE_FOUND for `FixedPointSettlement.redeem`. The cumulative candidate stays the asserted repair and was not edited. Log: `evidence/research/prism/invariant-coverage-2026-09-26.txt` (3 tests, exit 0). MODULE-ADMISSION-FINANCE-1 stays not met.

The two unexecuted `PredictionMarket` branches are classified PROVEN_UNDER_ASSUMPTIONS unreachable. SymPy 1.14.0 gives an INVALID open gap of 0 on even collateral and 1 on odd collateral, and an INVALID archive liability of 0. YES liability simplifies to the remaining YES supply and NO liability to the remaining NO supply. The integer model walk covered 208 states and 5200 transitions in 0.085581 seconds with no witness. Forge coverage was not re-run. Branch coverage stays 94.44% (34/36). PRED-CONTRACT-1 stays not PASS.

Original case, supply 2, payout `10^18-1`, decimals 18, ceil funding 2. Order A then B pays 0 then 1. Order B then A pays 0 then 1. Both orders pay 1 in total and leave residual 1. Fairness case, supply 3, payout `10^18/2+1`, order A, B, A: receipts are 0 and 1. The sum is the one-shot floor 1 and the residual is 1. A supply-4 partition `1+2+1` pays 0, 2, 1, total 3, which is the one-shot floor. The one-shot redemption pays 3. Chunks `2+2` pay 1 then 2, total 3.

Assembly `gas()` around CALL, optimizer 200, solc 0.8.26: fund transfer 25535, `makeRedeemable` 35308, first 1-unit redeem 40041, second 1-unit redeem 52188, sum 153072. The whole gas test in the forge snapshot is 472420 and includes deployment. Raw log: `evidence/research/prism/candidate-settlement-gas-2026-09-26.txt`.

## PRISM CONTRACT ARCHITECTURE

**PROPOSED, not pass.** `docs/prism/04-architecture/PHASE1_CANDIDATE_SERIES.md` describes `PrismSeries` and `PrismSeriesToken` for the cumulative-floor candidate: backing before mint, one global redemption cursor, residual 0 or 1 under exact ceil funding, per-holder cursor forbidden, immutable. It is contingent on ADR-R03. Canonical MATH-1 stays FAIL. The proposed series token is not written. The backing kernel above is the integer component rule only. It is not that series token and it is not the settlement kernel. ADR-R04..R07 remain proposals. The canonical vault diagram was not rewritten. CONTRACT-1 stays not_met.

## SOLIDITY KERNEL

`research/contract-kernels/src/prediction/`. Not in `contracts/src/v2`.

## DIFFERENTIAL TESTING

Python fixtures and Foundry assertions agree for split 100, merge to 60, YES payout 25, NO payout 0, and INVALID 1-unit streams on supply 5 leaving residual 1.

`PredictionDifferentialTest` reads the fixture files for split, merge, close mint, begin resolution, resolve YES, resolve NO, resolve INVALID, redeem YES, redeem NO, burn worthless, archive, locked merge, the INVALID stream, and the rejected sequences the kernel can express. 14 tests passed. No integer mismatch, so no new COUNTEREXAMPLE_FOUND. `cancelDraft` is still absent. P-I05_cancel_draft stays not_yet_validated.

## MATH-1F

**measured_simulation.** `research/prism-model/market_microstructure.py` is not a protocol theorem and not Kuru liquidity. On the declared normal book, C(3) = 117/2 and R(3) = 87/2. On the crossed book, C(1) = 5 and R(1) = 8, so R(q) > C(q). An empty book is NOT_YET_VALIDATED. The depth walk of 4 units costs 44. Those price bounds are SUPPORTED_BY_SIMULATION only for the declared levels. h = Gx on the declared weights (3, 4) stays true in every case, and backing still covers those weights. The quotes do not change that accounting. The module does not claim an arbitrage trade will happen. Runtime of one evaluation pass: 0.000203 seconds. Log: `evidence/research/prism/market-microstructure-2026-09-26.json`.

## Candidate telescope check

SymPy 1.14.0 simplifies the inductive step of one global cursor to 0, and a five-part composition cancels the same way. floor(0) = 0. Under those assumptions the sum of global-cursor deltas is floor(supply * payout / D). Classification of that identity: **PROVEN_UNDER_ASSUMPTIONS**. This does not change canonical MATH-1 from FAIL.

A per-holder cursor does not telescope. SymPy did not decide the symbolic gap (`equals` returned undecided). The witness payout `10^18-1` and denominator `10^18` has gap 1. Z3 5.1.0 finds the same inequality satisfiable. The Python candidate pays 1 on the global cursor and 0 on the per-holder cursor. That negative control is COUNTEREXAMPLE_FOUND for the per-holder equality. Runtime 0.269474 seconds. `evidence/research/prism/candidate-telescope-proof-2026-09-26.json`.

## BENCHMARKS

`research/benchmarks/README.md`. No percentiles. No invented SLOs. `benchmarks_measured` is `local_single_environment`. That is not admission.

One Foundry test, assembly `gas()` around CALL or CREATE, optimizer 200, solc 0.8.26, kernel SHA `c0af8e584137fa35ef4d71b4d8a46d260798deb4`. Market deploy 2438030, including two internal outcome tokens. `split(100)` 206722. `merge(40)` 37041. `resolve` YES 48909. `redeemYes(60)` on a YES win 34979 and pays 60. `redeemYes(5)` after INVALID 37779 and pays 2. The whole test is 6578687 and includes deployment, so the CALL rows are the measurement. Standalone outcome-token CREATE stays 534243 and was not rerun. There is no protocol factory contract, so that deploy was not run. Log: `evidence/research/prediction/operation-gas-2026-09-26.txt`.

Replication solve on declared binary matrices, five samples, exact re-check true: 2/4 median 0.000084s, 4/4 median 0.000275s, 4/16 median 0.000553s, 8/16 median 0.013973s. 16/16 was NOT_RUN because the solver cap is 8 components. Prediction exhaustive search, five samples: 208 states, 522 transitions, median 0.084142s. The committed summary file was not rewritten. Telescope check, five samples: median 0.011724s, max 0.268256s. Its classifications were unchanged and canonical MATH-1 stays FAIL. Raw: `evidence/research/benchmarks/reference-model-timings-2026-09-26.json`.

## SECURITY

Foundry unit, fuzz, and issuance invariant passed. Slither 0.11.6 still has no IR for `split`, `merge`, `burnWorthless`, and `_redeem`. The log says `Function not found mint` or `Function not found burn`, then `'NoneType' object has no attribute 'type'`. The missing names are OpenZeppelin `Context` (AST id 8774) and `IERC20Errors` (id 8649), so `OutcomeToken.mint` and `burn` are not in the IR. `--solc-force-legacy-json` did not create that IR. Forcing the solc framework raises `legacy JSON not supported from 0.8.x onwards`. `slither_complete_ir` is `blocked_tool`. S-P16 stays open. Reading `PredictionMarket.sol`, the redeemed cursors are storage zeros until `_redeem` adds to them after reading them. That inspection is PROVEN_UNDER_ASSUMPTIONS. No storage initializer was added. solhint 5.2.0 exited 0 with 42 warnings and 0 errors. Resolver honesty remains an accepted trust assumption. PRED-CONTRACT-1 is still not PASS.

`research/benchmarks/scripts/repro_local.sh` at `82ec6c3b0fe3c5bc58cc898cf387c5dfe4950dac` reran the committed suites on the existing interpreter. Prediction unit tests: 12 OK. PRISM unit tests: 85 OK. `forge test`: 63 passed, 0 failed. `reproducibility_local` is `rerun_pass`. This was not a fresh clone and not a fresh virtualenv. The exhaustive summary file was restored after the unit test changed only its runtime. Log: `evidence/research/repro/repro-local-2026-09-26.txt`.

`forge coverage --report summary --report lcov --fuzz-runs 64 --exclude-tests` exited 0 on 2026-09-26. Coverage disables the optimizer. 59 tests passed. Fuzz runs were 64. Invariant runs stayed 256, depth 500, 128000 calls, 47348 handler reverts. That revert count belongs to this coverage command. `PredictionMarket.sol` lines 100.00% (119/119), statements 98.75% (158/160), branches 94.44% (34/36), functions 100.00% (14/14). `OutcomeToken.sol` lines 100.00% (12/12), branches 100.00% (2/2). Two `PredictionMarket` branches remain uncovered: the true side of `Underfunded` in `openRedemption`, and the true side of `LiveLiability` in `archive`. The earlier run remains at `kernel-coverage-2026-09-26.txt` with branches 30.56% (11/36). The new summary is `evidence/research/prediction/kernel-coverage-fuzz64-2026-09-26.txt`. The report total, now including the backing kernels and more of OpenZeppelin `Math.sol`, is lines 59.66% (420/704) and branches 41.61% (57/137).

On a separate optimized build, assembly `gas()` around `CREATE` measured one full `OutcomeToken` at 534243 gas (runtime 2276 bytes). Two full tokens cost 1068486. A storage twin plus two ERC-1167 clones cost 789955: implementation 515299, each clone create 41064, each initialize 96264. A clone of `OutcomeToken` itself shares immutable market, index, and decimals. The market still deploys two full tokens. ADR-P01 stays PROPOSED.

## KURU COMPATIBILITY

Documentation plus a local `calculatePrecisions` worksheet, then a second primary-source pass of the router, SDK, OrderBook, vault, fee, contract-address, and Monad Kuru Flow pages. Those pages do not set RetroPick decimals, price precision, size precision, tick, min size, max size, maker/taker fees, or an allowance spender. RetroPick book parameters stay BLOCKED. No deployment and no fork. PRED-KURU-1 stays blocked. `research/integration/kuru/PARAMETER_WORKSHEET.md`.

## CROSS-MODULE INTEGRATION

BLOCKED. The source-asset list is proposed and not frozen: `docs/prism/04-architecture/SOURCE_ASSET_INTERFACE.md`. Prediction ERC-20s were not deposited into a PRISM series. X-I01..X-I07 are NOT_YET_VALIDATED. Blocker: source interface not frozen. No deposit harness was added. Kuru is not on the redeem path. Launchpad token was not reused.

## BLOCKERS

Listed in `research/reports/DUAL_RESEARCH_STATUS.md`.

## PROMOTION VERDICT

Do not promote. Prediction is a research-kernel candidate. PRISM settlement accounting failed the rounding gate. The joint admission gate is not met.

### Integration candidate map

| If later accepted | Destination |
|---|---|
| `OutcomeToken.sol` | `contracts/src/v2/prediction/OutcomeToken.sol` |
| `PredictionMarket.sol` | `contracts/src/v2/prediction/PredictionMarket.sol` |
| PRISM series, vault, settlement | `contracts/src/v2/prism/` only after MATH-1D is repaired and accepted |

## FILES CHANGED

This branch. See git history. Launchpad V2 sources were not edited except that `.agent/STATE.json` now records the PRISM math gate as FAIL.

## COMMANDS RUN

See `research/reports/EVIDENCE_INDEX.md`.

## EVIDENCE

`evidence/research/baseline/`, `evidence/research/prism/`, `evidence/research/prediction/`, and the paths named above.

## FINAL SHA

Recorded in the branch tip after the last commit of this program. The baseline SHA remains `73d5f1e72b65cc5cdad0d940782c192aa331f5ed`.

## Final statuses

| Module | Status |
|---|---|
| PREDICTION TOKEN | CONTRACT_CANDIDATE |
| PRISM | FAIL |
| CROSS-MODULE | BLOCKED |

MATH-1 = FAIL.  
PRED-CONTRACT-1 = NOT PASS.
