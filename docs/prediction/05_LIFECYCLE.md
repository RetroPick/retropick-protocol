# Lifecycle

Canonical names from `docs/prism/protocol/STATE_MACHINE.md`. Aliases used by the task program are recorded and are not a rename.

| Canonical | Alias | Allowed | Forbidden | Authority |
|---|---|---|---|---|
| DRAFT | | activate, cancel to ARCHIVED | split, resolve | factory activates |
| OPEN | ACTIVE | split, merge, transfer | spec edits, resolve | holders split/merge; resolver closes |
| LOCKED | MINT_CLOSED | merge, transfer | split | resolver begins resolution |
| RESOLUTION_PENDING | | transfer | split, merge, payout | resolver commits one result |
| RESOLVED | | prepare redemption | redeem | anyone may open redemption if funded |
| REDEEMABLE | | redeem, burn worthless, archive when flat | split, second result, pause | holders |
| ARCHIVED | | read | all economic writes | terminal |

Cancel before activation is `DRAFT -> ARCHIVED` with reason `CANCELLED_BEFORE_ACTIVATION`. There is no resurrection.

`openRedemption` is permissionless so the resolver cannot pause winners. `pause_redemption` raises in the reference model. The kernel has no pause.

The older `research/prism-model/native_market.py` machine (ACTIVE, RESOLVED, ARCHIVED, redeem inside RESOLVED) does not implement this table. It remains a reduced oracle. New prediction work uses this table.
