# Phase-1 candidate series architecture

**Status:** PROPOSED  
**Contingent on:** human acceptance of ADR-R03. That acceptance is not granted.  
**Solidity:** a candidate settlement kernel is in `research/contract-kernels/src/prism/CandidateCumulativeSettlement.sol`. It implements only the global-cursor redeem from `cumulative_settlement.py`. It is not this series, not MATH-1 PASS, and not a v2 promotion. The series token, mint path, and component vault are still not written. `contracts/src/v2/` is unchanged. ADR-R07 still stops a settlement port.  
**Math:** this file does not restate canonical theorems. Settlement rounding is the candidate in `research/prism-model/cumulative_settlement.py`. Canonical `FixedPointSettlement.redeem` stays the failing per-call rule.

Canonical diagrams that name a separate vault are not amended here.

## Scope

One boring series generation:

- immutable component list and non-negative weights;
- backing tokens are standard ERC-20s;
- backing is received before series tokens are minted;
- pre-resolution release uses the component requirement delta (ceil in, delta out);
- final redemption uses one global redeemed cursor;
- a per-holder cursor is forbidden;
- exact ceil funding leaves residual 0 or 1 after the whole supply is redeemed;
- the contract is not upgradeable.

A prediction outcome token is not a series token. Kuru balances are not backing.

## `PrismSeries`

The series contract is the backing controller and the only minter of its token.

### Why

One contract can enforce "deposit, then mint" and the global redemption cursor without a second vault whose balances could diverge.

### Storage

| Field | Meaning |
|---|---|
| `settlementAsset` | ERC-20 paid at final redemption. Immutable |
| `components` | Ordered component token addresses. Immutable |
| `weightWad` | Non-negative weight per component. Immutable |
| `supply` | Outstanding series units |
| `backing` | Series-scoped raw balance accounted per component |
| `requirement` | Ceil requirement currently reserved per component |
| `payoutWad` | Final payout. Zero until final resolution |
| `redeemedUnits` | Global cursor. Not stored per holder |
| `paidRaw` | Settlement asset already paid |
| `state` | `DRAFT`, `OPEN`, `LOCKED`, `RESOLVED`, `REDEEMABLE`, `ARCHIVED` |
| `resolver` | Address allowed to set the final payout once. Immutable |

Holder balances live on `PrismSeriesToken`, not in a second map here.

### Structs

`Component { token, weightWad }` is constructor input only. After construction the parallel arrays are immutable.

### Functions

| Function | Who | Effect |
|---|---|---|
| `activate` | factory | `DRAFT` to `OPEN` |
| `mint(to, quantity)` | user | Pull the ceil requirement delta for every component, then mint |
| `redeemComponents(quantity)` | holder, before final payout | Burn, then release the requirement delta |
| `resolve(payoutWad)` | resolver, once, from `LOCKED` | Store the payout. Do not move backing |
| `fundSettlement()` | anyone | Pull settlement asset up to the ceil funding target |
| `openRedemption()` | anyone | `RESOLVED` to `REDEEMABLE` only if the settlement balance covers the ceil target |
| `redeem(quantity)` | holder, in `REDEEMABLE` | Pay `floor((R+q)*payout/D) - floor(R*payout/D)` and advance the global cursor |
| `archive()` | anyone | Only at zero supply. Transfer residual settlement asset to the immutable dust sink |

`redeem` must not keep a cursor per holder. Two 1-unit redemptions of payout `10^18-1` with 18 settlement decimals pay 1 in total, not 0.

### Access control

Users mint and redeem their own token balances. The resolver sets the payout once and cannot mint, cannot withdraw live backing, and cannot change weights. There is no owner withdraw of reserved backing. There is no pause of final redemption.

### Events

`Activated`, `Minted(to, quantity)`, `ComponentsReleased(account, quantity)`, `Resolved(payoutWad)`, `SettlementFunded(amount)`, `RedemptionOpened`, `Redeemed(account, quantity, payout)`, `Archived(residual)`.

### Errors

`BadState`, `NotResolver`, `ZeroAmount`, `Shortfall`, `Underfunded`, `InsufficientBalance`, `PayoutAlreadySet`, `PerHolderCursorForbidden` is not a runtime mode. The code path does not exist.

### Dependencies

Standard ERC-20 `transferFrom` measured by balance delta. The series token. No prediction market interface. No Kuru router.

### Invariants

- For each component, accounted backing is at least the ceil requirement of the outstanding supply.
- Mint increases supply only after the balance delta covers the requirement increase.
- Sum of global-cursor redemptions equals `floor(supply * payout / D)` when the whole supply is redeemed.
- If funding started at the ceil target, residual after that redemption is 0 or 1, plus any later donation. Donation is not holder value created by the cursor.
- A single redemption pays the isolated floor or one more.
- `RESOLVED` does not pay. `REDEEMABLE` does.

### Attack surface

See the threat section below. The canonical per-call floor is not an allowed implementation of `redeem`.

### Upgrade policy

Immutable. No proxy, no beacon, no setter for weights, components, settlement asset, resolver, or the redemption formula.

## `PrismSeriesToken`

### Why

Holders need a transferable ERC-20. ADR-R05 is still a proposal. This token is the liability container, not the backing.

### Storage

`series` immutable. `decimals` immutable, copied from the settlement asset at construction. Name and symbol immutable. Standard ERC-20 balances and allowances.

### Structs

None beyond ERC-20.

### Functions

`mint` and `burn` callable only by `series`. Users get `transfer`, `approve`, and `transferFrom`.

### Access control

`onlySeries`. No owner mint.

### Events

ERC-20 `Transfer` and `Approval`.

### Errors

`NotSeries`.

### Dependencies

The series contract address, fixed in the constructor.

### Invariants

`totalSupply` equals `PrismSeries.supply`. Users cannot mint.

### Attack surface

A second minter, a clone initializer, or an upgradeable token would move liability without backing. Those shapes are out of this proposal.

### Upgrade policy

Immutable. No initializer.

## Threats

Severity is the original program scale. Open High and Critical items stay open. This section is not an admission claim and not an audit.

| ID | Severity | Issue | Status |
|---|---|---|---|
| S-R1 | Critical | Mint series tokens before backing is reserved | Open. Spec requires deposit-then-mint. No Solidity enforces it yet |
| S-R2 | Critical | Ship `FixedPointSettlement.redeem` per-call floor (`CX-FP-SETTLEMENT-001`) | Open. Canonical MATH-1D is FAIL. The candidate is not accepted |
| S-R3 | Critical | Per-holder redemption cursor | Open as a forbidden design. The negative control pays 0 on the original case |
| S-R4 | High | Sweep residual that still belongs to holders | Open under the canonical rule, where fragmented redemptions leave dust 2. The candidate kernel pays the cumulative delta. On the original fixture the residual is 1. The series dust sink is still not implemented |
| S-R5 | High | Fee-on-transfer or rebasing component credited at nominal amount | Open. Spec requires a balance-delta check. Not implemented |
| S-R6 | High | Treating a prediction resolution, a Kuru price, or an indexer row as settlement funding | Open. Those are not backing |
| S-R7 | Medium | Order of redemptions moves a carry between holders | Recorded on the candidate. Aggregate paid still matches the one-shot floor. Not dust capture |
| S-R8 | Medium | Donated settlement asset left in the contract | Residual can exceed 1. The 0-or-1 bound is only against exact ceil funding |
| S-R9 | Low | Adding an upgrade admin later | Out of policy. This spec is immutable |
| S-R10 | Informational | Kuru `calculatePrecisions` examples are not series parameters | Worksheet rows for a series book are BLOCKED |

No threat above is closed by this document. The candidate settlement kernel does not close any row in this table.
