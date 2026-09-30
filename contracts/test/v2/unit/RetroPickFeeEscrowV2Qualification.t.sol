// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "../../mocks/MockERC20.sol";
import {RetroPickFeeEscrowV2} from "../../../src/v2/RetroPickFeeEscrowV2.sol";

contract EscrowSurchargeQuote is MockERC20 {
    constructor() MockERC20("Surcharge", "SUR", 6) {}

    function _update(address from, address to, uint256 amount) internal override {
        super._update(from, to, amount);
        if (from != address(0) && to != address(0)) super._update(from, address(0), amount / 10);
    }
}

contract EscrowReducibleQuote is MockERC20 {
    constructor() MockERC20("Reducible", "RED", 6) {}

    function slash(address holder, uint256 amount) external {
        _burn(holder, amount);
    }
}

contract RetroPickFeeEscrowV2QualificationTest is Test {
    RetroPickFeeEscrowV2 internal escrow;
    MockERC20 internal quote;
    address internal payer = makeAddr("payer");
    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");

    function setUp() public {
        escrow = new RetroPickFeeEscrowV2();
        quote = new MockERC20("Exact Quote", "EXQ", 6);
        quote.mint(payer, 1_000e6);
        vm.deal(payer, 10 ether);
    }

    function testNativeCreditsClaimsAndDonationsRemainSeparate() public {
        vm.prank(payer);
        escrow.credit{value: 2 ether}(alice);
        vm.deal(address(escrow), address(escrow).balance + 1 ether);
        assertEq(escrow.balanceOf(alice), 2 ether);
        assertEq(escrow.totalNativeLiability(), 2 ether);
        assertEq(address(escrow).balance, 3 ether);

        vm.prank(alice);
        assertEq(escrow.claim(0.5 ether), 0.5 ether);
        vm.prank(alice);
        assertEq(escrow.claim(), 1.5 ether);
        assertEq(escrow.totalNativeLiability(), 0);
        assertEq(address(escrow).balance, 1 ether);
        vm.prank(alice);
        vm.expectRevert(RetroPickFeeEscrowV2.ZeroAmount.selector);
        escrow.claim();
    }

    function testExactTokenCreditsAndClaimsAreAssetSegregated() public {
        MockERC20 second = new MockERC20("Second Quote", "SND", 6);
        second.mint(payer, 100e6);
        vm.startPrank(payer);
        quote.approve(address(escrow), 100e6);
        second.approve(address(escrow), 40e6);
        escrow.creditToken(alice, address(quote), 60e6);
        escrow.creditToken(bob, address(quote), 40e6);
        escrow.creditToken(alice, address(second), 40e6);
        vm.stopPrank();
        quote.mint(address(escrow), 5e6); // Unsolicited surplus is not a claim.

        assertEq(escrow.totalTokenLiability(address(quote)), 100e6);
        assertEq(escrow.totalTokenLiability(address(second)), 40e6);
        vm.prank(alice);
        escrow.claimToken(address(quote), 20e6);
        vm.prank(bob);
        escrow.claimToken(address(quote));
        vm.prank(alice);
        escrow.claimToken(address(second));
        vm.prank(alice);
        escrow.claimToken(address(quote));
        assertEq(quote.balanceOf(address(escrow)), 5e6);
        assertEq(second.balanceOf(address(escrow)), 0);
        assertEq(escrow.totalTokenLiability(address(quote)), 0);
        assertEq(escrow.totalTokenLiability(address(second)), 0);
    }

    function testSenderSurchargeCreditRevertsBeforeLiabilityIsCreated() public {
        EscrowSurchargeQuote surcharge = new EscrowSurchargeQuote();
        surcharge.mint(payer, 100e6);
        vm.startPrank(payer);
        surcharge.approve(address(escrow), 10e6);
        vm.expectRevert(
            abi.encodeWithSelector(RetroPickFeeEscrowV2.InexactTokenTransfer.selector, address(surcharge), 10e6, 11e6)
        );
        escrow.creditToken(alice, address(surcharge), 10e6);
        vm.stopPrank();
        assertEq(surcharge.balanceOf(address(escrow)), 0);
        assertEq(escrow.balanceOfToken(alice, address(surcharge)), 0);
    }

    function testExternalBalanceLossStopsTokenClaimsWithoutCorruptingLedger() public {
        EscrowReducibleQuote reducible = new EscrowReducibleQuote();
        reducible.mint(payer, 100e6);
        vm.startPrank(payer);
        reducible.approve(address(escrow), 100e6);
        escrow.creditToken(alice, address(reducible), 100e6);
        vm.stopPrank();
        reducible.slash(address(escrow), 10e6);
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                RetroPickFeeEscrowV2.PhysicalBalanceDeficit.selector, address(reducible), 90e6, 100e6
            )
        );
        escrow.claimToken(address(reducible), 1e6);
        assertEq(escrow.balanceOfToken(alice, address(reducible)), 100e6);
        assertEq(escrow.totalTokenLiability(address(reducible)), 100e6);
    }

    function testRejectedCallsPreserveState() public {
        vm.prank(payer);
        vm.expectRevert(RetroPickFeeEscrowV2.ZeroAddress.selector);
        escrow.credit{value: 1 ether}(address(0));
        vm.prank(payer);
        vm.expectRevert(RetroPickFeeEscrowV2.ZeroAmount.selector);
        escrow.creditToken(alice, address(quote), 0);
        assertEq(escrow.totalNativeLiability(), 0);
        assertEq(escrow.totalTokenLiability(address(quote)), 0);
    }
}
