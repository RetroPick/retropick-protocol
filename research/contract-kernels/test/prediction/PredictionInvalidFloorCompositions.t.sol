// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {PredictionMarket} from "../../src/prediction/PredictionMarket.sol";

/// @notice Replays ordered compositions through the existing INVALID redeem path.
/// @dev The path is PredictionMarket._redeem with numerators (1, 1). This test does not change that payout.
///      The walk is one transaction. foundry.toml sets block_gas_limit above the default 2^30 cap.
contract PredictionInvalidFloorCompositionsTest is Test {
    uint256 internal constant SUPPLY_MAX = 16;

    MockCollateral internal collateral;
    PredictionMarket internal market;
    address internal resolver = address(0xBEEF);
    address internal dustSink = address(0xD057);
    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);
    uint256 internal snap;
    uint256[16] internal parts;
    address[16] internal who;
    uint256 internal partCount;

    function setUp() public {
        collateral = new MockCollateral(6);
        market = new PredictionMarket(
            address(collateral), resolver, dustSink, bytes32("invalid-floor"), "Yes", "YES", "No", "NO"
        );
        market.activate();
        collateral.mint(alice, 1_000_000);
        collateral.mint(bob, 1_000_000);
        vm.prank(alice);
        collateral.approve(address(market), type(uint256).max);
        vm.prank(bob);
        collateral.approve(address(market), type(uint256).max);
        snap = vm.snapshotState();
    }

    function test_supplyTwoPartsPayCumulativeFloor() public {
        assertTrue(vm.revertToState(snap));
        vm.prank(alice);
        market.split(1);
        vm.prank(bob);
        market.split(1);
        _openInvalid();
        vm.prank(alice);
        uint256 firstYes = market.redeemYes(1);
        vm.prank(bob);
        uint256 secondYes = market.redeemYes(1);
        assertEq(firstYes, 0);
        assertEq(secondYes, 1);
        vm.prank(alice);
        uint256 firstNo = market.redeemNo(1);
        vm.prank(bob);
        uint256 secondNo = market.redeemNo(1);
        assertEq(firstNo, 0);
        assertEq(secondNo, 1);
        assertEq(market.collateralLocked(), 0);
        assertEq(firstYes + secondYes, 1);
    }

    function test_invalidCompositionsMatchCumulativeFloor() public {
        uint256 states = 1;
        uint256 transitions = 2;
        uint256 gapRows;
        assertTrue(vm.revertToState(snap));
        _openInvalid();
        assertEq(market.yesNumerator(), 1);
        assertEq(market.noNumerator(), 1);
        assertEq(market.collateralLocked(), 0);
        assertEq(market.liability(), 0);

        for (uint256 supply = 1; supply <= SUPPLY_MAX; ++supply) {
            states += 1;
            uint256 masks = uint256(1) << (supply - 1);
            for (uint256 mask; mask < masks; ++mask) {
                for (uint256 labeling; labeling < 2; ++labeling) {
                    assertTrue(vm.revertToState(snap));
                    states += 1;
                    (uint256 steps, bool gap) = _replay(supply, mask, labeling == 1);
                    transitions += steps;
                    if (gap) gapRows += 1;
                }
            }
            console2.log("supply", supply);
        }

        assertGt(gapRows, 0);
        console2.log("supply_max", SUPPLY_MAX);
        console2.log("states", states);
        console2.log("transitions", transitions);
        console2.log("per_call_gap_rows", gapRows);
        console2.log("mismatches", uint256(0));
    }

    function _openInvalid() internal {
        vm.startPrank(resolver);
        market.closeMint();
        market.beginResolution();
        market.resolve(PredictionMarket.Result.INVALID);
        vm.stopPrank();
        market.openRedemption();
    }

    function _replay(uint256 supply, uint256 mask, bool alternating)
        internal
        returns (uint256 steps, bool perCallGap)
    {
        _loadParts(supply, mask, alternating);
        uint256 count = partCount;
        for (uint256 index; index < count; ++index) {
            vm.prank(who[index]);
            market.split(parts[index]);
        }
        _openInvalid();
        uint256 perCallPaid = _perCallTotal(count);
        steps = _redeemSide(true, supply, count);
        steps += _redeemSide(false, supply, count);
        assertEq(market.collateralLocked(), supply % 2);
        perCallGap = perCallPaid < supply / 2;
    }

    function _loadParts(uint256 supply, uint256 mask, bool alternating) internal {
        uint256 count;
        uint256 partStart;
        for (uint256 index; index < supply; ++index) {
            bool endPart = index + 1 == supply || ((mask >> index) & 1) == 1;
            if (endPart) {
                parts[count] = index + 1 - partStart;
                who[count] = (!alternating || count % 2 == 0) ? alice : bob;
                partStart = index + 1;
                ++count;
            }
        }
        partCount = count;
    }

    function _redeemSide(bool yesSide, uint256 supply, uint256 count) internal returns (uint256 steps) {
        uint256 cursor;
        uint256 paid;
        for (uint256 index; index < count; ++index) {
            uint256 amount = parts[index];
            uint256 expected = (cursor + amount) / 2 - cursor / 2;
            vm.prank(who[index]);
            uint256 payout = yesSide ? market.redeemYes(amount) : market.redeemNo(amount);
            assertEq(payout, expected);
            cursor += amount;
            paid += payout;
            ++steps;
        }
        assertEq(cursor, supply);
        assertEq(paid, supply / 2);
    }

    function _perCallTotal(uint256 count) internal view returns (uint256 perCallPaid) {
        for (uint256 index; index < count; ++index) {
            perCallPaid += parts[index] / 2;
        }
    }
}
