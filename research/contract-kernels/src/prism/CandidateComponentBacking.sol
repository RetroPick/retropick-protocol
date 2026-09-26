// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

/// @title Candidate component backing
/// @notice Research kernel of `FixedPointSeries.deposit_raw`, `mint`, and `redeem`
///         in `research/prism-model/fixed_point_model.py`.
/// @dev These are research-kernel semantics. This contract is not an accepted oracle,
///      not MATH-1 PASS, not CONTRACT-1, and not a promotion into `contracts/src/v2`.
///      It does not implement `FixedPointSettlement.redeem` or the cumulative-floor
///      settlement candidate. There is no fee, governance, upgrade path, leverage,
///      negative weight, or prediction-token interface.
///
///      Component i at supply S requires
///      ceil(S * weightWad[i] / (10^18 * 10^(18 - decimals[i]))) raw units.
///      Mint is allowed only when every component already holds at least that amount.
///      In-kind redeem decreases series liability before it decreases backing and
///      before it transfers tokens. Released raw units are the drop in that
///      requirement, not a fresh per-call rounding of the redeemed quantity.
contract CandidateComponentBacking is ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 internal constant WAD = 10 ** 18;

    uint256 public immutable componentCount;

    IERC20[] internal _tokens;
    uint256[] internal _weightsWad;
    uint8[] internal _decimals;

    uint256[] public backingRaw;
    uint256 public supplyUnits;
    mapping(address holder => uint256 units) public balanceOf;

    error DimensionMismatch(uint256 tokens, uint256 weights, uint256 decimals);
    error DecimalsOutOfRange(uint8 decimals);
    error ZeroComponent(uint256 index);
    error ZeroQuantity();
    error InsufficientBacking(uint256 index, uint256 backing, uint256 required);
    error InvalidQuantity(uint256 quantity, uint256 balance);
    error Shortfall(uint256 index, uint256 received, uint256 expected);
    error ReleaseExceedsBacking(uint256 index, uint256 release, uint256 backing);

    event Deposited(address indexed account, uint256 index, uint256 amount);
    event Minted(address indexed account, uint256 quantity, uint256 supply);
    event Redeemed(address indexed account, uint256 quantity, uint256 supply);

    constructor(address[] memory tokens, uint256[] memory weightsWad, uint8[] memory decimals_) {
        uint256 count = tokens.length;
        if (count == 0 || count != weightsWad.length || count != decimals_.length) {
            revert DimensionMismatch(count, weightsWad.length, decimals_.length);
        }
        componentCount = count;
        for (uint256 i; i < count; ++i) {
            if (tokens[i] == address(0)) revert ZeroComponent(i);
            if (decimals_[i] > 18) revert DecimalsOutOfRange(decimals_[i]);
            _tokens.push(IERC20(tokens[i]));
            _weightsWad.push(weightsWad[i]);
            _decimals.push(decimals_[i]);
            backingRaw.push(0);
        }
    }

    function componentToken(uint256 index) external view returns (address) {
        return address(_tokens[index]);
    }

    function weightWad(uint256 index) external view returns (uint256) {
        return _weightsWad[index];
    }

    function componentDecimals(uint256 index) external view returns (uint8) {
        return _decimals[index];
    }

    /// @notice Raw requirement of every component at `supply_`.
    function requiredRaw(uint256 supply_) public view returns (uint256[] memory requirement) {
        uint256 count = componentCount;
        requirement = new uint256[](count);
        for (uint256 i; i < count; ++i) {
            requirement[i] = _requiredAt(supply_, i);
        }
    }

    /// @notice Pull `amounts` before crediting them. A short receipt does not increase backing.
    /// @dev The balance check has to observe the transfer. Redeem, not deposit, is the
    ///      checks-effects-interactions path. Fee-on-transfer tokens are rejected.
    function deposit(uint256[] calldata amounts) external nonReentrant {
        uint256 count = componentCount;
        if (amounts.length != count) revert DimensionMismatch(amounts.length, count, count);
        for (uint256 i; i < count; ++i) {
            uint256 amount = amounts[i];
            if (amount == 0) continue;
            uint256 beforeBalance = _tokens[i].balanceOf(address(this));
            _tokens[i].safeTransferFrom(msg.sender, address(this), amount);
            uint256 received = _tokens[i].balanceOf(address(this)) - beforeBalance;
            if (received != amount) revert Shortfall(i, received, amount);
            backingRaw[i] += amount;
            emit Deposited(msg.sender, i, amount);
        }
        if (supplyUnits != 0) _assertBacked();
    }

    /// @notice Mint `quantity` series units against backing already on hand.
    function mint(uint256 quantity) external nonReentrant {
        if (quantity == 0) revert ZeroQuantity();
        uint256 newSupply = supplyUnits + quantity;
        uint256 count = componentCount;
        for (uint256 i; i < count; ++i) {
            uint256 requirement = _requiredAt(newSupply, i);
            if (backingRaw[i] < requirement) revert InsufficientBacking(i, backingRaw[i], requirement);
        }
        supplyUnits = newSupply;
        balanceOf[msg.sender] += quantity;
        emit Minted(msg.sender, quantity, newSupply);
    }

    /// @notice Burn series liability, then release the drop in component requirement.
    /// @dev Effects update `balanceOf`, `supplyUnits`, and `backingRaw` before any token transfer.
    function redeem(uint256 quantity) external nonReentrant returns (uint256[] memory released) {
        uint256 held = balanceOf[msg.sender];
        if (quantity == 0 || quantity > held) revert InvalidQuantity(quantity, held);

        uint256 oldSupply = supplyUnits;
        uint256 newSupply = oldSupply - quantity;
        uint256 count = componentCount;
        released = new uint256[](count);
        for (uint256 i; i < count; ++i) {
            uint256 release = _requiredAt(oldSupply, i) - _requiredAt(newSupply, i);
            if (release > backingRaw[i]) revert ReleaseExceedsBacking(i, release, backingRaw[i]);
            released[i] = release;
        }

        balanceOf[msg.sender] = held - quantity;
        supplyUnits = newSupply;
        for (uint256 i; i < count; ++i) {
            backingRaw[i] -= released[i];
        }
        for (uint256 i; i < count; ++i) {
            if (released[i] != 0) _tokens[i].safeTransfer(msg.sender, released[i]);
        }
        emit Redeemed(msg.sender, quantity, newSupply);
    }

    function _requiredAt(uint256 supply_, uint256 index) internal view returns (uint256) {
        uint256 factor = 10 ** (18 - uint256(_decimals[index]));
        return Math.mulDiv(supply_, _weightsWad[index], WAD * factor, Math.Rounding.Ceil);
    }

    function _assertBacked() internal view {
        uint256 count = componentCount;
        for (uint256 i; i < count; ++i) {
            uint256 requirement = _requiredAt(supplyUnits, i);
            if (backingRaw[i] < requirement) revert InsufficientBacking(i, backingRaw[i], requirement);
        }
    }
}
