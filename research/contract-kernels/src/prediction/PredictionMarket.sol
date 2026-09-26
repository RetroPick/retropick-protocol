// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

import {OutcomeToken} from "./OutcomeToken.sol";

/// @title PredictionMarket
/// @notice Phase-1 binary complete-set controller. This contract is the collateral vault.
/// @dev Implements the integer reference model in research/prediction-model.
///      YES_WIN pays 1, NO_WIN pays 1, INVALID pays cumulative floor(q/2) per side.
///      RESOLVED does not allow redemption. REDEEMABLE is a separate state.
///      There is no admin mint and no withdrawal of live liability.
contract PredictionMarket is ReentrancyGuard {
    using SafeERC20 for IERC20;

    enum State {
        DRAFT,
        OPEN,
        LOCKED,
        RESOLUTION_PENDING,
        RESOLVED,
        REDEEMABLE,
        ARCHIVED
    }

    enum Result {
        NONE,
        YES_WIN,
        NO_WIN,
        INVALID
    }

    enum CancelReason {
        NONE,
        CANCELLED_BEFORE_ACTIVATION
    }

    uint256 private constant PAYOUT_DENOMINATOR = 2;

    IERC20 public immutable collateral;
    address public immutable factory;
    address public immutable resolver;
    address public immutable dustSink;
    bytes32 public immutable resolutionSpecHash;
    uint8 public immutable collateralDecimals;

    OutcomeToken public immutable yesToken;
    OutcomeToken public immutable noToken;

    State public state;
    Result public result;
    CancelReason public cancelReason;
    uint256 public collateralLocked;
    uint256 public yesSupply;
    uint256 public noSupply;
    uint256 public yesRedeemed;
    uint256 public noRedeemed;
    uint256 public yesNumerator;
    uint256 public noNumerator;
    uint256 public collateralAtResolution;

    error NotFactory();
    error NotResolver();
    error ZeroAddress();
    error BadState();
    error ZeroAmount();
    error Shortfall();
    error Underfunded();
    error NotWorthless();
    error LiveSupply();
    error LiveLiability();

    event MarketActivated(address indexed yesToken, address indexed noToken);
    event DraftCancelled(CancelReason reason);
    event Split(address indexed account, uint256 amount);
    event Merged(address indexed account, uint256 amount);
    event MintClosed();
    event ResolutionBegun();
    event Resolved(Result result);
    event RedemptionOpened();
    event Redeemed(address indexed account, uint8 outcomeIndex, uint256 amount, uint256 payout);
    event WorthlessBurned(address indexed account, uint8 outcomeIndex, uint256 amount);
    event Archived(uint256 residual);

    /// @param collateral_ Standard ERC-20. Fee-on-transfer and rebasing tokens are not qualified.
    constructor(
        address collateral_,
        address resolver_,
        address dustSink_,
        bytes32 resolutionSpecHash_,
        string memory yesName,
        string memory yesSymbol,
        string memory noName,
        string memory noSymbol
    ) {
        if (collateral_ == address(0) || resolver_ == address(0) || dustSink_ == address(0)) revert ZeroAddress();
        collateral = IERC20(collateral_);
        factory = msg.sender;
        resolver = resolver_;
        dustSink = dustSink_;
        resolutionSpecHash = resolutionSpecHash_;
        uint8 decimals_ = IERC20Metadata(collateral_).decimals();
        collateralDecimals = decimals_;
        yesToken = new OutcomeToken(address(this), 0, yesName, yesSymbol, decimals_);
        noToken = new OutcomeToken(address(this), 1, noName, noSymbol, decimals_);
        state = State.DRAFT;
    }

    function activate() external {
        if (msg.sender != factory) revert NotFactory();
        if (state != State.DRAFT) revert BadState();
        state = State.OPEN;
        emit MarketActivated(address(yesToken), address(noToken));
    }

    /// @notice DRAFT to ARCHIVED. The factory is the same caller as activate. No collateral moves.
    function cancelDraft() external {
        if (msg.sender != factory) revert NotFactory();
        if (state != State.DRAFT) revert BadState();
        if (collateralLocked != 0) revert BadState();
        cancelReason = CancelReason.CANCELLED_BEFORE_ACTIVATION;
        state = State.ARCHIVED;
        emit DraftCancelled(cancelReason);
    }

    /// @notice P-I08. Before resolution the liability is the locked collateral.
    function liability() public view returns (uint256) {
        if (result == Result.NONE) return collateralLocked;
        uint256 y0 = yesSupply + yesRedeemed;
        uint256 n0 = noSupply + noRedeemed;
        uint256 obligation = (y0 * yesNumerator) / PAYOUT_DENOMINATOR + (n0 * noNumerator) / PAYOUT_DENOMINATOR;
        uint256 paid = (yesRedeemed * yesNumerator) / PAYOUT_DENOMINATOR + (noRedeemed * noNumerator) / PAYOUT_DENOMINATOR;
        return obligation - paid;
    }

    function split(uint256 amount) external nonReentrant {
        if (state != State.OPEN) revert BadState();
        if (amount == 0) revert ZeroAmount();
        uint256 beforeBalance = collateral.balanceOf(address(this));
        collateral.safeTransferFrom(msg.sender, address(this), amount);
        uint256 received = collateral.balanceOf(address(this)) - beforeBalance;
        if (received != amount) revert Shortfall();
        collateralLocked += amount;
        yesSupply += amount;
        noSupply += amount;
        yesToken.mint(msg.sender, amount);
        noToken.mint(msg.sender, amount);
        emit Split(msg.sender, amount);
    }

    function merge(uint256 amount) external nonReentrant {
        if (state != State.OPEN && state != State.LOCKED) revert BadState();
        if (amount == 0) revert ZeroAmount();
        yesToken.burn(msg.sender, amount);
        noToken.burn(msg.sender, amount);
        yesSupply -= amount;
        noSupply -= amount;
        collateralLocked -= amount;
        collateral.safeTransfer(msg.sender, amount);
        emit Merged(msg.sender, amount);
    }

    function closeMint() external {
        if (msg.sender != resolver) revert NotResolver();
        if (state != State.OPEN) revert BadState();
        state = State.LOCKED;
        emit MintClosed();
    }

    function beginResolution() external {
        if (msg.sender != resolver) revert NotResolver();
        if (state != State.LOCKED) revert BadState();
        state = State.RESOLUTION_PENDING;
        emit ResolutionBegun();
    }

    function resolve(Result nextResult) external {
        if (msg.sender != resolver) revert NotResolver();
        if (state != State.RESOLUTION_PENDING) revert BadState();
        if (nextResult != Result.YES_WIN && nextResult != Result.NO_WIN && nextResult != Result.INVALID) {
            revert BadState();
        }
        if (nextResult == Result.YES_WIN) {
            yesNumerator = 2;
            noNumerator = 0;
        } else if (nextResult == Result.NO_WIN) {
            yesNumerator = 0;
            noNumerator = 2;
        } else {
            yesNumerator = 1;
            noNumerator = 1;
        }
        result = nextResult;
        collateralAtResolution = collateralLocked;
        state = State.RESOLVED;
        emit Resolved(nextResult);
    }

    /// @notice Permissionless. A resolver cannot pause redemption after the result is final.
    function openRedemption() external {
        if (state != State.RESOLVED) revert BadState();
        if (collateralLocked < liability()) revert Underfunded();
        state = State.REDEEMABLE;
        emit RedemptionOpened();
    }

    function redeemYes(uint256 amount) external nonReentrant returns (uint256 payout) {
        payout = _redeem(msg.sender, true, amount);
    }

    function redeemNo(uint256 amount) external nonReentrant returns (uint256 payout) {
        payout = _redeem(msg.sender, false, amount);
    }

    function burnWorthless(bool yesSide, uint256 amount) external nonReentrant {
        if (state != State.REDEEMABLE) revert BadState();
        if (amount == 0) revert ZeroAmount();
        uint256 numerator = yesSide ? yesNumerator : noNumerator;
        if (numerator != 0) revert NotWorthless();
        if (yesSide) {
            yesToken.burn(msg.sender, amount);
            yesSupply -= amount;
        } else {
            noToken.burn(msg.sender, amount);
            noSupply -= amount;
        }
        emit WorthlessBurned(msg.sender, yesSide ? 0 : 1, amount);
    }

    function archive() external nonReentrant returns (uint256 residual) {
        if (state != State.REDEEMABLE) revert BadState();
        if (yesSupply != 0 || noSupply != 0) revert LiveSupply();
        if (liability() != 0) revert LiveLiability();
        residual = collateralLocked;
        collateralLocked = 0;
        state = State.ARCHIVED;
        if (residual != 0) collateral.safeTransfer(dustSink, residual);
        emit Archived(residual);
    }

    function _redeem(address account, bool yesSide, uint256 amount) internal returns (uint256 payout) {
        if (state != State.REDEEMABLE) revert BadState();
        if (amount == 0) revert ZeroAmount();
        uint256 numerator = yesSide ? yesNumerator : noNumerator;
        uint256 redeemed = yesSide ? yesRedeemed : noRedeemed;
        payout = ((redeemed + amount) * numerator) / PAYOUT_DENOMINATOR - (redeemed * numerator) / PAYOUT_DENOMINATOR;
        if (yesSide) {
            yesToken.burn(account, amount);
            yesSupply -= amount;
            yesRedeemed += amount;
        } else {
            noToken.burn(account, amount);
            noSupply -= amount;
            noRedeemed += amount;
        }
        collateralLocked -= payout;
        if (payout != 0) collateral.safeTransfer(account, payout);
        emit Redeemed(account, yesSide ? 0 : 1, amount, payout);
    }
}
