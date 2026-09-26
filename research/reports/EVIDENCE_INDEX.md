# Evidence index and reproducibility

Clean-room reproduction of the whole repository image was not performed. The commands below were run in this workspace from the committed tree after Foundry 1.8.3 was installed and, for the prover probes, after `sympy` 1.14.0 and `z3-solver` 5.1.0 were installed with pip. Those two Python packages are not in a repo lockfile. The PRISM oracle itself imports only the Python 3.12 standard library.

## Install

```bash
# Foundry, if forge is absent
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Optional, only for MATH-1E probes
python3 -m pip install --user sympy==1.14.0 z3-solver==5.1.0
```

solc 0.8.26 is downloaded by Forge on the first online build. `forge test --offline` fails before that download. That happened once and is recorded in the baseline.

## Reference models

```bash
cd research/prism-model
python3 -m unittest discover -s tests -v
python3 adversarial.py
python3 scenarios.py
python3 math1_probe.py
python3 cumulative_settlement_attack.py

cd ../prediction-model
python3 -m unittest discover -s tests -v

cd ../integration/kuru
node calculate_precisions.mjs

cd ../../prism-model
python3 generate_candidate_fixtures.py
python3 market_microstructure.py
python3 candidate_telescope_proof.py
```

On 2026-09-26 the prism-model suite was 63 tests, OK. A later prediction-model run was 11 tests, OK, including `test_invariants`. The cumulative attack reported 378530 states, 2542061 transitions, 2.973316 seconds, and no new counterexample. `forge test` in the kernel was 24 tests, OK, including invariant runs 256, 128000 calls, 48023 handler reverts. A later prism-model discovery was again 63 tests, OK. The candidate fixture generator wrote 7 cases. `forge test --match-path test/prism/*` was 3 tests, OK. After the synthetic market module and the telescope check, prism-model discovery was 69 tests, OK. Prediction-model discovery stayed 11 tests, OK. `forge test --match-path test/prediction/*` was 38 tests, OK, including the new differential tests and an invariant run of 256 runs, 128000 calls, 46694 handler reverts. That revert count is this command's run. The earlier full-suite figure remains 48023.

Fixture files are committed under `research/prediction-model/fixtures/`. The tests rewrite them to the same JSON. A hash comparison is `sha256sum research/prediction-model/fixtures/*.json` before and after the unittest.

## Foundry kernel

```bash
cd research/contract-kernels
forge test
forge snapshot
forge coverage --report summary --fuzz-runs 256 --exclude-tests
forge test --match-contract OutcomeTokenGasTest -vv
forge test --match-path "test/prism/*" -vv
forge test --match-path "test/prediction/*"
```

Recorded result: Foundry 1.8.3. The coverage run kept invariant runs 256, depth 500, 128000 calls, 0 reverts, and fuzz runs 256. Optimizer settings were disabled by the coverage tool. Deployment gas used a separate optimized build.

## Not reproduced

- `pnpm test:web` (no `node_modules`)
- Kuru testnet or fork
- echidna, medusa, halmos, mythril, semgrep
- a second clone of the repository in an empty directory

## Evidence paths

| Path | Contents |
|---|---|
| `evidence/research/baseline/` | baseline unittest, adversarial, scenarios, Doorway Forge summary |
| `evidence/research/prism/math1-probe-2026-09-26.json` | probe output |
| `evidence/research/prediction/operation-gas-2026-09-26.txt` | one Foundry run of prediction CALL and market CREATE gas |
| `research/benchmarks/reports/prediction-operation-gas-2026-09-26.md` | gas rows, SHA, optimizer, and the one-run limitation |
| `evidence/research/benchmarks/reference-model-timings-2026-09-26.json` | five-sample replication, exhaustive, and telescope timings |
| `research/benchmarks/raw/reference-model-timings-2026-09-26.json` | same timing output |
| `evidence/research/prediction/kernel-forge-2026-09-26.txt` | kernel test log |
| `evidence/research/prediction/kernel-coverage-2026-09-26.txt` | earlier forge coverage summary, branches 30.56% (11/36) |
| `evidence/research/prediction/kernel-coverage-fuzz64-2026-09-26.txt` | remeasured coverage. PredictionMarket branches 94.44% (34/36). Fuzz runs 64. Invariant runs 256 |
| `evidence/research/prediction/unreachable-branches-2026-09-26.json` | Underfunded and LiveLiability classified PROVEN_UNDER_ASSUMPTIONS. Coverage not re-run |
| `evidence/research/prediction/unreachable-branches-2026-09-26.txt` | prediction unit test for that classification |
| `evidence/research/prediction/invalid-floor-compositions-2026-09-26.json` | INVALID compositions supply 0..16. Cumulative floor clean. Per-call witness supply 2 parts (1, 1). Solidity matched |
| `evidence/research/prediction/invalid-floor-compositions-2026-09-26.txt` | python3 3.12.3 and forge 1.8.3 logs. Default suite skips the walk. Profile `invalid_floor_compositions` still executes it |
| `evidence/research/prediction/cancel-draft-2026-09-26.json` | DRAFT to ARCHIVED with CANCELLED_BEFORE_ACTIVATION. Collateral does not move. P-I05 kernel branch measured |
| `evidence/research/prediction/cancel-draft-2026-09-26.txt` | python3 3.12.3 and forge 1.8.3 logs for that transition |
| `evidence/research/prediction/issuance-invariant-2026-09-26.json` | issuance invariant after cancelDraft. Seeds 20260926 and 20260927 passed. Handlers do not call cancelDraft |
| `evidence/research/prediction/issuance-invariant-2026-09-26.txt` | forge 1.8.3 default-profile logs for those two seeds |
| `evidence/research/prism/unittest-minimum-cost-2026-09-26.txt` | prism-model unittest, 85 tests OK |
| `evidence/research/prism/minimum-cost-replication-2026-09-26.json` | exact minimum-cost replication. AND with constant 1 is PRODUCT_NOT_REPLICABLE |
| `evidence/research/prism/storage-layout-2026-09-26.json` | forge storage layouts. Isolation conclusion is INFERRED |
| `docs/prism/04-architecture/STORAGE_ISOLATION.md` | slots `split` and `mint` touch. Not a Monad throughput claim |
| `evidence/research/prism/candidate-settlement-ri08-2026-09-26.txt` | candidate settlement Foundry log, 3 tests passed, including R-I08 |
| `evidence/research/prism/unittest-partial-resolution-2026-09-26.txt` | prism-model unittest after the transform tests |
| `evidence/research/prism/partial-resolution-forge-2026-09-26.txt` | payoff-transform Foundry log |
| `evidence/research/prism/partial-resolution-fixtures-2026-09-26.txt` | transform fixture generator log |
| `research/prism-model/fixtures/partial_resolution.json` | payoff-equivalent transform integers |
| `evidence/research/prediction/branch-coverage-forge-2026-09-26.txt` | reject-branch Foundry log, 14 prediction tests passed, combined with the backing suite |
| `evidence/research/prism/backing-kernel-forge-2026-09-26.txt` | backing-kernel Foundry log, 4 tests passed, same combined run |
| `evidence/research/prism/rebasing-component-backing-2026-09-26.json` | COUNTEREXAMPLE_FOUND. Token balance 99, backingRaw 100, requiredRaw 100, supply 100 |
| `evidence/research/prism/rebasing-component-backing-2026-09-26.txt` | Forge default profile, 1 passed, gas 663233 |
| `evidence/research/prism/fee-on-transfer-component-backing-2026-09-26.json` | existing_rule. Shortfall on a 9-of-10 deposit. Token balance, backingRaw, requiredRaw, and supply stay 0 |
| `evidence/research/prism/fee-on-transfer-component-backing-2026-09-26.txt` | Forge default profile, 1 passed, gas 575199 |
| `evidence/research/prism/duplicate-component-backing-2026-09-26.json` | existing_rule. Same token in two slots. backingRaw 10 and 10. Token balance 20. mint(11) reverts InsufficientBacking |
| `evidence/research/prism/duplicate-component-backing-2026-09-26.txt` | Forge default profile, 1 passed, gas 758840 |
| `evidence/research/prism/zero-weight-component-backing-2026-09-26.json` | existing_rule. Weight 0 requires 0. Positive weight `10^18` stays backed at 4. Supply 4 |
| `evidence/research/prism/zero-weight-component-backing-2026-09-26.txt` | Forge default profile, 1 passed, gas 911911 |
| `evidence/research/prism/fee-on-transfer-settlement-funding-2026-09-26.json` | existing_rule. Underfunded. Transfer of 2 delivers 1. Token balance 1. No payout |
| `evidence/research/prism/fee-on-transfer-settlement-funding-2026-09-26.txt` | Forge default profile, 1 passed, gas 512925 |
| `evidence/research/prism/rebasing-settlement-funding-2026-09-26.json` | existing_rule. After redeemable, rebaseDown of 1 leaves balance 1. redeem(2) pays 1. paidRaw becomes 1 |
| `evidence/research/prism/rebasing-settlement-funding-2026-09-26.txt` | Forge default profile, 1 passed, gas 646410 |
| `evidence/research/prism/deep-rebasing-settlement-funding-2026-09-26.json` | existing_rule. rebaseDown of 2 leaves balance 0 below floor 1. redeem(2) reverts PayoutExceedsBalance. paidRaw stays 0. redeemable stays true |
| `evidence/research/prism/deep-rebasing-settlement-funding-2026-09-26.txt` | Forge default profile, 1 passed, gas 584736 |
| `evidence/research/prism/backing-fixtures-2026-09-26.txt` | backing fixture generator log |
| `evidence/research/prism/unittest-backing-kernel-2026-09-26.txt` | prism-model unittest, 70 tests OK |
| `research/prism-model/fixtures/backing_kernel.json` | FixedPointSeries and ReservationLedger integers |
| `evidence/research/prediction/outcome-token-gas-2026-09-26.txt` | full ERC-20 versus ERC-1167 CREATE gas |
| `evidence/research/prism/cumulative-floor-attack-2026-09-26.json` | candidate settlement attack. Compositions through supply 12 |
| `evidence/research/prism/cumulative-floor-supply16-2026-09-26.json` | compositions through supply 16 on 18 decimals. 917612 states, 7340046 transitions, clean |
| `evidence/research/prism/backing-domain-2026-09-26.json` | PrismSeries backing grid. 81 states, 2187 transitions, clean |
| `evidence/research/prism/extended-domains-2026-09-26.txt` | those two tests, exit 0 |
| `evidence/research/prism/r-theorem-1-2026-09-26.json` | SymPy discharge of R-THEOREM-1 / T-REPL-001. PROVEN_UNDER_ASSUMPTIONS |
| `evidence/research/prism/r-theorem-1-2026-09-26.txt` | that test, exit 0 |
| `evidence/research/prism/r-theorem-5-2026-09-26.json` | SymPy and Z3 discharge of R-THEOREM-5 / T-BS-004. PROVEN_UNDER_ASSUMPTIONS |
| `evidence/research/prism/r-theorem-5-2026-09-26.txt` | that test, exit 0 |
| `evidence/research/prism/r-theorem-6-2026-09-26.json` | Z3 and ledger discharge of R-THEOREM-6 / T-ALLOC-001. PROVEN_UNDER_ASSUMPTIONS |
| `evidence/research/prism/r-theorem-6-2026-09-26.txt` | that test, exit 0 |
| `evidence/research/prism/t-partial-002-2026-09-26.json` | SymPy and Z3 discharge of T-PARTIAL-002. PROVEN_UNDER_ASSUMPTIONS |
| `evidence/research/prism/t-partial-002-2026-09-26.txt` | that test, exit 0 |
| `evidence/research/prism/t-fp-001-2026-09-26.json` | Z3 discharge of T-FP-001. PROVEN_UNDER_ASSUMPTIONS |
| `evidence/research/prism/t-fp-001-2026-09-26.txt` | that test, exit 0 |
| `evidence/research/prism/t-fp-002-2026-09-26.json` | SymPy and Z3 discharge of T-FP-002. PROVEN_UNDER_ASSUMPTIONS |
| `evidence/research/prism/t-fp-002-2026-09-26.txt` | that test, exit 0 |
| `evidence/research/prism/t-fp-003-2026-09-26.json` | Z3 discharge of T-FP-003 funding guard. PROVEN_UNDER_ASSUMPTIONS. Holder underpayment remains CX-FP-SETTLEMENT-001 |
| `evidence/research/prism/t-fp-003-2026-09-26.txt` | that test, exit 0 |
| `evidence/research/prism/t-fp-004-2026-09-26.json` | SymPy and Z3 discharge of T-FP-004. PROVEN_UNDER_ASSUMPTIONS |
| `evidence/research/prism/t-fp-004-2026-09-26.txt` | that test, exit 0 |
| `evidence/research/prism/t-bs-001-2026-09-26.json` | SymPy and Z3 discharge of T-BS-001. PROVEN_UNDER_ASSUMPTIONS |
| `evidence/research/prism/t-bs-001-2026-09-26.txt` | that test, exit 0 |
| `evidence/research/prism/t-bs-002-2026-09-26.json` | SymPy and Z3 discharge of T-BS-002. PROVEN_UNDER_ASSUMPTIONS |
| `evidence/research/prism/t-bs-002-2026-09-26.txt` | that test, exit 0 |
| `evidence/research/prism/t-bs-003-2026-09-26.json` | SymPy and Z3 discharge of T-BS-003 for every finite component count. PROVEN_UNDER_ASSUMPTIONS |
| `evidence/research/prism/t-bs-003-2026-09-26.txt` | that test, exit 0 |
| `evidence/research/prism/t-native-001-2026-09-26.json` | SymPy and Z3 discharge of T-NATIVE-001. PROVEN_UNDER_ASSUMPTIONS |
| `evidence/research/prism/t-native-001-2026-09-26.txt` | that test, exit 0 |
| `evidence/research/prism/t-native-002-2026-09-26.json` | Z3 discharge of T-NATIVE-002 for valid YES and NO. Invalid payout unspecified. PROVEN_UNDER_ASSUMPTIONS |
| `evidence/research/prism/t-native-002-2026-09-26.txt` | that test, exit 0 |
| `evidence/research/prism/t-lc-001-2026-09-26.json` | Exact enumeration of T-LC-001. 7 edges, 42 rejected. No resurrection into ACTIVE. PROVEN_UNDER_ASSUMPTIONS |
| `evidence/research/prism/t-lc-001-2026-09-26.txt` | that test, exit 0 |
| `evidence/research/prism/t-lc-002-2026-09-26.json` | Exact enumeration of T-LC-002. One resolve commit from RESOLUTION_PENDING. PROVEN_UNDER_ASSUMPTIONS |
| `evidence/research/prism/t-lc-002-2026-09-26.txt` | that test, exit 0 |
| `evidence/research/prism/t-partial-001-2026-09-26.json` | SymPy and Z3 discharge of T-PARTIAL-001. NAV splits by resolved and unresolved sets. PROVEN_UNDER_ASSUMPTIONS |
| `evidence/research/prism/t-partial-001-2026-09-26.txt` | that test, exit 0 |
| `evidence/research/prism/precision-boundary-6-8-18-2026-09-26.json` | 168-cell 6/8/18 settlement bound matrix. CX-FP-SETTLEMENT-001 reproduced at 6, 8, and 18. EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN |
| `evidence/research/prism/precision-boundary-6-8-18-2026-09-26.txt` | that test, exit 0 |
| `evidence/research/prism/precision-boundary-solidity-2026-09-26.json` | 129 fitting cumulative cells matched the Solidity candidate. 15 overflow and 24 zero-supply cells excluded. Per-call rule not in Solidity |
| `evidence/research/prism/precision-boundary-solidity-2026-09-26.txt` | Python precision tests, 2 passed. Forge 1.8.3, solc 0.8.26, optimizer 200, 1 passed, no mismatch |
| `evidence/research/prism/zero-supply-dust-2026-09-26.json` | Zero-supply settlement residual sits. Sweep policy NOT_YET_VALIDATED. Residual bound PROVEN_UNDER_ASSUMPTIONS. No extraction witness |
| `evidence/research/prism/zero-supply-dust-2026-09-26.txt` | Python classification, exit 0. Forge 1.8.3, solc 0.8.26, optimizer 200, 4 passed |
| `evidence/research/prism/candidate-settlement-invariant-2026-09-26.json` | Candidate settlement stateful invariants. 256 runs, depth 128, seeds 20260926 and 20260927, 0 reverts. No counterexample |
| `evidence/research/prism/candidate-settlement-invariant-2026-09-26.txt` | Forge 1.8.3 warmup 32/16 and recorded 256/128 campaigns, both seeds, exit 0 |
| `evidence/research/prism/candidate-backing-invariant-2026-09-26.json` | Component-backing stateful invariants. 256 runs, depth 128, seeds 20260926 and 20260927, 0 reverts. No counterexample |
| `evidence/research/prism/candidate-reservation-invariant-2026-09-26.json` | Reservation-ledger stateful invariants. deposit and reserve only. 256 runs, depth 128, 0 reverts. No counterexample |
| `evidence/research/prism/candidate-backing-reservation-invariants-2026-09-26.txt` | Forge 1.8.3 warmup 32/16 and recorded 256/128 campaigns for both suites, both seeds, exit 0 |
| `evidence/research/prism/candidate-payoff-invariant-2026-09-26.json` | Payoff-transform stateful invariants. 256 runs, depth 128, seeds 20260926 and 20260927, 0 reverts. No counterexample |
| `evidence/research/prism/candidate-payoff-invariant-2026-09-26.txt` | Forge 1.8.3 warmup 32/16 and recorded 256/128 campaigns, both seeds, exit 0 |
| `research/prism-model/fixtures/precision_boundary_cumulative.json` | cumulative fixtures for the uint256-fitting cells and the Python per-call regressions |
| `evidence/research/prediction/invariant-ids-2026-09-26.txt` | P-I01..P-I10 Python and Forge logs |
| `evidence/research/prism/invariant-coverage-2026-09-26.txt` | R-I02, remaining R-I11 edges, and R-I12. 3 tests, exit 0 |
| `research/prism-model/tests/test_invariant_ids.py` | those three checks on the existing exact model |
| `evidence/research/prediction/kuru/` | outcome-token Kuru worksheet and helper output |
| `evidence/research/prism/kuru/` | series-token Kuru worksheet and helper output |
| `docs/prism/04-architecture/PHASE1_CANDIDATE_SERIES.md` | proposed PRISM architecture. Candidate settlement kernel is separate and is not this series |
| `evidence/research/prism/candidate-settlement-forge-2026-09-26.txt` | candidate kernel Foundry log, 3 tests passed |
| `evidence/research/prism/candidate-settlement-gas-2026-09-26.txt` | raw fund and redeem gas log |
| `evidence/research/prism/candidate-fixtures-2026-09-26.txt` | fixture generator log |
| `evidence/research/prism/unittest-candidate-kernel-2026-09-26.txt` | prism-model unittest, 63 tests OK |
| `research/prism-model/fixtures/candidate_cumulative_settlement.json` | Python candidate integers |
| `evidence/research/prism/kuru/source-pass-2026-09-26.json` | second Kuru source pass. PRED-KURU-1 stays blocked |
| `evidence/research/prediction/differential-forge-2026-09-26.txt` | prediction Foundry path, 38 tests passed |
| `evidence/research/prediction/unittest-differential-2026-09-26.txt` | prediction-model unittest, 11 tests OK |
| `evidence/research/prism/unittest-math1f-2026-09-26.txt` | prism-model unittest, 69 tests OK |
| `evidence/research/prism/market-microstructure-2026-09-26.json` | MATH-1F synthetic quotes. Not solvency |
| `evidence/research/prism/candidate-telescope-proof-2026-09-26.json` | SymPy 1.14.0 and Z3 5.1.0 cursor check |
| `docs/prism/04-architecture/SOURCE_ASSET_INTERFACE.md` | proposed, not frozen |
| `evidence/research/prism/source-interface-comparison-2026-09-26.json` | recorded_gap. Python lacks the proposed accessors. Interface was not frozen. X-I01..X-I07 stay NOT_YET_VALIDATED |
| `evidence/research/prism/deposit-component-count-2026-09-26.json` | bounded_by_constructor. Two constructor slots. backingRaw 0,0 then 1,1. Python credits the same integers |
| `evidence/research/prism/deposit-component-count-2026-09-26.txt` | Forge default profile, 1 passed, gas 556488 |
| `evidence/research/prism/non-depositor-mint-2026-09-26.json` | permissionless_mint. A deposits 1,1. B mints 2**256-1. Supply 0 then that quantity. backingRaw stays 1,1. B receives the series tokens. Python matches supply and backing |
| `evidence/research/prism/non-depositor-mint-2026-09-26.txt` | Forge default profile, 1 passed, gas 671578 |
| `evidence/research/prism/positive-weight-non-depositor-mint-2026-09-26.json` | permissionless_mint. Weights 10^18, 10^18. A deposits 1,1. B mints 1. Supply 0 then 1. backingRaw stays 1,1. requiredRaw at supply 1 is 1,1. B receives the series token |
| `evidence/research/prism/positive-weight-non-depositor-mint-2026-09-26.txt` | Forge default profile, 1 passed, gas 633405 |
| `evidence/research/prism/over-mint-2026-09-26.json` | existing_rule. Weights 10^18, 10^18. A deposits 1,1. B mint(2) reverts InsufficientBacking(0, 1, 2). Supply stays 0. backingRaw stays 1,1. requiredRaw at supply 2 is 2,2. Python rejects |
| `evidence/research/prism/over-mint-2026-09-26.txt` | Forge default profile, 1 passed, gas 549077 |
| `evidence/research/prism/non-depositor-redeem-2026-09-26.json` | redeem_pays_caller. Weights 10^18, 10^18. A deposits 1,1. B mints 1 and redeems 1. Supply 1 then 0. backingRaw 1,1 then 0,0. Component tokens sit with B |
| `evidence/research/prism/non-depositor-redeem-2026-09-26.txt` | Forge default profile, 1 passed, gas 780289 |
| `decisions/ADR-R10-non-depositor-redeem-pays-the-caller.md` | PROPOSED. Acceptance not granted. Mint and redeem were not edited |
| `evidence/research/prism/settlement-pays-holder-2026-09-26.json` | settlement_pays_holder. Funder is not the holder. After redeem, funder 0, holder 1, kernel 1. paidRaw 1. Python paid amount matches. ADR-R10 stays PROPOSED |
| `evidence/research/prism/settlement-pays-holder-2026-09-26.txt` | Forge default profile, 1 passed, gas 392842 |
| `evidence/research/prism/funder-residual-redeem-2026-09-26.json` | existing_rule. Funder redeem(1) reverts InvalidQuantity(1, 0). Funder 0, holder 1, kernel 1, paidRaw 1. Residual stays in the kernel. Sweep policy stays NOT_YET_VALIDATED |
| `evidence/research/prism/funder-residual-redeem-2026-09-26.txt` | Forge default profile, 1 passed, gas 395690 |
| `evidence/research/prism/two-unit-redeems-2026-09-26.json` | cumulative_floor_match. One holder, supply 2. redeem(1) then redeem(1) pays 0 then 1. Kernel balance 2 then 1. Canonical per-call pays 0 then 0. MATH-1 stays FAIL |
| `evidence/research/prism/two-unit-redeems-2026-09-26.txt` | Forge default profile, 1 passed, gas 431562 |
| `evidence/research/prism/two-holder-redeems-2026-09-26.json` | cumulative_floor_match. A then B each redeem 1. Payouts 0 then 1. The unit goes to B. Kernel balance ends at 1. paidRaw ends at 1 |
| `evidence/research/prism/two-holder-redeems-2026-09-26.txt` | Forge default profile, 1 passed, gas 437214 |
| `evidence/research/prism/over-reserve-2026-09-26.json` | existing_rule. Deposit 100, reserve 60, reserve 50 reverts InsufficientUnreserved. Reserved stays 60. Available stays 40. Python rejects the same integers |
| `evidence/research/prism/over-reserve-2026-09-26.txt` | Forge default profile, 1 passed, gas 214969 |
| `evidence/research/prism/remainder-reserve-2026-09-26.json` | existing_rule. Deposit 100, reserve 60, reserve 40 succeeds. Reserved becomes 100. Available becomes 0. Series B becomes 40. Python accepts the same integers |
| `evidence/research/prism/remainder-reserve-2026-09-26.txt` | Forge default profile, 1 passed, gas 235287 |
| `evidence/research/prism/same-series-reserve-2026-09-26.json` | existing_rule. Deposit 100. Series A reserves 60, then series A reserves 40. Series A becomes 100. Reserved becomes 100. Available becomes 0. Python accepts the same integers |
| `evidence/research/prism/same-series-reserve-2026-09-26.txt` | Forge default profile, 1 passed, gas 205460 |
| `decisions/ADR-R11-python-release-and-withdraw-are-absent-from-the-ledger.md` | PROPOSED. Acceptance not granted. Python declares release and withdraw. CandidateReservationLedger does not. T-ALLOC-001 is not MATH-1 PASS |
| `decisions/ADR-R12-component-backing-state-changing-names.md` | PROPOSED. Acceptance not granted. Python state-changing names are deposit_raw, mint, mint_with_minimum_backing, redeem, sweep_dust. Solidity names are deposit, mint, redeem. Not CONTRACT-1. Not MATH-1 PASS |
| `decisions/ADR-R13-settlement-fund-is-only-on-fixed-point-settlement.md` | PROPOSED. Acceptance not granted. fund is only on FixedPointSettlement. Cumulative kernel names are makeRedeemable and redeem. Sweep policy stays NOT_YET_VALIDATED. Not MATH-1 PASS |
| `evidence/research/prediction/slither-2026-09-26.txt` | earlier Slither log, including IR errors |
| `evidence/research/prediction/slither-focused-2026-09-26.txt` | focused Slither 0.11.6 rerun, exit 255, 14 results |
| `evidence/research/prediction/slither-legacy-ast-2026-09-26.txt` | `--solc-force-legacy-json` under Foundry. `_redeem` still has no IR. Exit 255 |
| `evidence/research/prediction/slither-solc-legacy-2026-09-26.txt` | solc framework rejects legacy JSON on 0.8.26. Exit 1 |
| `evidence/research/prediction/slither-sp16-2026-09-26.json` | fresh Slither 0.11.6 at 0636686. Exit 255. `_redeem` has no IR. Classification blocked_tool. S-P16 stays open |
| `evidence/research/prediction/slither-burn-lookup-2026-09-26.json` | `OutcomeToken.burn` calls `_burn`. Market `merge`, `burnWorthless`, and `_redeem` call `yesToken.burn` or `noToken.burn`. Quote does not give `_redeem` IR. S-P16 stays open |
| `evidence/research/prediction/compiler-redeem-ir-2026-09-26.json` | forge inspect ir-optimized, exit 0. Output contains `_redeem` and `burn`. compiler_sees_redeem_analyzer_does_not. S-P16 stays open |
| `evidence/research/prediction/slither-foundry-target-2026-09-26.json` | Foundry-targeted Slither 0.11.6, exit 255. `_redeem` has no IR. blocked_tool. S-P16 stays open |
| `evidence/research/prediction/slither-foundry-target-2026-09-26.txt` | same run, command log |
| `evidence/research/prediction/outsider-burn-2026-09-26.json` | existing_rule. After split(4), outsider `OutcomeToken.burn` of 1 reverts `NotMarket`. YES totalSupply stays 4. Holder balance stays 4. Python has no OutcomeToken |
| `evidence/research/prediction/outsider-burn-2026-09-26.txt` | Forge default profile, 1 passed, gas 322322 |
| `evidence/research/prediction/outsider-mint-2026-09-26.json` | existing_rule. After split(4), outsider `OutcomeToken.mint` of 1 reverts `NotMarket`. YES totalSupply stays 4. Holder balance stays 4. Python has no OutcomeToken |
| `evidence/research/prediction/outsider-mint-2026-09-26.txt` | Forge default profile, 1 passed, gas 322367 |
| `evidence/research/prediction/compiler-redeem-ir-2026-09-26.txt` | matching IR lines only |
| `evidence/research/prediction/slither-sp16-2026-09-26.txt` | same run, command log |
| `evidence/research/prediction/zero-address-initialize-2026-09-26.json` | `initialize(address(0))` stores the zero market. totalSupply stays 0. recorded_finding. Python has no counterpart. ADR-P14 PROPOSED |
| `evidence/research/prediction/zero-address-initialize-2026-09-26.txt` | Forge default profile, 1 passed, gas 228257 |
| `evidence/research/prediction/solhint-2026-09-26.txt` | solhint 5.2.0, exit 0, 42 warnings, 0 errors |
| `evidence/research/repro/repro-local-2026-09-26.txt` | local rerun: 12 and 85 unit tests OK, Foundry 63 passed |
| `evidence/research/repro/repro-local-2026-09-26-rerun.txt` | rerun at 0f14c30, exit 0. Prediction 15 OK, PRISM 109 OK, Foundry 76 passed, 0 failed, 1 skipped. The skip is the supply 0..16 walk |
| `evidence/research/prediction/resolved-redeem-contradiction-2026-09-26.json` | contradiction 2 stays open. Native redeem pays 1 inside RESOLVED. Prediction redeem rejects before REDEEMABLE |
| `evidence/research/prediction/false-return-collateral-2026-09-26.json` | false-return collateral stays open. Python rejects construction. Solidity split reverts SafeERC20FailedOperation |
| `evidence/research/prediction/false-return-collateral-2026-09-26.txt` | Python 1 test OK. Forge default profile, 1 passed, 0 failed |
| `evidence/research/prediction/rebasing-collateral-2026-09-26.json` | COUNTEREXAMPLE_FOUND. Balance 99, collateralLocked 100, YES 100, NO 100, liability 100 |
| `evidence/research/prediction/rebasing-collateral-2026-09-26.txt` | Python 1 test OK. Forge default profile, 1 passed, gas 787902 |
| `evidence/research/prediction/split-callback-2026-09-26.json` | existing nonReentrant guard. Callback split reverts. Locked, YES, and NO stay 0 |
| `evidence/research/prediction/split-callback-2026-09-26.txt` | Python 1 test OK. Forge default profile, 1 passed, gas 564941 |
| `evidence/research/prediction/live-collateral-withdrawal-2026-09-26.json` | existing_rule. No withdrawal while supply is live. Merge and redeem burn first |
| `evidence/research/prediction/live-collateral-withdrawal-2026-09-26.txt` | Python 1 test OK. Forge default profile, 1 passed, gas 1694955 |
| `evidence/research/prediction/double-yes-redeem-2026-09-26.json` | existing_rule. Second redeem of the same YES 4 reverts. Collateral falls once, from 4 to 0 |
| `evidence/research/prediction/unredeemed-liability-2026-09-26.json` | existing_rule. Before redeem, cursors 0 and 0, locked 4, liability 4. After redeemYes(1), 1, 0, 3, 3 |
| `evidence/research/prediction/unredeemed-liability-2026-09-26.txt` | Python 1 test OK. Forge default profile, 1 passed, gas 660397 |
| `evidence/research/prediction/double-yes-redeem-2026-09-26.txt` | Python 1 test OK. Forge default profile, 1 passed, gas 890687 |
| `evidence/research/prediction/second-yes-resolution-2026-09-26.json` | existing_rule. Second resolve after YES_WIN leaves numerators 2 and 0. Collateral, YES, and NO stay 4 |
| `evidence/research/prediction/second-yes-resolution-2026-09-26.txt` | Python 1 test OK. Forge default profile, 1 passed, gas 527769 |
| `evidence/research/prediction/unequal-merge-2026-09-26.json` | existing_rule. OPEN merge of YES 1 and NO 4 reverts. Collateral, YES, and NO stay 4 |
| `evidence/research/prediction/unequal-merge-2026-09-26.txt` | Python 1 test OK. Forge default profile, 1 passed, gas 661526 |
| `evidence/research/prediction/uint256-split-2026-09-26.json` | recorded_contradiction. Solidity split of uint256 max stays at 2**256-1. split(1) panics. Python split(1) reaches 2**256. ADR-P11 PROPOSED |
| `decisions/ADR-P11-uint256-split-domain.md` | PROPOSED. Acceptance not granted. Neither split was edited |
| `evidence/research/prediction/uint256-split-2026-09-26.txt` | Python 1 test OK. Forge default profile, 1 passed, gas 711665 |
| `evidence/research/prediction/split-max-2026-09-26.json` | existing_rule. split(2**256) after split 10 leaves collateral, YES, and NO at 10 |
| `evidence/research/prediction/split-max-2026-09-26.txt` | Python 1 test OK. Forge default profile, 1 passed, gas 313328 |
| `evidence/research/prediction/configured-split-maximum-2026-09-26.json` | recorded_contradiction. Python rejects split(1000000001). Solidity mints collateral, YES, and NO at 1000000001. ADR-P12 PROPOSED |
| `evidence/research/prediction/configured-split-maximum-2026-09-26.txt` | Python 1 test OK. Forge default profile, 1 passed, gas 315609 |
| `evidence/research/prediction/invalid-burn-rejected-2026-09-26.json` | existing_rule. After INVALID YES dust, burn of NO 1 reverts. Collateral 3, YES 0, NO 5 |
| `evidence/research/prediction/invalid-burn-rejected-2026-09-26.txt` | Python 1 test OK. Forge default profile, 1 passed, gas 962224 |
| `evidence/research/prediction/repeat-activate-2026-09-26.json` | existing_rule. A second activate while OPEN reverts. Collateral, YES, and NO stay 0 |
| `evidence/research/prediction/repeat-activate-2026-09-26.txt` | Python 1 test OK. Forge default profile, 1 passed, gas 134353 |
| `evidence/research/prediction/draft-split-2026-09-26.json` | existing_rule. Split of 1 while DRAFT reverts. Collateral, YES, and NO stay 0 |
| `evidence/research/prediction/draft-split-2026-09-26.txt` | Python 1 test OK. Forge default profile, 1 passed, gas 177693 |
| `evidence/research/prediction/rejection-inventory-2026-09-26.json` | 72 rows. 71 existing_rule. archive from DRAFT is recorded_contradiction. ADR-P13 PROPOSED |
| `evidence/research/prediction/rejection-inventory-2026-09-26.txt` | Python 1 test OK. Forge default profile, 1 passed, gas 8197908 |
| `decisions/ADR-P13-archive-from-draft.md` | PROPOSED. Acceptance not granted. Archive was not edited |
| `decisions/ADR-P14-zero-address-outcome-initialize.md` | PROPOSED. Acceptance not granted. Initialize was not edited |
| `decisions/ADR-P15-prediction-redeem-entry-points.md` | PROPOSED. Acceptance not granted. Solidity redeemYes and redeemNo. Python redeem. Spelling pairs cover the other state-changing names. Not PRED-CONTRACT-1 PASS |
| `evidence/research/prediction/python-stub-rejects-2026-09-26.json` | recorded_gap. Open market after split 4. Four Python stubs raise. Collateral, YES, and NO stay 4. Solidity declares none of the four |
| `evidence/research/prediction/python-stub-rejects-2026-09-26.txt` | same run, command log |
| `decisions/ADR-P16-python-admin-stubs-raise.md` | PROPOSED. Acceptance not granted. The four stubs stay raises. Solidity does not declare them |
| `evidence/research/prediction/no-redeem-2026-09-26.json` | existing_rule. Split 4, NO_WIN, redeem 1 NO. Payout 1. Collateral 3, YES 4, NO 3, no_redeemed 1. Python matches. ADR-P15 stays a name proposal |
| `evidence/research/prediction/no-redeem-2026-09-26.txt` | Forge default profile, 1 passed, gas 590465 |
| `evidence/research/prediction/losing-yes-redeem-2026-09-26.json` | existing_rule. Split 4, NO_WIN, redeemYes 1. Payout 0. Collateral 4, YES 3, NO 4, yes_redeemed 1, no_redeemed 0. Python matches. burnWorthless not called |
| `evidence/research/prediction/losing-yes-redeem-2026-09-26.txt` | Forge default profile, 1 passed, gas 586104 |
| `evidence/research/prediction/losing-yes-liability-2026-09-26.json` | existing_rule. Split 4, NO_WIN, redeemYes 1 pays 0. Liability 4 before and after. Collateral 4 before and after. yes_redeemed 0 then 1. no_redeemed stays 0. Python matches |
| `evidence/research/prediction/losing-yes-liability-2026-09-26.txt` | Forge default profile, 1 passed, gas 628527 |
| `evidence/research/prediction/losing-no-redeem-2026-09-26.json` | existing_rule. Split 4, YES_WIN, redeemNo 1 pays 0. Liability 4 before and after. Collateral 4 before and after. YES supply 4. NO supply 3. no_redeemed 1. Python matches |
| `evidence/research/prediction/losing-no-redeem-2026-09-26.txt` | Forge default profile, 1 passed, gas 662977 |
| `evidence/research/prediction/transferred-yes-redeem-2026-09-26.json` | existing_rule. A splits 4, transfers 1 YES to B, YES_WIN, B redeemYes 1 pays 1 to B. A collateral stays 999996. B collateral 0 then 1. Liability 4 then 3. Collateral locked 4 then 3. Python pays 1 to bob |
| `evidence/research/prediction/transferred-yes-redeem-2026-09-26.txt` | Forge default profile, 1 passed, gas 862377 |
| `decisions/ADR-P17-python-outcome-transfer-absent.md` | PROPOSED. Acceptance not granted. Python has no outcome transfer. Solidity OutcomeToken transfer is used. The book edit is not a payout contradiction. The transferred YES witness stays existing_rule |
| `evidence/research/prediction/full-yes-redeem-2026-09-26.json` | existing_rule. Split 4, YES_WIN, redeemYes 4 pays 4. Liability 4 then 0. Collateral locked 4 then 0. YES supply 4 then 0. NO supply 4. yes_redeemed 0 then 4. no_redeemed stays 0. Python matches |
| `evidence/research/prediction/full-yes-redeem-2026-09-26.txt` | Forge default profile, 1 passed, gas 677150 |
| `evidence/research/prediction/over-yes-redeem-2026-09-26.json` | existing_rule. Split 4, YES_WIN, redeemYes 5 reverts ERC20InsufficientBalance. Python raises redeem exceeds balance. Liability stays 4. Collateral locked stays 4. YES supply stays 4. yes_redeemed stays 0 |
| `evidence/research/prediction/over-yes-redeem-2026-09-26.txt` | Forge default profile, 1 passed, gas 717668 |
| `evidence/research/prediction/zero-yes-redeem-2026-09-26.json` | existing_rule. Split 4, YES_WIN, redeemYes 0 reverts ZeroAmount. Python raises redeem quantity must be positive. No payout. Liability stays 4. Collateral locked stays 4. Supplies and redeemed cursors stay unchanged |
| `evidence/research/prediction/zero-yes-redeem-2026-09-26.txt` | Forge default profile, 1 passed, gas 680560 |
| `evidence/research/prediction/merge-after-yes-redeem-2026-09-26.json` | existing_rule. Split 4, YES_WIN, redeem 1 YES pays 1, then merge 1 rejects. Liability stays 3. Collateral locked stays 3. YES supply 3. NO supply 4. yes_redeemed 1. no_redeemed 0. Inventory rows[50] has no prior redeem |
| `evidence/research/prediction/merge-after-yes-redeem-2026-09-26.txt` | Forge default profile, 1 passed, gas 805594 |
| `evidence/research/prediction/split-after-yes-redeem-2026-09-26.json` | existing_rule. Split 4, YES_WIN, redeem 1 YES pays 1, then split 1 rejects. Collateral pulled 0. Liability stays 3. Collateral locked stays 3. YES supply 3. NO supply 4. yes_redeemed 1. no_redeemed 0. Inventory rows[49] has no prior redeem |
| `evidence/research/prediction/split-after-yes-redeem-2026-09-26.txt` | Forge default profile, 1 passed, gas 800846 |
| `evidence/research/prediction/kuru-backing-claim-2026-09-26.json` | absent. Kuru orderbook liquidity is not protocol backing or redemption value. PRED-KURU-1 stays blocked |
| `decisions/ADR-P12-configured-split-maximum.md` | PROPOSED. Acceptance not granted. Neither split was edited |
| `evidence/research/prediction/resolved-redeem-contradiction-2026-09-26.txt` | `python3 -m unittest tests.test_resolved_redeem_contradiction -v`, 1 test OK, exit 0 |
| `research/benchmarks/scripts/repro_local.sh` | rerun script. Not a fresh clone or virtualenv |
| `research/prediction-model/outputs/exhaustive_summary.json` | 208-state search |
| `research/contract-kernels/.gas-snapshot` | one gas snapshot |

## Classifications used

PROVEN_UNDER_ASSUMPTIONS, EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN, SUPPORTED_BY_SIMULATION, SUPPORTED_BY_LIVE_EVIDENCE, MEASURED_LOCAL, MEASURED_TESTNET, INFERRED, RECOMMENDATION, NOT_YET_VALIDATED, COUNTEREXAMPLE_FOUND, BLOCKED.  
No MEASURED_TESTNET claim was made.
