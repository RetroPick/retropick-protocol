// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {CommunityTreasuryIntegrationFixtureV2} from "./CommunityTreasuryIntegration.t.sol";
import {CommunityTreasuryVaultV2 as V} from "../../../../src/v2/CommunityTreasuryVaultV2.sol";
import {CommunityFeeRouterV2 as R} from "../../../../src/v2/CommunityFeeRouterV2.sol";
import {RetroPickBondingCurveV2 as C} from "../../../../src/v2/RetroPickBondingCurveV2.sol";
import {CommunityTimelockV2 as T} from "../../../../src/v2/CommunityTimelockV2.sol";

contract CanonicalCommunityTreasuryPrefundTest is CommunityTreasuryIntegrationFixtureV2 {
    function prefunded(address asset, uint256 revenueInput, uint256 donation) internal {
        address predicted =
            computeCreateAddress(address(treasuryDeployment), vm.getNonce(address(treasuryDeployment)) + 1);
        if (asset == address(0)) {
            vm.deal(predicted, donation);
        } else {
            (bool ok,) = asset.call(abi.encodeWithSignature("mint(address,uint256)", predicted, donation));
            assertTrue(ok);
        }
        (C c, R r, V v) = launch(asset);
        assertEq(address(v), predicted);
        assertEq(v.claimed(), 0);
        assertEq(v.held(), 0);
        assertEq(v.surplus(), donation);
        cycle(c, revenueInput);
        r.settle();
        uint256 credit = r.credit(address(v));
        v.claimFromRouter(credit);
        assertEq(v.claimed(), credit);
        assertEq(v.surplus(), donation);
        T t = v.timelock();
        bytes memory data = payload(v, recipient, credit, bytes32(uint256(71)));
        bytes32 salt = bytes32(uint256(71));
        bytes32 op = queue(t, v, data, salt);
        vm.warp(t.getTimestamp(op));
        t.execute(address(v), 0, data, bytes32(0), salt);
        assertEq(v.held(), 0);
        assertEq(v.actualBalance(), donation);
        assertEq(v.spent(), credit);
        data = payload(v, recipient, 1, bytes32(uint256(72)));
        salt = bytes32(uint256(72));
        op = queue(t, v, data, salt);
        vm.warp(t.getTimestamp(op));
        vm.expectRevert(V.InvalidSpend.selector);
        t.execute(address(v), 0, data, bytes32(0), salt);
        assertEq(v.actualBalance(), donation);
        assertEq(r.credit(address(v)), 0);
    }

    function testCETreasuryPrefundedNativeAddressCannotCreateEarnedIncome() public {
        prefunded(address(0), 1 ether, 2 ether);
    }

    function testCETreasuryPrefundedUSDCAddressCannotCreateEarnedIncome() public {
        quote();
        prefunded(CIRCLE, 1e6, 2e6);
    }
}
