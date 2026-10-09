// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
// Separate pinned upstream build; existing V1/V2 vendored interfaces remain untouched.
import {PoolManager} from "@uniswap/v4-core/src/PoolManager.sol";
import {PositionManager} from "deployment-periphery/src/PositionManager.sol";
import {PositionDescriptor} from "deployment-periphery/src/PositionDescriptor.sol";
import {WETH} from "solmate/src/tokens/WETH.sol";
