# Hackathon P0 gate — 2026-09-28

**Verdict: NOT READY.** This report starts the separate Hackathon P0
qualification profile. It does not change production research status, accept
production ADRs, authorize production Solidity, or claim mainnet readiness.

Machine-readable source:

- `research/reports/hackathon-p0-gates.yaml`

## BASELINE

- Repository: `RetroPick/retropick-protocol`
- Branch: `codex/hackathon-p0-qualification`
- Base: `origin/main`
- Base SHA: `e354db0a96eca6b56b950d87bf81ad87fa4278fd`
- Baseline evidence: `evidence/hackathon-p0/repro/baseline-2026-09-28.md`

## SCOPE

Hackathon P0 is a reduced, exact, demo-safe profile. It is intended to make
currently known production-risk paths unreachable by construction, then prove
the remaining enabled paths.

## EXCLUDED PRODUCTION SEMANTICS

- Prediction INVALID and half-value payouts.
- Arbitrary payout numerators.
- Arbitrary ERC-20 collateral admission.
- Unbounded uint256 inventory.
- PRISM cash final settlement.
- PRISM settlement cursors and residual sweep.
- PRISM shared prefunding/deposit pools.
- Arbitrary external PRISM component sources.
- Any dependency on Kuru, indexer, frontend, or market price for solvency.

The production counterexamples in `research/reports/SMART_CONTRACT_RESEARCH_GATE.md`
remain valid and must be preserved.

## PREDICTION P0

Frozen semantic draft: `research/hackathon-p0/PREDICTION_P0_SPEC.md`.

Current status: NOT READY.

- Binary YES/NO only: Solidity research kernel subset PASS locally.
- Fixed qualified collateral: specified, not implemented.
- Complete-set issuance: Solidity research kernel subset PASS locally.
- Exact winner redemption: Solidity research kernel subset PASS locally,
  including the `MAX_OUTCOME_SUPPLY` boundary.
- Callback/lifecycle defense: Solidity research kernel subset PASS locally for
  collateral/resolver overlap and callback-during-split regression.
- Bounded arithmetic: specified as `type(uint128).max` and locally tested.
- Differential result: NOT_RUN.
- Invariant result: NOT_RUN.

Evidence:

- `research/contract-kernels/src/hackathon/PredictionMarketP0.sol`
- `research/contract-kernels/src/hackathon/PredictionFactoryP0.sol`
- `research/contract-kernels/test/hackathon/PredictionP0.t.sol`
- `evidence/hackathon-p0/prediction/prediction-p0-kernel-2026-09-28.json`

## PRISM P0

Frozen semantic draft: `research/hackathon-p0/PRISM_P0_SPEC.md`.

Current status: NOT READY.

- Exact replication: specified, not rechecked for a demo series.
- Exact lot derivation: specified, not implemented.
- Atomic minter-funded backing: specified, not implemented.
- Physical backing: specified, not implemented.
- In-kind redemption: specified, not implemented.
- Transferability: specified, not implemented.
- No shared prefunding: specified, not tested.
- No cash settlement: specified, not ABI-checked.
- Invariant result: NOT_RUN.

## CROSS MODULE

Spec: `research/hackathon-p0/CROSS_MODULE_P0_SPEC.md`.

Current status: NOT_READY / NOT_RUN.

The required end-to-end YES and NO world harness has not been implemented.
Prediction collateral liability and PRISM source backing remain conceptually
distinct in the spec, but no executable witness has proven that path yet.

## KURU

Spec: `research/hackathon-p0/KURU_P0_SPEC.md`.

Current status: BLOCKED_EXTERNAL / NOT_RUN.

Official current Kuru/Monad testnet data has not yet been verified in this P0
branch. No live market, liquidity, order, fill, or cancellation evidence exists.
Kuru remains a secondary venue only.

## SECURITY

P0 security evidence is not yet collected. Required future evidence includes
Foundry unit tests, fuzz tests, stateful invariants, manual threat model,
available static analyzer output, and solhint or equivalent. Existing
production static-analysis limitations remain separate and must not be hidden.

## REPRODUCIBILITY

The dedicated P0 reproducibility profile is not implemented yet. The intended
path is recorded in `research/hackathon-p0/scripts/README.md`.

## HACKATHON-P0-CONTRACT-READY

Status: NOT_RUN.

Reason: Prediction P0, PRISM P0, and cross-module executable gates have not yet
been implemented or verified.

## HACKATHON-P0-KURU-READY

Status: BLOCKED_EXTERNAL.

Reason: Live official Kuru testnet environment, deployed markets, liquidity,
orders, fills, and cancels have not yet been verified.

## HACKATHON-P0-DEMO-READY

Status: NOT_RUN.

Reason: Contract-ready and Kuru-ready are not PASS.

## PRODUCTION GATES UNCHANGED

Production research remains controlled by
`research/reports/qualification-gates.yaml` and
`research/reports/SMART_CONTRACT_RESEARCH_GATE.md`. This P0 profile does not
promote production Prediction or PRISM readiness.

## NEXT OWNER

Next research step: implement `HackathonPredictionModel`, `PredictionMarketP0`,
and focused boundary/differential tests for PRED-H1 through PRED-H6, including
the historical callback witness as a negative regression.
