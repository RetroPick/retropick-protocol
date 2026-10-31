// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {CommunityFlowFixtureV2} from "./CommunityCurveFlow.t.sol";
import {RetroPickBondingCurveV2} from "../../../src/v2-research-experiment/RetroPickBondingCurveV2.sol";
import {CommunityFeeRouterV2} from "../../../src/v2-research-experiment/CommunityFeeRouterV2.sol";
import {CommunityPolicyRegistryV2 as Registry} from "../../../src/v2-research-experiment/CommunityPolicyRegistryV2.sol";

contract CommunityEpochRoundingTest is CommunityFlowFixtureV2 {
    function testCEDustOneUnitNativeAndUSDC() public {
        installQuote();
        for (uint256 i; i < 2; ++i) {
            address quote = i == 0 ? address(0) : CIRCLE;
            (RetroPickBondingCurveV2 c, CommunityFeeRouterV2 r) = launchCE(quote, creator);
            vm.startPrank(creator);
            if (quote != address(0)) IERC20(quote).approve(address(c), 101);
            c.buy{value: i == 0 ? 1 : 0}(1, 0, creator);
            vm.stopPrank();
            r.settle();
            assertEq(r.totalFunded(), 0);
            assertEq(r.sequence(), 0);
            vm.prank(creator);
            c.buy{value: i == 0 ? 100 : 0}(100, 0, creator);
            assertEq(c.quoteFeeBalance(), 1);
            assertEq(c.creatorTaxBalance(), 0);
            r.settle();
            assertEq(r.totalFunded(), 1);
            assertEq(r.credit(creator), 0);
            assertEq(r.credit(treasury), 1);
            vm.prank(treasury);
            r.claim(1);
            assertEq(r.totalPaid(), 1);
            assertEq(r.totalLiability(), 0);
        }
    }

    function testFuzzCEEpochRights(uint16 nextShare, uint96 amount) public {
        nextShare = uint16(bound(nextShare, 1, 6000));
        amount = uint96(bound(amount, 1e8, 1 ether));
        (RetroPickBondingCurveV2 c, CommunityFeeRouterV2 r) = launchCE(address(0), creator);
        Registry reg = r.registry();
        cycle(c, amount);
        (, uint256 oldOwed) = communityOwed(c);
        address nextRecipient = address(0xBEEF);
        vm.prank(creator);
        uint256 n = reg.proposePolicy(allocation(nextShare, nextRecipient));
        vm.warp(block.timestamp + 3 days);
        reg.activatePolicy(n);
        uint256 oldCredit = oldOwed * 6000 / 10000;
        assertEq(r.credit(creator), oldCredit);
        assertEq(r.credit(nextRecipient), 0);
        assertEq(r.epochFunded(1), oldOwed);
        cycle(c, amount);
        (, uint256 newOwed) = communityOwed(c);
        r.settle();
        assertEq(r.credit(creator), oldCredit);
        assertEq(r.credit(nextRecipient), newOwed * nextShare / 10000);
        assertEq(r.epochFunded(2), newOwed);
        assertEq(r.totalFunded(), r.totalLiability());
        assertEq(r.credit(creator) + r.credit(nextRecipient) + r.credit(treasury), r.totalLiability());
        assertEq(address(r).balance, r.totalLiability());
    }
}
