# Contract Requirements Derived from MATH-1

**Status:** design requirements only; not authorization to implement production Solidity.

## CR-01 Series definition

Contract representation must make component identity and `unitsPerShare` immutable after activation.

## CR-02 Mint ordering

`mint(Q)` must:
1. normalize units;
2. compute post-mint requirement;
3. verify backing allocation;
4. update reserved backing;
5. mint only after checks.

## CR-03 Redemption ordering

Pre-resolution in-kind redemption must burn/decrease liability before external transfer and be reentrancy-safe.

## CR-04 Backing reservation

Backing accounting must be series-scoped or otherwise prove non-double-use.

## CR-05 Finalization

Resolution must be one-time and bind the canonical final payout.

## CR-06 Settlement gate

A series cannot enter `REDEEMABLE` until funded settlement covers all outstanding liabilities.

## CR-07 Precision

Solidity fixed-point policy must define:
- scale;
- multiplication/division order;
- round direction;
- dust ownership;
- maximum cumulative error.

The Python `Fraction` model is the semantic reference; deterministic fixed-point fixtures will define acceptable deviations.

## CR-08 Events

Future contracts should emit enough data to reconstruct:
- series definition;
- backing deposits/releases;
- mints/burns;
- lifecycle changes;
- resolution;
- settlement funding;
- final redemption.

## CR-09 Differential tests

For every generated fixture, Solidity must match the reference model within the accepted integer tolerance.

## CR-10 Authorization boundary

Admin/pause authority must not permit:
- arbitrary supply creation;
- backing seizure while liabilities exist;
- payoff mutation;
- duplicate finalization.
