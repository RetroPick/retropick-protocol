# Hackathon P0 specification

Status: FROZEN_SCOPE_DRAFT

This specification defines a hackathon-only qualification profile. It is not a
production protocol specification, audit, deployment approval, or acceptance of
any production ADR. The production research gate remains controlled by
`research/reports/qualification-gates.yaml`.

## Baseline

- Repository: `RetroPick/retropick-protocol`
- Branch: `codex/hackathon-p0-qualification`
- Base: `origin/main` at `e354db0a96eca6b56b950d87bf81ad87fa4278fd`
- Production gate at base: NOT READY / FAIL for unresolved financial research
- P0 profile: separate hackathon qualification layer

## P0 success target

Hackathon P0 may be declared ready only when all three gates pass:

- `HACKATHON-P0-CONTRACT-READY`
- `HACKATHON-P0-KURU-READY`
- `HACKATHON-P0-DEMO-READY`

These gates do not imply:

- production research handoff readiness;
- accepted production Prediction/PRISM ADRs;
- audit completion;
- mainnet readiness;
- authorization to move contracts into `contracts/src/v2`.

## Excluded production semantics

The P0 enabled domain excludes the known production blockers rather than
claiming to solve them:

- Prediction INVALID and half-value payout are absent.
- Prediction arbitrary payout numerators are absent.
- Prediction collateral is fixed and allowlisted, not arbitrary constructor
  input.
- Prediction inventory is explicitly bounded.
- PRISM cash final settlement is absent.
- PRISM settlement cursors and residual sweep are absent.
- PRISM shared deposit/prefunding pools are absent.
- PRISM arbitrary external component tokens are absent.
- Kuru liquidity, indexer state, frontend state, and market price are never
  backing.

Historical counterexamples remain permanent production evidence.

## Qualification order

1. H0 baseline and branch.
2. H1 Prediction P0 semantic freeze.
3. H2 Prediction P0 model and research kernel.
4. H3 Prediction P0 differential and invariants.
5. H4 PRISM P0 exact replication and lot derivation.
6. H5 PRISM P0 atomic physical-backed research kernel.
7. H6 PRISM P0 transfer, in-kind redemption, and stateful qualification.
8. H7 Prediction-to-PRISM end-to-end harness.
9. H8 contract-ready verdict.
10. H9 current official Kuru testnet verification.
11. H10-H13 live testnet market, liquidity, order, fill, cancel evidence.
12. H14-H15 Kuru-ready and demo-ready verdicts.
