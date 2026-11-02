// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId} from "@uniswap/v4-core/src/types/PoolId.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {IPositionManager} from "@uniswap/v4-periphery/src/interfaces/IPositionManager.sol";
import {Actions} from "@uniswap/v4-periphery/src/libraries/Actions.sol";
import {LiquidityAmounts} from "@uniswap/v4-periphery/src/libraries/LiquidityAmounts.sol";
import {PositionInfo} from "@uniswap/v4-periphery/src/libraries/PositionInfoLibrary.sol";
import {IAllowanceTransfer} from "permit2/src/interfaces/IAllowanceTransfer.sol";
import {RetroPickLaunchLockerV2} from "./RetroPickLaunchLockerV2.sol";
import {RetroPickMemeHookV2} from "./hooks/RetroPickMemeHookV2.sol";
import {RetroPickGraduationGuardV2} from "./RetroPickGraduationGuardV2.sol";
import {RetroPickBondingCurveV2} from "./RetroPickBondingCurveV2.sol";
import {RetroPickGraduationMathV2} from "./libraries/RetroPickGraduationMathV2.sol";
import {ExecutorDonationsV2, ExecutorDonationLockV2} from "./libraries/ExecutorDonationsV2.sol";
import {ExactAssetV2} from "./libraries/ExactAssetV2.sol";
import {IRetroPickFeeEscrowV2, IRetroPickLaunchFactoryV2} from "./interfaces/IRetroPickLaunchpadV2.sol";
import {
    IGraduationCoordinatorV2,
    IGraduationExecutorV2,
    GraduationVenue,
    GraduationPacket,
    GraduationReceipt
} from "./interfaces/IGraduationExecutorV2.sol";

/// @notice Coordinator-authorized V4 worker. Every completion disposes of its own residuals atomically.
contract UniswapV4GraduationExecutorV2 is IGraduationExecutorV2, ReentrancyGuard {
    using SafeERC20 for IERC20;
    address public immutable coordinator;
    address public immutable donationLock;
    IPoolManager public immutable poolManager;
    IPositionManager public immutable positionManager;
    IAllowanceTransfer public immutable permit2;
    RetroPickLaunchLockerV2 public immutable locker;
    RetroPickMemeHookV2 public immutable memeHook;
    IRetroPickFeeEscrowV2 public immutable feeEscrow;
    RetroPickGraduationGuardV2 public immutable guard;
    bytes32 public immutable policyHash;
    error Unauthorized();
    error InvalidPacket();
    error ResidualOrAllowance();
    error InvalidPosition();

    constructor(
        address coordinator_,
        IPoolManager poolManager_,
        IPositionManager positionManager_,
        IAllowanceTransfer permit2_,
        RetroPickLaunchLockerV2 locker_,
        RetroPickMemeHookV2 hook_,
        IRetroPickFeeEscrowV2 escrow_
    ) {
        if (
            coordinator_.code.length == 0 || address(poolManager_) == address(0)
                || address(positionManager_.poolManager()) != address(poolManager_) || address(permit2_) == address(0)
                || address(locker_) == address(0) || address(hook_) == address(0) || address(escrow_) == address(0)
        ) {
            revert InvalidPacket();
        }
        donationLock = address(new ExecutorDonationLockV2(address(this)));
        coordinator = coordinator_;
        poolManager = poolManager_;
        positionManager = positionManager_;
        permit2 = permit2_;
        locker = locker_;
        memeHook = hook_;
        feeEscrow = escrow_;
        guard = new RetroPickGraduationGuardV2();
        policyHash = keccak256(
            abi.encode(
                "RetroPick.UniswapV4.TESTNET_POLICY_V1.fullrange.atomicResiduals",
                poolManager_,
                positionManager_,
                permit2_,
                locker_,
                hook_,
                escrow_
            )
        );
    }
    modifier onlyCoordinator() {
        if (msg.sender != coordinator) revert Unauthorized();
        _;
    }

    function previewReceiver(GraduationPacket calldata) external view returns (address) {
        return address(locker);
    }

    function validateLaunch(GraduationPacket calldata p, uint256 supply) external view {
        _validate(p);
        uint256 reserved = Math.mulDiv(supply, p.phantomQuote, p.phantomQuote + p.graduationThreshold);
        uint256 seed = Math.mulDiv(reserved, p.graduationThreshold, p.phantomQuote + p.graduationThreshold);
        guard.assertSeedable(p.token, p.quoteAsset, p.tickSpacing, p.graduationThreshold, seed);
        // Validate the generic completion ceiling as well as initial threshold proportions.
        guard.assertSeedable(
            p.token,
            p.quoteAsset,
            p.tickSpacing,
            p.graduationQuoteCeiling,
            Math.mulDiv(reserved, p.graduationQuoteCeiling, p.phantomQuote + p.graduationQuoteCeiling)
        );
    }

    function _validate(GraduationPacket calldata p) private view {
        if (
            p.venue != GraduationVenue.UNISWAP_V4 || p.executor != address(this) || p.venuePolicyHash != policyHash
                || p.executorCodeHash != address(this).codehash || p.protectedLPReceiver != address(locker)
                || p.protectedExcessReceiver != address(locker) || p.poolFee != 0 || p.tickSpacing <= 0
                || locker.graduationExecutor() != address(this) || memeHook.graduationExecutor() != address(this)
        ) {
            revert InvalidPacket();
        }
    }

    function execute(GraduationPacket calldata p, uint256 quoteAmount, uint256 tokenAmount)
        external
        payable
        onlyCoordinator
        nonReentrant
        returns (GraduationReceipt memory r)
    {
        _validate(p);
        if (
            quoteAmount == 0 || quoteAmount > p.graduationQuoteCeiling || tokenAmount == 0
                || msg.value != (p.quoteAsset == address(0) ? quoteAmount : 0)
        ) revert ResidualOrAllowance();
        ExecutorDonationsV2.quarantine(p.token, p.quoteAsset, msg.value, donationLock);
        ExactAssetV2.pull(p.token, coordinator, address(this), tokenAmount);
        if (p.quoteAsset != address(0)) ExactAssetV2.pull(p.quoteAsset, coordinator, address(this), quoteAmount);
        uint256 baseSeed = Math.mulDiv(tokenAmount, quoteAmount, p.phantomQuote + quoteAmount);
        guard.assertSeedable(p.token, p.quoteAsset, p.tickSpacing, quoteAmount, baseSeed);
        (PoolKey memory key, bool quoteIs0) = _key(p);
        uint256 amount0 = quoteIs0 ? quoteAmount : baseSeed;
        uint256 amount1 = quoteIs0 ? baseSeed : quoteAmount;
        uint160 price = RetroPickGraduationMathV2.sqrtPriceX96FromAmounts(amount0, amount1);
        poolManager.initialize(key, price);
        IRetroPickLaunchFactoryV2.LaunchedToken memory launch =
            IRetroPickLaunchFactoryV2(IGraduationCoordinatorV2(coordinator).factory()).getLaunchedToken(p.token);
        memeHook.registerPool(
            key,
            p.token,
            launch.creatorFeeRecipient,
            RetroPickBondingCurveV2(p.curve).buybackCreatorRecipient(),
            launch.creatorTaxBps,
            launch.buybackEnabled,
            p.feePolicy
        );
        uint256 positionId = positionManager.nextTokenId();
        uint128 liquidity = _mint(key, price, amount0, amount1);
        if (positionManager.getPositionLiquidity(positionId) != liquidity) revert InvalidPosition();
        locker.lockPosition(p.token, positionId);
        uint256 excess = IERC20(p.token).balanceOf(address(this));
        uint256 quoteResidual = ExactAssetV2.balance(p.quoteAsset, address(this));
        if (excess > tokenAmount || quoteResidual >= quoteAmount || tokenAmount - excess == 0) {
            revert InvalidPosition();
        }
        if (excess != 0) {
            IERC20(p.token).forceApprove(address(locker), excess);
            locker.lockTokenSupply(p.token, excess);
            IERC20(p.token).forceApprove(address(locker), 0);
        }
        if (quoteResidual != 0) _creditResidual(p.quoteAsset, p.feePolicy.protocolFeeRecipient, quoteResidual);
        if (
            IERC20(p.token).balanceOf(address(this)) != 0 || ExactAssetV2.balance(p.quoteAsset, address(this)) != 0
                || IERC20(p.token).allowance(address(this), address(locker)) != 0
        ) revert ResidualOrAllowance();
        r.packetHash = keccak256(abi.encode(p));
        r.destinationIdentity = PoolId.unwrap(key.toId());
        r.lpAsset = address(positionManager);
        r.positionId = positionId;
        r.seededQuote = quoteAmount - quoteResidual;
        r.seededLaunchTokens = tokenAmount - excess;
        r.quoteResidual = quoteResidual;
        r.quoteResidualReceiver = p.feePolicy.protocolFeeRecipient;
        r.protectedLPReceiver = address(locker);
        r.protectedLPAmount = liquidity;
        r.protectedExcessReceiver = address(locker);
        r.protectedExcessAmount = excess;
    }

    function verifyReceipt(GraduationPacket calldata p, GraduationReceipt calldata r) external view {
        _validate(p);
        (PoolKey memory key,) = _key(p);
        (PoolKey memory actualKey, PositionInfo info) = positionManager.getPoolAndPositionInfo(r.positionId);
        int24 lower = (TickMath.MIN_TICK / p.tickSpacing) * p.tickSpacing;
        int24 upper = (TickMath.MAX_TICK / p.tickSpacing) * p.tickSpacing;
        if (
            r.destinationIdentity != PoolId.unwrap(key.toId()) || r.lpAsset != address(positionManager)
                || r.market != address(0) || r.vault != address(0)
                || keccak256(abi.encode(key)) != keccak256(abi.encode(actualKey)) || info.tickLower() != lower
                || info.tickUpper() != upper
                || IERC721(address(positionManager)).ownerOf(r.positionId) != address(locker)
                || locker.lockedPositions(p.token) != r.positionId || !locker.isLocked(p.token)
                || positionManager.getPositionLiquidity(r.positionId) != r.protectedLPAmount
        ) revert InvalidPosition();
    }

    function _key(GraduationPacket calldata p) private view returns (PoolKey memory key, bool quoteIs0) {
        quoteIs0 = p.quoteAsset < p.token;
        key = PoolKey(
            Currency.wrap(quoteIs0 ? p.quoteAsset : p.token),
            Currency.wrap(quoteIs0 ? p.token : p.quoteAsset),
            p.poolFee,
            p.tickSpacing,
            IHooks(address(memeHook))
        );
    }

    function _mint(PoolKey memory key, uint160 price, uint256 amount0, uint256 amount1)
        private
        returns (uint128 liquidity)
    {
        int24 lower = (TickMath.MIN_TICK / key.tickSpacing) * key.tickSpacing;
        int24 upper = (TickMath.MAX_TICK / key.tickSpacing) * key.tickSpacing;
        liquidity = LiquidityAmounts.getLiquidityForAmounts(
            price, TickMath.getSqrtPriceAtTick(lower), TickMath.getSqrtPriceAtTick(upper), amount0, amount1
        );
        address asset0 = Currency.unwrap(key.currency0);
        address asset1 = Currency.unwrap(key.currency1);
        if (asset0 != address(0)) _approve(asset0, amount0);
        _approve(asset1, amount1);
        bool native = asset0 == address(0);
        bytes memory actions = native
            ? abi.encodePacked(uint8(Actions.MINT_POSITION), uint8(Actions.SETTLE_PAIR), uint8(Actions.SWEEP))
            : abi.encodePacked(uint8(Actions.MINT_POSITION), uint8(Actions.SETTLE_PAIR));
        bytes[] memory params = new bytes[](native ? 3 : 2);
        params[0] = abi.encode(
            key, lower, upper, uint256(liquidity), uint128(amount0), uint128(amount1), address(locker), bytes("")
        );
        params[1] = abi.encode(key.currency0, key.currency1);
        if (native) params[2] = abi.encode(key.currency0, address(this));
        positionManager.modifyLiquidities{value: native ? amount0 : 0}(
            abi.encode(actions, params), block.timestamp + 300
        );
        if (asset0 != address(0)) _clear(asset0);
        _clear(asset1);
    }

    function _approve(address asset, uint256 amount) private {
        if (amount > type(uint128).max || IERC20(asset).allowance(address(this), address(permit2)) != 0) {
            revert ResidualOrAllowance();
        }
        IERC20(asset).forceApprove(address(permit2), amount);
        permit2.approve(asset, address(positionManager), uint160(amount), uint48(block.timestamp + 300));
    }

    function _clear(address asset) private {
        IERC20(asset).forceApprove(address(permit2), 0);
        permit2.approve(asset, address(positionManager), 0, 0);
        (uint160 amount,,) = permit2.allowance(address(this), asset, address(positionManager));
        if (amount != 0 || IERC20(asset).allowance(address(this), address(permit2)) != 0) revert ResidualOrAllowance();
    }

    function _creditResidual(address asset, address beneficiary, uint256 amount) private {
        if (asset == address(0)) {
            feeEscrow.credit{value: amount}(beneficiary);
        } else {
            if (IERC20(asset).allowance(address(this), address(feeEscrow)) != 0) revert ResidualOrAllowance();
            IERC20(asset).forceApprove(address(feeEscrow), amount);
            feeEscrow.creditToken(beneficiary, asset, amount);
            IERC20(asset).forceApprove(address(feeEscrow), 0);
            if (IERC20(asset).allowance(address(this), address(feeEscrow)) != 0) revert ResidualOrAllowance();
        }
    }
    receive() external payable {}
}
