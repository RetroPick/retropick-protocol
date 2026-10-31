// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {Test} from "forge-std/Test.sol";
import {
    CommunityPolicyRegistryV2 as R,
    ICommunityControllerV2,
    ICommunityCheckpointV2
} from "../../../src/v2-research-experiment/CommunityPolicyRegistryV2.sol";

contract AuthorityMock is ICommunityControllerV2 {
    address public controller;
    uint256 public controllerEpoch;

    constructor(address c) {
        controller = c;
    }

    function change(address c) external {
        controller = c;
        ++controllerEpoch;
    }
}

contract CheckpointMock is ICommunityCheckpointV2 {
    uint256 public pending;
    uint256 public calls;
    bool public fail;
    bool public reentered;
    R public target;
    uint256 public nonce;

    function configure(uint256 p, bool f) external {
        pending = p;
        fail = f;
    }

    function callback(R r, uint256 n) external {
        target = r;
        nonce = n;
    }

    function checkpoint(uint256) external {
        require(!fail, "injected");
        ++calls;
        if (address(target) != address(0)) {
            (reentered,) = address(target).call(abi.encodeCall(R.activatePolicy, (nonce)));
        }
    }
}

contract CommunityPolicyRegistryV2Test is Test {
    R r;
    AuthorityMock auth;
    CheckpointMock source;
    address treasury = address(100);

    function a(uint16 s) internal view returns (R.Allocation[] memory v) {
        v = new R.Allocation[](2);
        v[0] = R.Allocation(address(200), s, 0);
        v[1] = R.Allocation(treasury, uint16(10000 - s), 2);
    }

    function setUp() public {
        auth = new AuthorityMock(address(this));
        source = new CheckpointMock();
        address[5] memory m;
        m[0] = treasury;
        r = new R(address(1), auth, source, R.Bounds(5000, 2500, 200, 3 days), 100, m, a(4000));
    }

    function testRegistryDelayHistoryReplay() public {
        bytes32 old = r.policyHash(1);
        uint256 n = r.proposePolicy(a(3000));
        vm.expectRevert(R.OutsideWindow.selector);
        r.activatePolicy(n);
        vm.warp(block.timestamp + 3 days);
        vm.prank(address(999));
        r.activatePolicy(n);
        assertEq(r.epoch(), 2);
        assertEq(r.policyHash(1), old);
        assertEq(r.policyAtVersion(1)[0].bps, 4000);
        assertEq(r.policyAtVersion(2)[0].bps, 3000);
        assertEq(source.calls(), 1);
        vm.expectRevert(R.WrongProposal.selector);
        r.activatePolicy(n);
    }

    function testRegistryCheckpointFailureAndRetry() public {
        uint256 n = r.proposePolicy(a(3000));
        vm.warp(block.timestamp + 3 days);
        source.configure(1, false);
        vm.expectRevert(R.CheckpointIncomplete.selector);
        r.activatePolicy(n);
        assertEq(r.epoch(), 1);
        assertEq(source.calls(), 0);
        (bytes32 h, uint256 pn,,,,) = r.pendingPolicy();
        assertTrue(h != bytes32(0));
        assertEq(pn, n);
        source.configure(0, true);
        vm.expectRevert(bytes("injected"));
        r.activatePolicy(n);
        source.configure(0, false);
        r.activatePolicy(n);
        assertEq(r.epoch(), 2);
    }

    function testRegistryReentry() public {
        uint256 n = r.proposePolicy(a(3000));
        source.callback(r, n);
        vm.warp(block.timestamp + 3 days);
        r.activatePolicy(n);
        assertFalse(source.reentered());
        assertEq(r.epoch(), 2);
    }

    function testRegistryCancelConcurrentAndNonce() public {
        uint256 n = r.proposePolicy(a(3000));
        vm.expectRevert(R.WrongProposal.selector);
        r.proposePolicy(a(2000));
        r.cancelPolicy(n);
        uint256 next = r.proposePolicy(a(2000));
        assertEq(next, n + 1);
        vm.warp(block.timestamp + 3 days);
        vm.expectRevert(R.WrongProposal.selector);
        r.activatePolicy(n);
        r.activatePolicy(next);
    }

    function testRegistryExpiryAndStaleController() public {
        uint256 n = r.proposePolicy(a(3000));
        vm.warp(block.timestamp + 11 days);
        vm.expectRevert(R.OutsideWindow.selector);
        r.activatePolicy(n);
        r.cancelPolicy(n);
        n = r.proposePolicy(a(3000));
        vm.warp(block.timestamp + 3 days);
        auth.change(address(123));
        vm.expectRevert(R.WrongProposal.selector);
        r.activatePolicy(n);
    }

    function testRegistryControllerRoundTripDoesNotReviveProposal() public {
        uint256 n = r.proposePolicy(a(3000));
        auth.change(address(123));
        auth.change(address(this));
        vm.warp(block.timestamp + 3 days);
        vm.expectRevert(R.WrongProposal.selector);
        r.activatePolicy(n);
    }

    function testRegistryInvalidAddressesAndShares() public {
        R.Allocation[] memory v = a(3000);
        v[0].beneficiary = treasury;
        vm.expectRevert(R.InvalidPolicy.selector);
        r.proposePolicy(v);
        v = a(3000);
        v[1].beneficiary = address(456);
        vm.expectRevert(R.InvalidPolicy.selector);
        r.proposePolicy(v);
        v = a(3000);
        v[0].bps = 2999;
        vm.expectRevert(R.InvalidPolicy.selector);
        r.proposePolicy(v);
        v = a(3000);
        v[0].beneficiary = address(0);
        vm.expectRevert(R.InvalidPolicy.selector);
        r.proposePolicy(v);
    }

    function testRegistryUnauthorized() public {
        vm.prank(address(999));
        vm.expectRevert(R.Unauthorized.selector);
        r.proposePolicy(a(3000));
        uint256 n = r.proposePolicy(a(3000));
        vm.prank(address(999));
        vm.expectRevert(R.Unauthorized.selector);
        r.cancelPolicy(n);
    }

    function testFuzzRegistryCreatorCap(uint16 s) public {
        s = uint16(bound(s, 1, 9999));
        if (s > 5000) vm.expectRevert(R.InvalidPolicy.selector);
        uint256 n = r.proposePolicy(a(s));
        if (s <= 5000) {
            vm.warp(block.timestamp + 3 days);
            r.activatePolicy(n);
            assertLe(r.policyAtVersion(2)[0].bps, 5000);
        }
    }

    function testRegistryTreasuryFloorAndCardinality() public {
        R.Allocation[] memory v = new R.Allocation[](3);
        v[0] = R.Allocation(address(200), 1000, 0);
        v[1] = R.Allocation(treasury, 2000, 2);
        v[2] = R.Allocation(address(300), 7000, 1);
        vm.expectRevert(R.InvalidPolicy.selector);
        r.proposePolicy(v);
        v = new R.Allocation[](0);
        vm.expectRevert(R.InvalidPolicy.selector);
        r.proposePolicy(v);
        v = new R.Allocation[](11);
        vm.expectRevert(R.InvalidPolicy.selector);
        r.proposePolicy(v);
    }

    function testRegistryConstructionFeeCapAndDelay() public {
        address[5] memory m;
        m[0] = treasury;
        vm.expectRevert(R.InvalidBinding.selector);
        new R(address(1), auth, source, R.Bounds(5000, 2500, 200, 3 days), 201, m, a(4000));
        vm.expectRevert(R.InvalidBinding.selector);
        new R(address(1), auth, source, R.Bounds(5000, 2500, 200, 2 days), 100, m, a(4000));
    }
}
