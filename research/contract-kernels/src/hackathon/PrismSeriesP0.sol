// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

import {OutcomeTokenP0} from "./OutcomeTokenP0.sol";
import {PredictionFactoryP0} from "./PredictionFactoryP0.sol";
import {PredictionMarketP0} from "./PredictionMarketP0.sol";

interface IPrismFactoryP0View {
    function predictionFactory() external view returns (address);
}

/// @notice Exact-lot, physically backed, in-kind PRISM P0 research kernel.
/// @dev Deliberately excludes cash settlement, cursors, shared deposits, and arbitrary sources.
contract PrismSeriesP0 is ERC20, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public constant MAX_COMPONENTS = 4;
    uint256 public constant MAX_SERIES_SUPPLY = type(uint128).max;
    uint256 public constant MAX_WEIGHT_PART = type(uint64).max;
    bytes32 public constant SEMANTIC_VERSION = keccak256("RETROPICK_PRISM_P0_V1");

    struct Component {
        address token;
        uint128 numerator;
        uint128 denominator;
        address market;
        uint8 outcomeIndex;
        bytes32 resolutionSpecHash;
    }

    PredictionFactoryP0 public immutable predictionFactory;
    address public immutable collateral;
    uint8 public immutable componentDecimals;
    uint256 public immutable lotSizeRaw;
    bytes32 public immutable payoffHash;
    bytes32 public immutable replicationHash;
    bytes32 public immutable sourceSetHash;
    Component[] private _components;

    error BadComponentCount(uint256 count);
    error ZeroAddress();
    error DuplicateComponent(address token);
    error InvalidWeight(uint256 index);
    error UnqualifiedSource(address token);
    error SourceConfigurationMismatch(address token);
    error NonUniformDecimals(address token, uint8 expected, uint8 actual);
    error LotTooLarge(uint256 lotSize);
    error MissingCommitment();
    error OnlyPrismFactory();
    error InvalidReceiver();
    error InvalidLot(uint256 amount, uint256 lotSize);
    error ZeroAmount();
    error SupplyCapExceeded(uint256 supply, uint256 amount, uint256 maximum);
    error ShortComponentReceipt(address token, uint256 expected, uint256 received);
    error NonExactComponentTransfer(address token, uint256 expected, uint256 debited, uint256 received);
    error InsufficientWalletComponent(address token, uint256 expected, uint256 available);
    error PhysicalBackingDeficit(address token, uint256 balance, uint256 required);

    event Minted(address indexed minter, address indexed receiver, uint256 amount);
    event RedeemedInKind(address indexed holder, address indexed receiver, uint256 amount);

    constructor(
        address prismFactory_,
        address predictionFactory_,
        address[] memory tokens_,
        uint128[] memory numerators_,
        uint128[] memory denominators_,
        string memory name_,
        string memory symbol_,
        bytes32 payoffHash_,
        bytes32 replicationHash_
    ) ERC20(name_, symbol_) {
        if (prismFactory_ == address(0) || msg.sender != prismFactory_) revert OnlyPrismFactory();
        if (IPrismFactoryP0View(prismFactory_).predictionFactory() != predictionFactory_) {
            revert OnlyPrismFactory();
        }
        uint256 count = tokens_.length;
        if (count == 0 || count > MAX_COMPONENTS) revert BadComponentCount(count);
        if (count != numerators_.length || count != denominators_.length) revert BadComponentCount(count);
        if (predictionFactory_ == address(0)) revert ZeroAddress();
        if (payoffHash_ == bytes32(0) || replicationHash_ == bytes32(0)) revert MissingCommitment();

        predictionFactory = PredictionFactoryP0(predictionFactory_);
        payoffHash = payoffHash_;
        replicationHash = replicationHash_;
        sourceSetHash = keccak256(abi.encode(predictionFactory_, tokens_, numerators_, denominators_));
        collateral = predictionFactory.allowedCollateral();
        uint8 decimals_ = IERC20Metadata(collateral).decimals();
        componentDecimals = decimals_;

        uint256 lot = 1;
        for (uint256 i; i < count; ++i) {
            uint128 reducedDenominator = _validateAndStoreComponent(tokens_, numerators_, denominators_, i);
            uint256 factor = uint256(reducedDenominator) / _gcd(lot, reducedDenominator);
            if (factor != 0 && lot > MAX_SERIES_SUPPLY / factor) revert LotTooLarge(lot * factor);
            lot *= factor;
        }
        lotSizeRaw = lot;
    }

    function _validateAndStoreComponent(
        address[] memory tokens_,
        uint128[] memory numerators_,
        uint128[] memory denominators_,
        uint256 index
    ) private returns (uint128 reducedDenominator) {
        address token = tokens_[index];
        uint128 numerator = numerators_[index];
        uint128 denominator = denominators_[index];
        if (token == address(0)) revert ZeroAddress();
        if (numerator == 0 || denominator == 0 || numerator > MAX_WEIGHT_PART || denominator > MAX_WEIGHT_PART) {
            revert InvalidWeight(index);
        }
        for (uint256 j; j < index; ++j) {
            if (tokens_[j] == token) revert DuplicateComponent(token);
        }

        OutcomeTokenP0 outcome = OutcomeTokenP0(token);
        PredictionMarketP0 market = PredictionMarketP0(outcome.market());
        if (!predictionFactory.isMarket(address(market)) || market.factory() != address(predictionFactory)) {
            revert UnqualifiedSource(token);
        }
        if (
            market.collateral() != IERC20(collateral)
                || market.SEMANTIC_VERSION() != keccak256("RETROPICK_PREDICTION_P0_V1")
                || outcome.outcomeIndex() > 1
                || (outcome.outcomeIndex() == 0 && address(market.yesToken()) != token)
                || (outcome.outcomeIndex() == 1 && address(market.noToken()) != token)
        ) revert SourceConfigurationMismatch(token);

        uint8 sourceDecimals = IERC20Metadata(token).decimals();
        if (sourceDecimals != componentDecimals) {
            revert NonUniformDecimals(token, componentDecimals, sourceDecimals);
        }

        uint256 divisor = _gcd(numerator, denominator);
        uint128 reducedNumerator = uint128(uint256(numerator) / divisor);
        reducedDenominator = uint128(uint256(denominator) / divisor);
        _components.push(
            Component({
                token: token,
                numerator: reducedNumerator,
                denominator: reducedDenominator,
                market: address(market),
                outcomeIndex: outcome.outcomeIndex(),
                resolutionSpecHash: market.resolutionSpecHash()
            })
        );
    }

    function decimals() public view override returns (uint8) {
        return componentDecimals;
    }

    function componentCount() external view returns (uint256) {
        return _components.length;
    }

    function component(uint256 index) external view returns (Component memory) {
        return _components[index];
    }

    function componentAmount(uint256 prismAmount, uint256 index) public view returns (uint256) {
        _validateLot(prismAmount);
        Component storage item = _components[index];
        // lot validity makes this division exact; divide before multiplying to avoid an unnecessary wide product.
        // Both terms are bounded to uint128/uint64 respectively; the product fits uint192.
        return (prismAmount / item.denominator) * item.numerator;
    }

    function requiredBacking(uint256 supply, uint256 index) public view returns (uint256) {
        if (supply != 0 && supply % lotSizeRaw != 0) revert InvalidLot(supply, lotSizeRaw);
        Component storage item = _components[index];
        return (supply / item.denominator) * item.numerator;
    }

    function mint(uint256 amount, address receiver) external nonReentrant {
        _validateAmount(amount);
        if (receiver == address(0)) revert ZeroAddress();
        if (receiver == address(this)) revert InvalidReceiver();
        uint256 supply = totalSupply();
        if (amount > MAX_SERIES_SUPPLY - supply) revert SupplyCapExceeded(supply, amount, MAX_SERIES_SUPPLY);

        uint256 count = _components.length;
        uint256[] memory amounts = new uint256[](count);
        for (uint256 i; i < count; ++i) amounts[i] = componentAmount(amount, i);

        for (uint256 i; i < count; ++i) {
            IERC20 token = IERC20(_components[i].token);
            uint256 beforeBalance = token.balanceOf(address(this));
            token.safeTransferFrom(msg.sender, address(this), amounts[i]);
            uint256 afterBalance = token.balanceOf(address(this));
            uint256 received = afterBalance - beforeBalance;
            if (received != amounts[i]) revert ShortComponentReceipt(address(token), amounts[i], received);
        }

        _mint(receiver, amount);
        _assertPhysicalBacking(totalSupply());
        emit Minted(msg.sender, receiver, amount);
    }

    function redeemInKind(uint256 amount, address receiver) external nonReentrant {
        _validateAmount(amount);
        if (receiver == address(0)) revert ZeroAddress();
        if (receiver == address(this)) revert InvalidReceiver();
        uint256 supply = totalSupply();
        uint256 count = _components.length;
        uint256[] memory amounts = new uint256[](count);
        for (uint256 i; i < count; ++i) amounts[i] = componentAmount(amount, i);

        _burn(msg.sender, amount);
        uint256 remainingSupply = supply - amount;
        for (uint256 i; i < count; ++i) {
            IERC20 token = IERC20(_components[i].token);
            _transferComponentExact(token, receiver, amounts[i]);
            uint256 balance = token.balanceOf(address(this));
            uint256 required = requiredBacking(remainingSupply, i);
            if (balance < required) revert PhysicalBackingDeficit(address(token), balance, required);
        }
        emit RedeemedInKind(msg.sender, receiver, amount);
    }

    function _transferComponentExact(IERC20 token, address receiver, uint256 amount) private {
        uint256 beforeSeries = token.balanceOf(address(this));
        uint256 beforeReceiver = token.balanceOf(receiver);
        token.safeTransfer(receiver, amount);
        uint256 afterSeries = token.balanceOf(address(this));
        uint256 afterReceiver = token.balanceOf(receiver);
        if (
            afterSeries > beforeSeries || beforeSeries - afterSeries != amount || afterReceiver < beforeReceiver
                || afterReceiver - beforeReceiver != amount
        ) {
            revert NonExactComponentTransfer(
                address(token),
                amount,
                beforeSeries >= afterSeries ? beforeSeries - afterSeries : 0,
                afterReceiver >= beforeReceiver ? afterReceiver - beforeReceiver : 0
            );
        }
    }

    function _validateAmount(uint256 amount) internal view {
        if (amount == 0) revert ZeroAmount();
        _validateLot(amount);
    }

    function _validateLot(uint256 amount) internal view {
        if (amount % lotSizeRaw != 0) revert InvalidLot(amount, lotSizeRaw);
    }

    function _assertPhysicalBacking(uint256 supply) internal view {
        for (uint256 i; i < _components.length; ++i) {
            IERC20 token = IERC20(_components[i].token);
            uint256 balance = token.balanceOf(address(this));
            uint256 required = requiredBacking(supply, i);
            if (balance < required) revert PhysicalBackingDeficit(address(token), balance, required);
        }
    }

    function _gcd(uint256 a, uint256 b) private pure returns (uint256) {
        while (b != 0) {
            (a, b) = (b, a % b);
        }
        return a;
    }
}
