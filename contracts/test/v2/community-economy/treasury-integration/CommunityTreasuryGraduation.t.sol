// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {CommunityTreasuryIntegrationFixtureV2} from "./CommunityTreasuryIntegration.t.sol";
import {CommunityTreasuryVaultV2 as V} from "../../../../src/v2/CommunityTreasuryVaultV2.sol";
import {CommunityFeeRouterV2 as R} from "../../../../src/v2/CommunityFeeRouterV2.sol";
import {RetroPickBondingCurveV2 as C} from "../../../../src/v2/RetroPickBondingCurveV2.sol";
import {CommunityTimelockV2 as T} from "../../../../src/v2/CommunityTimelockV2.sol";
import {IGraduationExecutorV2} from "../../../../src/v2/interfaces/IGraduationExecutorV2.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Real curve/coordinator/custody; unavailable local venue, never a fork.
contract CanonicalCommunityTreasuryGraduationTest is CommunityTreasuryIntegrationFixtureV2 {
    function physical(address asset) internal view returns (uint256) {
        return asset == address(0) ? address(coordinator).balance : IERC20(asset).balanceOf(address(coordinator));
    }

    function boundary(address asset, uint256 amount) internal {
        (C c, R r, V v) = launch(asset);
        address token = c.token();
        vm.deal(creator, 200 ether);
        vm.startPrank(creator);
        if (asset != address(0)) IERC20(asset).approve(address(c), amount);
        c.buy{value: asset == address(0) ? amount : 0}(amount, 0, creator);
        vm.stopPrank();
        assertTrue(c.graduated());
        assertEq(c.communityPending(), 0);
        uint256 secured = physical(asset);
        assertGt(secured, 0);
        assertEq(secured, factory.getLaunchedToken(token).sweptQuote);
        uint256 owed = r.credit(address(v));
        uint256 creatorOwed = r.credit(creator);
        assertGt(owed, 0);
        vm.expectCall(address(executor), abi.encodePacked(IGraduationExecutorV2.execute.selector));
        vm.expectRevert();
        factory.createGraduatedPool(token);
        assertEq(physical(asset), secured);
        v.claimFromRouter(owed);
        assertEq(v.held(), owed);
        assertEq(r.credit(creator), creatorOwed);
        T t = v.timelock();
        bytes memory data = payload(v, recipient, owed, bytes32(uint256(81)));
        bytes32 salt = bytes32(uint256(81));
        bytes32 op = queue(t, v, data, salt);
        vm.warp(t.getTimestamp(op));
        t.execute(address(v), 0, data, bytes32(0), salt);
        assertEq(v.held(), 0);
        assertEq(v.spent(), owed);
        assertEq(physical(asset), secured);
        uint256 funded = r.totalFunded();
        r.settle();
        assertEq(r.totalFunded(), funded);
        vm.expectCall(address(executor), abi.encodePacked(IGraduationExecutorV2.execute.selector));
        vm.expectRevert();
        factory.createGraduatedPool(token);
        assertEq(physical(asset), secured);
        assertEq(r.credit(address(v)), 0);
        assertEq(r.totalFunded(), r.totalPaid() + r.totalLiability());
    }

    function testCETreasuryNativeClaimsSurviveSecuredGraduationAndFailedVenueRetries() public {
        boundary(address(0), 150 ether);
    }

    function testCETreasuryUSDCClaimsSurviveSecuredGraduationAndFailedVenueRetries() public {
        quote();
        boundary(CIRCLE, 150e6);
    }
}
