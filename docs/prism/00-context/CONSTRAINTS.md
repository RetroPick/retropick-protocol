# Constraints

1. Back first, mint second.
2. No arbitrary owner mint.
3. No backing collateral used as LP inventory or fees.
4. Phase-1 replication weights are non-negative.
5. Desired payoff must be exactly replicable within the accepted fixed-point domain.
6. Arbitrary nonlinear payoffs are out of scope.
7. Resolution semantics must not be mutated after activation.
8. Simulation does not prove live market liquidity or adoption.
9. Production Solidity is gated on MATH-1.
