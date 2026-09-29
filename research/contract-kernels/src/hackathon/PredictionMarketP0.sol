// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

import {OutcomeTokenP0} from "./OutcomeTokenP0.sol";

/// @notice Hackathon-only binary Prediction research kernel.
/// @dev This contract deliberately excludes INVALID and arbitrary payout numerators.
///      It is not production Solidity and is not promoted into contracts/src/v2.
contract PredictionMarketP0 is ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public constant MAX_OUTCOME_SUPPLY = type(uint128).max;
    bytes32 public constant SEMANTIC_VERSION = keccak256("RETROPICK_PREDICTION_P0_V1");

    enum State {
        DRAFT,
        OPEN,
        LOCKED,
        RESOLVED,
        REDEEMABLE,
        ARCHIVED
    }

    enum Result {
        NONE,
        YES_WIN,
        NO_WIN
    }

    IERC20 public immutable collateral;
    address public immutable factory;
    address public immutable resolver;
    bytes32 public immutable resolutionSpecHash;
    uint8 public immutable collateralDecimals;

    OutcomeTokenP0 public immutable yesToken;
    OutcomeTokenP0 public immutable noToken;

    State public state;
    Result public result;
    uint256 public collateralLocked;
    uint256 public yesSupply;
    uint256 public noSupply;

    error NotFactory();
    error NotResolver();
    error ZeroAddress();
    error BadState();
    error ZeroAmount();
    error Shortfall();
    error NonExactCollateralTransfer(uint256 expected, uint256 debited, uint256 received);
    error SupplyCapExceeded(uint256 currentSupply, uint256 amount, uint256 maxSupply);
    error CollateralResolverOverlap();
    error StateChangedDuringTransfer();
    error Underfunded();
    error NotWinner();
    error LiveLiability();

    event MarketActivated(address indexed yesToken, address indexed noToken);
    event Split(address indexed account, uint256 amount);
    event Merged(address indexed account, uint256 amount);
    event MintClosed();
    event Resolved(Result result);
    event RedemptionOpened();
    event Redeemed(address indexed account, uint8 outcomeIndex, uint256 amount, uint256 payout);
    event WorthlessBurned(address indexed account, uint8 outcomeIndex, uint256 amount);
    event Archived();

    constructor(
        address collateral_,
        address factory_,
        address resolver_,
        bytes32 resolutionSpecHash_,
        string memory yesName,
        string memory yesSymbol,
        string memory noName,
        string memory noSymbol
    ) {
        if (collateral_ == address(0) || factory_ == address(0) || resolver_ == address(0)) {
            revert ZeroAddress();
        }
        if (collateral_ == resolver_) revert CollateralResolverOverlap();
        collateral = IERC20(collateral_);
        factory = factory_;
        resolver = resolver_;
        resolutionSpecHash = resolutionSpecHash_;
        uint8 decimals_ = IERC20Metadata(collateral_).decimals();
        collateralDecimals = decimals_;
        yesToken = new OutcomeTokenP0(address(this), 0, yesName, yesSymbol, decimals_);
        noToken = new OutcomeTokenP0(address(this), 1, noName, noSymbol, decimals_);
        state = State.DRAFT;
    }

    function activate() external nonReentrant {
        if (msg.sender != factory) revert NotFactory();
        if (state != State.DRAFT) revert BadState();
        state = State.OPEN;
        emit MarketActivated(address(yesToken), address(noToken));
    }

    function liability() public view returns (uint256) {
        if (result == Result.YES_WIN) return yesSupply;
        if (result == Result.NO_WIN) return noSupply;
        return collateralLocked;
    }

    function split(uint256 amount) external nonReentrant {
        if (state != State.OPEN) revert BadState();
        if (amount == 0) revert ZeroAmount();
        _checkSupplyCap(amount);

        uint256 beforeBalance = collateral.balanceOf(address(this));
        collateral.safeTransferFrom(msg.sender, address(this), amount);
        if (state != State.OPEN) revert StateChangedDuringTransfer();
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
        _transferCollateralExact(msg.sender, amount);
        emit Merged(msg.sender, amount);
    }

    function closeMint() external nonReentrant {
        if (msg.sender != resolver) revert NotResolver();
        if (state != State.OPEN) revert BadState();
        state = State.LOCKED;
        emit MintClosed();
    }

    function resolve(Result nextResult) external nonReentrant {
        if (msg.sender != resolver) revert NotResolver();
        if (state != State.LOCKED) revert BadState();
        if (nextResult != Result.YES_WIN && nextResult != Result.NO_WIN) revert BadState();
        result = nextResult;
        state = State.RESOLVED;
        emit Resolved(nextResult);
    }

    function openRedemption() external nonReentrant {
        if (state != State.RESOLVED) revert BadState();
        if (collateral.balanceOf(address(this)) < liability()) revert Underfunded();
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
        if (_isWinningSide(yesSide)) revert NotWinner();
        if (yesSide) {
            yesToken.burn(msg.sender, amount);
            yesSupply -= amount;
        } else {
            noToken.burn(msg.sender, amount);
            noSupply -= amount;
        }
        emit WorthlessBurned(msg.sender, yesSide ? 0 : 1, amount);
    }

    function archive() external nonReentrant {
        if (state != State.REDEEMABLE) revert BadState();
        if (liability() != 0) revert LiveLiability();
        state = State.ARCHIVED;
        emit Archived();
    }

    function _redeem(address account, bool yesSide, uint256 amount) internal returns (uint256 payout) {
        if (state != State.REDEEMABLE) revert BadState();
        if (amount == 0) revert ZeroAmount();
        if (!_isWinningSide(yesSide)) revert NotWinner();

        payout = amount;
        if (yesSide) {
            yesToken.burn(account, amount);
            yesSupply -= amount;
        } else {
            noToken.burn(account, amount);
            noSupply -= amount;
        }
        collateralLocked -= payout;
        _transferCollateralExact(account, payout);
        emit Redeemed(account, yesSide ? 0 : 1, amount, payout);
    }

    function _transferCollateralExact(address receiver, uint256 amount) private {
        uint256 beforeMarket = collateral.balanceOf(address(this));
        uint256 beforeReceiver = collateral.balanceOf(receiver);
        collateral.safeTransfer(receiver, amount);
        uint256 afterMarket = collateral.balanceOf(address(this));
        uint256 afterReceiver = collateral.balanceOf(receiver);
        uint256 debited = afterMarket <= beforeMarket ? beforeMarket - afterMarket : 0;
        uint256 received = afterReceiver >= beforeReceiver ? afterReceiver - beforeReceiver : 0;
        if (debited != amount || received != amount) {
            revert NonExactCollateralTransfer(amount, debited, received);
        }
    }

    function _checkSupplyCap(uint256 amount) internal view {
        uint256 current = yesSupply;
        if (current > MAX_OUTCOME_SUPPLY || amount > MAX_OUTCOME_SUPPLY - current) {
            revert SupplyCapExceeded(current, amount, MAX_OUTCOME_SUPPLY);
        }
    }

    function _isWinningSide(bool yesSide) internal view returns (bool) {
        return (yesSide && result == Result.YES_WIN) || (!yesSide && result == Result.NO_WIN);
    }
}
