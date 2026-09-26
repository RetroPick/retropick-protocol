# Dual research status

**Date:** 2026-09-26  
**Branch:** `cursor/finance-qualification-bbd4`  
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
MATH-1D candidate cumulative floor: PROVEN_UNDER_ASSUMPTIONS. Domain check: EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN. Ready for ADR acceptance. Not an oracle pass.  
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
- PRISM settlement Solidity after that acceptance. It was not written in this pass.
- Complete Slither IR or another static-analysis pass. Forge coverage is now measured and is not a pass by itself.
- Kuru router address and a RetroPick parameter set. The worksheet's book rows are BLOCKED. No fork and no deployment.
- Cross-module differential harness. The source-asset list is `proposed_not_frozen`, not frozen. X-I01..X-I07 are not tested.
- Kernel `cancelDraft` for the cancelled-draft branch of P-I05.
- Echidna, Medusa, Halmos, Mythril, semgrep, solhint: not installed.
