// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";

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
import {GraduationCoordinatorV2} from "../../../src/v2-research-experiment/GraduationCoordinatorV2.sol";
import {RetroPickQuoteAssetRegistryV2} from "../../../src/v2-research-experiment/RetroPickQuoteAssetRegistryV2.sol";
import {
    QuoteAssetConfig,
    GraduationVenue,
    GraduationState
} from "../../../src/v2-research-experiment/interfaces/IGraduationExecutorV2.sol";
import {ExactAssetV2} from "../../../src/v2-research-experiment/libraries/ExactAssetV2.sol";
import {RetroPickLaunchFactoryV2} from "../../../src/v2-research-experiment/RetroPickLaunchFactoryV2.sol";
import {RetroPickLaunchDeployerV2} from "../../../src/v2-research-experiment/RetroPickLaunchDeployerV2.sol";
import {UniswapV4GraduationExecutorV2} from "../../../src/v2-research-experiment/UniswapV4GraduationExecutorV2.sol";
import {RetroPickLaunchLockerV2} from "../../../src/v2-research-experiment/RetroPickLaunchLockerV2.sol";
import {RetroPickBondingCurveV2} from "../../../src/v2-research-experiment/RetroPickBondingCurveV2.sol";
import {
    RetroPickBondingCurveMathV2
} from "../../../src/v2-research-experiment/libraries/RetroPickBondingCurveMathV2.sol";
import {RetroPickLauncherTokenV2} from "../../../src/v2-research-experiment/RetroPickLauncherTokenV2.sol";
import {RetroPickBuybackVaultV2} from "../../../src/v2-research-experiment/RetroPickBuybackVaultV2.sol";
import {RetroPickFeeEscrowV2} from "../../../src/v2-research-experiment/RetroPickFeeEscrowV2.sol";
import {RetroPickQuoteAssetPolicyV2} from "../../../src/v2-research-experiment/RetroPickQuoteAssetPolicyV2.sol";
import {RetroPickMemeHookV2} from "../../../src/v2-research-experiment/hooks/RetroPickMemeHookV2.sol";
import {
    FeePolicySnapshot,
    IRetroPickFeeEscrowV2,
    GraduationPhase
} from "../../../src/v2-research-experiment/interfaces/IRetroPickLaunchpadV2.sol";

/// @notice Stateful V4 seam for Core behavioral regression. It is not a V4 integration fixture.
contract CEV4BehaviorPoolManager {
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
contract CEV4BehaviorPermit2 {
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
contract CEV4BehaviorPositionManager {
    error ForcedMintFailure();

    address public immutable poolManager;
    CEV4BehaviorPermit2 public immutable permit2;
    uint256 public nextTokenId = 1;
    bool public failMint;
    mapping(uint256 tokenId => address owner) public ownerOf;
    mapping(uint256 => uint128) public getPositionLiquidity;
    mapping(uint256 => PoolKey) internal keys;
    mapping(uint256 => PositionInfo) internal infos;
    bytes32 public lastPoolHash;

    constructor(address poolManager_, CEV4BehaviorPermit2 permit2_) {
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
abstract contract CommunityV4BehaviorFixtureV2 is Test {
    address internal creator = makeAddr("v4-creator");
    address internal protocol = makeAddr("v4-protocol");
    address internal hook = makeAddr("v4-hook");

    RetroPickLaunchFactoryV2 internal factory;
    GraduationCoordinatorV2 internal coordinator;
    RetroPickQuoteAssetRegistryV2 internal registry;
    RetroPickLaunchLockerV2 internal locker;
    RetroPickFeeEscrowV2 internal escrow;
    CEV4BehaviorPoolManager internal pool;
    CEV4BehaviorPositionManager internal position;
    CEV4BehaviorPermit2 internal permit2;

    function setUp() public virtual {
        vm.chainId(10143);
        _configure();
    }

    function _configure() internal {
        pool = new CEV4BehaviorPoolManager();
        permit2 = new CEV4BehaviorPermit2();
        position = new CEV4BehaviorPositionManager(address(pool), permit2);
        escrow = new RetroPickFeeEscrowV2();
        hook = address(
            new CEHookHarness(
                IPoolManager(address(pool)), IRetroPickFeeEscrowV2(address(escrow)), protocol, address(this)
            )
        );
        locker = new RetroPickLaunchLockerV2(address(this), address(position));
        RetroPickBuybackVaultV2 buybackVault = new RetroPickBuybackVaultV2(
            address(this), RetroPickMemeHookV2(payable(hook)), IRetroPickFeeEscrowV2(address(escrow))
        );
        registry = new RetroPickQuoteAssetRegistryV2(address(this));
        coordinator = new GraduationCoordinatorV2(address(this));
        _admit(address(0), 100 ether, 100 ether, 18);
        factory = RetroPickLaunchFactoryV2(
            payable(vm.deployCode(
                    "src/v2-research-experiment/RetroPickLaunchFactoryV2.sol:RetroPickLaunchFactoryV2",
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
            vm.deployCode(
                "src/v2-research-experiment/RetroPickLaunchDeployerV2.sol:RetroPickLaunchDeployerV2",
                abi.encode(address(factory))
            )
        );
        UniswapV4GraduationExecutorV2 executor = UniswapV4GraduationExecutorV2(
            payable(vm.deployCode(
                    "src/v2-research-experiment/UniswapV4GraduationExecutorV2.sol:UniswapV4GraduationExecutorV2",
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
        RetroPickMemeHookV2(payable(hook)).setFactory(address(factory));
        RetroPickMemeHookV2(payable(hook)).setBuybackVault(buybackVault);
        RetroPickMemeHookV2(payable(hook)).setGraduationExecutor(address(executor));
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

import {BaseHook} from "@uniswap/v4-hooks-public/src/base/BaseHook.sol";
import {CommunityLaunchBuilderV2 as Builder} from "../../../src/v2-research-experiment/CommunityLaunchBuilderV2.sol";
import {CommunityFeeRouterV2} from "../../../src/v2-research-experiment/CommunityFeeRouterV2.sol";
import {CommunityPolicyRegistryV2 as Registry} from "../../../src/v2-research-experiment/CommunityPolicyRegistryV2.sol";

contract CEHookHarness is RetroPickMemeHookV2 {
    using PoolIdLibrary for PoolKey;
    constructor(IPoolManager p, IRetroPickFeeEscrowV2 e, address recipient, address owner_)
        RetroPickMemeHookV2(p, e, recipient, owner_)
    {}
    // Test-only address permission bypass; fee accounting and registration remain real.
    function validateHookAddress(BaseHook) internal pure override {}

    function readInfo(PoolKey calldata key) external view returns (LaunchInfo memory) {
        return launches[key.toId()];
    }
}

contract CommunityV4RegistrationTest is CommunityV4BehaviorFixtureV2 {
    using PoolIdLibrary for PoolKey;

    function testCEV4CompletionHasZeroCommunityHookFeesAndPermanentCustody() public {
        Builder b = new Builder(address(factory));
        factory.setCommunityBuilder(b);
        Builder.Config memory cfg;
        cfg.controller = creator;
        cfg.guardian = address(0xCAFE);
        cfg.bounds = Registry.Bounds(6000, 4000, 150, 3 days);
        cfg.modules[0] = address(0xBEEF);
        cfg.allocations = new Registry.Allocation[](2);
        cfg.allocations[0] = Registry.Allocation(creator, 6000, 0);
        cfg.allocations[1] = Registry.Allocation(address(0xBEEF), 4000, 2);
        bytes memory encoded = abi.encode(cfg);
        bytes32 commitment = keccak256(abi.encode(address(b), address(b).codehash, encoded));
        RetroPickLaunchFactoryV2.TokenParams memory params = _params();
        params.expectedEconomics = factory.previewLaunchEconomics(0, address(0));
        vm.prank(creator);
        (address token, address curve) = factory.launchCommunityToken(params, 0, address(0), encoded, commitment);
        vm.prank(creator);
        RetroPickBondingCurveV2(payable(curve)).buy{value: 150 ether}(150 ether, 0, creator);
        factory.createGraduatedPool(token);
        assertEq(uint256(factory.getLaunchedToken(token).phase), uint256(GraduationPhase.PoolCreated));
        PoolKey memory key = PoolKey(Currency.wrap(address(0)), Currency.wrap(token), 0, 60, IHooks(hook));
        RetroPickMemeHookV2.LaunchInfo memory info = CEHookHarness(payable(hook)).readInfo(key);
        address router = RetroPickBondingCurveV2(payable(curve)).communityRouter();
        assertTrue(info.registered);
        assertEq(info.creator, router);
        assertEq(info.creatorTaxBps, 0);
        assertEq(info.hookFeeBps, 0);
        assertFalse(info.buybackEnabled);
        RetroPickMemeHookV2(payable(hook)).setHookFeeBps(1000);
        info = CEHookHarness(payable(hook)).readInfo(key);
        assertEq(info.hookFeeBps, 0);
        assertEq(position.ownerOf(locker.lockedPositions(token)), address(locker));
        assertGt(CommunityFeeRouterV2(payable(router)).totalLiability(), 0);
        vm.prank(creator);
        CommunityFeeRouterV2(payable(router)).claim(1);
    }
}
