# Invariants P-I01 through P-I10

Checked by `research/prediction-model/invariants.py` after successful operations, and by the Foundry tests where noted.

| ID | Statement | Where enforced |
|---|---|---|
| P-I01 | Supplies, balances, and collateral are non-negative and supplies match balances | reference `check_market` |
| P-I02 | In OPEN, LOCKED, and RESOLUTION_PENDING, YES supply = NO supply = collateral locked | reference model; Foundry invariant while issuance is open |
| P-I03 | Split only in OPEN, equal mint | `split` |
| P-I04 | Merge only in OPEN or LOCKED, equal burn, equal collateral out | `merge` |
| P-I05 | Spec hash immutable after activation | no setter; `try_replace_spec` reverts in the model |
| P-I06 | One result, only from RESOLUTION_PENDING, only by the resolver | `resolve` |
| P-I07 | Redeem only in REDEEMABLE and only up to the holder's balance | `redeem` |
| P-I08 | Collateral locked >= liability | reference check; integer cursor includes residual after archive |
| P-I09 | No admin mint. Kernel mint/burn is `only` the market | `admin_mint` reverts; `OutcomeToken.mint` reverts for other callers |
| P-I10 | No withdrawal that drops collateral below liability. Residual moves only on archive at zero supply | `admin_withdraw` reverts; `archive` |

Python `research/prediction-model/invariant_ids.py` runs one positive case and one rejecting case for each id. Classification on those scenarios: EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN. That is not a uint256 proof.

Foundry `PredictionInvariantIdsTest` encodes P-I01 through P-I10 for operations the kernel has. The cancelled-draft branch of P-I05 is NOT_YET_VALIDATED in the kernel because `cancelDraft` does not exist. The immutable `resolutionSpecHash` branch is tested.

`invariant_preResolutionConservation` checks P-I01 and P-I02 while the state is OPEN, LOCKED, or RESOLUTION_PENDING. Handlers are split, merge, closeMint, and beginResolution. The 2026-09-26 `forge test` run was 256 runs, 128000 calls, 48023 handler reverts, and the invariant held. It still does not walk redemption. Redemption is in `test_P_I07`, `test_P_I08`, and `test_P_I10`.
