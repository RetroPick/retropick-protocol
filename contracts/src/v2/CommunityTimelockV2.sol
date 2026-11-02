// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {TimelockController} from "./vendor/openzeppelin-v5.4.0/contracts/governance/TimelockController.sol";

/// @notice Experimental treasury governance policy around the pinned upstream scheduler.
/// @dev Membership changes are timelocked self-calls. No external admin, delay downgrade,
///      executor closure, or immediate role renunciation is available.
contract CommunityTimelockV2 is TimelockController {
    uint256 public constant MINIMUM_DELAY = 72 hours;
    uint256 public constant EXECUTION_WINDOW = 7 days;

    error InvalidProposer();
    error ImmutableTimelockPolicy();
    error OperationExpired(bytes32 id);

    constructor(address proposer)
        TimelockController(MINIMUM_DELAY, _single(proposer), _single(address(0)), address(0))
    {
        if (proposer == address(0) || proposer == address(this) || proposer == msg.sender) {
            revert InvalidProposer();
        }
    }

    function updateDelay(uint256) external pure override {
        revert ImmutableTimelockPolicy();
    }

    function grantRole(bytes32 role, address account) public override {
        _mutableMembership(role, account);
        super.grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public override {
        _mutableMembership(role, account);
        super.revokeRole(role, account);
    }

    function renounceRole(bytes32, address) public pure override {
        revert ImmutableTimelockPolicy();
    }

    /// @notice Expiry is separate from upstream's scheduler-only Ready state.
    function isExpired(bytes32 id) public view returns (bool) {
        uint256 eta = getTimestamp(id);
        return eta > _DONE_TIMESTAMP && block.timestamp > eta && block.timestamp - eta > EXECUTION_WINDOW;
    }

    /// @notice Does not prove predecessor completion or successful target execution.
    function isReadyWithinWindow(bytes32 id) external view returns (bool) {
        return isOperationReady(id) && !isExpired(id);
    }

    function execute(address target, uint256 value, bytes calldata payload, bytes32 predecessor, bytes32 salt)
        public
        payable
        override
    {
        _requireUnexpired(hashOperation(target, value, payload, predecessor, salt));
        super.execute(target, value, payload, predecessor, salt);
    }

    function executeBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata payloads,
        bytes32 predecessor,
        bytes32 salt
    ) public payable override {
        _requireUnexpired(hashOperationBatch(targets, values, payloads, predecessor, salt));
        super.executeBatch(targets, values, payloads, predecessor, salt);
    }

    function _requireUnexpired(bytes32 id) private view {
        if (isExpired(id)) revert OperationExpired(id);
    }

    function _mutableMembership(bytes32 role, address account) private pure {
        if ((role != PROPOSER_ROLE && role != CANCELLER_ROLE) || account == address(0)) {
            revert ImmutableTimelockPolicy();
        }
    }

    function _single(address account) private pure returns (address[] memory accounts) {
        accounts = new address[](1);
        accounts[0] = account;
    }
}
