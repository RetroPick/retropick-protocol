# PRISM P0 specification

Status: FROZEN_SCOPE_DRAFT; exact-lot executable candidate added 2026-09-29

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

The implementation candidate reduces each fraction to coprime `n_i/d_i`, then
sets `lotSizeRaw = lcm(d_1, ..., d_m)`. A valid `q = k * lotSizeRaw` therefore
has exact component amount `k * (lotSizeRaw/d_i) * n_i`. Conversely, since each
`n_i/d_i` is reduced, integrality for every component requires every `d_i` to
divide `q`, so this LCM is the smallest valid raw lot. P0 bounds reduced
numerators and denominators to `uint64` and total PRISM supply and lot size to
`uint128`; dividing by `d_i` before multiplying by `n_i` keeps the exact
component amount below `2^192` and within `uint256`.

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

The Hackathon `PrismFactoryP0` instance is deployed against one approved
`PredictionFactoryP0`; every series it creates uses that same factory. Each
series creator is fixed at factory deployment and only that address can admit
series. Each series records immutable payoff and replication hashes plus a
deterministic source-set hash. The hashes identify the reviewed off-chain
certificate; the P0 kernel does not solve or recheck arbitrary replication
systems onchain. The creator must independently exact-recheck the certificate
before admitting a series. `PrismSeriesP0` construction is callable only by the
factory passed into its constructor, and that factory must report the same
bound `PredictionFactoryP0`. A direct constructor call cannot bypass the
pinned-creator check or receive canonical `isSeries` registration.

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

Mint and redemption reject `address(this)` as receiver so callers cannot
accidentally strand PRISM claims or redeemed components at the series contract.
Component out-transfers verify both the exact series debit and exact receiver
credit.

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

## Executable candidate and evidence

- Python oracle: `research/hackathon-p0/models/prism_p0.py`.
- Solidity research kernel: `research/contract-kernels/src/hackathon/PrismSeriesP0.sol`.
- Exact fixture: `research/hackathon-p0/fixtures/prism_p0_exact_lot.json`.
- Unit and adversarial tests: `research/contract-kernels/test/hackathon/PrismP0.t.sol`.
- Stateful handler: `research/contract-kernels/test/hackathon/PrismP0Invariant.t.sol`.

The kernel admits only outcome tokens whose market is registered by the
configured `PredictionFactoryP0`, whose market uses that factory's one approved
collateral, and whose token/market report the P0 version and common decimals.
It provides atomic caller-funded `mint(q, receiver)` and transferable in-kind
`redeemInKind(q, receiver)`. It has no public deposit, cash settlement,
settlement cursor, or surplus sweep method. This remains a research candidate;
it is not production PRISM Solidity.
