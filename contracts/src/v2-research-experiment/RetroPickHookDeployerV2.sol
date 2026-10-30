// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IRetroPickFeeEscrowV2} from "./interfaces/IRetroPickLaunchpadV2.sol";
import {RetroPickMemeHookV2} from "./hooks/RetroPickMemeHookV2.sol";

/// @notice Narrow CREATE2 deployer for the V4 hook's required permission bits.
contract RetroPickHookDeployerV2 {
    address public immutable owner;
    error Unauthorized();

    constructor(address owner_) {
        owner = owner_;
    }

    function deploy(bytes32 salt, IPoolManager manager, IRetroPickFeeEscrowV2 escrow, address treasury)
        external
        returns (RetroPickMemeHookV2 hook)
    {
        if (msg.sender != owner) revert Unauthorized();
        return new RetroPickMemeHookV2{salt: salt}(manager, escrow, treasury, owner);
    }
}
