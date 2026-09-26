// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {CandidateCumulativeSettlement} from "../../src/prism/CandidateCumulativeSettlement.sol";

/// @notice External caller so assembly gas() wraps each CALL. Includes CALL overhead.
contract FundRedeemMeter {
    function measure(CandidateCumulativeSettlement book, MockCollateral token)
        external
        returns (uint256 fundGas, uint256 openGas, uint256 firstRedeemGas, uint256 secondRedeemGas)
    {
        token.mint(address(this), 2);
        fundGas = _call(address(token), abi.encodeCall(IERC20.transfer, (address(book), 2)));
        openGas = _call(address(book), abi.encodeCall(CandidateCumulativeSettlement.makeRedeemable, ()));
        firstRedeemGas = _call(address(book), abi.encodeCall(CandidateCumulativeSettlement.redeem, (1)));
        secondRedeemGas = _call(address(book), abi.encodeCall(CandidateCumulativeSettlement.redeem, (1)));
    }

    function _call(address target, bytes memory data) private returns (uint256 gasUsed) {
        uint256 gasBefore;
        uint256 gasAfter;
        bool ok;
        assembly {
            gasBefore := gas()
            ok := call(gas(), target, 0, add(data, 0x20), mload(data), 0, 0)
            gasAfter := gas()
        }
        require(ok, "candidate call failed");
        gasUsed = gasBefore - gasAfter;
    }
}

/// @notice Gas for funding and redeeming the candidate. Not a canonical MATH-1 measurement.
/// @dev Scenario: supply 2, payout 10^18-1, decimals 18, one holder, ceil funding 2,
///      then two 1-unit redemptions. Python pays 0 then 1, total 1, residual 1.
contract CandidateSettlementGasTest is Test {
    function test_fund_and_redeem_gas() public {
        FundRedeemMeter meter = new FundRedeemMeter();
        MockCollateral token = new MockCollateral(18);
        address[] memory holders = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        holders[0] = address(meter);
        amounts[0] = 2;
        CandidateCumulativeSettlement book =
            new CandidateCumulativeSettlement(address(token), 10 ** 18 - 1, 18, holders, amounts);

        (uint256 fundGas, uint256 openGas, uint256 firstRedeemGas, uint256 secondRedeemGas) = meter.measure(book, token);

        emit log_named_uint("fund_transfer_gas", fundGas);
        emit log_named_uint("make_redeemable_gas", openGas);
        emit log_named_uint("redeem_first_unit_gas", firstRedeemGas);
        emit log_named_uint("redeem_second_unit_gas", secondRedeemGas);
        emit log_named_uint("fund_open_two_redeems_gas", fundGas + openGas + firstRedeemGas + secondRedeemGas);

        assertEq(token.balanceOf(address(meter)), 1);
        assertEq(token.balanceOf(address(book)), 1);
        assertEq(book.paidRaw(), 1);
        assertEq(book.redeemedUnits(), 2);
        assertEq(book.oneShotFloor(), 1);
    }
}
