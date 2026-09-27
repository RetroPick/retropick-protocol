// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {CandidateComponentBacking} from "../../src/prism/CandidateComponentBacking.sol";

/// @notice Constructor attempt with component decimals 19 and 19.
/// @dev The decimals check is not edited. No mint follows a reject.
contract DecimalsNineteenRejectTest is Test {
    uint256 internal constant WAD = 10 ** 18;

    function test_constructor_rejects_decimals_19() public {
        MockCollateral first = new MockCollateral(19);
        MockCollateral second = new MockCollateral(19);
        address[] memory tokens = new address[](2);
        uint256[] memory weights = new uint256[](2);
        uint8[] memory decimals_ = new uint8[](2);
        tokens[0] = address(first);
        tokens[1] = address(second);
        weights[0] = WAD;
        weights[1] = WAD;
        decimals_[0] = 19;
        decimals_[1] = 19;

        emit log_string("attempt: decimals 19 and 19");
        emit log_string("weights: 1000000000000000000,1000000000000000000");
        emit log_string("mint: not_executed");
        vm.expectRevert(abi.encodeWithSelector(CandidateComponentBacking.DecimalsOutOfRange.selector, uint8(19)));
        new CandidateComponentBacking(tokens, weights, decimals_);
    }
}
