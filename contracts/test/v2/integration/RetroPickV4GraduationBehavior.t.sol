// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
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
import {RetroPickMemeHookV2} from "../../../src/v2/hooks/RetroPickMemeHookV2.sol";
import {
    FeePolicySnapshot,
    IRetroPickFeeEscrowV2,
    GraduationPhase
} from "../../../src/v2/interfaces/IRetroPickLaunchpadV2.sol";

/// @notice Stateful V4 seam for Core behavioral regression. It is not a V4 integration fixture.
contract V4BehaviorPoolManager {
    uint256 public initializationCount;
    bytes32 public lastPoolHash;

    function initialize(PoolKey calldata key, uint160 sqrtPriceX96) external returns (int24) {
        require(sqrtPriceX96 != 0 && initializationCount == 0, "bad pool initialization");
        initializationCount = 1;
        lastPoolHash = keccak256(abi.encode(key));
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
        nextTokenId++;
    }
}

/// @notice Current V4 Factory semantics before any Factory/coordinator extraction.
/// The stateful V4 seam verifies Core routing and physical custody; it does not prove real V4 compatibility.
contract RetroPickV4GraduationBehaviorTest is Test {
    address internal creator = makeAddr("v4-creator");
    address internal protocol = makeAddr("v4-protocol");
    address internal hook = makeAddr("v4-hook");

    RetroPickLaunchFactoryV2 internal factory;
    RetroPickLaunchLockerV2 internal locker;
    RetroPickFeeEscrowV2 internal escrow;
    V4BehaviorPoolManager internal pool;
    V4BehaviorPositionManager internal position;
    V4BehaviorPermit2 internal permit2;

    function setUp() public {
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
        factory = new RetroPickLaunchFactoryV2(
            address(this),
            IPoolManager(address(pool)),
            IPositionManager(address(position)),
            IAllowanceTransfer(address(permit2)),
            locker,
            RetroPickMemeHookV2(payable(hook)),
            IRetroPickFeeEscrowV2(address(escrow)),
            buybackVault,
            new RetroPickQuoteAssetPolicyV2(),
            0
        );
        RetroPickLaunchDeployerV2 deployer = new RetroPickLaunchDeployerV2(address(factory));
        RetroPickGraduationExecutorV2 executor = new RetroPickGraduationExecutorV2(
            IPositionManager(address(position)), IAllowanceTransfer(address(permit2)), locker, address(factory)
        );
        locker.setFactory(address(factory));
        buybackVault.setFactory(address(factory));
        factory.setLaunchDeployer(deployer);
        factory.setGraduationExecutor(executor);

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
        factory.setPairTokenEconomics(circle, 100e6, 100e6, 6);
        factory.setPairTokenApproved(circle, true);
        deal(circle, creator, 150e6);
        _exercise(circle);
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
        assertEq(RetroPickLauncherTokenV2(tokenAddress).balanceOf(address(factory)), secured.sweptTokens);
        assertEq(_quoteBalance(quote, address(factory)), secured.sweptQuote);
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
        assertEq(_quoteBalance(quote, address(factory)), secured.sweptQuote);
        assertEq(RetroPickLauncherTokenV2(tokenAddress).balanceOf(address(factory)), secured.sweptTokens);
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
        assertEq(_quoteBalance(quote, address(factory)), 0);

        vm.expectRevert(RetroPickLaunchFactoryV2.WrongGraduationPhase.selector);
        factory.createGraduatedPool(tokenAddress);
        assertEq(position.nextTokenId(), 2);
        assertEq(pool.initializationCount(), 1);
        assertEq(_quoteBalance(quote, address(position)), secured.sweptQuote);
    }

    function _quoteBalance(address quote, address holder) internal view returns (uint256) {
        return quote == address(0) ? holder.balance : IERC20(quote).balanceOf(holder);
    }
}
