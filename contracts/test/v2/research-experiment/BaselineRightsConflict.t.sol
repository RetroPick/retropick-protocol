// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
// Explicit canonical-reference reproducer. This is not an experimental integration fixture.
import {
    RetroPickFactoryLaunchV2QualificationTest as CanonicalFixture
} from "../integration/RetroPickFactoryLaunchV2Qualification.t.sol";
import {RetroPickBondingCurveV2 as CanonicalCurve} from "../../../src/v2/RetroPickBondingCurveV2.sol";

contract BaselineRightsConflictTest is CanonicalFixture {
    function testAccruedUnsweptFeesFollowReplacement() public {
        vm.prank(creator);
        (address token, address curveAddress) = factory.launchToken(_params(bytes32(uint256(901))), 0, address(0));
        CanonicalCurve curve = CanonicalCurve(payable(curveAddress));
        vm.prank(creator);
        curve.buy{value: 1 ether}(1 ether, 0, creator);
        uint256 fees = curve.quoteFeeBalance();
        uint256 owed = fees - fees * 3000 / 10000 + curve.creatorTaxBalance();
        address replacement = makeAddr("replacement");
        vm.prank(creator);
        factory.transferCreatorFeeRecipient(token, replacement);
        vm.prank(replacement);
        curve.sweepFees(0);
        assertGt(owed, 0);
        assertEq(escrow.balanceOf(replacement), owed);
        assertEq(escrow.balanceOf(creator), 0);
    }

    function testUnreleasedVestingFollowsReplacementButEscrowCreditDoesNot() public {
        vm.prank(creator);
        (address token, address curveAddress) = factory.launchToken(_params(bytes32(uint256(902))), 0, address(0));
        vm.prank(creator);
        factory.setBuybackEnabled(token, true);
        vm.prank(creator);
        CanonicalCurve(payable(curveAddress)).buy{value: 1 ether}(1 ether, 0, creator);
        vm.prank(feeOperator);
        CanonicalCurve(payable(curveAddress)).sweepFees(1);
        assertGt(vault.totalLocked(token), 0);
        uint256 oldCredit = escrow.balanceOf(creator);
        vm.warp(block.timestamp + 365 days);
        uint256 vestedBefore = vault.releasable(token);
        assertGt(vestedBefore, 0);
        address replacement = makeAddr("replacement");
        vm.prank(creator);
        factory.transferCreatorFeeRecipient(token, replacement);
        vm.prank(replacement);
        vault.release(token);
        assertGt(escrow.balanceOfToken(replacement, token), 0);
        assertEq(escrow.balanceOfToken(creator, token), 0);
        assertEq(escrow.balanceOf(creator), oldCredit);
    }
}
