# Working Decisions

Accepted ADRs live in `decisions/`.

Current locked decisions:

- **D-001:** Phase 1 is specification and exact reference-model work only.
- **D-002:** PRISM hackathon MVP supports non-negative exact replication, not arbitrary nonlinear payoff creation.
- **D-003:** canonical feasibility set is `C = {Gx | x >= 0}`.
- **D-004:** component-wise backing `B_i >= S*x_i` is the primary active-series invariant.
- **D-005:** backing collateral is separate from LP inventory and fees.
- **D-006:** production Solidity derives from MATH-1, never the reverse.
