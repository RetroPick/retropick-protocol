// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {CandidateCumulativeSettlement} from "../../src/prism/CandidateCumulativeSettlement.sol";

/// @notice Replays the Python holder-allocation counterexample. Aggregate
///         conservation still holds; the recipient of each rounding carry
///         depends on transaction ordering and fragmentation.
contract CandidateHolderFairnessTest is Test {
    address private constant HOLDER_A = address(0xA0);
    address private constant HOLDER_B = address(0xA1);

    function test_alternating_holders_match_python_counterexamples() public {
        string memory json = vm.readFile("../prism-model/fixtures/holder_fairness.json");
        assertEq(vm.parseJsonString(json, ".classification"), "COUNTEREXAMPLE_FOUND");
        for (uint256 i; i < 3; ++i) {
            _replay(json, i);
        }
    }

    function _replay(string memory json, uint256 index) private {
        string memory prefix = string.concat(".cases[", vm.toString(index), "]");
        uint256 pairs = _field(json, prefix, ".pairs");
        uint256 chunk = _field(json, prefix, ".chunk_units");
        (MockCollateral token, CandidateCumulativeSettlement book) = _deploy(json, prefix);
        for (uint256 j; j < pairs; ++j) {
            vm.prank(HOLDER_A);
            assertEq(book.redeem(chunk), 0);
            vm.prank(HOLDER_B);
            assertEq(book.redeem(chunk), 1);
        }

        assertEq(book.supplyUnits(), 0);
        assertEq(book.redeemedUnits(), book.initialSupply());
        assertEq(book.paidRaw(), _field(json, prefix, ".aggregate_paid_raw"));
        assertEq(book.oneShotFloor(), _field(json, prefix, ".aggregate_one_shot_floor_raw"));
        assertEq(token.balanceOf(HOLDER_A), _field(json, prefix, ".holder_a_paid_raw"));
        assertEq(token.balanceOf(HOLDER_B), _field(json, prefix, ".holder_b_paid_raw"));
        assertEq(token.balanceOf(address(book)), _field(json, prefix, ".residual_raw"));
    }

    function _deploy(string memory json, string memory prefix)
        private
        returns (MockCollateral token, CandidateCumulativeSettlement book)
    {
        uint8 decimals_ = uint8(_field(json, prefix, ".decimals"));
        address[] memory holders = new address[](2);
        holders[0] = HOLDER_A;
        holders[1] = HOLDER_B;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = _field(json, prefix, ".initial_units_per_holder");
        amounts[1] = amounts[0];

        token = new MockCollateral(decimals_);
        book = new CandidateCumulativeSettlement(
            address(token), _field(json, prefix, ".payout_wad"), decimals_, holders, amounts
        );
        assertEq(book.initialSupply(), _field(json, prefix, ".supply_units"));
        assertEq(book.ceilFunding(), _field(json, prefix, ".exact_ceil_funding_raw"));
        token.mint(address(book), book.ceilFunding());
        book.makeRedeemable();
    }

    function _field(string memory json, string memory prefix, string memory key) private pure returns (uint256) {
        return vm.parseJsonUint(json, string.concat(prefix, key));
    }
}
