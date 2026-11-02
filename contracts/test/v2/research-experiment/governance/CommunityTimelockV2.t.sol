// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {Test} from "forge-std/Test.sol";
import {CommunityTimelockV2 as Policy} from "../../../../src/v2-research-experiment/CommunityTimelockV2.sol";

contract GovernanceTargetV2 {
    uint256 public number;
    bool public reject;
    Policy public immutable timelock;
    address public immutable tester;

    constructor(Policy t) {
        timelock = t;
        tester = msg.sender;
    }

    function rejectCalls(bool value) external {
        require(msg.sender == tester);
        reject = value;
    }

    function setNumber(uint256 n) external payable {
        require(msg.sender == address(timelock), "wrong authority");
        require(!reject, "injected target failure");
        number = n;
    }
}

contract GovernanceCallbackV2 {
    Policy public immutable timelock;
    bool public escalated;
    bool public entered;
    bytes32 public salt;

    constructor(Policy t) {
        timelock = t;
    }

    function configure(bytes32 s) external {
        salt = s;
    }

    function attemptPrivilegeEscalation() external {
        (escalated,) =
            address(timelock).call(abi.encodeCall(timelock.grantRole, (timelock.PROPOSER_ROLE(), address(this))));
    }

    function reenterSameOperation() external {
        if (entered) return;
        entered = true;
        timelock.execute(address(this), 0, abi.encodeCall(this.reenterSameOperation, ()), bytes32(0), salt);
    }
}

contract SelfProposerConstructionProbeV2 {
    constructor() {
        address predicted = address(uint160(uint256(keccak256(abi.encodePacked(hex"d694", address(this), hex"01")))));
        new Policy(predicted);
    }
}

/// @notice Real policy/scheduler tests. Pranked proposer models role authority, not Safe signature qualification.
contract CommunityTimelockV2Test is Test {
    Policy internal t;
    GovernanceTargetV2 internal target;
    address internal proposer = makeAddr("community-proposer");
    address internal next = makeAddr("next-proposer");
    address internal keeper = makeAddr("permissionless-keeper");
    bytes32 internal constant SALT = keccak256("governance-test");

    function setUp() public {
        t = new Policy(proposer);
        target = new GovernanceTargetV2(t);
    }

    function schedule(address to, bytes memory data, bytes32 salt) internal returns (bytes32 id) {
        vm.prank(proposer);
        t.schedule(to, 0, data, bytes32(0), salt, 3 days);
        id = t.hashOperation(to, 0, data, bytes32(0), salt);
    }

    function ready(bytes32 id) internal {
        vm.warp(t.getTimestamp(id));
    }

    function execute(address to, bytes memory data, bytes32 salt) internal {
        vm.prank(keeper);
        t.execute(to, 0, data, bytes32(0), salt);
    }

    function testCEGovBootstrapRolesAndFixedDelay() public view {
        assertEq(t.getMinDelay(), 3 days);
        assertTrue(t.hasRole(t.PROPOSER_ROLE(), proposer));
        assertTrue(t.hasRole(t.CANCELLER_ROLE(), proposer));
        assertTrue(t.hasRole(t.EXECUTOR_ROLE(), address(0)));
        assertTrue(t.hasRole(bytes32(0), address(t)));
        assertFalse(t.hasRole(bytes32(0), address(this)));
        assertFalse(t.hasRole(bytes32(0), proposer));
    }

    function testCEGovRejectsInvalidProposers() public {
        vm.expectRevert(Policy.InvalidProposer.selector);
        new Policy(address(0));
        vm.expectRevert(Policy.InvalidProposer.selector);
        new Policy(address(this));
        vm.expectRevert(Policy.InvalidProposer.selector);
        new SelfProposerConstructionProbeV2();
    }

    function testCEGovPermissionlessReadyExecutionAndNoScheduleAuthority() public {
        bytes memory data = abi.encodeCall(target.setNumber, (11));
        vm.prank(keeper);
        vm.expectRevert();
        t.schedule(address(target), 0, data, 0, SALT, 3 days);
        bytes32 id = schedule(address(target), data, SALT);
        ready(id);
        execute(address(target), data, SALT);
        assertEq(target.number(), 11);
        assertTrue(t.isOperationDone(id));
        vm.expectRevert();
        t.execute(address(target), 0, data, 0, SALT);
        vm.prank(proposer);
        vm.expectRevert();
        t.schedule(address(target), 0, data, 0, SALT, 3 days);
    }

    function testCEGovInsufficientDelayAndPredecessor() public {
        bytes memory data = abi.encodeCall(target.setNumber, (11));
        vm.prank(proposer);
        vm.expectRevert();
        t.schedule(address(target), 0, data, 0, SALT, 3 days - 1);
        bytes32 predecessor = bytes32(uint256(123));
        vm.prank(proposer);
        t.schedule(address(target), 0, data, predecessor, SALT, 3 days);
        bytes32 id = t.hashOperation(address(target), 0, data, predecessor, SALT);
        ready(id);
        assertTrue(t.isReadyWithinWindow(id));
        vm.expectRevert();
        t.execute(address(target), 0, data, predecessor, SALT);
        assertEq(target.number(), 0);
    }

    function testCEGovExactReadinessAndDeadline() public {
        bytes memory data = abi.encodeCall(target.setNumber, (22));
        bytes32 id = schedule(address(target), data, SALT);
        uint256 eta = t.getTimestamp(id);
        vm.warp(eta - 1);
        vm.expectRevert();
        t.execute(address(target), 0, data, 0, SALT);
        vm.warp(eta);
        assertTrue(t.isReadyWithinWindow(id));
        vm.warp(eta + 7 days);
        assertFalse(t.isExpired(id));
        execute(address(target), data, SALT);
        assertEq(target.number(), 22);
    }

    function testCEGovExpirySeparateFromUpstreamReady() public {
        bytes memory data = abi.encodeCall(target.setNumber, (33));
        bytes32 id = schedule(address(target), data, SALT);
        vm.warp(t.getTimestamp(id) + 7 days + 1);
        assertTrue(t.isOperationReady(id));
        assertTrue(t.isExpired(id));
        assertFalse(t.isReadyWithinWindow(id));
        vm.expectRevert(abi.encodeWithSelector(Policy.OperationExpired.selector, id));
        t.execute(address(target), 0, data, 0, SALT);
        assertEq(target.number(), 0);
        vm.prank(proposer);
        t.cancel(id);
        assertFalse(t.isExpired(id));
    }

    function testCEGovCancelRequeueRestartsFullDelay() public {
        bytes memory data = abi.encodeCall(target.setNumber, (44));
        bytes32 id = schedule(address(target), data, SALT);
        ready(id);
        vm.prank(keeper);
        vm.expectRevert();
        t.cancel(id);
        vm.prank(proposer);
        t.cancel(id);
        vm.expectRevert();
        t.execute(address(target), 0, data, 0, SALT);
        schedule(address(target), data, SALT);
        vm.expectRevert();
        t.execute(address(target), 0, data, 0, SALT);
        ready(id);
        execute(address(target), data, SALT);
        assertEq(target.number(), 44);
    }

    function testCEGovDirectAndGovernedDelayChangeAlwaysFails() public {
        vm.expectRevert(Policy.ImmutableTimelockPolicy.selector);
        t.updateDelay(0);
        bytes memory data = abi.encodeCall(t.updateDelay, (0));
        bytes32 id = schedule(address(t), data, SALT);
        ready(id);
        vm.expectRevert(Policy.ImmutableTimelockPolicy.selector);
        t.execute(address(t), 0, data, 0, SALT);
        assertEq(t.getMinDelay(), 3 days);
        assertTrue(t.isOperationReady(id));
    }

    function testCEGovImmutableAdminExecutorAndRenunciation() public {
        bytes32[3] memory roles = [bytes32(0), t.EXECUTOR_ROLE(), keccak256("unknown")];
        for (uint256 i; i < roles.length; ++i) {
            vm.expectRevert(Policy.ImmutableTimelockPolicy.selector);
            t.grantRole(roles[i], next);
            vm.expectRevert(Policy.ImmutableTimelockPolicy.selector);
            t.revokeRole(roles[i], address(t));
            vm.prank(proposer);
            vm.expectRevert(Policy.ImmutableTimelockPolicy.selector);
            t.renounceRole(roles[i], proposer);
        }
        bytes32 role = t.PROPOSER_ROLE();
        vm.prank(proposer);
        vm.expectRevert(Policy.ImmutableTimelockPolicy.selector);
        t.renounceRole(role, proposer);
        role = t.CANCELLER_ROLE();
        vm.prank(proposer);
        vm.expectRevert(Policy.ImmutableTimelockPolicy.selector);
        t.renounceRole(role, proposer);
        role = t.EXECUTOR_ROLE();
        bytes memory data = abi.encodeCall(t.revokeRole, (role, address(0)));
        bytes32 id = schedule(address(t), data, SALT);
        ready(id);
        vm.expectRevert(Policy.ImmutableTimelockPolicy.selector);
        t.execute(address(t), 0, data, 0, SALT);
        assertTrue(t.hasRole(role, address(0)));
        assertTrue(t.hasRole(bytes32(0), address(t)));
    }

    function testCEGovMembershipRequiresSelfCallAndRejectsZero() public {
        bytes32 role = t.PROPOSER_ROLE();
        vm.prank(proposer);
        vm.expectRevert();
        t.grantRole(role, next);
        vm.prank(proposer);
        vm.expectRevert();
        t.revokeRole(role, proposer);
        vm.expectRevert(Policy.ImmutableTimelockPolicy.selector);
        t.grantRole(role, address(0));
        bytes memory data = abi.encodeCall(t.grantRole, (role, next));
        bytes32 id = schedule(address(t), data, SALT);
        ready(id);
        execute(address(t), data, SALT);
        assertTrue(t.hasRole(role, next));
    }

    function batch(bytes[] memory calls, address[] memory targets) internal returns (bytes32 id) {
        uint256[] memory values = new uint256[](calls.length);
        vm.prank(proposer);
        t.scheduleBatch(targets, values, calls, 0, SALT, 3 days);
        id = t.hashOperationBatch(targets, values, calls, 0, SALT);
    }

    function testCEGovAtomicProposerReplacement() public {
        bytes[] memory calls = new bytes[](4);
        address[] memory targets = new address[](4);
        bytes32 p = t.PROPOSER_ROLE();
        bytes32 c = t.CANCELLER_ROLE();
        calls[0] = abi.encodeCall(t.grantRole, (p, next));
        calls[1] = abi.encodeCall(t.grantRole, (c, next));
        calls[2] = abi.encodeCall(t.revokeRole, (p, proposer));
        calls[3] = abi.encodeCall(t.revokeRole, (c, proposer));
        for (uint256 i; i < 4; ++i) {
            targets[i] = address(t);
        }
        bytes32 id = batch(calls, targets);
        ready(id);
        t.executeBatch(targets, new uint256[](4), calls, 0, SALT);
        assertTrue(t.hasRole(p, next));
        assertTrue(t.hasRole(c, next));
        assertFalse(t.hasRole(p, proposer));
        assertFalse(t.hasRole(c, proposer));
        vm.prank(next);
        t.schedule(address(target), 0, abi.encodeCall(target.setNumber, (55)), 0, bytes32(uint256(2)), 3 days);
        bytes32 nextId =
            t.hashOperation(address(target), 0, abi.encodeCall(target.setNumber, (55)), 0, bytes32(uint256(2)));
        vm.prank(proposer);
        vm.expectRevert();
        t.cancel(nextId);
        vm.prank(next);
        t.cancel(nextId);
    }

    function testCEGovGovernedAdminExecutorAndRenounceBypassesRejected() public {
        bytes[] memory calls = new bytes[](5);
        calls[0] = abi.encodeCall(t.grantRole, (bytes32(0), next));
        calls[1] = abi.encodeCall(t.revokeRole, (bytes32(0), address(t)));
        calls[2] = abi.encodeCall(t.renounceRole, (bytes32(0), address(t)));
        calls[3] = abi.encodeCall(t.revokeRole, (t.EXECUTOR_ROLE(), address(0)));
        calls[4] = abi.encodeCall(t.grantRole, (t.EXECUTOR_ROLE(), next));
        for (uint256 i; i < calls.length; ++i) {
            bytes32 salt = bytes32(i + 1);
            bytes32 id = schedule(address(t), calls[i], salt);
            ready(id);
            vm.expectRevert(Policy.ImmutableTimelockPolicy.selector);
            t.execute(address(t), 0, calls[i], 0, salt);
            assertTrue(t.hasRole(bytes32(0), address(t)));
            assertFalse(t.hasRole(bytes32(0), next));
            assertTrue(t.hasRole(t.EXECUTOR_ROLE(), address(0)));
        }
    }

    function testCEGovBatchExactDeadlineAndReplay() public {
        bytes[] memory calls = new bytes[](2);
        address[] memory targets = new address[](2);
        targets[0] = address(target);
        targets[1] = address(target);
        calls[0] = abi.encodeCall(target.setNumber, (1));
        calls[1] = abi.encodeCall(target.setNumber, (2));
        bytes32 id = batch(calls, targets);
        vm.warp(t.getTimestamp(id) + 7 days);
        vm.prank(keeper);
        t.executeBatch(targets, new uint256[](2), calls, 0, SALT);
        assertEq(target.number(), 2);
        assertTrue(t.isOperationDone(id));
        vm.expectRevert();
        t.executeBatch(targets, new uint256[](2), calls, 0, SALT);
    }

    function testCEGovFixedNativeValueAndTargetAuthority() public {
        bytes memory data = abi.encodeCall(target.setNumber, (123));
        vm.expectRevert();
        target.setNumber(123);
        vm.deal(address(t), 10);
        vm.prank(proposer);
        t.schedule(address(target), 3, data, 0, SALT, 3 days);
        bytes32 id = t.hashOperation(address(target), 3, data, 0, SALT);
        ready(id);
        vm.expectRevert();
        t.execute(address(target), 4, data, 0, SALT);
        vm.prank(keeper);
        t.execute(address(target), 3, data, 0, SALT);
        assertEq(address(target).balance, 3);
        assertEq(address(t).balance, 7);
        assertEq(target.number(), 123);
    }

    function testCEGovBatchExpiryAndAtomicFailure() public {
        bytes[] memory calls = new bytes[](2);
        address[] memory targets = new address[](2);
        targets[0] = address(target);
        targets[1] = address(t);
        calls[0] = abi.encodeCall(target.setNumber, (66));
        calls[1] = abi.encodeCall(t.updateDelay, (0));
        bytes32 id = batch(calls, targets);
        ready(id);
        vm.expectRevert(Policy.ImmutableTimelockPolicy.selector);
        t.executeBatch(targets, new uint256[](2), calls, 0, SALT);
        assertEq(target.number(), 0);
        assertTrue(t.isOperationReady(id));
        vm.warp(t.getTimestamp(id) + 7 days + 1);
        vm.expectRevert(abi.encodeWithSelector(Policy.OperationExpired.selector, id));
        t.executeBatch(targets, new uint256[](2), calls, 0, SALT);
    }

    function testCEGovTargetFailureRetryAndIndependentOperation() public {
        bytes memory first = abi.encodeCall(target.setNumber, (77));
        bytes32 id = schedule(address(target), first, SALT);
        ready(id);
        target.rejectCalls(true);
        vm.expectRevert();
        t.execute(address(target), 0, first, 0, SALT);
        assertTrue(t.isOperationReady(id));
        target.rejectCalls(false);
        execute(address(target), first, SALT);
        bytes memory second = abi.encodeCall(target.setNumber, (88));
        bytes32 salt = bytes32(uint256(2));
        bytes32 id2 = schedule(address(target), second, salt);
        ready(id2);
        execute(address(target), second, salt);
        assertEq(target.number(), 88);
    }

    function testCEGovCallbackCannotEscalateRole() public {
        GovernanceCallbackV2 receiver = new GovernanceCallbackV2(t);
        bytes memory data = abi.encodeCall(receiver.attemptPrivilegeEscalation, ());
        bytes32 id = schedule(address(receiver), data, SALT);
        ready(id);
        execute(address(receiver), data, SALT);
        assertFalse(receiver.escalated());
        assertFalse(t.hasRole(t.PROPOSER_ROLE(), address(receiver)));
    }

    function testCEGovSameOperationReentryRollsBack() public {
        GovernanceCallbackV2 receiver = new GovernanceCallbackV2(t);
        receiver.configure(SALT);
        bytes memory data = abi.encodeCall(receiver.reenterSameOperation, ());
        bytes32 id = schedule(address(receiver), data, SALT);
        ready(id);
        vm.expectRevert();
        t.execute(address(receiver), 0, data, 0, SALT);
        assertFalse(receiver.entered());
        assertTrue(t.isOperationReady(id));
    }

    function testCEGovLastProposerRemovalIsExplicitLivenessRisk() public {
        bytes32 role = t.PROPOSER_ROLE();
        bytes memory data = abi.encodeCall(t.revokeRole, (role, proposer));
        bytes32 id = schedule(address(t), data, SALT);
        ready(id);
        execute(address(t), data, SALT);
        vm.prank(proposer);
        vm.expectRevert();
        t.schedule(address(target), 0, abi.encodeCall(target.setNumber, (99)), 0, SALT, 3 days);
        assertTrue(t.hasRole(bytes32(0), address(t)));
        assertTrue(t.hasRole(t.EXECUTOR_ROLE(), address(0)));
    }

    function testCEGovHugeFutureTimestampDoesNotOverflowViews() public {
        bytes memory data = abi.encodeCall(target.setNumber, (1));
        vm.prank(proposer);
        t.schedule(address(target), 0, data, 0, SALT, type(uint256).max - block.timestamp);
        bytes32 id = t.hashOperation(address(target), 0, data, 0, SALT);
        assertFalse(t.isExpired(id));
        assertFalse(t.isReadyWithinWindow(id));
        vm.expectRevert();
        t.execute(address(target), 0, data, 0, SALT);
    }

    function testFuzzCEGovCannotExecuteEarly(uint32 elapsed) public {
        elapsed = uint32(bound(elapsed, 0, 3 days - 1));
        bytes memory data = abi.encodeCall(target.setNumber, (1));
        bytes32 id = schedule(address(target), data, SALT);
        uint256 eta = t.getTimestamp(id);
        vm.warp(eta - 3 days + elapsed);
        vm.expectRevert();
        t.execute(address(target), 0, data, 0, SALT);
        assertEq(target.number(), 0);
        assertFalse(t.isOperationDone(id));
    }

    function testFuzzCEGovExecutionWindow(uint32 elapsed) public {
        elapsed = uint32(bound(elapsed, 0, 14 days));
        bytes memory data = abi.encodeCall(target.setNumber, (1));
        bytes32 id = schedule(address(target), data, SALT);
        vm.warp(t.getTimestamp(id) + elapsed);
        if (elapsed <= 7 days) {
            execute(address(target), data, SALT);
            assertEq(target.number(), 1);
        } else {
            vm.expectRevert(abi.encodeWithSelector(Policy.OperationExpired.selector, id));
            t.execute(address(target), 0, data, 0, SALT);
            assertEq(target.number(), 0);
        }
    }
}
