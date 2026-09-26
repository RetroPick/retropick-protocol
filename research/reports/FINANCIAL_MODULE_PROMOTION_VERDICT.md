# Financial module promotion verdict

Human acceptance was not granted. Nothing in `contracts/src/v2/` was added or moved. `MODULE-ADMISSION-FINANCE-1` is not met. That gate would only mean "ready to request promotion into the V2 source tree." It would not mean mainnet-ready or legally approved. The technical conditions are not met.

## REPOSITORY BASELINE

`main` at `73d5f1e72b65cc5cdad0d940782c192aa331f5ed` matched `origin/main`. Working tree was clean. Record: `research/reports/DUAL_RESEARCH_BASELINE.md`.

## RESEARCH EXECUTED

Prediction integer and exact models, exhaustive search, adversarial rejections, PRISM suite reproduction, Z3 and SymPy checks, settlement counterexample, Kuru documentation read, Foundry kernel tests. Market-demand hypotheses were not promoted.

## PREDICTION TOKEN SCHEMA

Proposed: two full ERC-20s, decimals copied from collateral, `market()` and `outcomeIndex()` only, no owner mint. ADR-P01, ADR-P02. Clone and beacon gas were not measured.

## PREDICTION MARKET ARCHITECTURE

Proposed: the market contract is the collateral controller. ADR-P03. Canonical CompleteSetVault diagram left in place.

## PREDICTION PROOFS

P-THEOREM-1 through P-THEOREM-5 and P-THEOREM-7: PROVEN for the qualified model on the tests that call them. P-THEOREM-6 qualified cumulative floor: PROVEN on those tests. Half-up and per-call floor: COUNTEREXAMPLE_FOUND. Exhaustive domain `max_unit=3`: 208 states, 0 failures. This is not a universal uint256 proof.

## PRISM MODEL

Existing oracle re-ran. 55 tests on the baseline commit, 60 after the new probe tests. Adversarial JSON from 2026-09-17 reproduced. AND counterexample reproduced.

## PRISM MATH-1

**FAIL.** MATH-1D per-call settlement floor is the blocking counterexample `CX-FP-SETTLEMENT-001` (holders paid 0, sweepable dust 2, one-shot floor would have paid 1). Component requirement-delta round trip did not show extraction. Exact-fraction solvency tests did not fail. Market hypotheses stay NOT_YET_VALIDATED. A cumulative-floor repair is proposed in ADR-R03 and was not written into the oracle.

## PRISM CONTRACT ARCHITECTURE

Not accepted. ADR-R04..R07 are proposals. No PRISM Solidity was added, because the settlement rule failed and the prediction token interface is not frozen.

## SOLIDITY KERNEL

`research/contract-kernels/src/prediction/`. Not in `contracts/src/v2`.

## DIFFERENTIAL TESTING

Python fixtures and Foundry assertions agree for split 100, merge to 60, YES payout 25, NO payout 0, and INVALID 1-unit streams on supply 5 leaving residual 1.

## BENCHMARKS

`research/benchmarks/README.md`. No percentiles. No invented SLOs.

## SECURITY

Foundry unit, fuzz, and issuance invariant passed. Slither 0.11.6 did not finish a complete IR. Other listed tools were absent. Resolver honesty is an accepted trust assumption. No known unbacked-mint bug in the qualified kernel. PRED-CONTRACT-1 is still not PASS.

## KURU COMPATIBILITY

Documentation only. `research/integration/kuru/KURU_TOKEN_COMPATIBILITY.md`. No deployment.

## CROSS-MODULE INTEGRATION

BLOCKED. Prediction ERC-20s were not deposited into a PRISM series. PRISM does not call a prediction interface. Kuru is not on the redeem path. Launchpad token was not reused.

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
