# Architecture Decision Records

Status: `PROPOSED`, `ACCEPTED`, `SUPERSEDED`, `REJECTED`.

## Accepted

- ADR-001 through ADR-007: Prediction/PRISM Phase-1 semantics/gates.
- `ADR-008-retropick-launchpad-v2-development-line.md`: V1 stable/reference, V2 active Launchpad line.

## Proposed Launchpad decisions

- `ADR-009-kuru-default-launchpad-graduation-venue.md`
- `ADR-010-same-quote-graduation.md`
- `ADR-011-launchpad-quote-asset-policy.md`
- `ADR-012-doorway-excluded-from-launchpad-p0.md`
- `ADR-013-launchpad-typescript-workspace.md`
- `ADR-014-launchpad-backend-runtime.md`
- `ADR-015-launchpad-indexer-provider.md`
- `ADR-016-launchpad-wallet-auth.md`
- `ADR-017-launchpad-metadata-storage.md`
- `ADR-018-launchpad-admin-key-model.md`
- `ADR-019-launchpad-non-upgradeability.md`
- `ADR-020-v4-retirement-after-kuru-proof.md`
- `ADR-021-kuru-market-parameter-policy.md`

PROPOSED means agents must not treat the choice as binding implementation authority. Accept or supersede explicitly.

## Proposed Prediction / PRISM research decisions (2026-09-26)

These files are proposals from the research-to-contract program. They do not supersede ADR-001 through ADR-007.

- `ADR-P01` through `ADR-P07`: prediction token, decimals, custody, lifecycle, INVALID rounding, collateral, resolution hash.
- `ADR-P08`: false-return collateral before activation. PROPOSED. Acceptance is not granted. The kernel was not edited.
- `ADR-P09`: `collateralLocked` is not the rebasing token balance. PROPOSED. Acceptance is not granted. The counterexample stays `COUNTEREXAMPLE_FOUND`. The kernel was not edited.
- `ADR-P10`: native redeem stays outside prediction RESOLVED. PROPOSED. Acceptance is not granted. Contradiction 2 stays open. Neither redeem function was edited.
- `ADR-R01` through `ADR-R07`: replication confirmation, component rounding, settlement-floor failure, ERC-20 backing boundary, series token shape, isolation, Solidity stop.
- `ADR-R08`: `backingRaw` is not the rebasing component token balance. PROPOSED. Acceptance is not granted. The counterexample stays `COUNTEREXAMPLE_FOUND`. The kernel was not edited.
