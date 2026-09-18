# Architecture Decision Records

ADRs preserve accepted boundaries so agents do not repeatedly redesign settled protocol semantics.

Status values:
- `PROPOSED`
- `ACCEPTED`
- `SUPERSEDED`
- `REJECTED`

## Current accepted decisions

- `ADR-001-phase-1-math-first.md` — model/prove before production Solidity.
- `ADR-002-exact-long-only-replication.md` — Phase-1 PRISM uses non-negative exact replication.
- `ADR-003-no-backing-mirror-phase1.md` — same-chain Monad backing is read directly; no Phase-1 BackingMirror.
- `ADR-004-admission-vs-runtime-invariants.md` — prove `h=Gx` at admission, enforce `B_i>=S*x_i` at runtime.
- `ADR-005-retail-trade-vs-primary-create.md` — retail PRISM BUY is secondary trading; CREATE is primary issuance.
- `ADR-006-resolved-vs-redeemable.md` — final payout knowledge and settlement funding are separate states.
- `ADR-007-math-first-phase-gates.md` — hard dependency gates control Metropolis execution.
- `ADR-008-vendor-derived-v2-launchpad-baseline.md` — vendor-derived experimental V2 baseline; does not supersede math-first or authorize production.

## Rule

If implementation requires contradicting an accepted ADR, do not work around it silently. Create a new ADR that explicitly supersedes the old decision and explains the changed assumptions/evidence.
