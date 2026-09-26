// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

/// @title Candidate cumulative-floor settlement
/// @notice Research kernel of `research/prism-model/cumulative_settlement.py`.
///         This is a candidate. It is not the canonical oracle, not MATH-1 PASS,
///         and not a promotion into `contracts/src/v2`.
/// @dev Financial invariant. Let R be the global redeemed cursor, q the quantity
///      in this call, and D = 10^18 * 10^(18 - settlementDecimals). This redemption
///      pays floor((R + q) * payoutWad / D) - floor(R * payoutWad / D).
///      Any partition of a fixed supply telescopes to floor(supply * payoutWad / D).
///      Ceil funding of that supply is the redeemable precondition.
///      A per-holder cursor is not implemented. There is no fee, governance,
///      upgrade path, leverage, or prediction-token interface.
///      Canonical `FixedPointSettlement.redeem` stays the failing per-call rule.
contract CandidateCumulativeSettlement is ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable settlementToken;
    uint256 public immutable payoutWad;
    uint8 public immutable settlementDecimals;
    /// @notice D in the invariant above.
    uint256 public immutable denominator;
    /// @notice Supply allocated in the constructor. Redemptions do not change it.
    uint256 public immutable initialSupply;

    uint256 public supplyUnits;
    uint256 public redeemedUnits;
    uint256 public paidRaw;
    bool public redeemable;
    mapping(address holder => uint256 units) public balances;

    error DecimalsOutOfRange(uint8 decimals);
    error HolderLengthMismatch(uint256 holders, uint256 amounts);
    error ZeroHolder();
    error ZeroAllocation(address holder);
    error DuplicateHolder(address holder);
    error ZeroSupply();
    error Underfunded(uint256 balance, uint256 required);
    error NotRedeemable();
    error InvalidQuantity(uint256 quantity, uint256 balance);
    error PayoutExceedsBalance(uint256 payout, uint256 balance);

    event RedeemableOpened(uint256 balance, uint256 ceilFunding);
    event Redeemed(address indexed account, uint256 quantity, uint256 payout);

    constructor(
        address settlementToken_,
        uint256 payoutWad_,
        uint8 settlementDecimals_,
        address[] memory holders,
        uint256[] memory amounts
    ) {
        if (settlementDecimals_ > 18) revert DecimalsOutOfRange(settlementDecimals_);
        if (holders.length != amounts.length) revert HolderLengthMismatch(holders.length, amounts.length);
        settlementToken = IERC20(settlementToken_);
        payoutWad = payoutWad_;
        settlementDecimals = settlementDecimals_;
        denominator = 10 ** 18 * 10 ** uint256(18 - settlementDecimals_);

        uint256 supply;
        uint256 length = holders.length;
        for (uint256 i; i < length; ++i) {
            address holder = holders[i];
            uint256 amount = amounts[i];
            if (holder == address(0)) revert ZeroHolder();
            if (amount == 0) revert ZeroAllocation(holder);
            if (balances[holder] != 0) revert DuplicateHolder(holder);
            balances[holder] = amount;
            supply += amount;
        }
        if (supply == 0) revert ZeroSupply();
        supplyUnits = supply;
        initialSupply = supply;
    }

    /// @notice Ceil funding of the supply still outstanding.
    function ceilFunding() public view returns (uint256) {
        return Math.mulDiv(supplyUnits, payoutWad, denominator, Math.Rounding.Ceil);
    }

    /// @notice One-shot floor of the constructor supply. Partitions of that supply pay this total.
    function oneShotFloor() public view returns (uint256) {
        return Math.mulDiv(initialSupply, payoutWad, denominator);
    }

    /// @notice Opens redemption when the settlement-token balance covers ceil funding.
    function makeRedeemable() external nonReentrant {
        uint256 balance = settlementToken.balanceOf(address(this));
        uint256 required = ceilFunding();
        if (balance < required) revert Underfunded(balance, required);
        redeemable = true;
        emit RedeemableOpened(balance, required);
    }

    /// @notice Pay the global-cursor delta and advance R by `quantity`.
    /// @dev Checks, then effects, then the settlement-token transfer.
    function redeem(uint256 quantity) external nonReentrant returns (uint256 payout) {
        if (!redeemable) revert NotRedeemable();
        uint256 held = balances[msg.sender];
        if (quantity == 0 || quantity > held) revert InvalidQuantity(quantity, held);

        uint256 cursor = redeemedUnits;
        uint256 beforePayout = Math.mulDiv(cursor, payoutWad, denominator);
        uint256 afterPayout = Math.mulDiv(cursor + quantity, payoutWad, denominator);
        payout = afterPayout - beforePayout;

        uint256 tokenBalance = settlementToken.balanceOf(address(this));
        if (payout > tokenBalance) revert PayoutExceedsBalance(payout, tokenBalance);

        balances[msg.sender] = held - quantity;
        supplyUnits = supplyUnits - quantity;
        redeemedUnits = cursor + quantity;
        paidRaw += payout;

        if (payout != 0) {
            settlementToken.safeTransfer(msg.sender, payout);
        }
        emit Redeemed(msg.sender, quantity, payout);
    }
}
