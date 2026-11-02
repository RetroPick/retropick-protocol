// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {IKuruRouterV2} from "./interfaces/IKuruV2.sol";

/// @notice Fail-closed observable Monad testnet environment commitment.
/// @dev Proxy implementation slots are checked offchain before broadcast, never read from Solidity.
contract KuruEnvironmentV2 {
    address public constant ROUTER = 0x7EFbE105Ca7415dE98F96622173458ac1c054630;
    address public constant MARGIN = 0xd029C2D98ff85D8F64799017fE00a59B1159CE02;
    address public constant ORDERBOOK_IMPL = 0x72caE0a99C19B574e8a6De558F43fc1D019c9374;
    address public constant VAULT_IMPL = 0x4d54e0d60CaB0cec0100cdA8e00897bC933C5Bb6;
    bytes32 public constant PROXY_HASH = 0xae572ec3ca9b5f49c0364ca34edc5880b6b2837e47802e64e6b681bf2e74aa5c;
    bytes32 public constant ORDERBOOK_HASH = 0x24c5974f233021f00d607bfa191d430f79565663fb90805ebcfca52de7333500;
    bytes32 public constant VAULT_HASH = 0xde0b16a79cf8f711403e89093c1e82ce0e7813949dd0f5041b41da324fdd3dc3;
    bytes32 public constant ENVIRONMENT_HASH = keccak256(
        abi.encode(uint256(10143), ROUTER, MARGIN, ORDERBOOK_IMPL, VAULT_IMPL, PROXY_HASH, ORDERBOOK_HASH, VAULT_HASH)
    );
    error EnvironmentDrift();

    function validate() external view {
        IKuruRouterV2 router = IKuruRouterV2(ROUTER);
        if (
            block.chainid != 10143 || ROUTER.codehash != PROXY_HASH || MARGIN.codehash != PROXY_HASH
                || ORDERBOOK_IMPL.codehash != ORDERBOOK_HASH || VAULT_IMPL.codehash != VAULT_HASH
                || router.marginAccountAddress() != MARGIN || router.orderBookImplementation() != ORDERBOOK_IMPL
                || router.kuruAmmVaultImplementation() != VAULT_IMPL
        ) revert EnvironmentDrift();
    }
}
