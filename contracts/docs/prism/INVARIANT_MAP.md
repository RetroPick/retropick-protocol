# PRISM Contract Invariant Map

**Status:** TARGET VALIDATION MAP

Canonical invariants live in `../../../docs/prism/protocol/INVARIANTS.md`.

## Native prediction

- split mints both YES and NO;
- merge burns equal complementary claims;
- collateral, YES supply and NO supply reconcile while active;
- final resolution is immutable.

## PRISM

- `h = Gx` is fixed at admission;
- component identity and `x_i` are immutable after activation;
- `B_i >= S*x_i` for every component;
- no supply increase before required backing is allocated;
- no reserved balance unit backs two liabilities;
- partial transformations preserve payoff obligations;
- final settlement is fully funded before redeemability;
- final redemption preserves funding for remaining supply;
- lifecycle transitions are monotonic.

Every mutable Solidity path must be covered by unit/fuzz/stateful invariant or differential evidence as appropriate.
