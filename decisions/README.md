# Architecture Decision Records

ADRs preserve accepted boundaries so agents do not repeatedly redesign settled semantics.

Status values: `PROPOSED`, `ACCEPTED`, `SUPERSEDED`, `REJECTED`.

## Current accepted decisions

- `ADR-001-phase-1-math-first.md`
- `ADR-002-exact-long-only-replication.md`
- `ADR-003-no-backing-mirror-phase1.md`
- `ADR-004-admission-vs-runtime-invariants.md`
- `ADR-005-retail-trade-vs-primary-create.md`
- `ADR-006-resolved-vs-redeemable.md`
- `ADR-007-math-first-phase-gates.md`
- `ADR-008-retropick-launchpad-v2-development-line.md`

Launchpad venue, quote-asset, upgradeability and operations decisions should be separate ADRs when they become implementation-binding.

If implementation requires contradicting an accepted ADR, do not work around it silently. Supersede it explicitly.
