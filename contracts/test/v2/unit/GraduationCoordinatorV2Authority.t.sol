// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {RetroPickV4BehaviorFixtureV2} from "../integration/RetroPickV4GraduationBehavior.t.sol";
import {GraduationCoordinatorV2} from "../../../src/v2/GraduationCoordinatorV2.sol";
import {RetroPickLaunchFactoryV2} from "../../../src/v2/RetroPickLaunchFactoryV2.sol";
import {RetroPickBondingCurveV2} from "../../../src/v2/RetroPickBondingCurveV2.sol";
import {UniswapV4GraduationExecutorV2} from "../../../src/v2/UniswapV4GraduationExecutorV2.sol";
import {GraduationVenue, GraduationState, GraduationPacket} from "../../../src/v2/interfaces/IGraduationExecutorV2.sol";

contract GraduationCoordinatorV2AuthorityTest is RetroPickV4BehaviorFixtureV2 {
    function testOnlyFactoryCanConfigureRegisterOrSecureAndBindingIsOneTime() public {
        vm.expectRevert(GraduationCoordinatorV2.InvalidBinding.selector);
        coordinator.bindFactory(address(factory));
        vm.prank(creator);
        vm.expectRevert(GraduationCoordinatorV2.Unauthorized.selector);
        coordinator.configureExecutor(GraduationVenue.KURU, address(0xBAD));
        vm.prank(creator);
        vm.expectRevert(GraduationCoordinatorV2.Unauthorized.selector);
        coordinator.registerLaunch(address(1), address(2), GraduationVenue.KURU, 0, 60);
        vm.prank(creator);
        vm.expectRevert(GraduationCoordinatorV2.Unauthorized.selector);
        coordinator.secure(address(1));
        vm.expectRevert(RetroPickLaunchFactoryV2.WrongGraduationPhase.selector);
        factory.secureCurve(address(1));
        vm.prank(address(coordinator));
        vm.expectRevert(RetroPickLaunchFactoryV2.WrongGraduationPhase.selector);
        factory.secureCurve(address(1));
        address worker = coordinator.executors(GraduationVenue.UNISWAP_V4);
        GraduationPacket memory packet;
        vm.expectRevert(UniswapV4GraduationExecutorV2.Unauthorized.selector);
        UniswapV4GraduationExecutorV2(payable(worker)).execute(packet, 0, 0);
    }

    function testInexactSecureReportCannotCreateDurableLedgerThenExactHandoffRetries() public {
        vm.prank(creator);
        (address token, address curveAddress) = factory.launchToken(_params(), 0, address(0));
        RetroPickBondingCurveV2 curve = RetroPickBondingCurveV2(curveAddress);
        (uint256 terminal, uint256 gross) = curve.completionQuote();
        vm.mockCall(
            curveAddress,
            abi.encodeWithSelector(curve.graduate.selector, address(coordinator)),
            abi.encode(terminal, curve.reservedTokens())
        );
        vm.prank(creator);
        curve.buy{value: gross}(gross, 0, creator);
        assertEq(uint8(coordinator.ledger(token).phase), uint8(GraduationState.NONE));
        assertEq(coordinator.ledger(token).securedQuote, 0);
        assertEq(address(coordinator).balance, 0);
        assertEq(coordinator.quoteLiability(address(0)), 0);
        assertFalse(curve.graduated());
        assertTrue(curve.readyToGraduate());
        vm.expectRevert(GraduationCoordinatorV2.InexactHandoff.selector);
        factory.graduate(token);
        vm.clearMockedCalls();
        factory.graduate(token);
        assertEq(uint8(coordinator.ledger(token).phase), uint8(GraduationState.GRADUATING));
        assertEq(coordinator.ledger(token).securedQuote, terminal);
        assertEq(address(coordinator).balance, terminal);
        vm.expectRevert(GraduationCoordinatorV2.WrongPhase.selector);
        factory.graduate(token);
        assertEq(coordinator.ledger(token).securedQuote, terminal);
    }
}
