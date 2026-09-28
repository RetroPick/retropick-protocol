# PRISM P0 specification

Status: FROZEN_SCOPE_DRAFT

PRISM P0 is exact-backed, long-only, transferable, and redeemable in kind. It is
not the production PRISM settlement design and does not change PRISM `MATH-1`.

## Excluded paths

PRISM P0 has no:

- final cash settlement;
- global settlement cursor;
- per-holder settlement cursor;
- settlement residual sweep;
- resolution-based PRISM cash payout;
- shared reservation vault;
- shared prefunding pool;
- public `deposit()` that can be consumed by another minter.

Therefore the production final-settlement counterexamples remain real but are
outside the P0 enabled path.

## Exact replication

Every admitted P0 series must satisfy:

```text
h = Gx
x >= 0
```

using exact rational arithmetic. Float tolerance, approximate replication,
probability guesses, and `P(A) * P(B)` substitutions are forbidden. The missing
interaction-term `AND(A,B)` negative control must remain.

## Exact lot semantics

Each component weight is encoded as:

```text
x_i = numerator_i / denominator_i
```

A deterministic `lotSizeRaw` is chosen so every valid mint/redeem quantity `q`
satisfies:

```text
q % lotSizeRaw == 0
q * numerator_i % denominator_i == 0
```

Component amount is exact:

```text
componentAmount_i(q) = q * numerator_i / denominator_i
```

No floor, ceil, or rounding operation may exist on the enabled mint/redeem path.

## Component scope

P0 accepts:

- 1 to 4 components;
- distinct token addresses;
- nonzero nonnegative weights;
- outcome tokens from the accepted `PredictionFactoryP0`;
- same approved Prediction P0 ecosystem;
- same qualified collateral family;
- fixed source decimal policy;
- exact rational encoding.

P0 rejects duplicate components, zero components, unqualified ERC-20s, rebasing
tokens, fee-on-transfer tokens, arbitrary external tokens, and more than four
components.

## Source admission

A component must prove it is an outcome token created by the accepted
`PredictionFactoryP0` and bind at least:

- token address;
- market;
- outcome index;
- collateral;
- decimals;
- resolution identity/spec hash if present;
- P0 semantic version.

This is a narrow hackathon trust boundary, not the production source-interface
freeze.

## Atomic mint

`mint(q, receiver)` is minter-funded and atomic:

1. Validate `q` as a lot multiple.
2. Calculate exact component amounts.
3. Snapshot physical balances.
4. Pull each component from `msg.sender`.
5. Verify exact received deltas.
6. Verify physical backing covers required backing.
7. Mint exactly `q` PRISM ERC-20 units to `receiver`.

If any component transfer is short, the whole mint reverts. A cannot
accidentally fund B's mint because there is no shared deposit pool.

## Physical backing

For every component `i`:

```text
IERC20(component_i).balanceOf(series) >= requiredBacking_i(totalSupply)
requiredBacking_i(S) = S * numerator_i / denominator_i
```

Internal accounting alone is not proof of backing.

## In-kind redemption

`redeemInKind(q, receiver)`:

1. Validates `q` as a lot multiple.
2. Calculates exact component entitlement.
3. Burns `q` PRISM units from the caller.
4. Transfers exact component amounts to `receiver`.
5. Verifies remaining physical backing.

After Prediction resolves, a PRISM holder redeems in kind to receive outcome
ERC-20s, then separately redeems the winning outcome at the Prediction market.

## Transferability

The PRISM series token is a normal transferable ERC-20 claim. Transfer moves
claim ownership, not backing. The required P0 witness is:

- Alice mints 10 lots.
- Alice transfers 6 lots to Bob.
- Bob redeems 6 lots.
- Bob receives exact underlying components.
- Alice cannot claim Bob's redeemed backing.
- Remaining physical backing covers remaining supply.

## Direct donations

Direct component transfers that make `physicalBalance > requiredBacking` are
surplus. P0 does not sweep, assign, or count them as somebody's prefunding.
They may remain stranded.
