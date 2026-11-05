// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {DeployV2MonadTestnet} from "../../../script/DeployV2MonadTestnet.s.sol";
import {RetroPickLaunchFactoryV2} from "../../../src/v2/RetroPickLaunchFactoryV2.sol";
import {RetroPickBondingCurveV2} from "../../../src/v2/RetroPickBondingCurveV2.sol";
import {GraduationCoordinatorV2} from "../../../src/v2/GraduationCoordinatorV2.sol";
import {
    GraduationVenue,
    GraduationState,
    GraduationReceipt
} from "../../../src/v2/interfaces/IGraduationExecutorV2.sol";

/// @notice Actual pinned PoolManager/PositionManager/Permit2/hook, on a fresh Monad fork. No V4 mocks.
contract FullV4StackV2ForkTest is Test {
    DeployV2MonadTestnet.Deployment internal deployment;
    address internal actor;

    function setUp() public {
        vm.createSelectFork(vm.envString("MONAD_TESTNET_RPC_URL"), vm.envUint("MONAD_V2_FORK_BLOCK"));
        assertEq(block.chainid, 10143);
        actor = vm.envAddress("MONAD_TESTNET_ACTOR_A");
        // All constructor and wiring code is shared with the release script; no network broadcast occurs in tests.
        DeployV2MonadTestnet release =
            DeployV2MonadTestnet(vm.deployCode("DeployV2MonadTestnet.s.sol:DeployV2MonadTestnet"));
        deployment = release.run();
        vm.deal(actor, 10 ether);
    }

    function testActualV4NativeFullRangeMintProtectedCustody() public {
        _graduate(address(0));
    }

    function testActualV4CircleFullRangeMintProtectedCustody() public {
        _graduate(0x534b2f3A21130d7a60830c2Df862319e593943A3);
    }

    function _graduate(address quote) internal {
        RetroPickLaunchFactoryV2 factory = RetroPickLaunchFactoryV2(payable(deployment.factory));
        GraduationCoordinatorV2 coordinator = GraduationCoordinatorV2(payable(deployment.coordinator));
        RetroPickLaunchFactoryV2.TokenParams memory params;
        params.name = "Actual V4 fork";
        params.symbol = "AV4";
        params.creatorFeeRecipient = actor;
        params.expectedEconomics = factory.previewLaunchEconomics(0, quote);
        vm.startPrank(actor);
        (address token, address curveAddress) = factory.launchToken(params, 0, quote);
        RetroPickBondingCurveV2 curve = RetroPickBondingCurveV2(curveAddress);
        (uint256 terminal, uint256 gross) = curve.completionQuote();
        if (quote == address(0)) {
            curve.buy{value: gross}(gross, curve.sellableTokens(), actor);
        } else {
            deal(quote, actor, gross);
            IERC20(quote).approve(curveAddress, gross);
            curve.buy(gross, curve.sellableTokens(), actor);
        }
        vm.stopPrank();
        assertEq(coordinator.ledger(token).securedQuote, terminal);
        GraduationReceipt memory r = coordinator.complete(token);
        assertEq(uint8(coordinator.ledger(token).phase), uint8(GraduationState.GRADUATED));
        assertEq(IERC721(deployment.positionManager).ownerOf(r.positionId), deployment.locker);
        assertEq(r.lpAsset, deployment.positionManager);
        assertGt(r.protectedLPAmount, 0);
        assertEq(IERC20(token).balanceOf(deployment.locker), r.protectedExcessAmount);
        assertEq(IERC20(token).balanceOf(deployment.v4Executor), 0);
        assertEq(IERC20(token).allowance(deployment.v4Executor, deployment.permit2), 0);
        if (quote != address(0)) {
            assertEq(IERC20(quote).balanceOf(deployment.v4Executor), 0);
            assertEq(IERC20(quote).allowance(deployment.v4Executor, deployment.permit2), 0);
        } else {
            assertEq(deployment.v4Executor.balance, 0);
        }
        assertEq(coordinator.ledger(token).consumedQuote, coordinator.ledger(token).securedQuote);
        vm.expectRevert(GraduationCoordinatorV2.WrongPhase.selector);
        coordinator.complete(token);
    }
}
