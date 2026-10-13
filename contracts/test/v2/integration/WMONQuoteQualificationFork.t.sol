// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {KuruV2EndToEndForkTest} from "./KuruV2EndToEndFork.t.sol";
import {RetroPickBondingCurveV2} from "../../../src/v2/RetroPickBondingCurveV2.sol";
import {RetroPickLaunchFactoryV2} from "../../../src/v2/RetroPickLaunchFactoryV2.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
interface IQualificationWrapper { function deposit() external payable; function withdraw(uint256) external; }
/// Local fork only: permissions and launches exist solely in this test's new fixture deployment.
contract WMONQuoteQualificationForkTest is KuruV2EndToEndForkTest {
    address constant WRAPPER = 0xff437B117Ec17a79a3b24Da4B5047dca4da9D0a2;
    function testWMONExistingWrapperAndRealKuruGraduation() public {
        assertGt(WRAPPER.code.length, 0);
        assertEq(IERC20Metadata(WRAPPER).decimals(), 18);
        assertEq(IERC20Metadata(WRAPPER).symbol(), "WETH"); // Historical deployed metadata; native MON backing.
        uint256 nativeBefore = creator.balance;
        vm.startPrank(creator);
        IQualificationWrapper(WRAPPER).deposit{value: 3 ether}();
        uint256 balance = IERC20(WRAPPER).balanceOf(creator);
        assertGe(balance, 3 ether);
        IQualificationWrapper(WRAPPER).withdraw(1 ether);
        assertEq(creator.balance, nativeBefore - 2 ether);
        assertEq(IERC20(WRAPPER).balanceOf(creator), balance - 1 ether);
        address receiver = makeAddr("wrapper receiver");
        assertTrue(IERC20(WRAPPER).transfer(receiver, 0.1 ether));
        vm.stopPrank();
        vm.prank(receiver);
        assertTrue(IERC20(WRAPPER).transfer(creator, 0.1 ether));
        _admit(WRAPPER, 1 ether, 1 ether, 18);
        RetroPickLaunchFactoryV2.TokenParams memory p = _params(bytes32(0));
        p.creatorTaxBps = 0;
        vm.prank(creator);
        (bool ok, bytes memory result) = address(factory).call(this.encodeLaunch(p, WRAPPER));
        if (!ok) { assembly ("memory-safe") { revert(add(result, 32), mload(result)) } }
        (address token, address curveAddress) = abi.decode(result, (address, address));
        RetroPickBondingCurveV2 curve = RetroPickBondingCurveV2(curveAddress);
        vm.startPrank(creator);
        assertTrue(IERC20(WRAPPER).approve(curveAddress, 2 ether));
        uint256 gasBefore = gasleft();
        curve.buy(2 ether, 0, creator);
        emit log_named_uint("WMON_completion_buy_gas", gasBefore - gasleft());
        vm.stopPrank();
        _assertDurable(token, WRAPPER);
        gasBefore = gasleft();
        _completeAndVerify(token, WRAPPER, curve);
        emit log_named_uint("WMON_graduation_test_segment_gas", gasBefore - gasleft());
        assertEq(coordinator.packet(token).quoteDecimals, 18);
        assertEq(coordinator.packet(token).graduationThreshold, 1 ether);
        assertEq(coordinator.packet(token).graduationQuoteCeiling, 50 ether);
    }
}
