# Collateral and solvency

Phase 1 admits one explicitly approved standard ERC-20. Construction of the reference market rejects fee-on-transfer, rebasing, ERC-777, and false-return classes. The kernel enforces the balance-delta check, which is the on-chain form of the fee-on-transfer rejection. Rebasing that changes the balance without a protocol call is outside the model; a downward rebase breaks `collateral >= liability`. Classification of "rebasing collateral is safe": COUNTEREXAMPLE_FOUND if the protocol credits a snapshot and the token later reduces the balance.

## Liability

| Result | Exact liability | Integer liability |
|---|---|---|
| before resolution | `CollateralLocked` | same |
| YES_WIN | `YES_supply` | `YES_supply` |
| NO_WIN | `NO_supply` | `NO_supply` |
| INVALID | `(YES_supply + NO_supply) / 2` | remaining cumulative floor obligation |

P-THEOREM-3 checks the three results on a 9-unit integer market and is labeled PROVEN for that construction. The exhaustive search (`max_unit = 3`, 208 states, 522 successful transitions, 0 failures, 0.087s) is EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN, not a proof for every `uint256`.

After a YES redemption and a partial worthless burn, YES supply and NO supply differ while liability still holds. P-THEOREM-7 is PROVEN as a counterexample to "supplies stay equal after redemption."
