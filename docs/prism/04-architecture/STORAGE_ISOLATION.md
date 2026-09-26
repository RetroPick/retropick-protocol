# Storage isolation of the current kernels

**Classification:** INFERRED from `forge inspect storage-layout` (solc 0.8.26, optimizer 200, Cancun).  
**Not a Monad throughput measurement.** No conflict trace was collected. ADR-R06 stays PROPOSED. This note does not describe Monad as fast.

Layout dump: `evidence/research/prism/storage-layout-2026-09-26.json`.

Each `PredictionMarket` is one market. Each `CandidateComponentBacking` is one series. Neither contract stores a mapping of many markets or many series. Two deployments do not share storage, because Ethereum storage is keyed by `(address, slot)`.

OpenZeppelin `ReentrancyGuard` (v5.5.0) does not use slot 0. `nonReentrant` writes the ERC-7201 slot

`0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00`

to 2 for the call and then back to 1. The slot number is the same on every inheriting contract. The address is not.

## Slots `PredictionMarket.split` touches

On the market address:

| Access | Slot | Field |
|---|---|---|
| read | 0, offset 0 | `state` (packed with `result` at offset 1). `split` does not write this slot |
| write | ERC-7201 guard above | entered, then not-entered |
| write | 1 | `collateralLocked` |
| write | 2 | `yesSupply` |
| write | 3 | `noSupply` |

`split` does not write market slots 0, 4, 5, 6, 7, or 8.

`yesToken.mint` and `noToken.mint` write two other contracts. `forge inspect OutcomeToken storage-layout` places ERC-20 balances at slot 0 and `_totalSupply` at slot 2. Mint writes `_totalSupply` and the balance element `keccak256(abi.encode(account, uint256(0)))`. Allowances (slot 1), name (slot 3), and symbol (slot 4) are not written. `market`, `outcomeIndex`, and `decimals` are immutables, not storage.

`safeTransferFrom` writes the collateral token's own balance slots. That token is not the market.

## Slots `CandidateComponentBacking.mint` touches

On the series address:

| Access | Slot | Field |
|---|---|---|
| write | ERC-7201 guard above | entered, then not-entered |
| read | 1 data | `_weightsWad`. Length is slot 1. Element `i` is `keccak256(uint256(1)) + i` |
| read | 2 data | `_decimals`. Length is slot 2. `uint8` elements are packed from `keccak256(uint256(2))` |
| read | 3 data | `backingRaw`. Length is slot 3. Element `i` is `keccak256(uint256(3)) + i`. Mint does not write this slot |
| read and write | 4 | `supplyUnits` |
| write | 5 data | `balanceOf[msg.sender]` at `keccak256(abi.encode(account, uint256(5)))` |

Mint does not write slots 0, 1, 2, or 3. Slot 0 is the component-token array.

`CandidateCumulativeSettlement` and `CandidatePayoffTransform` are different contracts. Their slots are not the mint slots. Settlement `redeemable` is slot 3 of the settlement contract. Transform `backing` is slot 2 of the transform contract.

## Do two markets share the split slots?

No. Two markets are two `PredictionMarket` addresses, and each market deploys its own YES and NO tokens. The market slots and the outcome-token slots above are different `(address, slot)` keys.

If two markets are constructed with the same collateral ERC-20, `transferFrom` writes that collateral contract. Those writes are the collateral token's slots, not `PredictionMarket` slots. This note does not measure whether a scheduler would serialize them.

## Do two series share the mint slots?

No, when each series is its own `CandidateComponentBacking`. The slot numbers match and the addresses do not.

A later contract that stored many series in one address would share that address's slots. The current kernel does not.
