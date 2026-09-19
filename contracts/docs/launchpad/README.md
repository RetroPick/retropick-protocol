# RetroPick Launchpad Solidity Documentation

**Status:** ACTIVE  
**Owner:** Smart Contracts  
**Authority:** Implementation-level specification subordinate to `docs/launchpad/03-protocol/`.

This directory documents how RetroPick V1 and V2 Solidity implement launchpad semantics: contract responsibilities, storage, access control, ABI/events, curve accounting, fee accounting, graduation, invariants, security and deployment.

## Version policy

V1 is stable/reference. V2 is active development.

## Core contract responsibilities

- Factory: launch configuration, orchestration and lifecycle ownership.
- Deployer: deploy token/curve pairs while controlling factory bytecode size.
- Launch token: fixed/capped ERC-20 representation.
- Bonding curve: primary buy/sell and reserve/fee accounting.
- Graduation guard/executor: preflight and transition into mature market infrastructure.
- Buyback vault / fee components: isolated fee-side accounting.
- Hook/locker components: venue-specific post-graduation behavior where enabled.

Protocol requirements live in `../../../docs/launchpad/03-protocol/`; this directory must not redefine them.
