# Prediction reference model

Exact and integer semantic oracle for a binary, fully collateralized prediction market.

This model is not production Solidity and it does not amend accepted ADRs. Canonical lifecycle names come from `docs/prism/protocol/STATE_MACHINE.md`. The task names ACTIVE and MINT_CLOSED are aliases of OPEN and LOCKED.

## Phase-1 economics

Before resolution, with zero fees:

```text
split(q) : collateral += q, YES += q, NO += q
merge(q) : the inverse, only while OPEN or LOCKED
YES_supply = NO_supply = CollateralLocked
```

Resolution results:

| Result | YES payout | NO payout |
|---|---|---|
| YES_WIN | 1 | 0 |
| NO_WIN | 0 | 1 |
| INVALID | 1/2 | 1/2 |

`RESOLVED` freezes the result. `REDEEMABLE` is a separate state entered only after `collateral >= liability`.

Integer INVALID redemptions use a cumulative floor:

```text
paid(R) = floor(R / 2)
this redemption = paid(R_before + q) - paid(R_before)
```

When supplies equal collateral `C`, full redemption of both sides leaves dust `C mod 2`. Paying `ceil(q/2)` on both sides is insolvent for `q = 1`. Paying `floor(q/2)` independently on every 1-unit call strands the entire payout.

Only standard ERC-20 collateral is admitted. Fee-on-transfer, rebasing, ERC-777, and false-return tokens are rejected at construction. A shortfall between the amount credited and the amount received is rejected inside `split`.

## Run

```bash
cd research/prediction-model
python3 -m unittest discover -s tests -v
```

Python 3.12 standard library only. Do not use float equality as protocol truth.
