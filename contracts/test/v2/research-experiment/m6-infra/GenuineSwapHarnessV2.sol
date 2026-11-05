// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IUnlockCallback} from "@uniswap/v4-core/src/interfaces/callback/IUnlockCallback.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {BalanceDelta, BalanceDeltaLibrary} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";

/// @notice Test-only payment gateway into a genuine PoolManager; never a venue mock.
/// @dev Not a production router, permit mechanism, path planner or conversion strategy.
contract GenuineSwapHarnessV2 is IUnlockCallback {
    using SafeERC20 for IERC20;
    using BalanceDeltaLibrary for BalanceDelta;
    IPoolManager public immutable manager;
    bool private busy;
    error InvalidSwap();
    error UnauthorizedCallback();
    error PaymentFailed();

    struct Request {
        address payer;
        uint256 nativeBudget;
        PoolKey key;
        SwapParams params;
        uint256 maxInput;
        uint256 minOutput;
    }

    constructor(IPoolManager manager_) {
        manager = manager_;
    }
    receive() external payable {}

    function swap(PoolKey calldata key, SwapParams calldata params, uint256 maxInput, uint256 minOutput)
        external
        payable
        returns (BalanceDelta delta)
    {
        if (busy || params.amountSpecified == 0 || maxInput == 0 || minOutput == 0) revert InvalidSwap();
        busy = true;
        uint256 priorNative = address(this).balance - msg.value;
        delta = abi.decode(
            manager.unlock(abi.encode(Request(msg.sender, msg.value, key, params, maxInput, minOutput))), (BalanceDelta)
        );
        uint256 refund = address(this).balance - priorNative;
        if (refund != 0) {
            (bool ok,) = payable(msg.sender).call{value: refund}("");
            if (!ok) revert PaymentFailed();
        }
        if (address(this).balance != priorNative) revert PaymentFailed();
        busy = false;
    }

    function unlockCallback(bytes calldata data) external returns (bytes memory) {
        if (msg.sender != address(manager) || !busy) revert UnauthorizedCallback();
        Request memory r = abi.decode(data, (Request));
        BalanceDelta delta = manager.swap(r.key, r.params, "");
        int128 inputDelta = r.params.zeroForOne ? delta.amount0() : delta.amount1();
        int128 outputDelta = r.params.zeroForOne ? delta.amount1() : delta.amount0();
        if (inputDelta >= 0 || outputDelta <= 0) revert InvalidSwap();
        uint256 input = uint256(-int256(inputDelta));
        uint256 output = uint256(int256(outputDelta));
        if (input > r.maxInput || output < r.minOutput) revert InvalidSwap();
        Currency inputCurrency = r.params.zeroForOne ? r.key.currency0 : r.key.currency1;
        Currency outputCurrency = r.params.zeroForOne ? r.key.currency1 : r.key.currency0;
        address asset = Currency.unwrap(inputCurrency);
        if (asset == address(0)) {
            if (input > r.nativeBudget) revert PaymentFailed();
            manager.settle{value: input}();
        } else {
            if (r.nativeBudget != 0) revert PaymentFailed();
            manager.sync(inputCurrency);
            IERC20(asset).safeTransferFrom(r.payer, address(manager), input);
            if (manager.settle() != input) revert PaymentFailed();
        }
        manager.take(outputCurrency, r.payer, output);
        return abi.encode(delta);
    }
}
