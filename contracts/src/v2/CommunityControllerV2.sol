// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {ICommunityControllerV2} from "./CommunityPolicyRegistryV2.sol";

/// @notice Changes future administration only. This contract never holds or redirects claims.
contract CommunityControllerV2 is ICommunityControllerV2 {
    address public controller;
    uint256 public controllerEpoch;
    address public immutable guardian;
    uint256 public nonce;
    address public pendingController;
    uint256 public effectiveAt;
    bool public recovery;
    error Unauthorized();
    error InvalidTransition();
    event Scheduled(uint256 indexed nonce, address indexed replacement, uint256 effectiveAt, bool recovery);
    event Cancelled(uint256 indexed nonce);
    event Accepted(uint256 indexed nonce, address indexed controller, uint256 generation);

    constructor(address initial, address guardian_) {
        if (initial == address(0) || guardian_ == address(0)) revert InvalidTransition();
        controller = initial;
        guardian = guardian_;
    }

    function schedule(address replacement, bool recover) external {
        if (recover ? msg.sender != guardian : msg.sender != controller) revert Unauthorized();
        if (replacement == address(0) || replacement == controller || (!recover && pendingController != address(0))) {
            revert InvalidTransition();
        }
        // Only the declared guardian may replace a pending voluntary transition.
        if (recovery && pendingController != address(0)) revert InvalidTransition();
        pendingController = replacement;
        recovery = recover;
        effectiveAt = block.timestamp + (recover ? 7 days : 3 days);
        ++nonce;
        emit Scheduled(nonce, replacement, effectiveAt, recover);
    }

    function cancel(uint256 expectedNonce) external {
        if (recovery ? msg.sender != guardian : msg.sender != controller) revert Unauthorized();
        if (pendingController == address(0) || expectedNonce != nonce) revert InvalidTransition();
        delete pendingController;
        delete effectiveAt;
        delete recovery;
        emit Cancelled(nonce);
    }

    /// @notice Clears only an expired transition; never changes controller or economic rights.
    function expire(uint256 expectedNonce) external {
        if (pendingController == address(0) || expectedNonce != nonce || block.timestamp <= effectiveAt + 7 days) {
            revert InvalidTransition();
        }
        delete pendingController;
        delete effectiveAt;
        delete recovery;
        emit Cancelled(nonce);
    }

    function accept(uint256 expectedNonce) external {
        if (
            msg.sender != pendingController || expectedNonce != nonce || block.timestamp < effectiveAt
                || block.timestamp > effectiveAt + 7 days
        ) revert InvalidTransition();
        controller = msg.sender;
        ++controllerEpoch;
        delete pendingController;
        delete effectiveAt;
        delete recovery;
        emit Accepted(nonce, controller, controllerEpoch);
    }
}
