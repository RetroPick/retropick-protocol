// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IRetroPickFeeEscrowV2} from "./interfaces/IRetroPickLaunchpadV2.sol";

/// @notice Asset-segregated pull payments for launch fees and vested buyback tokens.
/// @dev A direct donation is never credited to a recipient or counted as a liability.
///      Token credits and claims require exact sender and recipient balance deltas.
contract RetroPickFeeEscrowV2 is IRetroPickFeeEscrowV2, ReentrancyGuard {
    using SafeERC20 for IERC20;

    error ZeroAddress();
    error ZeroAmount();
    error InsufficientCredit();
    error TransferFailed();
    error InexactTokenTransfer(address token, uint256 expected, uint256 actual);
    error PhysicalBalanceDeficit(address token, uint256 physical, uint256 liability);

    event NativeCredited(address indexed payer, address indexed recipient, uint256 amount);
    event TokenCredited(address indexed payer, address indexed recipient, address indexed token, uint256 amount);
    event NativeClaimed(address indexed recipient, uint256 amount);
    event TokenClaimed(address indexed recipient, address indexed token, uint256 amount);

    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override balanceOfToken;
    uint256 public totalNativeLiability;
    mapping(address => uint256) public totalTokenLiability;

    receive() external payable {}

    function credit(address recipient) external payable override nonReentrant {
        if (recipient == address(0)) revert ZeroAddress();
        if (msg.value == 0) revert ZeroAmount();
        balanceOf[recipient] += msg.value;
        totalNativeLiability += msg.value;
        emit NativeCredited(msg.sender, recipient, msg.value);
    }

    function creditToken(address recipient, address token, uint256 amount) external override nonReentrant {
        if (recipient == address(0) || token == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();
        IERC20 asset = IERC20(token);
        uint256 beforeBalance = asset.balanceOf(address(this));
        uint256 payerBefore = asset.balanceOf(msg.sender);
        _requireTokenBacking(token, beforeBalance);
        asset.safeTransferFrom(msg.sender, address(this), amount);
        uint256 afterBalance = asset.balanceOf(address(this));
        uint256 payerAfter = asset.balanceOf(msg.sender);
        if (afterBalance < beforeBalance || afterBalance - beforeBalance != amount) {
            revert InexactTokenTransfer(token, amount, afterBalance > beforeBalance ? afterBalance - beforeBalance : 0);
        }
        if (payerAfter > payerBefore || payerBefore - payerAfter != amount) {
            revert InexactTokenTransfer(token, amount, payerBefore > payerAfter ? payerBefore - payerAfter : 0);
        }
        balanceOfToken[recipient][token] += amount;
        totalTokenLiability[token] += amount;
        emit TokenCredited(msg.sender, recipient, token, amount);
    }

    function claim() external override nonReentrant returns (uint256 amount) {
        amount = balanceOf[msg.sender];
        _claimNative(amount);
    }

    function claim(uint256 amount) external override nonReentrant returns (uint256) {
        _claimNative(amount);
        return amount;
    }

    function claimToken(address token) external override nonReentrant returns (uint256 amount) {
        amount = balanceOfToken[msg.sender][token];
        _claimToken(token, amount);
    }

    function claimToken(address token, uint256 amount) external override nonReentrant returns (uint256) {
        _claimToken(token, amount);
        return amount;
    }

    function _claimNative(uint256 amount) private {
        if (amount == 0) revert ZeroAmount();
        if (balanceOf[msg.sender] < amount) revert InsufficientCredit();
        if (address(this).balance < totalNativeLiability) {
            revert PhysicalBalanceDeficit(address(0), address(this).balance, totalNativeLiability);
        }
        balanceOf[msg.sender] -= amount;
        totalNativeLiability -= amount;
        emit NativeClaimed(msg.sender, amount);
        (bool sent,) = payable(msg.sender).call{value: amount}("");
        if (!sent) revert TransferFailed();
    }

    function _claimToken(address token, uint256 amount) private {
        if (token == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();
        if (balanceOfToken[msg.sender][token] < amount) revert InsufficientCredit();
        IERC20 asset = IERC20(token);
        uint256 beforeBalance = asset.balanceOf(address(this));
        uint256 recipientBefore = asset.balanceOf(msg.sender);
        _requireTokenBacking(token, beforeBalance);
        balanceOfToken[msg.sender][token] -= amount;
        totalTokenLiability[token] -= amount;
        asset.safeTransfer(msg.sender, amount);
        uint256 afterBalance = asset.balanceOf(address(this));
        uint256 recipientAfter = asset.balanceOf(msg.sender);
        if (afterBalance > beforeBalance || beforeBalance - afterBalance != amount) {
            revert InexactTokenTransfer(token, amount, beforeBalance > afterBalance ? beforeBalance - afterBalance : 0);
        }
        if (recipientAfter < recipientBefore || recipientAfter - recipientBefore != amount) {
            revert InexactTokenTransfer(
                token, amount, recipientAfter > recipientBefore ? recipientAfter - recipientBefore : 0
            );
        }
        _requireTokenBacking(token, afterBalance);
        emit TokenClaimed(msg.sender, token, amount);
    }

    function _requireTokenBacking(address token, uint256 physical) private view {
        uint256 liability = totalTokenLiability[token];
        if (physical < liability) revert PhysicalBalanceDeficit(token, physical, liability);
    }
}
