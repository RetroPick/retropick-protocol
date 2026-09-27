// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {CandidateCumulativeSettlement} from "../../src/prism/CandidateCumulativeSettlement.sol";

/// @notice Stateful checks for the existing cumulative-settlement research kernel.
///         Handlers are fund, makeRedeemable, and redeem. Known revert paths return
///         before the call. `fail_on_revert` is false so an unexpected revert is
///         discarded. This suite does not change payout, funding, or transfer behavior.
/// forge-config: default.invariant.runs = 256
/// forge-config: default.invariant.depth = 128
/// forge-config: default.invariant.fail_on_revert = false
contract CandidateCumulativeSettlementInvariantTest is Test {
    uint256 internal constant FUND_CAP = 64;

    MockCollateral internal token;
    CandidateCumulativeSettlement internal book;
    address[] internal holders;

    uint256 internal payoutWad;
    uint256 internal denominator;
    uint256 internal exactCeil;
    uint256 internal fundedTotal;

    function setUp() public {
        token = new MockCollateral(18);
        holders = new address[](2);
        holders[0] = address(0xA0);
        holders[1] = address(0xA1);
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 3;
        amounts[1] = 5;
        payoutWad = 10 ** 18 - 1;
        book = new CandidateCumulativeSettlement(address(token), payoutWad, 18, holders, amounts);
        denominator = book.denominator();
        exactCeil = book.ceilFunding();

        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = this.fund.selector;
        selectors[1] = this.makeRedeemable.selector;
        selectors[2] = this.redeem.selector;
        targetSelector(FuzzSelector({addr: address(this), selectors: selectors}));
        targetContract(address(this));
        excludeContract(address(book));
        excludeContract(address(token));
    }

    /// @notice Mint settlement tokens into the book. That is the existing funding path.
    function fund(uint8 mode, uint96 amount) external {
        uint256 add;
        if (mode % 5 == 0 && fundedTotal < exactCeil) {
            add = exactCeil - fundedTotal;
        } else {
            add = bound(uint256(amount), 0, FUND_CAP);
        }
        if (add == 0) return;
        token.mint(address(book), add);
        fundedTotal += add;
    }

    function makeRedeemable() external {
        if (token.balanceOf(address(book)) < book.ceilFunding()) return;
        book.makeRedeemable();
    }

    function redeem(uint256 holderIndex, uint256 quantity) external {
        if (!book.redeemable()) return;
        address holder = holders[holderIndex % holders.length];
        uint256 held = book.balances(holder);
        if (held == 0) return;
        quantity = bound(quantity, 1, held);
        uint256 cursor = book.redeemedUnits();
        uint256 expected = _delta(cursor, quantity);
        if (expected > token.balanceOf(address(book))) return;
        vm.prank(holder);
        uint256 payout = book.redeem(quantity);
        assertEq(payout, expected);
    }

    function invariant_redeemedSupplyNeverExceedsConstructed() public view {
        assertLe(book.redeemedUnits(), book.initialSupply());
    }

    function invariant_eachRedeemPaysCumulativeFloorDelta() public view {
        assertEq(book.paidRaw(), Math.mulDiv(book.redeemedUnits(), payoutWad, denominator));
    }

    function invariant_balanceIncreasesOnlyThroughFund() public view {
        assertGe(fundedTotal, book.paidRaw());
        assertEq(token.balanceOf(address(book)), fundedTotal - book.paidRaw());
    }

    function invariant_fullRedemptionLeftoverMatchesFunding() public view {
        if (book.supplyUnits() != 0) return;
        if (book.redeemedUnits() != book.initialSupply()) return;
        assertGe(fundedTotal, book.paidRaw());
        assertEq(token.balanceOf(address(book)), fundedTotal - book.paidRaw());
    }

    function invariant_exactCeilLeftoverIsZeroOrOne() public view {
        if (book.supplyUnits() != 0) return;
        if (book.redeemedUnits() != book.initialSupply()) return;
        if (fundedTotal != exactCeil) return;
        assertLe(token.balanceOf(address(book)), 1);
    }

    function _delta(uint256 cursor, uint256 quantity) private view returns (uint256) {
        return Math.mulDiv(cursor + quantity, payoutWad, denominator) - Math.mulDiv(cursor, payoutWad, denominator);
    }
}
