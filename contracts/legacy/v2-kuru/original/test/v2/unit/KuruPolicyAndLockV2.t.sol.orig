// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {Test} from "forge-std/Test.sol";
import {MockERC20} from "../../mocks/MockERC20.sol";
import {KuruLiquidityLockV2} from "../../../src/v2/KuruLiquidityLockV2.sol";
import {KuruParameterPolicyV2 as Policy} from "../../../src/v2/libraries/KuruParameterPolicyV2.sol";

contract KuruPolicyHarnessV2 {
    function validate(uint256 supply, uint8 decimals, uint256 p, uint256 q, uint256 ceiling) external pure {
        Policy.validate(supply, decimals, p, q, ceiling);
    }

    function seed(uint256 t, uint256 q, uint256 p) external pure returns (uint256) {
        return Policy.seed(t, q, p);
    }
}

contract KuruPolicyAndLockV2Test is Test {
    function testQualifiedTupleAndSeedsUseExactQuoteScale() public {
        KuruPolicyHarnessV2 policy = new KuruPolicyHarnessV2();
        policy.validate(1000 ether, 18, 1 ether, 1 ether, 50 ether);
        policy.validate(1000 ether, 6, 1e6, 1e6, 50e6);
        assertEq(policy.seed(500 ether, 1 ether, 1 ether), 250 ether);
        assertEq(policy.seed(500 ether, 1e6, 1e6), 250 ether);
        vm.expectRevert(Policy.OutsideQualifiedDomain.selector);
        policy.validate(1_000_000 ether, 18, 1 ether, 1 ether, 50 ether);
        vm.expectRevert(Policy.OutsideQualifiedDomain.selector);
        policy.validate(1000 ether, 6, 1 ether, 1 ether, 50 ether);
        vm.expectRevert(Policy.OutsideQualifiedDomain.selector);
        policy.validate(1000 ether, 18, 1 ether, 1 ether, 51 ether);
    }

    function testPermanentBoundCustodyHasNoEscapeEntrypoints() public {
        MockERC20 base = new MockERC20("Launch", "L", 18);
        MockERC20 quote = new MockERC20("Quote", "Q", 6);
        MockERC20 lp = new MockERC20("LP", "LP", 18);
        KuruLiquidityLockV2 lock = new KuruLiquidityLockV2(address(base), address(quote), address(0x1234), address(lp));
        base.mint(address(lock), 250 ether);
        lp.mint(address(lock), 100 ether);
        bytes[] memory calls = new bytes[](8);
        calls[0] = abi.encodeWithSignature("withdraw(uint256,address,address)", 100 ether, address(this), address(lock));
        calls[1] = abi.encodeWithSignature("approve(address,uint256)", address(this), type(uint256).max);
        calls[2] = abi.encodeWithSignature("transfer(address,uint256)", address(this), 100 ether);
        calls[3] = abi.encodeWithSignature(
            "execute(address,bytes)",
            address(base),
            abi.encodeWithSignature("transfer(address,uint256)", address(this), 250 ether)
        );
        calls[4] = abi.encodeWithSignature("rescue(address,address,uint256)", address(base), address(this), 250 ether);
        calls[5] = abi.encodeWithSignature("delegatecall(address,bytes)", address(base), bytes(""));
        calls[6] = abi.encodeWithSignature("burn(uint256)", 100 ether);
        calls[7] = abi.encodeWithSignature("transferOwnership(address)", address(this));
        for (uint256 i; i < calls.length; ++i) {
            (bool ok,) = address(lock).call(calls[i]);
            assertFalse(ok);
        }
        (uint256 shares, uint256 excess) = lock.protectedBalances();
        assertEq(shares, 100 ether);
        assertEq(excess, 250 ether);
        assertEq(base.allowance(address(lock), address(this)), 0);
        assertEq(lp.allowance(address(lock), address(this)), 0);
    }
}
