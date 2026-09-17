# Failure Modes and Kill Criteria

## KILL-01 Unbacked mint

Any valid user/action sequence can make `B_i < S*x_i`.

Result: MATH-1 FAIL.

## KILL-02 Over-redemption

A holder can redeem more than the proportional or final entitlement.

Result: MATH-1 FAIL.

## KILL-03 Double backing

One backing allocation can satisfy multiple independent liabilities.

Result: MATH-1 FAIL.

## KILL-04 Terminal insolvency

An admitted exact-replication series becomes insolvent in a valid terminal world.

Result: MATH-1 FAIL.

## KILL-05 Illegal lifecycle path

A reachable transition permits mint after final resolution, mutable payout semantics, or underfunded `REDEEMABLE`.

Result: MATH-1 FAIL.

## KILL-06 Precision extraction

Repeated legal operations can extract positive value beyond the documented rounding bound.

Result: redesign precision policy.

## KILL-07 False replication acceptance

The admission engine accepts `h` when no non-negative exact solution to `Gx=h` exists in the canonical numeric domain.

Result: MATH-1 FAIL.

## KILL-08 Market thesis failure

Creation/redemption cannot economically constrain substantial mispricing under reasonable simulated/live frictions.

Result: protocol accounting may remain safe, but market thesis is `CONDITIONAL` or rejected. This is not automatically a solvency failure.

## Operational risks for later phases

- stale exchange orders at resolution;
- source/oracle dispute delay;
- bridge/custody mismatch for external assets;
- insufficient Kuru depth;
- LP adverse selection;
- settlement funding delay;
- ERC-20 non-standard behavior;
- admin key compromise.
