// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import {PredictionMarket} from "../../src/prediction/PredictionMarket.sol";

/// @notice Collateral whose transfer and transferFrom return false and move no balance.
contract FalseReturnCollateral {
    function decimals() external pure returns (uint8) {
        return 6;
    }

    function balanceOf(address) external pure returns (uint256) {
        return 0;
    }

    function allowance(address, address) external pure returns (uint256) {
        return 0;
    }

    function approve(address, uint256) external pure returns (bool) {
        return true;
    }

    function transfer(address, uint256) external pure returns (bool) {
        return false;
    }

    function transferFrom(address, address, uint256) external pure returns (bool) {
        return false;
    }
}

contract FalseReturnCollateralTest is Test {
    address internal resolver = address(0xBEEF);
    address internal dustSink = address(0xD057);
    address internal alice = address(0xA11CE);

    function test_split_reverts_when_transfer_returns_false() public {
        FalseReturnCollateral token = new FalseReturnCollateral();
        assertFalse(token.transfer(alice, 1));
        assertFalse(token.transferFrom(alice, address(this), 1));

        PredictionMarket market = new PredictionMarket(
            address(token), resolver, dustSink, bytes32("false-return"), "Yes", "YES", "No", "NO"
        );
        market.activate();
        assertEq(uint256(market.state()), uint256(PredictionMarket.State.OPEN));

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(SafeERC20.SafeERC20FailedOperation.selector, address(token)));
        market.split(1);

        assertEq(market.collateralLocked(), 0);
        assertEq(market.yesSupply(), 0);
        assertEq(market.noSupply(), 0);
        assertEq(market.yesToken().balanceOf(alice), 0);
        assertEq(market.noToken().balanceOf(alice), 0);
        assertEq(uint256(market.state()), uint256(PredictionMarket.State.OPEN));
    }
}
