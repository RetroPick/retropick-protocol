# Prediction P0 specification

Status: FROZEN_SCOPE_DRAFT

Prediction P0 is a deliberately narrow binary market profile for the hackathon.
It does not change the production Prediction contract gate.

## Result domain

Allowed terminal results:

- `YES_WIN`
- `NO_WIN`

Excluded:

- `INVALID`
- half payout;
- cancelled payout;
- arbitrary payout numerator;
- fallback value for ambiguous questions.

If a question cannot be resolved YES or NO, the market remains unresolved.

## Collateral admission

P0 admits exactly one named collateral asset per hackathon environment. The
asset must be qualified before use:

- standard ERC-20 transfer and transferFrom behavior;
- exact balance deltas on inbound and outbound transfers;
- non-rebasing;
- no fee-on-transfer;
- not callback-capable under the P0 assumptions;
- fixed known decimals;
- collateral address is not the resolver;
- collateral address is not an admin or factory authority.

The preferred implementation is factory-level allowlisting. Arbitrary token
constructor input is outside the P0 domain.

Live Kuru/Monad addresses must be verified from current official sources before
testnet deployment. Old reports are not sufficient address authority.

## Lifecycle

Allowed lifecycle:

| State | Meaning | Enabled financial actions |
| --- | --- | --- |
| `DRAFT` | Market exists, issuance unavailable | none |
| `OPEN` | Complete-set issuance and merge enabled | split, merge |
| `LOCKED` | New split disabled; complete sets may still be closed | merge |
| `RESOLVED` | Winner committed exactly once | open redemption only |
| `REDEEMABLE` | Winning outcome redemption enabled | redeem winner |
| `ARCHIVED` | No live liability | none |

No transition may resurrect issuance after `LOCKED`.

## Issuance

For a split of `q` raw collateral units:

1. Require `state == OPEN`.
2. Require `q > 0`.
3. Require `currentSupply + q <= MAX_OUTCOME_SUPPLY`.
4. Snapshot collateral balance.
5. Pull exactly `q` collateral from the caller.
6. Verify exact physical receipt.
7. Re-check lifecycle state after the external token call.
8. Increase locked/accounted collateral by `q`.
9. Mint exactly `q` YES and `q` NO to the caller.

No one-sided mint, admin mint, creator mint, or arbitrary token mint exists.
Outcome ERC-20 balances are transferable in every lifecycle state. Transfer
moves the holder's claim and does not change aggregate supply, collateral, or
liability. YES and NO balances can move independently; only a holder with both
sides may merge a complete set.

## Arithmetic domain

P0 uses an explicit inventory bound:

```text
MAX_OUTCOME_SUPPLY = type(uint128).max
```

All supply-increasing paths must enforce:

```text
currentSupply + q <= MAX_OUTCOME_SUPPLY
```

Checked overflow is not the domain definition. Boundary tests must cover:

- 0;
- 1;
- 2;
- `MAX_OUTCOME_SUPPLY - 1`;
- `MAX_OUTCOME_SUPPLY`;
- `MAX_OUTCOME_SUPPLY + 1` rejects before state change.

## Winner redemption

No binary winner payout may multiply by two and divide by two.

For `YES_WIN`:

- YES holder burns `q` YES.
- Holder receives exactly `q` collateral.
- NO holder receives zero.
- Liability is remaining YES supply.

For `NO_WIN`:

- NO holder burns `q` NO.
- Holder receives exactly `q` collateral.
- YES holder receives zero.
- Liability is remaining NO supply.

Second redemption of the same balance cannot double pay.

## Callback and lifecycle defense

The historical callback witness `CX-PRED-CALLBACK-RESOLVER-001` must reject in
P0 with no state change and no post-resolution mint. Required defenses:

- fixed admitted collateral;
- collateral != resolver;
- shared reentrancy/transition protection on financial and lifecycle calls;
- state recheck after collateral transfer before outcome mint.
