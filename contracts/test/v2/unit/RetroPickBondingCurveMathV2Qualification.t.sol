// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {RetroPickBondingCurveMathV2} from "../../../src/v2/libraries/RetroPickBondingCurveMathV2.sol";

contract CurveMathV2Harness {
    function amountOut(uint256 inputAmount, uint256 reserveIn, uint256 reserveOut, uint256 feeBps)
        external
        pure
        returns (uint256)
    {
        return RetroPickBondingCurveMathV2.getAmountOut(inputAmount, reserveIn, reserveOut, feeBps);
    }

    function amountIn(uint256 outputAmount, uint256 reserveIn, uint256 reserveOut, uint256 feeBps)
        external
        pure
        returns (uint256)
    {
        return RetroPickBondingCurveMathV2.getAmountIn(outputAmount, reserveIn, reserveOut, feeBps);
    }

    function quoteAmountOut(uint256 inputAmount, uint256 reserveIn, uint256 reserveOut, uint256 feeBps)
        external
        pure
        returns (uint256)
    {
        return RetroPickBondingCurveMathV2.quoteAmountOut(inputAmount, reserveIn, reserveOut, feeBps);
    }
}

/// @notice A behavioral lock for the CURRENT V2 integer math; it does not propose Kuru terms.
contract RetroPickBondingCurveMathV2QualificationTest is Test {
    CurveMathV2Harness internal math;

    function setUp() public {
        math = new CurveMathV2Harness();
    }

    function testGoldenAmountOutNoFee() public view {
        assertEq(math.amountOut(100, 1_000, 1_000, 0), 90);
        assertEq(math.amountOut(1_000_000, 1_000_000, 1 ether, 100), 497_487_437_185_929_648);
    }

    function testGoldenAmountInCurrentPlusOneRounding() public view {
        // Current getAmountIn adds one even if the rational quotient is already integral.
        assertEq(math.amountIn(500, 1_000, 1_000, 0), 1_001);
        assertEq(math.amountIn(100, 1_000, 1_000, 100), 113);
    }

    function testZeroAndEmptyDomains() public {
        vm.expectRevert(RetroPickBondingCurveMathV2.InsufficientInputAmount.selector);
        math.amountOut(0, 1, 1, 0);
        vm.expectRevert(RetroPickBondingCurveMathV2.InsufficientLiquidity.selector);
        math.amountOut(1, 0, 1, 0);
        vm.expectRevert(RetroPickBondingCurveMathV2.InsufficientOutputAmount.selector);
        math.amountOut(1, 1_000, 1_000, 0);
        vm.expectRevert(RetroPickBondingCurveMathV2.InsufficientLiquidity.selector);
        math.amountIn(1, 1, 1, 0);
        assertEq(math.quoteAmountOut(1, 1_000, 1_000, 10_000), 0);
    }

    function testFuzzAmountOutExactIntegerFormula(
        uint256 rawIn,
        uint256 rawInReserve,
        uint256 rawOutReserve,
        uint16 rawFee
    ) public view {
        uint256 amount = bound(rawIn, 1, 1e18);
        uint256 reserveIn = bound(rawInReserve, 1, 1e24);
        uint256 reserveOut = bound(rawOutReserve, 1, 1e24);
        uint256 feeBps = bound(rawFee, 0, 2_000);
        uint256 adjusted = amount * (10_000 - feeBps);
        uint256 expected = (adjusted * reserveOut) / (reserveIn * 10_000 + adjusted);

        assertEq(math.quoteAmountOut(amount, reserveIn, reserveOut, feeBps), expected);
        if (expected == 0) return;
        assertEq(math.amountOut(amount, reserveIn, reserveOut, feeBps), expected);
        assertLt(expected, reserveOut);
    }

    function testFuzzAmountInExactIntegerFormula(
        uint256 rawOut,
        uint256 rawInReserve,
        uint256 rawOutReserve,
        uint16 rawFee
    ) public view {
        uint256 reserveIn = bound(rawInReserve, 1, 1e24);
        uint256 reserveOut = bound(rawOutReserve, 2, 1e24);
        uint256 amountOut = bound(rawOut, 1, reserveOut - 1);
        uint256 feeBps = bound(rawFee, 0, 2_000);
        uint256 expected = (amountOut * reserveIn * 10_000) / ((reserveOut - amountOut) * (10_000 - feeBps)) + 1;
        assertEq(math.amountIn(amountOut, reserveIn, reserveOut, feeBps), expected);
    }
}
