# Hackathon P0 qualification

This directory is a separate qualification profile for a deliberately narrow
RetroPick Hackathon P0. It does not change the production Prediction/PRISM
research verdicts and does not authorize production contracts under
`contracts/src/v2`.

The P0 objective is to prove a small demo domain whose enabled paths avoid the
known production counterexamples by construction:

- Prediction P0 is binary-only: YES or NO, with no INVALID or fractional payout.
- Prediction P0 admits one explicitly qualified standard ERC-20 collateral.
- PRISM P0 is exact-backed, long-only, transferable, and redeemable in kind.
- PRISM P0 has no final cash settlement, settlement cursor, residual sweep, or
  shared prefunding pool.
- Kuru is a secondary venue only; it is not backing, resolution, or redemption
  authority.

The canonical report for this profile is:

- `research/reports/HACKATHON_P0_GATE.md`

The machine-readable status source is:

- `research/reports/hackathon-p0-gates.yaml`

## Current phase

The reduced Prediction/PRISM local contract profile and local cross-module
harness are qualified as `PASS` under the assumptions in
`research/reports/HACKATHON_P0_GATE.md`. Live Kuru market creation, liquidity,
order, fill, and cancellation remain `BLOCKED_EXTERNAL` pending a deployed P0
system and a funded authorized testnet wallet. This does not change any
production-module gate.

Run `./research/hackathon-p0/scripts/test-p0.sh fast` for the local regression
profile or `./research/hackathon-p0/scripts/test-p0.sh stateful` to include the
three-seed invariant campaigns.
