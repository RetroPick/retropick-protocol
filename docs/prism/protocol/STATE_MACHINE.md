# Canonical Protocol State Machines

**Status:** CANONICAL  
**Scope:** RetroPick native binary markets and PRISM Phase 1

The protocol has two related but distinct state machines. Native prediction markets determine primitive YES/NO claims. PRISM series depend on those claims but have their own minting and settlement lifecycle.

---

# 1. Native RetroPick market lifecycle

```text
DRAFT
  |
  | activate immutable event + ResolutionSpec
  v
OPEN
  |
  | trading/split allowed until market cutoff
  v
LOCKED
  |
  | event window complete; canonical result pending
  v
RESOLUTION_PENDING
  |
  | resolver commits final outcome
  v
RESOLVED
  |
  | collateral/path ready for winning-claim redemption
  v
REDEEMABLE
  |
  | all liabilities satisfied / market retired
  v
ARCHIVED
```

## DRAFT

Allowed:

- define event statement;
- define outcome set;
- define collateral;
- define immutable `ResolutionSpec`;
- validate dates/cutoffs;
- cancel before activation.

Forbidden:

- user split/mint;
- public trading of protocol-issued claims;
- final resolution.

## OPEN

Allowed:

- collateral split into complete YES/NO set;
- complete-set merge where permitted;
- transfer/trading of outcome tokens;
- Kuru secondary trading.

Required:

```math
YES_{supply}=NO_{supply}=CollateralLocked
```

under canonical complete-set accounting before resolution-specific burns/redemptions.

Forbidden:

- mutation of `ResolutionSpec`;
- unilateral payout change.

## LOCKED

The market no longer accepts actions that create new event exposure after its accepted cutoff.

Allowed:

- secondary transfer/trading if the product policy permits;
- complete-set merge only if safe under the finality policy;
- progression to resolution.

Forbidden:

- new event-definition mutation;
- new complete-set issuance after cutoff.

## RESOLUTION_PENDING

The event window has ended and the protocol awaits the canonical resolver path.

Allowed:

- CRE/resolver workflow execution;
- evidence processing according to `ResolutionSpec`;
- transfers unless a separately accepted safety policy pauses them.

Forbidden:

- new split/mint;
- changing the resolution source or semantics;
- final payout before canonical result.

## RESOLVED

The terminal outcome is immutable and known.

Allowed:

- prepare settlement/redemption accounting;
- transform winning claims into settlement entitlements;
- transfers.

Forbidden:

- resolution overwrite;
- new issuance.

## REDEEMABLE

Winning-claim holders can burn/redeem for deterministic settlement according to the native market payout rule.

Losing claims may remain transferable but have zero protocol redemption value.

## ARCHIVED

No unresolved native liability remains.

No transition returns to an earlier economic state.

---

# 2. PRISM series lifecycle

```text
DRAFT
  |
  | replication accepted + activation
  v
ACTIVE
  |
  | mint cutoff / explicit issuance pause
  v
MINT_PAUSED
  |
  | source maturity / payoff-relevant resolution begins
  v
RESOLUTION_PENDING
  |
  | all payoff-relevant source outcomes final
  v
RESOLVED
  |
  | settlement-funding invariant satisfied
  v
REDEEMABLE
  |
  | outstanding supply == 0
  v
ARCHIVED
```

## DRAFT

Allowed:

- define supported components;
- choose basket mode or payoff mode;
- compute/solve replication;
- verify exact non-negative admission;
- set resolution references;
- cancel before activation.

Forbidden:

- mint user PRISM;
- activate a non-replicable payoff;
- final redemption.

## ACTIVE

Allowed:

- backing deposit/allocation;
- mint only after component backing requirements are satisfied;
- transfer;
- secondary Kuru trading;
- pre-resolution in-kind redemption.

Required:

```math
B_i\ge Sx_i\qquad\forall i
```

Forbidden:

- mutate component set or `x`;
- release allocated backing without proportional liability burn;
- count backing as LP inventory.

## MINT_PAUSED

Allowed:

- transfer;
- Kuru secondary trading;
- in-kind redemption where safe;
- payoff-equivalent partial backing transformation after a component has canonically resolved;
- progression toward resolution.

Forbidden:

- new PRISM mint.

`MINT_PAUSED` may be reached by normal cutoff or an accepted emergency policy. Emergency pause must not confiscate backing or mutate payoff semantics.

## RESOLUTION_PENDING

One or more payoff-relevant source conditions are awaiting canonical finality.

Allowed:

- resolution processing under immutable source references;
- partial-resolution transformation of canonically resolved components where payoff equivalence is preserved;
- transfers unless separately paused by an accepted policy;
- safe in-kind redemption only if remaining backing semantics make it well-defined.

Forbidden:

- new mint;
- changing `x`;
- changing source semantics;
- final payout commitment before all payoff-relevant outcomes are final.

## RESOLVED

All payoff-relevant source conditions are final and:

```math
R=h(\omega^*)
```

is immutable.

`RESOLVED` means the liability is known. It does **not** mean the cash settlement vault is necessarily funded.

Allowed:

- convert/redeem resolved backing;
- fund settlement;
- transfer PRISM.

Forbidden:

- mint;
- change `R`;
- enter `REDEEMABLE` while underfunded.

## REDEEMABLE

Entry gate:

```math
SettlementBalance\ge OutstandingSupply\times FinalPayout
```

Allowed:

- burn PRISM for deterministic final settlement;
- transfer PRISM until burned.

Every redemption must preserve sufficient settlement funding for remaining supply.

## ARCHIVED

Reached only when:

```text
outstanding PRISM supply == 0
and
no unresolved settlement liability remains
```

The historical contract/state remains queryable for auditability.

---

# 3. Partial resolution is not a separate terminal state

If only part of a PRISM basket resolves, the series generally remains economically live.

Example:

```text
pFEDBTC = 0.6 FED_YES + 0.4 BTC_NO
```

If `BTC_NO` resolves to `1` while `FED_YES` remains uncertain, the economic exposure becomes:

```text
0.6 FED_YES + 0.4 settlement cash
```

The series is not finally `RESOLVED` because FED exposure remains uncertain.

Partial-resolution transformation is an operation inside `MINT_PAUSED` / `RESOLUTION_PENDING`, not a shortcut to final payout.

---

# 4. Exchange trading versus lifecycle

The protocol state does not require an external Kuru market contract to disappear.

A token may remain technically tradable after `RESOLVED` or `REDEEMABLE`.

The economic meaning changes:

```text
before final resolution -> uncertain event-linked asset
after final resolution  -> fixed redemption claim
```

A zero-payout claim may still be transferable but has zero protocol redemption value.

The RetroPick UI should remove resolved series from active discovery and make redemption the primary action while still allowing users to inspect external trading venues.

---

# 5. Illegal transitions

At minimum the following are forbidden:

```text
RESOLVED -> ACTIVE
REDEEMABLE -> ACTIVE
ARCHIVED -> ACTIVE
ARCHIVED -> RESOLVED
DRAFT -> REDEEMABLE
```

No state transition may:

- re-enable mint after terminal resolution;
- mutate a final outcome;
- reduce required backing without a corresponding liability reduction;
- enter final redemption while settlement is underfunded.
