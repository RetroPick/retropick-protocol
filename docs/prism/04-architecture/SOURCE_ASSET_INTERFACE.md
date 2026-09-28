# Source-asset interface

**Status:** PROPOSED_NOT_FROZEN  
**Gate:** `SOURCE-ASSET-INTERFACE-FREEZE` = `proposed_not_frozen`  
**What this is not:** a cross-module deposit harness. X-I01 through X-I07 are not tested. PRISM does not call this interface.

**2026-09-28 qualification:** `research/reports/PRISM_ADMISSION_SOURCE_INTERFACE_PACKET.md` proposes the missing certificate/registry and executable X-I01..X-I07 boundary. Prediction INVALID holder allocation (ADR-P05) and winner uint256 liveness (ADR-P19) remain unresolved; the payoff/settlement version of a Prediction source cannot be frozen from the ERC-20 address alone. This does not change this file's PROPOSED_NOT_FROZEN status.

The prediction kernel can expose the following today. Anything else is out of the freeze.

| Field | Where | Rule |
|---|---|---|
| Token identity | `OutcomeToken` address | Distinct YES and NO ERC-20s created by the market |
| `market()` | outcome token | Immutable market that minted the token |
| `outcomeIndex()` | outcome token | Immutable `0` for YES and `1` for NO |
| Decimals | `OutcomeToken.decimals()` and `PredictionMarket.collateralDecimals()` | Both copy the collateral's `decimals()` at construction |
| `resolutionSpecHash()` | market, not the token | Immutable `bytes32` from the market constructor |
| Collateral | `PredictionMarket.collateral()` | One standard ERC-20. The kernel rejects a fee-on-transfer shortfall |
| Rebasing | disqualified | The kernel does not support a rebasing collateral |
| Transfer | ERC-20 | Holders transfer balances. Financial payout state stays on the market |

A later PRISM series may hold one of these ERC-20s only as a normal ERC-20 balance. It must not read resolution as backing, and it must not be written until this freeze is accepted and the deposit harness exists. Neither of those is done.

Classification: RECOMMENDATION for the field list the current kernel already stores. NOT_YET_VALIDATED as a frozen ABI. BLOCKED for cross-module use.
