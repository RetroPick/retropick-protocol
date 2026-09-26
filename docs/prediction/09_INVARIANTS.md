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

The Foundry invariant `invariant_preResolutionConservation` covered split and merge only. It did not walk resolution. Classification: EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN for the Python search with `max_unit = 3`. The Foundry run is a stateful fuzz of issuance, not a proof of P-I08 after every resolution path. Resolution paths are covered by unit and fuzz tests, not by that invariant.
