// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
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
import {RetroPickFeeEscrowV2} from "../../../src/v2/RetroPickFeeEscrowV2.sol";
import {RetroPickQuoteAssetPolicyV2} from "../../../src/v2/RetroPickQuoteAssetPolicyV2.sol";
import {IRetroPickQuoteAssetPolicyV2} from "../../../src/v2/interfaces/IRetroPickQuoteAssetPolicyV2.sol";
import {RetroPickMemeHookV2} from "../../../src/v2/hooks/RetroPickMemeHookV2.sol";
import {
    FeePolicySnapshot,
    IRetroPickFeeEscrowV2,
    GraduationPhase
} from "../../../src/v2/interfaces/IRetroPickLaunchpadV2.sol";
import {MockERC20} from "../../mocks/MockERC20.sol";

/// @notice An ERC20 whose sender pays an additional burn on every transfer.
/// Balance-delta receipt does not protect the Curve when it is the sender.
contract SenderSurchargeQuote is ERC20 {
    constructor() ERC20("Surcharge Quote", "SQ") {}

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function _update(address from, address to, uint256 value) internal override {
        super._update(from, to, value);
        if (from != address(0) && to != address(0)) {
            super._update(from, address(0), value / 10);
        }
    }
}

contract FalseReturnQuote is MockERC20 {
    constructor() MockERC20("False Return Quote", "FQ", 6) {}

    function transferFrom(address, address, uint256) public pure override returns (bool) {
        return false;
    }
}

contract ExternallyReducibleQuote is MockERC20 {
    constructor() MockERC20("Reducible Quote", "RQ", 6) {}

    function slash(address holder, uint256 amount) external {
        _burn(holder, amount);
    }
}

contract CallbackQuote is MockERC20 {
    address public targetCurve;
    uint256 public attempts;
    bool public callbackSucceeded;

    constructor() MockERC20("Callback Quote", "CQ", 6) {}

    function setTargetCurve(address curve) external {
        targetCurve = curve;
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        bool transferred = super.transferFrom(from, to, value);
        if (to == targetCurve && attempts == 0) {
            attempts = 1;
            (callbackSucceeded,) =
                targetCurve.call(abi.encodeWithSelector(RetroPickBondingCurveV2.buy.selector, 1e6, 0, from));
        }
        return transferred;
    }
}

/// @notice Deliberately permissive research fixture for malicious-token negatives.
/// It is not the production P0 quote admission policy.
contract ResearchPermissiveQuotePolicy is IRetroPickQuoteAssetPolicyV2 {
    function isSupportedQuote(address) external pure returns (bool) {
        return true;
    }

    function validateQuote(address, uint8) external pure {}
}

/// @notice Real Factory/Deployer/Token/Curve path with explicitly mocked V4-only singletons.
/// The mocks do not qualify V4 pool creation or a live Kuru destination.
contract RetroPickFactoryLaunchV2QualificationTest is Test {
    address internal owner = address(this);
    address internal creator = makeAddr("creator");
    address internal protocol = makeAddr("protocol");
    address internal feeOperator = makeAddr("fee-operator");
    address internal poolManager = makeAddr("pool-manager");
    address internal positionManager = makeAddr("position-manager");
    address internal permit2 = makeAddr("permit2");
    address internal hook = makeAddr("hook");

    RetroPickLaunchFactoryV2 internal factory;
    RetroPickLaunchDeployerV2 internal deployer;
    RetroPickGraduationExecutorV2 internal executor;
    RetroPickLaunchLockerV2 internal locker;
    RetroPickBuybackVaultV2 internal vault;
    RetroPickFeeEscrowV2 internal escrow;

    function setUp() public {
        vm.etch(positionManager, hex"00");
        vm.etch(hook, hex"00");
        vm.mockCall(positionManager, abi.encodeWithSignature("poolManager()"), abi.encode(poolManager));
        escrow = new RetroPickFeeEscrowV2();
        ResearchPermissiveQuotePolicy researchPolicy = new ResearchPermissiveQuotePolicy();
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
            researchPolicy,
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
        vm.mockCall(hook, abi.encodeWithSignature("feeSweepOperator()"), abi.encode(feeOperator));
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

    function testCanonicalP0PolicyRejectsArbitraryOwnerApprovedQuote() public {
        RetroPickQuoteAssetPolicyV2 p0Policy = new RetroPickQuoteAssetPolicyV2();
        assertTrue(p0Policy.isSupportedQuote(address(0)));
        assertTrue(p0Policy.isSupportedQuote(p0Policy.CIRCLE_TEST_USDC()));
        MockERC20 arbitrary = new MockERC20("Arbitrary", "ARB", 6);
        assertFalse(p0Policy.isSupportedQuote(address(arbitrary)));
        RetroPickLaunchFactoryV2 p0Factory = new RetroPickLaunchFactoryV2(
            owner,
            IPoolManager(poolManager),
            IPositionManager(positionManager),
            IAllowanceTransfer(permit2),
            locker,
            RetroPickMemeHookV2(payable(hook)),
            IRetroPickFeeEscrowV2(address(escrow)),
            vault,
            p0Policy,
            0
        );
        vm.expectRevert(RetroPickQuoteAssetPolicyV2.QuoteNotSupported.selector);
        p0Factory.setPairTokenEconomics(address(arbitrary), 100e6, 100e6, 6);
        vm.expectRevert(RetroPickLaunchFactoryV2.PairTokenEconomicsInvalid.selector);
        p0Factory.setPairTokenApproved(address(arbitrary), true);

        address circle = p0Policy.CIRCLE_TEST_USDC();
        vm.etch(circle, hex"");
        vm.expectRevert(RetroPickQuoteAssetPolicyV2.QuoteCodeMissing.selector);
        p0Factory.setPairTokenEconomics(circle, 100e6, 100e6, 6);

        MockERC20 wrongScale = new MockERC20("Wrong Scale", "WS", 18);
        vm.etch(circle, address(wrongScale).code);
        vm.expectRevert(
            abi.encodeWithSelector(RetroPickQuoteAssetPolicyV2.QuoteDecimalsMismatch.selector, uint8(6), uint8(18))
        );
        p0Factory.setPairTokenEconomics(circle, 100e6, 100e6, 6);

        MockERC20 exactScale = new MockERC20("Circle fixture", "CF", 6);
        vm.etch(circle, address(exactScale).code);
        p0Factory.setPairTokenEconomics(circle, 100e6, 100e6, 6);
        p0Factory.setPairTokenApproved(circle, true);
        assertTrue(p0Factory.approvedPairTokens(circle));
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

    function testApprovedExactTransferSixDecimalQuoteBuySellBalances() public {
        MockERC20 quote = new MockERC20("Exact Quote", "EQ", 6);
        factory.setPairTokenEconomics(address(quote), 100e6, 100e6, 6);
        factory.setPairTokenApproved(address(quote), true);
        vm.prank(creator);
        (address tokenAddress, address curveAddress) =
            factory.launchToken(_params(bytes32(uint256(5))), 0, address(quote));
        RetroPickBondingCurveV2 curve = RetroPickBondingCurveV2(payable(curveAddress));
        quote.mint(creator, 10e6);
        vm.startPrank(creator);
        quote.approve(curveAddress, 10e6);
        uint256 tokensOut = curve.buy(10e6, 0, creator);
        assertEq(quote.balanceOf(curveAddress), curve.trackedQuote());
        RetroPickLauncherTokenV2(tokenAddress).approve(curveAddress, tokensOut / 2);
        curve.sell(tokensOut / 2, 0, creator);
        vm.stopPrank();
        assertEq(quote.balanceOf(curveAddress), curve.trackedQuote(), "exact-transfer quote preserves tracked backing");
    }

    function testApprovedSenderSurchargeQuoteRejectedBeforeCurveAccounting() public {
        SenderSurchargeQuote quote = new SenderSurchargeQuote();
        factory.setPairTokenEconomics(address(quote), 100e6, 100e6, 6);
        factory.setPairTokenApproved(address(quote), true);
        vm.prank(creator);
        (, address curveAddress) =
            factory.launchToken(_params(bytes32(uint256(4))), 0, address(quote));
        RetroPickBondingCurveV2 curve = RetroPickBondingCurveV2(payable(curveAddress));
        quote.mint(creator, 20e6);
        vm.startPrank(creator);
        quote.approve(curveAddress, 10e6);
        vm.expectRevert(
            abi.encodeWithSelector(RetroPickBondingCurveV2.InexactQuoteTransfer.selector, 10e6, 11e6)
        );
        curve.buy(10e6, 0, creator);
        vm.stopPrank();
        assertEq(quote.balanceOf(curveAddress), 0);
        assertEq(curve.trackedQuote(), 0);
        assertEq(quote.balanceOf(creator), 20e6);
    }

    function testApprovedFalseReturnQuoteBuyRevertsWithoutStateChange() public {
        FalseReturnQuote quote = new FalseReturnQuote();
        factory.setPairTokenEconomics(address(quote), 100e6, 100e6, 6);
        factory.setPairTokenApproved(address(quote), true);
        vm.prank(creator);
        (address tokenAddress, address curveAddress) =
            factory.launchToken(_params(bytes32(uint256(6))), 0, address(quote));
        RetroPickBondingCurveV2 curve = RetroPickBondingCurveV2(payable(curveAddress));
        quote.mint(creator, 10e6);
        vm.startPrank(creator);
        quote.approve(curveAddress, 10e6);
        vm.expectRevert(abi.encodeWithSelector(SafeERC20.SafeERC20FailedOperation.selector, address(quote)));
        curve.buy(10e6, 0, creator);
        vm.stopPrank();
        assertEq(quote.balanceOf(curveAddress), 0);
        assertEq(curve.trackedQuote(), 0);
        assertEq(curve.trackedTokens(), RetroPickLauncherTokenV2(tokenAddress).totalSupply());
        assertEq(RetroPickLauncherTokenV2(tokenAddress).balanceOf(creator), 0);
    }

    function testApprovedExternallyReducibleQuoteLossFailsClosed() public {
        ExternallyReducibleQuote quote = new ExternallyReducibleQuote();
        factory.setPairTokenEconomics(address(quote), 100e6, 100e6, 6);
        factory.setPairTokenApproved(address(quote), true);
        vm.prank(creator);
        (, address curveAddress) = factory.launchToken(_params(bytes32(uint256(7))), 0, address(quote));
        RetroPickBondingCurveV2 curve = RetroPickBondingCurveV2(payable(curveAddress));
        quote.mint(creator, 10e6);
        vm.startPrank(creator);
        quote.approve(curveAddress, 10e6);
        curve.buy(10e6, 0, creator);
        vm.stopPrank();
        assertEq(quote.balanceOf(curveAddress), curve.trackedQuote());

        quote.slash(curveAddress, 1e6);
        assertEq(curve.trackedQuote() - quote.balanceOf(curveAddress), 1e6);
        bytes memory deficit = abi.encodeWithSelector(
            RetroPickBondingCurveV2.QuoteBackingDeficit.selector, 9e6, 10e6
        );
        vm.expectRevert(deficit);
        curve.realQuoteReserve();
        vm.prank(creator);
        vm.expectRevert(deficit);
        curve.sweepFees(0);
        assertEq(curve.trackedQuote(), 10e6);
    }

    function testApprovedCallbackQuoteCannotReenterBuyAccounting() public {
        CallbackQuote quote = new CallbackQuote();
        factory.setPairTokenEconomics(address(quote), 100e6, 100e6, 6);
        factory.setPairTokenApproved(address(quote), true);
        vm.prank(creator);
        (address tokenAddress, address curveAddress) =
            factory.launchToken(_params(bytes32(uint256(8))), 0, address(quote));
        quote.setTargetCurve(curveAddress);
        quote.mint(creator, 10e6);
        vm.startPrank(creator);
        quote.approve(curveAddress, 10e6);
        uint256 tokensOut = RetroPickBondingCurveV2(payable(curveAddress)).buy(10e6, 0, creator);
        vm.stopPrank();

        assertEq(quote.attempts(), 1);
        assertFalse(quote.callbackSucceeded());
        assertEq(quote.balanceOf(curveAddress), RetroPickBondingCurveV2(payable(curveAddress)).trackedQuote());
        assertEq(RetroPickLauncherTokenV2(tokenAddress).balanceOf(creator), tokensOut);
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

    function testCrossingBuySweepsAssetsAndFailedMockV4SeedPreservesThem() public {
        vm.deal(creator, 200 ether);
        vm.prank(creator);
        (address tokenAddress, address curveAddress) = factory.launchToken(_params(bytes32(uint256(12))), 0, address(0));
        RetroPickBondingCurveV2 curve = RetroPickBondingCurveV2(payable(curveAddress));

        vm.prank(creator);
        uint256 purchased = curve.buy{value: 150 ether}(150 ether, 0, creator);
        assertEq(purchased, 500_000 ether, "crossing order is clamped to sellable allocation");
        assertEq(curve.sellableTokens(), 0);
        assertTrue(curve.graduated(), "crossing buy auto-sweeps into Factory");
        assertEq(uint256(factory.getLaunchedToken(tokenAddress).phase), uint256(GraduationPhase.Swept));
        uint256 lockedQuote = address(factory).balance;
        uint256 lockedTokens = RetroPickLauncherTokenV2(tokenAddress).balanceOf(address(factory));
        assertEq(lockedQuote, factory.getLaunchedToken(tokenAddress).sweptQuote);
        assertEq(lockedTokens, factory.getLaunchedToken(tokenAddress).sweptTokens);

        vm.prank(creator);
        vm.expectRevert(RetroPickBondingCurveV2.CurveGraduated.selector);
        curve.buy{value: 1 ether}(1 ether, 0, creator);
        vm.prank(creator);
        vm.expectRevert(RetroPickBondingCurveV2.CurveGraduated.selector);
        curve.sell(1 ether, 0, creator);
        vm.expectRevert();
        factory.createGraduatedPool(tokenAddress);

        assertEq(address(factory).balance, lockedQuote, "failed V4 seed did not move secured quote");
        assertEq(RetroPickLauncherTokenV2(tokenAddress).balanceOf(address(factory)), lockedTokens);
        assertEq(uint256(factory.getLaunchedToken(tokenAddress).phase), uint256(GraduationPhase.Swept));
    }

    function testCreatorFeeRecipientOverrideIsDelayedAndSupersedesInterveningTransfer() public {
        address attacker = makeAddr("attacker");
        address replacement = makeAddr("replacement");
        address ownerChoice = makeAddr("owner-choice");
        vm.prank(creator);
        (address tokenAddress, address curveAddress) = factory.launchToken(_params(bytes32(uint256(13))), 0, address(0));
        RetroPickBondingCurveV2 curve = RetroPickBondingCurveV2(payable(curveAddress));

        vm.prank(attacker);
        vm.expectRevert(RetroPickLaunchFactoryV2.NotCreatorFeeRecipient.selector);
        factory.transferCreatorFeeRecipient(tokenAddress, attacker);
        assertEq(factory.getLaunchedToken(tokenAddress).creatorFeeRecipient, creator);

        factory.setCreatorFeeRecipient(tokenAddress, ownerChoice);
        vm.prank(attacker);
        vm.expectPartialRevert(RetroPickLaunchFactoryV2.TimelockNotElapsed.selector);
        factory.executeCreatorFeeRecipientChange(tokenAddress);

        vm.prank(creator);
        factory.transferCreatorFeeRecipient(tokenAddress, replacement);
        assertEq(factory.getLaunchedToken(tokenAddress).creatorFeeRecipient, replacement);
        assertEq(curve.deployer(), replacement);

        vm.warp(block.timestamp + factory.CREATOR_FEE_RECIPIENT_TIMELOCK());
        vm.prank(attacker);
        factory.executeCreatorFeeRecipientChange(tokenAddress);
        assertEq(factory.getLaunchedToken(tokenAddress).creatorFeeRecipient, ownerChoice);
        assertEq(curve.deployer(), ownerChoice);
    }

    function testBuybackAuthorizationCreatorCanEnableOwnerCanOnlyDisable() public {
        address attacker = makeAddr("attacker");
        vm.prank(creator);
        (address tokenAddress, address curveAddress) = factory.launchToken(_params(bytes32(uint256(14))), 0, address(0));
        RetroPickBondingCurveV2 curve = RetroPickBondingCurveV2(payable(curveAddress));

        vm.expectRevert(RetroPickLaunchFactoryV2.NotBuybackController.selector);
        factory.setBuybackEnabled(tokenAddress, true);
        vm.prank(attacker);
        vm.expectRevert(RetroPickLaunchFactoryV2.NotBuybackController.selector);
        factory.setBuybackEnabled(tokenAddress, false);
        assertFalse(curve.buybackEnabled());

        vm.prank(creator);
        factory.setBuybackEnabled(tokenAddress, true);
        assertTrue(curve.buybackEnabled());
        assertTrue(factory.getLaunchedToken(tokenAddress).buybackEnabled);
        factory.setBuybackEnabled(tokenAddress, false);
        assertFalse(curve.buybackEnabled());
        assertFalse(factory.getLaunchedToken(tokenAddress).buybackEnabled);
    }

    function testTrustedFeeSweepLocksBuybackTokensAndPreservesQuoteAccounting() public {
        RetroPickLaunchFactoryV2.TokenParams memory p = _params(bytes32(uint256(15)));
        p.buybackEnabled = true;
        vm.prank(creator);
        (address tokenAddress, address curveAddress) = factory.launchToken(p, 0, address(0));
        RetroPickBondingCurveV2 curve = RetroPickBondingCurveV2(payable(curveAddress));
        vm.prank(creator);
        curve.buy{value: 10 ether}(10 ether, 0, creator);
        uint256 pending = curve.quoteFeeBalance();
        uint256 tax = curve.creatorTaxBalance();
        uint256 earmark = curve.buybackQuoteBalance();
        uint256 realBefore = curve.realQuoteReserve();
        assertGt(earmark, 0);

        vm.prank(creator);
        vm.expectRevert(RetroPickBondingCurveV2.InternalSwapRequiresOperator.selector);
        curve.sweepFees(1);
        vm.prank(feeOperator);
        vm.expectPartialRevert(RetroPickBondingCurveV2.SlippageExceeded.selector);
        curve.sweepFees(type(uint256).max);
        assertEq(curve.quoteFeeBalance(), pending);
        assertEq(curve.creatorTaxBalance(), tax);
        assertEq(curve.buybackQuoteBalance(), earmark);
        assertEq(vault.totalLocked(tokenAddress), 0);
        vm.prank(feeOperator);
        curve.sweepFees(1);

        uint256 locked = vault.totalLocked(tokenAddress);
        assertGt(locked, 0);
        assertEq(RetroPickLauncherTokenV2(tokenAddress).balanceOf(address(vault)), locked);
        assertEq(curve.quoteFeeBalance(), 0);
        assertEq(curve.creatorTaxBalance(), 0);
        assertEq(curve.buybackQuoteBalance(), 0);
        assertEq(curve.realQuoteReserve(), realBefore + earmark);
        assertEq(address(curve).balance, curve.trackedQuote());
        assertEq(escrow.balanceOf(protocol), pending * 3_000 / 10_000);
        assertEq(escrow.balanceOf(creator), pending - pending * 3_000 / 10_000 - earmark + tax);

        uint256 protocolEscrowBeforeRelease = escrow.balanceOf(protocol);
        uint256 creatorEscrowBeforeRelease = escrow.balanceOf(creator);
        vm.warp(block.timestamp + vault.VESTING_DURATION());
        vm.prank(makeAddr("unrelated"));
        vm.expectRevert(RetroPickBuybackVaultV2.NotVestBeneficiary.selector);
        vault.release(tokenAddress);
        vm.prank(creator);
        assertEq(vault.release(tokenAddress), locked);
        assertEq(vault.totalReleased(tokenAddress), locked);
        assertEq(RetroPickLauncherTokenV2(tokenAddress).balanceOf(address(vault)), 0);
        assertEq(RetroPickLauncherTokenV2(tokenAddress).balanceOf(address(escrow)), locked);
        assertEq(escrow.balanceOf(protocol), protocolEscrowBeforeRelease);
        assertEq(escrow.balanceOf(creator), creatorEscrowBeforeRelease);
        assertEq(escrow.balanceOfToken(protocol, tokenAddress), locked * 3_000 / 10_000);
        assertEq(escrow.balanceOfToken(creator, tokenAddress), locked - locked * 3_000 / 10_000);
    }
}
