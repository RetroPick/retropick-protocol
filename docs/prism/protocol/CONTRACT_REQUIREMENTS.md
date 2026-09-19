# Contract Requirements Derived from MATH-1

**Status:** CANONICAL DESIGN REQUIREMENTS  
**Implementation authorization:** production Solidity remains blocked until `MATH-1` closes with `PASS` or an explicitly accepted `CONDITIONAL_PASS` whose unresolved items are outside protocol accounting.

These requirements are downstream of `PRISM_PROTOCOL_SPEC.md`, `MATH_MODEL.md`, `INVARIANTS.md`, and `STATE_MACHINE.md`. Contract code must implement those semantics; contract code must not redefine them.

---

## CR-01 Separate native markets from PRISM

RetroPick native prediction markets and PRISM series are different financial objects.

Native market contracts own:
- event definition and immutable `ResolutionSpec`;
- complete-set collateralization;
- YES/NO issuance;
- YES/NO merge;
- native resolution and redemption.

PRISM contracts own:
- structured-series definition;
- component basket `x`;
- structured backing custody/accounting;
- structured mint/burn;
- partial/final settlement.

Creating a binary market must not invoke the PRISM spanning engine.

---

## CR-02 Immutable activated series definition

After activation, the following are immutable for a series generation:
- component token identity;
- component ordering;
- `unitsPerShare` / replication vector `x`;
- replication hash;
- payoff derivation/hash;
- settlement asset;
- maturity/mint cutoff;
- canonical resolution references;
- precision domain.

Mutation requires a new series generation, never an in-place economic rewrite.

---

## CR-03 No BackingMirror in Metropolis Phase 1

Same-chain PRISM backing is authoritative in the Monad `PrismBackingVault` and its series-scoped accounting.

The Phase-1 mint path MUST NOT depend on:
- an oracle-fed backing mirror;
- Merkle roots of same-chain balances;
- CRE attestations of same-chain vault state;
- external-chain custody proofs.

A future external-asset adapter may introduce bridge/custody proofs under a separate ADR and threat model.

---

## CR-04 Runtime backing check is component-wise

For each component `i`:

```math
B_i \ge Sx_i
```

must hold for outstanding supply `S`.

For mint quantity `Q`, the contract computes the post-mint requirement:

```math
required_i = (S+Q)x_i
```

and rejects mint unless every component has sufficient series-scoped backing.

The contract MUST NOT enumerate all terminal worlds during every mint in Phase 1. Exact replication is an admission-time property; component solvency is the runtime property.

---

## CR-05 Back-first mint ordering

A successful primary creation MUST execute semantically as:

```text
validate ACTIVE
-> compute required components
-> receive/allocate all backing
-> verify post-deposit component invariant
-> update reserved accounting
-> mint PRISM
```

Supply may never increase before the required backing is irrevocably allocated to that liability within the transaction/state transition.

Partial acquisition of a multi-leg basket must not authorize a partial PRISM mint unless the series explicitly defines such a quantity and all corresponding component requirements are satisfied.

---

## CR-06 Reserved units cannot be double pledged

The same ERC-20 token type may back many series.

The forbidden condition is double allocation of the same balance units.

Accounting must therefore prove, directly or by series-isolated custody, that:

```text
allocated backing unit -> at most one outstanding liability allocation
```

Phase 1 should prefer simple series-scoped aggregate balances over per-mint BackingLots unless provenance is needed for a concrete requirement.

---

## CR-07 Pre-resolution redemption is liability-first

Where lifecycle rules permit in-kind redemption:

```text
burn/decrease Q liability
-> decrease reserved requirement by Q*x_i
-> release Q*x_i component units
```

The implementation must be reentrancy-safe and must preserve:

```math
B_i' \ge S'x_i
```

for every component.

---

## CR-08 Partial-resolution transformation must preserve payoff

A resolved component may be transformed into settlement collateral only if the transformation preserves every remaining payoff obligation.

No transformation may:
- increase user liability without funding it;
- release value needed by unresolved supply;
- rely on a non-final result;
- silently change the series payoff function.

The reference model must contain deterministic fixtures for each supported transformation before Solidity enables it.

---

## CR-09 Final resolution is one-time

Final resolution must bind one canonical terminal outcome/payout for a series generation.

The contract must reject:
- duplicate finalization;
- changing a final payout after finalization;
- returning from a terminal lifecycle state to an issuance state.

Resolution authority and source verification are separate from backing accounting.

---

## CR-10 `RESOLVED` is not `REDEEMABLE`

`RESOLVED` means the final payout `R` is known.

`REDEEMABLE` means the protocol is actually funded for all outstanding final claims.

Before entering `REDEEMABLE`, enforce:

```math
SettlementBalance \ge OutstandingSupply \times FinalPayout
```

within the accepted fixed-point policy.

Final redemption burns liability and transfers exactly the deterministic entitlement subject only to documented rounding.

---

## CR-11 Native complete-set conservation

For each fully collateralized binary native market, split/merge semantics must preserve the complete-set relation.

Conceptually:

```text
1 collateral -> 1 YES + 1 NO
1 YES + 1 NO -> 1 collateral
```

subject to explicit token decimals and fees.

Protocol accounting must make collateral locked, YES supply, and NO supply reconcilable. Open-interest analytics must not double-count YES+NO as two independent collateral sets.

---

## CR-12 Precision policy is a protocol surface

Before Solidity implementation, define:
- unit scale for series supply;
- scale for `x_i`;
- multiplication/division ordering;
- round-up locations for backing requirements;
- round-down locations for user payouts where unavoidable;
- dust owner/account;
- maximum per-operation error;
- maximum cumulative error under adversarial repetition.

Backing requirements should bias toward solvency. Any rounding policy that permits repeatable positive-value extraction fails `MATH-1`.

The Python `Fraction` model is the semantic source; fixed-point fixtures define allowed implementation deviation.

---

## CR-13 Retail trade and primary creation are separate APIs

Secondary purchase:

```text
user -> Kuru PRISM/quote market -> existing PRISM changes owner
```

Primary creation:

```text
creator/AP/market maker -> supply exact components -> mint new PRISM
```

The contracts and application APIs must not conflate these actions.

Recommended application boundary:
- `POST /markets` for native market creation;
- `POST /series` for PRISM admission/creation;
- `POST /series/{id}/create` for primary PRISM creation;
- exchange order flow for normal PRISM trading.

---

## CR-14 Events must support independent reconstruction

Future contracts should emit sufficient data to reconstruct:
- native market definition and resolution reference;
- complete-set split/merge;
- series definition;
- component backing deposits/releases;
- PRISM mint/burn;
- lifecycle changes;
- component transformations;
- resolution;
- settlement funding;
- final redemption.

Indexers are derived read models, not accounting authorities.

---

## CR-15 Authorization boundaries

Admin/pause authority must not permit:
- arbitrary supply creation;
- withdrawal/seizure of reserved backing while liabilities exist;
- activated payoff mutation;
- duplicate finalization;
- marking underfunded claims `REDEEMABLE`;
- bypassing the immutable `ResolutionSpec`.

Pause authority may stop new risk creation while preserving user exit paths that remain safe.

---

## CR-16 Differential and invariant testing

Every economically important Solidity transition must be testable against the Python reference model.

Required comparison fields include:
- total supply;
- per-component backing;
- required backing;
- released backing;
- lifecycle state;
- final payout;
- settlement balance;
- redemption amount.

Foundry invariant tests must continuously assert the canonical invariants after arbitrary valid/adversarial action sequences.

---

## CR-17 Explicit non-goals

Phase-1 contracts MUST NOT implement by implication:
- arbitrary nonlinear StatePool claims;
- approximate replication;
- trustless cross-chain wrappers;
- an internal price oracle for mint solvency;
- market-maker profitability guarantees;
- exchange-price pegs.

Those require separate specs, ADRs, and gates.
