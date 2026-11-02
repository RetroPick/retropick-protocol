// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {Test} from "forge-std/Test.sol";
import {CommunityControllerV2 as C} from "../../../../src/v2/CommunityControllerV2.sol";

contract CanonicalCommunityControllerTemporalTest is Test {
    C c;
    address creator = address(0xA);
    address guardian = address(0xB);
    address next = address(0xC);

    function setUp() public {
        c = new C(creator, guardian);
    }

    function schedule(bool recovery) internal {
        vm.prank(recovery ? guardian : creator);
        c.schedule(next, recovery);
    }

    function testCERecoverySupersedesVoluntaryAndCannotBeCancelledByCreator() public {
        schedule(false);
        uint256 oldNonce = c.nonce();
        schedule(true);
        assertEq(c.nonce(), oldNonce + 1);
        vm.prank(creator);
        vm.expectRevert(C.Unauthorized.selector);
        c.cancel(oldNonce + 1);
        vm.warp(c.effectiveAt());
        vm.prank(next);
        vm.expectRevert(C.InvalidTransition.selector);
        c.accept(oldNonce);
        vm.prank(next);
        c.accept(oldNonce + 1);
        assertEq(c.controller(), next);
        assertEq(c.controllerEpoch(), 1);
    }

    function testCEVoluntaryExactReadinessAndAcceptanceDeadline() public {
        schedule(false);
        uint256 n = c.nonce();
        uint256 eta = c.effectiveAt();
        vm.warp(eta - 1);
        vm.prank(next);
        vm.expectRevert(C.InvalidTransition.selector);
        c.accept(n);
        vm.warp(eta + 7 days);
        vm.expectRevert(C.InvalidTransition.selector);
        c.expire(n);
        vm.prank(next);
        c.accept(n);
        assertEq(c.controller(), next);
    }

    function testCERecoveryExpiresOnlyAfterDeadlineAndDoesNotChangeAuthority() public {
        schedule(true);
        uint256 n = c.nonce();
        vm.warp(c.effectiveAt() + 7 days + 1);
        vm.prank(next);
        vm.expectRevert(C.InvalidTransition.selector);
        c.accept(n);
        c.expire(n);
        assertEq(c.controller(), creator);
        assertEq(c.controllerEpoch(), 0);
        vm.expectRevert(C.InvalidTransition.selector);
        c.expire(n);
    }

    function testCEGuardianCancellationInvalidatesRecovery() public {
        schedule(true);
        uint256 n = c.nonce();
        vm.prank(guardian);
        c.cancel(n);
        vm.warp(block.timestamp + 8 days);
        vm.prank(next);
        vm.expectRevert(C.InvalidTransition.selector);
        c.accept(n);
        assertEq(c.controllerEpoch(), 0);
    }

    function testCERecoveryDoesNotFreezeCurrentControllerDuringDelay() public {
        schedule(true);
        assertEq(c.controller(), creator);
        assertEq(c.controllerEpoch(), 0);
        vm.prank(creator);
        vm.expectRevert(C.InvalidTransition.selector);
        c.schedule(address(0xD), false);
    }

    function testFuzzCENoEarlyRecoveryAcceptance(uint32 elapsed) public {
        elapsed = uint32(bound(elapsed, 0, 7 days - 1));
        schedule(true);
        uint256 n = c.nonce();
        vm.warp(block.timestamp + elapsed);
        vm.prank(next);
        vm.expectRevert(C.InvalidTransition.selector);
        c.accept(n);
        assertEq(c.controller(), creator);
    }
}
