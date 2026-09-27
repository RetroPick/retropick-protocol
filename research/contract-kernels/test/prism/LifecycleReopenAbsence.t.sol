// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {CandidateCumulativeSettlement} from "../../src/prism/CandidateCumulativeSettlement.sol";

/// @notice The settlement candidate can open `redeemable` and has no way to leave it.
/// @dev No lifecycle function is added. Backing, redeem, and payout are not edited.
contract LifecycleReopenAbsenceTest is Test {
    address internal holder = address(0xA11CE);
    address internal funder = address(0xB0B);

    function test_candidate_has_no_reopen() public {
        MockCollateral token = new MockCollateral(18);
        address[] memory holders = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        holders[0] = holder;
        amounts[0] = 2;
        CandidateCumulativeSettlement book =
            new CandidateCumulativeSettlement(address(token), 10 ** 18 - 1, 18, holders, amounts);

        emit log_named_uint("redeemable_before_open", book.redeemable() ? 1 : 0);
        token.mint(funder, 2);
        vm.prank(funder);
        assertTrue(token.transfer(address(book), 2));
        book.makeRedeemable();

        bool redeemable = book.redeemable();
        emit log_named_uint("redeemable_after_open", redeemable ? 1 : 0);
        emit log_named_uint("series_state_enum", 0);
        emit log_named_uint("archived_state", 0);
        emit log_named_uint("reopen_function", 0);
        emit log_named_uint("redeemable_after_absent_reopen", book.redeemable() ? 1 : 0);
    }
}
