// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Per-launch permanent custody. No owner, approval, withdrawal or arbitrary call entrypoint.
contract KuruLiquidityLockV2 {
    address public immutable launchToken;
    address public immutable quoteToken;
    address public immutable market;
    address public immutable vault;
    error InvalidBinding();

    constructor(address launchToken_, address quoteToken_, address market_, address vault_) {
        if (launchToken_ == address(0) || market_ == address(0) || vault_ == address(0)) revert InvalidBinding();
        launchToken = launchToken_;
        quoteToken = quoteToken_;
        market = market_;
        vault = vault_;
    }

    function protectedBalances() external view returns (uint256 lpShares, uint256 excessLaunchTokens) {
        return (IERC20(vault).balanceOf(address(this)), IERC20(launchToken).balanceOf(address(this)));
    }
}
