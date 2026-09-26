// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {PredictionMarket} from "../../src/prediction/PredictionMarket.sol";

/// @notice The constructor stores resolutionSpecHash and leaves the market DRAFT.
/// @dev resolve and activate are not edited. Resolve runs only while the hash is already set and the state is still DRAFT.
contract DraftSpecPresenceTest is Test {
    MockCollateral internal collateral;
    PredictionMarket internal market;
    address internal resolver = address(0xBEEF);
    address internal dustSink = address(0xD057);
    bytes32 internal specHash = bytes32("draft-spec-presence");

    function setUp() public {
        collateral = new MockCollateral(6);
        market = new PredictionMarket(
            address(collateral), resolver, dustSink, specHash, "Yes", "YES", "No", "NO"
        );
    }

    function test_spec_hash_present_while_draft_then_resolve() public {
        assertEq(uint256(market.state()), uint256(PredictionMarket.State.DRAFT));
        assertEq(market.resolutionSpecHash(), specHash);

        emit log_string("spec_setting_call: constructor");
        emit log_string("state_after_constructor: DRAFT");
        emit log_named_bytes32("resolution_spec_hash", market.resolutionSpecHash());
        emit log_string("result_before: NONE");
        emit log_named_uint("liability_before", market.liability());
        emit log_named_uint("collateral_before", market.collateralLocked());

        vm.prank(resolver);
        vm.expectRevert(PredictionMarket.BadState.selector);
        market.resolve(PredictionMarket.Result.YES_WIN);

        emit log_string("solidity_resolve_accepted: false");
        emit log_string("error: BadState");
        emit log_string("state_after_resolve: DRAFT");
        emit log_string("result_after_resolve: NONE");
        emit log_named_bytes32("resolution_spec_hash_after_resolve", market.resolutionSpecHash());
        emit log_named_uint("liability_after", market.liability());
        emit log_named_uint("collateral_after", market.collateralLocked());

        assertEq(uint256(market.state()), uint256(PredictionMarket.State.DRAFT));
        assertEq(uint256(market.result()), uint256(PredictionMarket.Result.NONE));
        assertEq(market.resolutionSpecHash(), specHash);
        assertEq(market.liability(), 0);
        assertEq(market.collateralLocked(), 0);

        market.activate();
        emit log_string("activate_sets_hash: false");
        emit log_string("state_after_activate: OPEN");
        emit log_named_bytes32("resolution_spec_hash_after_activate", market.resolutionSpecHash());
        assertEq(uint256(market.state()), uint256(PredictionMarket.State.OPEN));
        assertEq(market.resolutionSpecHash(), specHash);
        assertEq(uint256(market.result()), uint256(PredictionMarket.Result.NONE));
    }
}
