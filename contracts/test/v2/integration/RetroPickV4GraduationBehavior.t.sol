// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PositionInfo, PositionInfoLibrary} from "@uniswap/v4-periphery/src/libraries/PositionInfoLibrary.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {IPositionManager} from "@uniswap/v4-periphery/src/interfaces/IPositionManager.sol";
import {IAllowanceTransfer} from "permit2/src/interfaces/IAllowanceTransfer.sol";
import {GraduationCoordinatorV2} from "../../../src/v2/GraduationCoordinatorV2.sol";
import {RetroPickQuoteAssetRegistryV2} from "../../../src/v2/RetroPickQuoteAssetRegistryV2.sol";
import {QuoteAssetConfig, GraduationVenue, GraduationState} from "../../../src/v2/interfaces/IGraduationExecutorV2.sol";
import {ExactAssetV2} from "../../../src/v2/libraries/ExactAssetV2.sol";
import {RetroPickLaunchFactoryV2} from "../../../src/v2/RetroPickLaunchFactoryV2.sol";
import {RetroPickLaunchDeployerV2} from "../../../src/v2/RetroPickLaunchDeployerV2.sol";
import {UniswapV4GraduationExecutorV2} from "../../../src/v2/UniswapV4GraduationExecutorV2.sol";
import {RetroPickLaunchLockerV2} from "../../../src/v2/RetroPickLaunchLockerV2.sol";
import {RetroPickBondingCurveV2} from "../../../src/v2/RetroPickBondingCurveV2.sol";
import {RetroPickBondingCurveMathV2} from "../../../src/v2/libraries/RetroPickBondingCurveMathV2.sol";
import {RetroPickLauncherTokenV2} from "../../../src/v2/RetroPickLauncherTokenV2.sol";
import {RetroPickBuybackVaultV2} from "../../../src/v2/RetroPickBuybackVaultV2.sol";
import {RetroPickFeeEscrowV2} from "../../../src/v2/RetroPickFeeEscrowV2.sol";
import {RetroPickQuoteAssetPolicyV2} from "../../../src/v2/RetroPickQuoteAssetPolicyV2.sol";
import {RetroPickMemeHookV2} from "../../../src/v2/hooks/RetroPickMemeHookV2.sol";
import {
    FeePolicySnapshot,
    IRetroPickFeeEscrowV2,
    GraduationPhase
} from "../../../src/v2/interfaces/IRetroPickLaunchpadV2.sol";

/// @notice Stateful V4 seam for Core behavioral regression. It is not a V4 integration fixture.
contract V4BehaviorPoolManager {
    uint256 public initializationCount;
    mapping(bytes32 => bool) public initialized;
    bytes32 public lastPoolHash;

    function initialize(PoolKey calldata key, uint160 sqrtPriceX96) external returns (int24) {
        bytes32 identity = keccak256(abi.encode(key));
        require(sqrtPriceX96 != 0 && !initialized[identity], "bad pool initialization");
        initialized[identity] = true;
        initializationCount += 1;
        lastPoolHash = identity;
        return 0;
    }
}

/// @notice Minimal allowance-carrying Permit2 seam; ERC20 transferFrom remains real.
contract V4BehaviorPermit2 {
    using SafeERC20 for IERC20;

    mapping(address owner => mapping(address spender => mapping(address token => uint160 amount))) public allowances;

    function approve(address token, address spender, uint160 amount, uint48) external {
        allowances[msg.sender][spender][token] = amount;
    }

    function allowance(address owner, address token, address spender) external view returns (uint160, uint48, uint48) {
        return (allowances[owner][spender][token], 0, 0);
    }

    function pull(address from, address token, uint160 amount) external {
        uint160 allowed = allowances[from][msg.sender][token];
        require(allowed >= amount, "permit2 allowance");
        allowances[from][msg.sender][token] = allowed - amount;
        IERC20(token).safeTransferFrom(from, msg.sender, amount);
    }
}

/// @notice Executes a stateful successful mint seam with real asset movement and NFT ownership readback.
contract V4BehaviorPositionManager {
    error ForcedMintFailure();

    address public immutable poolManager;
    V4BehaviorPermit2 public immutable permit2;
    uint256 public nextTokenId = 1;
    bool public failMint;
    mapping(uint256 tokenId => address owner) public ownerOf;
    mapping(uint256 => uint128) public getPositionLiquidity;
    mapping(uint256 => PoolKey) internal keys;
    mapping(uint256 => PositionInfo) internal infos;
    bytes32 public lastPoolHash;

    constructor(address poolManager_, V4BehaviorPermit2 permit2_) {
        poolManager = poolManager_;
        permit2 = permit2_;
    }

    function setFailMint(bool value) external {
        failMint = value;
    }

    function modifyLiquidities(bytes calldata unlockData, uint256) external payable {
        if (failMint) revert ForcedMintFailure();
        (bytes memory actions, bytes[] memory params) = abi.decode(unlockData, (bytes, bytes[]));
        require(actions.length == 2 || actions.length == 3, "wrong V4 action count");
        require(params.length == actions.length, "wrong V4 parameter count");
        (
            PoolKey memory key,
            int24 tickLower,
            int24 tickUpper,
            uint256 liquidity,
            uint128 amount0,
            uint128 amount1,
            address receiver,
            bytes memory hookData
        ) = abi.decode(params[0], (PoolKey, int24, int24, uint256, uint128, uint128, address, bytes));
        require(tickLower < tickUpper && liquidity > 0 && receiver != address(0), "invalid mint");
        require(hookData.length == 0, "unexpected hook data");
        (Currency currency0, Currency currency1) = abi.decode(params[1], (Currency, Currency));
        require(Currency.unwrap(currency0) == Currency.unwrap(key.currency0), "currency0 mismatch");
        require(Currency.unwrap(currency1) == Currency.unwrap(key.currency1), "currency1 mismatch");

        uint256 nativeRequired;
        if (currency0.isAddressZero()) nativeRequired += amount0;
        else permit2.pull(msg.sender, Currency.unwrap(currency0), uint160(amount0));
        if (currency1.isAddressZero()) nativeRequired += amount1;
        else permit2.pull(msg.sender, Currency.unwrap(currency1), uint160(amount1));
        require(msg.value == nativeRequired, "native seed mismatch");

        lastPoolHash = keccak256(abi.encode(key));
        ownerOf[nextTokenId] = receiver;
        getPositionLiquidity[nextTokenId] = uint128(liquidity);
        keys[nextTokenId] = key;
        infos[nextTokenId] = PositionInfoLibrary.initialize(key, tickLower, tickUpper);
        nextTokenId++;
    }

    function getPoolAndPositionInfo(uint256 tokenId) external view returns (PoolKey memory, PositionInfo) {
        return (keys[tokenId], infos[tokenId]);
    }
}

/// @notice Current V4 Factory semantics before any Factory/coordinator extraction.
/// The stateful V4 seam verifies Core routing and physical custody; it does not prove real V4 compatibility.
abstract contract RetroPickV4BehaviorFixtureV2 is Test {
    address internal creator = makeAddr("v4-creator");
    address internal protocol = makeAddr("v4-protocol");
    address internal hook = makeAddr("v4-hook");

    RetroPickLaunchFactoryV2 internal factory;
    GraduationCoordinatorV2 internal coordinator;
    RetroPickQuoteAssetRegistryV2 internal registry;
    RetroPickLaunchLockerV2 internal locker;
    RetroPickFeeEscrowV2 internal escrow;
    V4BehaviorPoolManager internal pool;
    V4BehaviorPositionManager internal position;
    V4BehaviorPermit2 internal permit2;

    function setUp() public virtual {
        vm.chainId(10143);
        _configure();
    }

    function _configure() internal {
        pool = new V4BehaviorPoolManager();
        permit2 = new V4BehaviorPermit2();
        position = new V4BehaviorPositionManager(address(pool), permit2);
        escrow = new RetroPickFeeEscrowV2();
        locker = new RetroPickLaunchLockerV2(address(this), address(position));
        RetroPickBuybackVaultV2 buybackVault = new RetroPickBuybackVaultV2(
            address(this), RetroPickMemeHookV2(payable(hook)), IRetroPickFeeEscrowV2(address(escrow))
        );
        registry = new RetroPickQuoteAssetRegistryV2(address(this));
        coordinator = new GraduationCoordinatorV2(address(this));
        _admit(address(0), 100 ether, 100 ether, 18);
        factory = RetroPickLaunchFactoryV2(
            payable(vm.deployCode(
                    "RetroPickLaunchFactoryV2.sol:RetroPickLaunchFactoryV2",
                    abi.encode(
                        address(this),
                        IPoolManager(address(pool)),
                        IPositionManager(address(position)),
                        IAllowanceTransfer(address(permit2)),
                        locker,
                        RetroPickMemeHookV2(payable(hook)),
                        IRetroPickFeeEscrowV2(address(escrow)),
                        buybackVault,
                        registry,
                        coordinator,
                        0
                    )
                ))
        );
        RetroPickLaunchDeployerV2 deployer = RetroPickLaunchDeployerV2(
            vm.deployCode("RetroPickLaunchDeployerV2.sol:RetroPickLaunchDeployerV2", abi.encode(address(factory)))
        );
        UniswapV4GraduationExecutorV2 executor = UniswapV4GraduationExecutorV2(
            payable(vm.deployCode(
                    "UniswapV4GraduationExecutorV2.sol:UniswapV4GraduationExecutorV2",
                    abi.encode(
                        address(coordinator),
                        IPoolManager(address(pool)),
                        IPositionManager(address(position)),
                        IAllowanceTransfer(address(permit2)),
                        locker,
                        RetroPickMemeHookV2(payable(hook)),
                        IRetroPickFeeEscrowV2(address(escrow))
                    )
                ))
        );
        locker.setFactory(address(factory));
        buybackVault.setFactory(address(factory));
        factory.setLaunchDeployer(deployer);
        coordinator.bindFactory(address(factory));
        factory.configureVenueExecutor(GraduationVenue.UNISWAP_V4, address(executor));
        locker.setGraduationExecutor(address(executor));
        vm.mockCall(hook, abi.encodeWithSignature("graduationExecutor()"), abi.encode(address(executor)));

        vm.mockCall(hook, abi.encodeWithSignature("factory()"), abi.encode(address(factory)));
        vm.mockCall(hook, abi.encodeWithSignature("buybackVault()"), abi.encode(address(buybackVault)));
        vm.mockCall(hook, abi.encodeWithSignature("poolManager()"), abi.encode(address(pool)));
        vm.mockCall(hook, abi.encodeWithSignature("feeEscrow()"), abi.encode(address(escrow)));
        vm.mockCall(hook, abi.encodeWithSignature("feeSweepOperator()"), abi.encode(address(this)));
        FeePolicySnapshot memory policy = FeePolicySnapshot(protocol, 3_000, 5_000, 100, 300);
        vm.mockCall(hook, abi.encodeWithSignature("currentFeePolicy()"), abi.encode(policy));

        factory.addLaunchConfig(
            RetroPickLaunchFactoryV2.LaunchConfig({
                supply: 1_000_000 ether,
                curveFeeBps: 100,
                phantomQuote: 100 ether,
                graduationThreshold: 100 ether,
                poolFee: 0,
                tickSpacing: 60,
                enabled: true
            })
        );
        factory.setLaunchEnabled(true);
        vm.deal(creator, 200 ether);
    }

    function _params() internal pure returns (RetroPickLaunchFactoryV2.TokenParams memory p) {
        RetroPickLauncherTokenV2.Socials memory socials;
        p = RetroPickLaunchFactoryV2.TokenParams({
            name: "V4 Behavior",
            symbol: "V4B",
            logo: "",
            description: "",
            socials: socials,
            creatorFeeRecipient: address(0),
            creatorTaxBps: 50,
            buybackEnabled: false,
            expectedEconomics: bytes32(0),
            salt: bytes32(uint256(42))
        });
    }

    function _admit(address quote, uint256 phantom, uint256 threshold, uint8 decimals) internal {
        QuoteAssetConfig memory c = QuoteAssetConfig(
            true,
            decimals,
            3,
            registry.getConfig(quote).policyVersion + 1,
            phantom,
            threshold,
            threshold * 50,
            keccak256("TEST_FIXTURE_QUALIFICATION"),
            bytes32(0)
        );
        registry.configure(quote, c);
    }
}

contract RetroPickV4GraduationBehaviorTest is RetroPickV4BehaviorFixtureV2 {
    function testNativeCurrentV4FailureRetryCustodyAndReplay() public {
        _exercise(address(0));
    }

    function testCircleCurrentV4FailureRetryCustodyAndReplay() public {
        string memory rpc = vm.envOr("MONAD_TESTNET_RPC_URL", string(""));
        if (bytes(rpc).length == 0) {
            vm.skip(true, "Circle test requires pinned Monad Testnet fork");
            return;
        }
        vm.createSelectFork(rpc, 66752717);
        assertEq(block.chainid, 10143);
        _configure();
        address circle = RetroPickQuoteAssetPolicyV2(address(factory.quoteAssetPolicy())).CIRCLE_TEST_USDC();
        _admit(circle, 100e6, 100e6, 6);
        deal(circle, creator, 150e6);
        _exercise(circle);
    }

    function testNativeRoundTripHistoryChangesTerminalQuote() public {
        _exerciseRoundingCycles(address(0), 10, 10);
    }

    function testNativeMinimumRawRoundTripPumpsReserveRepeatedly() public {
        _exerciseRoundingCycles(address(0), 2, 16);
    }

    function testOneRawQuoteCannotCompleteInitialRoundTrip() public {
        vm.prank(creator);
        (address tokenAddress, address curveAddress) = factory.launchToken(_params(), 0, address(0));
        RetroPickBondingCurveV2 curve = RetroPickBondingCurveV2(payable(curveAddress));
        vm.prank(creator);
        uint256 bought = curve.buy{value: 1}(1, 0, creator);
        vm.prank(creator);
        IERC20(tokenAddress).approve(curveAddress, bought);
        vm.expectRevert();
        vm.prank(creator);
        curve.sell(bought, 0, creator); // gross output floors to zero
        assertEq(curve.realQuoteReserve(), 1);
        assertEq(curve.trackedTokens(), 1_000_000 ether - bought);
    }

    function testCircleRoundTripHistoryChangesTerminalQuote() public {
        string memory rpc = vm.envOr("MONAD_TESTNET_RPC_URL", string(""));
        if (bytes(rpc).length == 0) {
            vm.skip(true, "Circle test requires pinned Monad Testnet fork");
            return;
        }
        vm.createSelectFork(rpc, 66752717);
        assertEq(block.chainid, 10143);
        _configure();
        address circle = RetroPickQuoteAssetPolicyV2(address(factory.quoteAssetPolicy())).CIRCLE_TEST_USDC();
        _admit(circle, 100e6, 100e6, 6);
        deal(circle, creator, 151e6);
        _exerciseRoundingCycles(circle, 10, 10);
    }

    function testCircleMinimumRawRoundTripPumpsReserveRepeatedly() public {
        string memory rpc = vm.envOr("MONAD_TESTNET_RPC_URL", string(""));
        if (bytes(rpc).length == 0) {
            vm.skip(true, "Circle test requires pinned Monad Testnet fork");
            return;
        }
        vm.createSelectFork(rpc, 66752717);
        assertEq(block.chainid, 10143);
        _configure();
        address circle = RetroPickQuoteAssetPolicyV2(address(factory.quoteAssetPolicy())).CIRCLE_TEST_USDC();
        _admit(circle, 100e6, 100e6, 6);
        deal(circle, creator, 151e6);
        _exerciseRoundingCycles(circle, 2, 16);
    }

    function testNativeCompletionQuoteMatchesImmediateFinalBuyAcrossStates() public {
        _exerciseCompletionDifferential(address(0));
    }

    function testCircleCompletionQuoteMatchesImmediateFinalBuyAcrossStates() public {
        string memory rpc = vm.envOr("MONAD_TESTNET_RPC_URL", string(""));
        if (bytes(rpc).length == 0) {
            vm.skip(true, "Circle test requires pinned Monad Testnet fork");
            return;
        }
        vm.createSelectFork(rpc, 66752717);
        assertEq(block.chainid, 10143);
        _configure();
        address circle = RetroPickQuoteAssetPolicyV2(address(factory.quoteAssetPolicy())).CIRCLE_TEST_USDC();
        _admit(circle, 100e6, 100e6, 6);
        deal(circle, creator, 250e6);
        _exerciseCompletionDifferential(circle);
    }

    function testBuybackEnabledCompletionQuoteBeforeAndAfterSweep() public {
        RetroPickLaunchFactoryV2.TokenParams memory params = _params();
        params.buybackEnabled = true;
        vm.prank(creator);
        (address tokenAddress, address curveAddress) = factory.launchToken(params, 0, address(0));
        RetroPickBondingCurveV2 curve = RetroPickBondingCurveV2(payable(curveAddress));
        vm.prank(creator);
        curve.buy{value: 20 ether}(20 ether, 0, creator);
        assertGt(curve.buybackQuoteBalance(), 0);
        _assertImmediateCompletion(curve, tokenAddress, address(0));
        curve.sweepFees(1); // trusted sweep operator; executes bounded buyback if possible
        assertEq(curve.quoteFeeBalance(), 0);
        _assertImmediateCompletion(curve, tokenAddress, address(0));
    }

    function testNativeResearchCeilingRejectsFifthCycleSell() public {
        _exerciseCeilingAttack(address(0));
    }

    function testCircleResearchCeilingRejectsFifthCycleSell() public {
        string memory rpc = vm.envOr("MONAD_TESTNET_RPC_URL", string(""));
        if (bytes(rpc).length == 0) {
            vm.skip(true, "Circle test requires pinned Monad Testnet fork");
            return;
        }
        vm.createSelectFork(rpc, 66752717);
        assertEq(block.chainid, 10143);
        _configure();
        address circle = RetroPickQuoteAssetPolicyV2(address(factory.quoteAssetPolicy())).CIRCLE_TEST_USDC();
        _admit(circle, 100e6, 100e6, 6);
        deal(circle, creator, 151e6);
        _exerciseCeilingAttack(circle);
    }

    /// @notice A generic production ceiling rejects the fifth raw-unit sell, retaining an executable final buy.
    function _exerciseCeilingAttack(address quote) internal {
        QuoteAssetConfig memory c = registry.getConfig(quote);
        c.policyVersion += 1;
        c.graduationQuoteCeiling = c.phantomQuote + 10;
        c.policyHash = bytes32(0);
        registry.configure(quote, c);
        vm.prank(creator);
        (address tokenAddress, address curveAddress) = factory.launchToken(_params(), 0, quote);
        RetroPickBondingCurveV2 curve = RetroPickBondingCurveV2(payable(curveAddress));
        uint256 ceiling = c.graduationQuoteCeiling;
        if (quote != address(0)) {
            vm.prank(creator);
            IERC20(quote).approve(curveAddress, type(uint256).max);
        }
        for (uint256 cycle; cycle < 5; ++cycle) {
            vm.prank(creator);
            uint256 bought = quote == address(0) ? curve.buy{value: 2}(2, 0, creator) : curve.buy(2, 0, creator);
            vm.prank(creator);
            IERC20(tokenAddress).approve(curveAddress, bought);
            assertLe(curve.completionTerminalQuote(), ceiling);
            if (cycle == 4) {
                assertEq(curve.completionTerminalQuote(), ceiling);
                uint256 quoteBefore = curve.trackedQuote();
                uint256 tokensBefore = curve.trackedTokens();
                vm.prank(creator);
                vm.expectRevert(
                    abi.encodeWithSelector(
                        RetroPickBondingCurveV2.CompletionCeilingExceeded.selector, c.phantomQuote + 12, ceiling
                    )
                );
                curve.sell(bought, 0, creator);
                assertEq(curve.trackedQuote(), quoteBefore);
                assertEq(curve.trackedTokens(), tokensBefore);
                assertEq(curve.completionTerminalQuote(), ceiling);
                _assertImmediateCompletion(curve, tokenAddress, quote);
            } else {
                vm.prank(creator);
                assertEq(curve.sell(bought, 0, creator), 1);
                assertLe(curve.completionTerminalQuote(), ceiling);
            }
        }
    }

    function _exerciseCompletionDifferential(address quote) internal {
        vm.prank(creator);
        (address tokenAddress, address curveAddress) = factory.launchToken(_params(), 0, quote);
        RetroPickBondingCurveV2 curve = RetroPickBondingCurveV2(payable(curveAddress));
        if (quote != address(0)) {
            vm.prank(creator);
            IERC20(quote).approve(curveAddress, type(uint256).max);
        }
        _assertImmediateCompletion(curve, tokenAddress, quote); // untouched launch

        uint256 bought;
        if (quote == address(0)) {
            vm.prank(creator);
            bought = curve.buy{value: 2}(2, 0, creator);
        } else {
            vm.prank(creator);
            bought = curve.buy(2, 0, creator);
        }
        _assertImmediateCompletion(curve, tokenAddress, quote); // tiny partial buy
        vm.prank(creator);
        IERC20(tokenAddress).approve(curveAddress, bought);
        vm.prank(creator);
        curve.sell(bought, 0, creator);
        _assertImmediateCompletion(curve, tokenAddress, quote); // reserve-gaining round trip

        uint256 largeBuy = quote == address(0) ? 20 ether : 20e6;
        if (quote == address(0)) {
            vm.prank(creator);
            bought = curve.buy{value: largeBuy}(largeBuy, 0, creator);
        } else {
            vm.prank(creator);
            bought = curve.buy(largeBuy, 0, creator);
        }
        _assertImmediateCompletion(curve, tokenAddress, quote); // pending fee/tax buckets
        vm.prank(creator);
        IERC20(tokenAddress).approve(curveAddress, bought / 2);
        vm.prank(creator);
        curve.sell(bought / 2, 0, creator);
        _assertImmediateCompletion(curve, tokenAddress, quote); // sell after large buy
        vm.prank(creator);
        curve.sweepFees(0);
        _assertImmediateCompletion(curve, tokenAddress, quote); // explicit fee sweep
    }

    /// @notice Research-only exact formula using production getAmountIn/Math.mulDiv.
    /// The Curve remains venue-agnostic and unchanged.
    function _completionTerminalQuote(RetroPickBondingCurveV2 curve)
        internal
        view
        returns (uint256 requiredGross, uint256 terminalQuote)
    {
        uint256 real = curve.realQuoteReserve();
        uint256 sellable = curve.trackedTokens() - curve.reservedTokens();
        if (sellable == 0) return (0, real);
        uint256 net =
            RetroPickBondingCurveMathV2.getAmountIn(sellable, curve.phantomQuote() + real, curve.trackedTokens(), 0);
        uint256 feeBps = curve.feeBps();
        uint256 taxBps = curve.creatorTaxBps();
        requiredGross = Math.mulDiv(net, 10_000, 10_000 - feeBps - taxBps, Math.Rounding.Ceil);
        terminalQuote = real + requiredGross - requiredGross * feeBps / 10_000 - requiredGross * taxBps / 10_000;
    }

    function _assertImmediateCompletion(RetroPickBondingCurveV2 curve, address tokenAddress, address quote) internal {
        (uint256 requiredGross, uint256 predicted) = _completionTerminalQuote(curve);
        assertGt(requiredGross, 0);
        uint256 snap = vm.snapshotState();
        if (quote == address(0)) {
            vm.deal(creator, requiredGross + 1 ether);
            vm.prank(creator);
            curve.buy{value: requiredGross}(requiredGross, 0, creator);
        } else {
            deal(quote, creator, requiredGross + 1e6);
            vm.prank(creator);
            curve.buy(requiredGross, 0, creator);
        }
        RetroPickLaunchFactoryV2.LaunchedToken memory secured = factory.getLaunchedToken(tokenAddress);
        assertEq(uint256(secured.phase), uint256(GraduationPhase.Swept));
        assertEq(secured.sweptQuote, predicted);
        assertEq(_quoteBalance(quote, address(coordinator)), predicted);
        assertTrue(vm.revertToState(snap));
        assertFalse(curve.graduated());
    }

    /// @notice Ten accepted buy/sell round trips return the token reserve to its initial
    /// value but add one raw quote unit per round to the tradeable reserve.
    function _exerciseRoundingCycles(address quote, uint256 grossPerBuy, uint256 rounds) internal {
        vm.prank(creator);
        (address tokenAddress, address curveAddress) = factory.launchToken(_params(), 0, quote);
        RetroPickBondingCurveV2 curve = RetroPickBondingCurveV2(payable(curveAddress));
        uint256 originalTokens = curve.trackedTokens();
        uint256 threshold = quote == address(0) ? 100 ether : 100e6;
        if (quote != address(0)) {
            vm.prank(creator);
            IERC20(quote).approve(curveAddress, type(uint256).max);
        }
        for (uint256 i; i < rounds; ++i) {
            uint256 bought;
            if (quote == address(0)) {
                vm.prank(creator);
                bought = curve.buy{value: grossPerBuy}(grossPerBuy, 0, creator);
            } else {
                vm.prank(creator);
                bought = curve.buy(grossPerBuy, 0, creator);
            }
            vm.prank(creator);
            IERC20(tokenAddress).approve(curveAddress, bought);
            vm.prank(creator);
            assertEq(curve.sell(bought, 0, creator), grossPerBuy - 1);
            assertEq(curve.trackedTokens(), originalTokens);
            assertEq(curve.realQuoteReserve(), i + 1);
        }

        if (quote == address(0)) {
            vm.prank(creator);
            assertEq(curve.buy{value: 150 ether}(150 ether, 0, creator), 500_000 ether);
        } else {
            vm.prank(creator);
            assertEq(curve.buy(150e6, 0, creator), 500_000 ether);
        }
        RetroPickLaunchFactoryV2.LaunchedToken memory secured = factory.getLaunchedToken(tokenAddress);
        assertEq(uint256(secured.phase), uint256(GraduationPhase.Swept));
        assertEq(secured.sweptQuote, threshold + 2 + 2 * rounds);
        assertGt(secured.sweptQuote, threshold + 2); // one-shot scenario is not an upper bound
        assertEq(_quoteBalance(quote, address(coordinator)), secured.sweptQuote);
    }

    function _exercise(address quote) internal {
        vm.prank(creator);
        (address tokenAddress, address curveAddress) = factory.launchToken(_params(), 0, quote);
        RetroPickBondingCurveV2 curve = RetroPickBondingCurveV2(payable(curveAddress));
        if (quote == address(0)) {
            vm.prank(creator);
            assertEq(curve.buy{value: 150 ether}(150 ether, 0, creator), 500_000 ether);
        } else {
            vm.startPrank(creator);
            IERC20(quote).approve(curveAddress, 150e6);
            assertEq(curve.buy(150e6, 0, creator), 500_000 ether);
            vm.stopPrank();
        }

        RetroPickLaunchFactoryV2.LaunchedToken memory secured = factory.getLaunchedToken(tokenAddress);
        assertEq(uint256(secured.phase), uint256(GraduationPhase.Swept));
        // getAmountIn's +1 and the gross fee ceil leave two raw quote units above threshold.
        assertEq(secured.sweptQuote, quote == address(0) ? 100 ether + 2 : 100e6 + 2);
        assertTrue(curve.graduated());
        assertEq(RetroPickLauncherTokenV2(tokenAddress).balanceOf(address(coordinator)), secured.sweptTokens);
        assertEq(_quoteBalance(quote, address(coordinator)), secured.sweptQuote);
        if (quote == address(0)) {
            assertEq(address(escrow).balance, escrow.totalNativeLiability());
        } else {
            assertEq(IERC20(quote).balanceOf(address(escrow)), escrow.totalTokenLiability(quote));
        }
        uint256 seedBase =
            Math.mulDiv(secured.sweptTokens, secured.sweptQuote, curve.phantomQuote() + secured.sweptQuote);
        uint256 excess = secured.sweptTokens - seedBase;

        position.setFailMint(true);
        vm.expectRevert(V4BehaviorPositionManager.ForcedMintFailure.selector);
        factory.createGraduatedPool(tokenAddress);
        assertEq(uint256(factory.getLaunchedToken(tokenAddress).phase), uint256(GraduationPhase.Swept));
        assertEq(factory.getLaunchedToken(tokenAddress).sweptQuote, secured.sweptQuote);
        assertEq(factory.getLaunchedToken(tokenAddress).sweptTokens, secured.sweptTokens);
        assertEq(_quoteBalance(quote, address(coordinator)), secured.sweptQuote);
        assertEq(RetroPickLauncherTokenV2(tokenAddress).balanceOf(address(coordinator)), secured.sweptTokens);
        assertEq(pool.initializationCount(), 0);
        assertEq(position.nextTokenId(), 1);
        assertEq(locker.lockedTokenSupply(tokenAddress), 0);

        position.setFailMint(false);
        uint256 positionId = factory.createGraduatedPool(tokenAddress);
        assertEq(positionId, 1);
        assertEq(uint256(factory.getLaunchedToken(tokenAddress).phase), uint256(GraduationPhase.PoolCreated));
        assertEq(factory.getLaunchedToken(tokenAddress).sweptQuote, 0);
        assertEq(factory.getLaunchedToken(tokenAddress).sweptTokens, 0);
        assertEq(pool.initializationCount(), 1);
        assertEq(pool.lastPoolHash(), position.lastPoolHash());
        assertEq(position.ownerOf(positionId), address(locker));
        assertEq(locker.lockedPositions(tokenAddress), positionId);
        assertTrue(locker.isLocked(tokenAddress));
        assertEq(locker.lockedTokenSupply(tokenAddress), excess);
        assertEq(RetroPickLauncherTokenV2(tokenAddress).balanceOf(address(locker)), excess);
        assertEq(RetroPickLauncherTokenV2(tokenAddress).balanceOf(address(position)), seedBase);
        assertEq(RetroPickLauncherTokenV2(tokenAddress).totalSupply(), 500_000 ether + seedBase + excess);
        assertEq(_quoteBalance(quote, address(position)), secured.sweptQuote);
        assertEq(_quoteBalance(quote, address(coordinator)), 0);

        vm.expectRevert(GraduationCoordinatorV2.WrongPhase.selector);
        factory.createGraduatedPool(tokenAddress);
        assertEq(position.nextTokenId(), 2);
        assertEq(pool.initializationCount(), 1);
        assertEq(_quoteBalance(quote, address(position)), secured.sweptQuote);
    }

    function _quoteBalance(address quote, address holder) internal view returns (uint256) {
        return quote == address(0) ? holder.balance : IERC20(quote).balanceOf(holder);
    }
}
