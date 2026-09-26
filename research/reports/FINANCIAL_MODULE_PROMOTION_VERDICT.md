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

## Candidate cumulative settlement

This is not an oracle replacement and it is not MATH-1 PASS.

`CumulativeFloorSettlement` keeps one global redeemed cursor. For any partition of a fixed supply the payouts sum to `floor(supply * payout / D)`. Against exact ceil funding the residual is 0 or 1. A single redemption pays `floor(q * payout / D)` or one more.

That bound is **PROVEN_UNDER_ASSUMPTIONS** for exact non-negative integer division, no mint on this candidate, a starting balance at or above ceil funding, and redemption of the whole supply. The Python candidate matched the bound on the searched domain: **EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN**. The search visited 378530 states and 2542061 transitions in 2.973316 seconds. No new counterexample was found.

The original case pays 1 and leaves residual 1. Both holder orders do that. A per-holder cursor on the same case pays 0. That negative control is not the candidate.

A holder who splits a balance can receive less than their isolated floor. Recorded example: payout `10^18/2 + 1`, supply 3, order A then B then A. A receives 0 and B receives 1. The sum is still the one-shot floor and the ceil-funded residual is 1. The unit moves to the other holder. It is not swept. Single-call redemptions in the search had shortfall 0 and surplus at most 1.

The candidate has no mint. A shared global cursor charged on mint and refunded on redeem had 0 mismatches in 1920 samples. Per-call floor mint of the original two units, followed by a one-shot redeem, extracts 1 raw unit. That extraction belongs to the per-call rule.

The candidate rule is ready for a human to accept or reject under ADR-R03. Canonical MATH-1 and MATH-1D stay FAIL until that acceptance.

`research/contract-kernels/src/prism/CandidateCumulativeSettlement.sol` is a research kernel of that candidate. Foundry differential tests matched the Python integers. Classification: `differential_research_kernel`. This is not MATH-1 PASS, not CONTRACT-1, and not a v2 promotion.

Original case, supply 2, payout `10^18-1`, decimals 18, ceil funding 2. Order A then B pays 0 then 1. Order B then A pays 0 then 1. Both orders pay 1 in total and leave residual 1. Fairness case, supply 3, payout `10^18/2+1`, order A, B, A: receipts are 0 and 1. The sum is the one-shot floor 1 and the residual is 1. A supply-4 partition `1+2+1` pays 0, 2, 1, total 3, which is the one-shot floor. The one-shot redemption pays 3. Chunks `2+2` pay 1 then 2, total 3.

Assembly `gas()` around CALL, optimizer 200, solc 0.8.26: fund transfer 25535, `makeRedeemable` 35308, first 1-unit redeem 40041, second 1-unit redeem 52188, sum 153072. The whole gas test in the forge snapshot is 472420 and includes deployment. Raw log: `evidence/research/prism/candidate-settlement-gas-2026-09-26.txt`.

## PRISM CONTRACT ARCHITECTURE

**PROPOSED, not pass.** `docs/prism/04-architecture/PHASE1_CANDIDATE_SERIES.md` describes `PrismSeries` and `PrismSeriesToken` for the cumulative-floor candidate: backing before mint, one global redemption cursor, residual 0 or 1 under exact ceil funding, per-holder cursor forbidden, immutable. It is contingent on ADR-R03. Canonical MATH-1 stays FAIL. The series token and mint path are not written. The settlement kernel above is not that series. ADR-R04..R07 remain proposals. The canonical vault diagram was not rewritten. CONTRACT-1 stays not_met.

## SOLIDITY KERNEL

`research/contract-kernels/src/prediction/`. Not in `contracts/src/v2`.

## DIFFERENTIAL TESTING

Python fixtures and Foundry assertions agree for split 100, merge to 60, YES payout 25, NO payout 0, and INVALID 1-unit streams on supply 5 leaving residual 1.

## BENCHMARKS

`research/benchmarks/README.md`. No percentiles. No invented SLOs.

## SECURITY

Foundry unit, fuzz, and issuance invariant passed. Slither 0.11.6 did not finish a complete IR. Other listed tools were absent. Resolver honesty is an accepted trust assumption. No known unbacked-mint bug in the qualified kernel. PRED-CONTRACT-1 is still not PASS.

`forge coverage --report summary --fuzz-runs 256 --exclude-tests` exited 0 on 2026-09-26. Coverage disables the optimizer. 14 tests passed, including invariant runs 256, depth 500, 128000 calls, 0 reverts, and fuzz runs 256. `PredictionMarket.sol` lines 89.92% (107/119), statements 78.75% (126/160), branches 30.56% (11/36), functions 92.86% (13/14). `OutcomeToken.sol` lines 100% (12/12), branches 50% (1/2). The report total, including touched OpenZeppelin files, is lines 75.14% (266/354) and branches 25.88% (22/85).

On a separate optimized build, assembly `gas()` around `CREATE` measured one full `OutcomeToken` at 534243 gas (runtime 2276 bytes). Two full tokens cost 1068486. A storage twin plus two ERC-1167 clones cost 789955: implementation 515299, each clone create 41064, each initialize 96264. A clone of `OutcomeToken` itself shares immutable market, index, and decimals. The market still deploys two full tokens. ADR-P01 stays PROPOSED.

## KURU COMPATIBILITY

Documentation plus a local `calculatePrecisions` worksheet, then a second primary-source pass of the router, SDK, OrderBook, vault, fee, contract-address, and Monad Kuru Flow pages. Those pages do not set RetroPick decimals, price precision, size precision, tick, min size, max size, maker/taker fees, or an allowance spender. RetroPick book parameters stay BLOCKED. No deployment and no fork. PRED-KURU-1 stays blocked. `research/integration/kuru/PARAMETER_WORKSHEET.md`.

## CROSS-MODULE INTEGRATION

BLOCKED. The source-asset list is proposed and not frozen: `docs/prism/04-architecture/SOURCE_ASSET_INTERFACE.md`. Prediction ERC-20s were not deposited into a PRISM series. X-I01..X-I07 are not tested. Kuru is not on the redeem path. Launchpad token was not reused.

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
