// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {RetroPickFactoryFixtureV2} from "./RetroPickFactoryLaunchV2Qualification.t.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IVenueLaunchV2} from "../../../src/v2/interfaces/IVenueLaunchV2.sol";
import {RetroPickLaunchFactoryV2} from "../../../src/v2/RetroPickLaunchFactoryV2.sol";
import {RetroPickBondingCurveV2} from "../../../src/v2/RetroPickBondingCurveV2.sol";
import {KuruEnvironmentV2} from "../../../src/v2/KuruEnvironmentV2.sol";
import {KuruGraduationExecutorV2} from "../../../src/v2/KuruGraduationExecutorV2.sol";
import {KuruLiquidityLockV2} from "../../../src/v2/KuruLiquidityLockV2.sol";
import {IKuruRouterV2, IKuruVaultV2} from "../../../src/v2/interfaces/IKuruV2.sol";
import {GraduationCoordinatorV2} from "../../../src/v2/GraduationCoordinatorV2.sol";
import {
    GraduationVenue,
    GraduationState,
    GraduationPacket,
    GraduationLedger,
    GraduationReceipt
} from "../../../src/v2/interfaces/IGraduationExecutorV2.sol";

/// @notice Fresh fork, production Factory/Curve/Coordinator/Kuru worker and permanent lock.
/// V4 dependencies are mocked here; V4 has a separate behavioral and actual-stack campaign.
contract KuruV2EndToEndForkTest is RetroPickFactoryFixtureV2 {
    KuruEnvironmentV2 internal environment;
    KuruGraduationExecutorV2 internal kuru;

    function setUp() public override {
        // Required configuration: this suite never silently skips a missing RPC.
        string memory rpc = vm.envString("MONAD_TESTNET_RPC_URL");
        uint256 forkBlock = vm.envUint("MONAD_V2_FORK_BLOCK");
        require(bytes(rpc).length != 0 && forkBlock != 0, "fresh fork configuration required");
        vm.createSelectFork(rpc, forkBlock);
        assertEq(block.chainid, 10143);
        super.setUp();
        environment = KuruEnvironmentV2(vm.deployCode("KuruEnvironmentV2.sol:KuruEnvironmentV2"));
        environment.validate();
        kuru = KuruGraduationExecutorV2(
            vm.deployCode(
                "KuruGraduationExecutorV2.sol:KuruGraduationExecutorV2", abi.encode(address(coordinator), environment)
            )
        );
        factory.configureVenueExecutor(GraduationVenue.KURU, address(kuru));
        _admit(address(0), 1 ether, 1 ether, 18);
        RetroPickLaunchFactoryV2.LaunchConfig memory config = _config();
        config.supply = 1000 ether;
        config.phantomQuote = 1 ether;
        config.graduationThreshold = 1 ether;
        factory.updateLaunchConfig(0, config);
        emit log_named_uint("fresh_monad_kuru_fork_block", block.number);
    }

    function _launch(address quote) internal returns (address token, RetroPickBondingCurveV2 curve) {
        if (quote != address(0)) _admit(quote, 1e6, 1e6, 6);
        RetroPickLaunchFactoryV2.TokenParams memory params = _params(bytes32(0));
        params.creatorTaxBps = 0;
        bytes memory encoded = this.encodeLaunch(params, quote);
        vm.prank(creator);
        (bool ok, bytes memory result) = address(factory).call(encoded);
        if (!ok) {
            assembly ("memory-safe") { revert(add(result, 32), mload(result)) }
        }
        address curveAddress;
        (token, curveAddress) = abi.decode(result, (address, address));
        curve = RetroPickBondingCurveV2(curveAddress);
        GraduationPacket memory p = coordinator.packet(token);
        assertEq(uint8(p.venue), uint8(GraduationVenue.KURU));
        assertEq(p.executor, address(kuru));
        assertEq(p.graduationQuoteCeiling, quote == address(0) ? 50 ether : 50e6);
        assertEq(p.protectedLPReceiver.code.length, 0);
    }

    // Isolate the large metadata encoding from completion-test live variables (solc 0.8.26 via-IR stack limit).
    function encodeLaunch(RetroPickLaunchFactoryV2.TokenParams calldata params, address quote)
        external
        pure
        returns (bytes memory)
    {
        return abi.encodeCall(IVenueLaunchV2.launchToken, (params, 0, quote, GraduationVenue.KURU));
    }

    function _buyToCompletion(address quote, RetroPickBondingCurveV2 curve) internal {
        if (quote == address(0)) {
            vm.prank(creator);
            curve.buy{value: 2 ether}(2 ether, 0, creator);
        } else {
            deal(quote, creator, 2e6);
            vm.startPrank(creator);
            IERC20(quote).approve(address(curve), 2e6);
            curve.buy(2e6, 0, creator);
            vm.stopPrank();
        }
    }

    function _assertDurable(address token, address quote) internal view {
        GraduationLedger memory l = coordinator.ledger(token);
        assertEq(uint8(l.phase), uint8(GraduationState.GRADUATING));
        assertEq(l.destinationIdentity, bytes32(0));
        assertEq(l.consumedQuote, 0);
        assertEq(l.consumedLaunchTokens, 0);
        assertEq(IERC20(token).balanceOf(address(coordinator)), l.securedLaunchTokens);
        uint256 physical =
            quote == address(0) ? address(coordinator).balance : IERC20(quote).balanceOf(address(coordinator));
        assertEq(physical, l.securedQuote);
        assertEq(IERC20(token).allowance(address(coordinator), address(kuru)), 0);
        if (quote != address(0)) assertEq(IERC20(quote).allowance(address(coordinator), address(kuru)), 0);
        assertEq(l.protectedLPReceiver.code.length, 0);
    }

    function _completeAndVerify(address token, address quote, RetroPickBondingCurveV2 curve) internal {
        GraduationPacket memory p = coordinator.packet(token);
        GraduationLedger memory before = coordinator.ledger(token);
        vm.prank(address(0xCA11));
        GraduationReceipt memory r = coordinator.complete(token);
        GraduationLedger memory l = coordinator.ledger(token);
        assertEq(uint8(l.phase), uint8(GraduationState.GRADUATED));
        assertEq(l.consumedQuote, before.securedQuote);
        assertEq(l.consumedLaunchTokens, before.securedLaunchTokens);
        assertEq(l.destinationIdentity, bytes32(uint256(uint160(r.market))));
        assertTrue(curve.graduated());
        KuruLiquidityLockV2 lock = KuruLiquidityLockV2(p.protectedLPReceiver);
        assertEq(lock.launchToken(), token);
        assertEq(lock.quoteToken(), quote);
        assertEq(lock.market(), r.market);
        assertEq(lock.vault(), r.vault);
        assertEq(IERC20(r.vault).balanceOf(address(lock)), l.protectedLPAmount);
        assertEq(IERC20(token).balanceOf(address(lock)), l.protectedExcessAmount);
        assertEq(IERC20(token).balanceOf(address(kuru)), 0);
        assertEq(IERC20(token).allowance(address(kuru), r.vault), 0);
        if (quote != address(0)) {
            assertEq(IERC20(quote).balanceOf(address(kuru)), 0);
            assertEq(IERC20(quote).allowance(address(kuru), r.vault), 0);
        } else {
            assertEq(address(kuru).balance, 0);
        }
        uint256 shares = l.protectedLPAmount;
        vm.expectRevert(GraduationCoordinatorV2.WrongPhase.selector);
        coordinator.complete(token);
        assertEq(IERC20(r.vault).balanceOf(address(lock)), shares);
        vm.expectRevert(GraduationCoordinatorV2.WrongPhase.selector);
        factory.graduate(token);
    }

    function testFreshNativeProductionGraduationCustodyReplay() public {
        (address token, RetroPickBondingCurveV2 curve) = _launch(address(0));
        _buyToCompletion(address(0), curve);
        _assertDurable(token, address(0));
        _completeAndVerify(token, address(0), curve);
    }

    function testFreshCircleProductionGraduationCustodyReplay() public {
        address quote = registry.CIRCLE_TEST_USDC();
        (address token, RetroPickBondingCurveV2 curve) = _launch(quote);
        _buyToCompletion(quote, curve);
        _assertDurable(token, quote);
        _completeAndVerify(token, quote, curve);
    }

    function testTwoLaunchLedgersConserveSharedNativeCustodyIndependently() public {
        (address first, RetroPickBondingCurveV2 firstCurve) = _launch(address(0));
        (address second, RetroPickBondingCurveV2 secondCurve) = _launch(address(0));
        _buyToCompletion(address(0), firstCurve);
        _buyToCompletion(address(0), secondCurve);
        uint256 firstQuote = coordinator.ledger(first).securedQuote;
        uint256 secondQuote = coordinator.ledger(second).securedQuote;
        assertEq(address(coordinator).balance, firstQuote + secondQuote);
        assertEq(coordinator.quoteLiability(address(0)), firstQuote + secondQuote);
        _completeAndVerify(first, address(0), firstCurve);
        assertEq(address(coordinator).balance, secondQuote);
        assertEq(coordinator.quoteLiability(address(0)), secondQuote);
        _completeAndVerify(second, address(0), secondCurve);
        assertEq(address(coordinator).balance, 0);
        assertEq(coordinator.quoteLiability(address(0)), 0);
        assertTrue(coordinator.ledger(first).destinationIdentity != coordinator.ledger(second).destinationIdentity);
    }

    function testImmutableVenueAndExecutorSurviveProspectiveRegistryChanges() public {
        (address token, RetroPickBondingCurveV2 curve) = _launch(address(0));
        bytes32 commitment = keccak256(abi.encode(coordinator.packet(token)));
        _buyToCompletion(address(0), curve);
        KuruGraduationExecutorV2 replacement = KuruGraduationExecutorV2(
            vm.deployCode(
                "KuruGraduationExecutorV2.sol:KuruGraduationExecutorV2", abi.encode(address(coordinator), environment)
            )
        );
        factory.configureVenueExecutor(GraduationVenue.KURU, address(replacement));
        _admit(address(0), 2 ether, 2 ether, 18);
        assertEq(keccak256(abi.encode(coordinator.packet(token))), commitment);
        assertEq(coordinator.packet(token).executor, address(kuru));
        _completeAndVerify(token, address(0), curve);
    }

    function testUnsolicitedAssetsCannotDeadlockOrEnterLaunchReceipt() public {
        (address token, RetroPickBondingCurveV2 curve) = _launch(address(0));
        _buyToCompletion(address(0), curve);
        vm.prank(creator);
        IERC20(token).transfer(address(kuru), 1);
        new NativeDonationBombV2{value: 1}(payable(address(kuru)));
        _completeAndVerify(token, address(0), curve);
        assertEq(IERC20(token).balanceOf(kuru.donationLock()), 1);
        assertEq(kuru.donationLock().balance, 1);
    }

    function testSecureFailureRollsBackThenOneHopRetries() public {
        (address token, RetroPickBondingCurveV2 curve) = _launch(address(0));
        vm.mockCallRevert(
            address(curve), abi.encodeWithSelector(curve.graduate.selector, address(coordinator)), "secure-fault"
        );
        _buyToCompletion(address(0), curve);
        GraduationLedger memory l = coordinator.ledger(token);
        assertEq(uint8(l.phase), uint8(GraduationState.NONE));
        assertEq(l.securedQuote, 0);
        assertEq(address(coordinator).balance, 0);
        assertFalse(curve.graduated());
        assertTrue(curve.readyToGraduate());
        vm.expectRevert(RetroPickLaunchFactoryV2.WrongGraduationPhase.selector);
        factory.secureCurve(token);
        vm.clearMockedCalls();
        factory.graduate(token);
        _assertDurable(token, address(0));
        _completeAndVerify(token, address(0), curve);
    }

    function testEnvironmentRouterVerificationDepositLpFailuresPreserveThenRetry() public {
        (address token, RetroPickBondingCurveV2 curve) = _launch(address(0));
        _buyToCompletion(address(0), curve);
        GraduationPacket memory p = coordinator.packet(token);
        IKuruRouterV2 router = IKuruRouterV2(environment.ROUTER());
        address market = router.computeAddress(token, address(0), 1e8, 1e8, 1, 1e6, 1e16, 30, 0, 100, address(0), false);
        address vaultAddress = router.computeVaultAddress(market, address(0), false);
        vm.mockCall(
            environment.ROUTER(),
            abi.encodeWithSelector(router.marginAccountAddress.selector),
            abi.encode(address(0xBAD))
        );
        vm.expectRevert(KuruEnvironmentV2.EnvironmentDrift.selector);
        coordinator.complete(token);
        _assertDurable(token, address(0));
        vm.clearMockedCalls();
        vm.mockCallRevert(environment.ROUTER(), abi.encodeWithSelector(router.deployProxy.selector), "router-fault");
        vm.expectRevert();
        coordinator.complete(token);
        _assertDurable(token, address(0));
        vm.clearMockedCalls();
        vm.mockCall(
            environment.ROUTER(), abi.encodeWithSelector(router.verifiedMarket.selector, market), abi.encode(uint256(0))
        );
        vm.expectRevert(KuruGraduationExecutorV2.InvalidMarket.selector);
        coordinator.complete(token);
        _assertDurable(token, address(0));
        vm.clearMockedCalls();
        vm.mockCallRevert(vaultAddress, abi.encodeWithSelector(IKuruVaultV2.deposit.selector), "deposit-fault");
        vm.etch(vaultAddress, hex""); // Remove Foundry's automatic mock stub; retain the selector interception after CREATE2.
        vm.expectRevert();
        coordinator.complete(token);
        _assertDurable(token, address(0));
        vm.clearMockedCalls();
        vm.mockCall(
            vaultAddress,
            abi.encodeWithSelector(IKuruVaultV2.balanceOf.selector, p.protectedLPReceiver),
            abi.encode(uint256(0))
        );
        vm.etch(vaultAddress, hex"");
        vm.expectRevert(KuruGraduationExecutorV2.InvalidDeposit.selector);
        coordinator.complete(token);
        _assertDurable(token, address(0));
        vm.clearMockedCalls();
        assertEq(market.code.length, 0);
        assertEq(vaultAddress.code.length, 0);
        _completeAndVerify(token, address(0), curve);
    }
}

/// @dev Test-only forced native transfer, bypassing recipient receive restrictions.
contract NativeDonationBombV2 {
    constructor(address payable receiver) payable {
        selfdestruct(receiver);
    }
}
