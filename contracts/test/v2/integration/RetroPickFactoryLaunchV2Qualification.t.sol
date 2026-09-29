// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IPositionManager} from "@uniswap/v4-periphery/src/interfaces/IPositionManager.sol";
import {IAllowanceTransfer} from "permit2/src/interfaces/IAllowanceTransfer.sol";
import {RetroPickLaunchFactoryV2} from "../../../src/v2/RetroPickLaunchFactoryV2.sol";
import {RetroPickLaunchDeployerV2} from "../../../src/v2/RetroPickLaunchDeployerV2.sol";
import {RetroPickGraduationExecutorV2} from "../../../src/v2/RetroPickGraduationExecutorV2.sol";
import {RetroPickLaunchLockerV2} from "../../../src/v2/RetroPickLaunchLockerV2.sol";
import {RetroPickBondingCurveV2} from "../../../src/v2/RetroPickBondingCurveV2.sol";
import {RetroPickLauncherTokenV2} from "../../../src/v2/RetroPickLauncherTokenV2.sol";
import {RetroPickBuybackVaultV2} from "../../../src/v2/RetroPickBuybackVaultV2.sol";
import {RetroPickMemeHookV2} from "../../../src/v2/hooks/RetroPickMemeHookV2.sol";
import {
    FeePolicySnapshot,
    IRetroPickFeeEscrowV2,
    GraduationPhase
} from "../../../src/v2/interfaces/IRetroPickLaunchpadV2.sol";
import {CurveStateFeeEscrowV2} from "../unit/RetroPickCurrentCurveStateV2Qualification.t.sol";
import {MockERC20} from "../../mocks/MockERC20.sol";

/// @notice Real Factory/Deployer/Token/Curve path with explicitly mocked V4-only singletons.
/// The mocks do not qualify V4 pool creation or a live Kuru destination.
contract RetroPickFactoryLaunchV2QualificationTest is Test {
    address internal owner = address(this);
    address internal creator = makeAddr("creator");
    address internal protocol = makeAddr("protocol");
    address internal poolManager = makeAddr("pool-manager");
    address internal positionManager = makeAddr("position-manager");
    address internal permit2 = makeAddr("permit2");
    address internal hook = makeAddr("hook");

    RetroPickLaunchFactoryV2 internal factory;
    RetroPickLaunchDeployerV2 internal deployer;
    RetroPickGraduationExecutorV2 internal executor;
    RetroPickLaunchLockerV2 internal locker;
    RetroPickBuybackVaultV2 internal vault;
    CurveStateFeeEscrowV2 internal escrow;

    function setUp() public {
        vm.etch(positionManager, hex"00");
        vm.etch(hook, hex"00");
        vm.mockCall(positionManager, abi.encodeWithSignature("poolManager()"), abi.encode(poolManager));
        escrow = new CurveStateFeeEscrowV2();
        locker = new RetroPickLaunchLockerV2(owner, positionManager);
        vault = new RetroPickBuybackVaultV2(
            owner, RetroPickMemeHookV2(payable(hook)), IRetroPickFeeEscrowV2(address(escrow))
        );
        factory = new RetroPickLaunchFactoryV2(
            owner,
            IPoolManager(poolManager),
            IPositionManager(positionManager),
            IAllowanceTransfer(permit2),
            locker,
            RetroPickMemeHookV2(payable(hook)),
            IRetroPickFeeEscrowV2(address(escrow)),
            vault,
            0
        );
        deployer = new RetroPickLaunchDeployerV2(address(factory));
        executor = new RetroPickGraduationExecutorV2(
            IPositionManager(positionManager), IAllowanceTransfer(permit2), locker, address(factory)
        );
        locker.setFactory(address(factory));
        vault.setFactory(address(factory));
        factory.setLaunchDeployer(deployer);
        factory.setGraduationExecutor(executor);

        vm.mockCall(hook, abi.encodeWithSignature("factory()"), abi.encode(address(factory)));
        vm.mockCall(hook, abi.encodeWithSignature("buybackVault()"), abi.encode(address(vault)));
        vm.mockCall(hook, abi.encodeWithSignature("poolManager()"), abi.encode(poolManager));
        vm.mockCall(hook, abi.encodeWithSignature("feeEscrow()"), abi.encode(address(escrow)));
        FeePolicySnapshot memory policy = FeePolicySnapshot(protocol, 3_000, 5_000, 100, 300);
        vm.mockCall(hook, abi.encodeWithSignature("currentFeePolicy()"), abi.encode(policy));

        factory.addLaunchConfig(_config());
        factory.setLaunchEnabled(true);
        vm.deal(creator, 10 ether);
    }

    function _config() internal pure returns (RetroPickLaunchFactoryV2.LaunchConfig memory) {
        return RetroPickLaunchFactoryV2.LaunchConfig({
            supply: 1_000_000 ether,
            curveFeeBps: 100,
            phantomQuote: 100 ether,
            graduationThreshold: 100 ether,
            poolFee: 0,
            tickSpacing: 60,
            enabled: true
        });
    }

    function _params(bytes32 salt) internal pure returns (RetroPickLaunchFactoryV2.TokenParams memory p) {
        RetroPickLauncherTokenV2.Socials memory socials;
        p = RetroPickLaunchFactoryV2.TokenParams({
            name: "Factory Launch",
            symbol: "FLCH",
            logo: "",
            description: "",
            socials: socials,
            creatorFeeRecipient: address(0),
            creatorTaxBps: 50,
            buybackEnabled: false,
            expectedEconomics: bytes32(0),
            salt: salt
        });
    }

    function testFactoryCreatesAndRecordsNativeLaunch() public {
        RetroPickLaunchFactoryV2.TokenParams memory p = _params(bytes32(uint256(1)));
        p.expectedEconomics = factory.previewLaunchEconomics(0, address(0));
        vm.prank(creator);
        (address tokenAddress, address curveAddress) = factory.launchToken(p, 0, address(0));
        RetroPickLauncherTokenV2 token = RetroPickLauncherTokenV2(tokenAddress);
        RetroPickBondingCurveV2 curve = RetroPickBondingCurveV2(payable(curveAddress));
        assertEq(curve.factory(), address(factory));
        assertEq(curve.token(), tokenAddress);
        assertEq(token.launchFactory(), address(factory));
        assertEq(token.curve(), curveAddress);
        assertEq(token.totalSupply(), 1_000_000 ether);
        assertEq(token.balanceOf(curveAddress), token.totalSupply());
        assertEq(uint256(factory.getLaunchedToken(tokenAddress).phase), uint256(GraduationPhase.NotGraduated));
        assertEq(factory.getLaunchedToken(tokenAddress).deployer, creator);
        assertEq(curve.feeBps(), 100);
        assertEq(curve.creatorTaxBps(), 50);
        assertEq(curve.reservedTokens(), 500_000 ether);
    }

    function testEconomicsPinAndDisabledConfigRejectWithoutLaunch() public {
        RetroPickLaunchFactoryV2.TokenParams memory p = _params(bytes32(uint256(2)));
        p.expectedEconomics = factory.previewLaunchEconomics(0, address(0));
        RetroPickLaunchFactoryV2.LaunchConfig memory changed = _config();
        changed.curveFeeBps = 200;
        factory.updateLaunchConfig(0, changed);
        vm.prank(creator);
        vm.expectPartialRevert(RetroPickLaunchFactoryV2.LaunchEconomicsMismatch.selector);
        factory.launchToken(p, 0, address(0));

        changed.enabled = false;
        factory.updateLaunchConfig(0, changed);
        p.expectedEconomics = bytes32(0);
        vm.prank(creator);
        vm.expectRevert(RetroPickLaunchFactoryV2.LaunchConfigDisabled.selector);
        factory.launchToken(p, 0, address(0));
    }

    function testCurrentSaltDoesNotAffectAddressesFromIdenticalPrelaunchState() public {
        uint256 state = vm.snapshotState();
        vm.prank(creator);
        (address firstToken, address firstCurve) = factory.launchToken(_params(bytes32(uint256(111))), 0, address(0));
        vm.revertToState(state);
        vm.prank(creator);
        (address secondToken, address secondCurve) = factory.launchToken(_params(bytes32(uint256(222))), 0, address(0));
        assertEq(firstToken, secondToken, "salt is ignored by current CREATE deployment");
        assertEq(firstCurve, secondCurve, "salt is ignored by current CREATE deployment");
    }

    function testUnapprovedQuoteRejectedAndApprovedSixDecimalQuoteLaunched() public {
        MockERC20 stable = new MockERC20("Test USDC", "USDC", 6);
        RetroPickLaunchFactoryV2.TokenParams memory p = _params(bytes32(uint256(3)));
        vm.prank(creator);
        vm.expectRevert(RetroPickLaunchFactoryV2.PairTokenNotApproved.selector);
        factory.launchToken(p, 0, address(stable));

        factory.setPairTokenEconomics(address(stable), 100e6, 100e6, 6);
        factory.setPairTokenApproved(address(stable), true);
        p.expectedEconomics = factory.previewLaunchEconomics(0, address(stable));
        vm.prank(creator);
        (address tokenAddress, address curveAddress) = factory.launchToken(p, 0, address(stable));
        assertEq(RetroPickBondingCurveV2(payable(curveAddress)).pairToken(), address(stable));
        assertEq(RetroPickLauncherTokenV2(tokenAddress).totalSupply(), 1_000_000 ether);
        assertEq(RetroPickBondingCurveV2(payable(curveAddress)).phantomQuote(), 100e6);
    }

    function testSnipeSettingDoesNotChangeCurrentBuyEconomics() public {
        uint256 state = vm.snapshotState();
        vm.prank(creator);
        (, address firstCurve) = factory.launchToken(_params(bytes32(uint256(11))), 0, address(0));
        vm.prank(creator);
        uint256 firstOut = RetroPickBondingCurveV2(payable(firstCurve)).buy{value: 1 ether}(1 ether, 0, creator);
        uint256 firstTax = RetroPickBondingCurveV2(payable(firstCurve)).creatorTaxBalance();
        vm.revertToState(state);

        factory.setSnipeTaxStartBps(0);
        factory.setSnipeTaxSeconds(1);
        vm.prank(creator);
        (, address secondCurve) = factory.launchToken(_params(bytes32(uint256(11))), 0, address(0));
        vm.prank(creator);
        uint256 secondOut = RetroPickBondingCurveV2(payable(secondCurve)).buy{value: 1 ether}(1 ether, 0, creator);
        assertEq(firstOut, secondOut);
        assertEq(firstTax, RetroPickBondingCurveV2(payable(secondCurve)).creatorTaxBalance());
    }
}
