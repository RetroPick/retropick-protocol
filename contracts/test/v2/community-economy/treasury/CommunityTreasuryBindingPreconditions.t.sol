// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {CommunityFlowFixtureV2} from "../CommunityCurveFlow.t.sol";
import {CommunityFeeRouterV2} from "../../../../src/v2/CommunityFeeRouterV2.sol";
import {RetroPickBondingCurveV2} from "../../../../src/v2/RetroPickBondingCurveV2.sol";

/// @notice Reproduces source preconditions, not an implemented-helper exploit.
contract CanonicalCommunityTreasuryBindingPreconditionsTest is CommunityFlowFixtureV2 {
    function testCETwoLaunchesCanCreditSamePlannedTreasury() public {
        (RetroPickBondingCurveV2 a, CommunityFeeRouterV2 ra) = launchCE(address(0), creator);
        (RetroPickBondingCurveV2 b, CommunityFeeRouterV2 rb) = launchCE(address(0), creator);
        assertTrue(address(ra) != address(rb));
        assertEq(ra.factory(), rb.factory());
        assertEq(ra.feeAsset(), rb.feeAsset());
        assertEq(ra.registry().module(2), treasury);
        assertEq(rb.registry().module(2), treasury);
        cycle(a, 1 ether);
        cycle(b, 1 ether);
        ra.settle();
        rb.settle();
        assertGt(ra.credit(treasury), 0);
        assertGt(rb.credit(treasury), 0);
    }
}
