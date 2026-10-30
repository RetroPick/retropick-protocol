// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library ExactAssetV2 {
    using SafeERC20 for IERC20;
    error InexactAssetTransfer(address asset);

    function pull(address asset, address from, address to, uint256 amount) internal {
        if (amount == 0) return;
        uint256 source = IERC20(asset).balanceOf(from);
        uint256 destination = IERC20(asset).balanceOf(to);
        IERC20(asset).safeTransferFrom(from, to, amount);
        if (IERC20(asset).balanceOf(from) != source - amount || IERC20(asset).balanceOf(to) != destination + amount) {
            revert InexactAssetTransfer(asset);
        }
    }

    function send(address asset, address to, uint256 amount) internal {
        if (amount == 0) return;
        uint256 source = IERC20(asset).balanceOf(address(this));
        uint256 destination = IERC20(asset).balanceOf(to);
        IERC20(asset).safeTransfer(to, amount);
        if (
            IERC20(asset).balanceOf(address(this)) != source - amount
                || IERC20(asset).balanceOf(to) != destination + amount
        ) revert InexactAssetTransfer(asset);
    }

    function balance(address asset, address holder) internal view returns (uint256) {
        return asset == address(0) ? holder.balance : IERC20(asset).balanceOf(holder);
    }
}
