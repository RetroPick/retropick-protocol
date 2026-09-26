# Token schema

## Models

| Model | Shape | Phase-1 disposition |
|---|---|---|
| A | Two full ERC-20 contracts | Implemented in `research/contract-kernels`. Proposed by ADR-P01 |
| B | ERC-1167 clones of one implementation | Not implemented. Initializer replay remains an open attack |
| C | Beacon / upgradeable proxy | Rejected for Phase 1. Financial semantics should be immutable |

The kernel's `OutcomeToken` stores `market` and `outcomeIndex`. Decimals are copied from collateral at construction. Mint and burn revert unless `msg.sender` is the market. There is no owner mint.

`marketId`, collateral, `resolutionSpecHash`, and maturity are not stored again on the token. Holders read them from the market. That avoids a second financial store.

## What was measured

Foundry 1.8.3, solc 0.8.26, optimizer 200. Test-function gas is in `research/contract-kernels/.gas-snapshot`. Those numbers include fixture setup inside the test. They are not isolated opcode costs and they are not a clone-versus-full comparison.

Deployment-gas, runtime-gas, and bytecode size for schema B and C were not measured. Classification of "A is cheaper": NOT_YET_VALIDATED. Classification of "A avoids initializer replay": RECOMMENDATION from the absence of an initializer, not from a measured attack on a clone.

## Interface

```text
interface IOutcomeToken is IERC20 {
    function market() external view returns (address);
    function outcomeIndex() external view returns (uint8);
}
```

PRISM is not required to call these functions. See ADR-R04.
