// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {CandidateComponentBacking} from "../../src/prism/CandidateComponentBacking.sol";

/// @notice Records series supply at the moment backing tokens leave the kernel.
contract BackingReleaseProbe is ERC20 {
    uint8 private immutable _decimals;
    address public kernel;
    uint256 public supplyAtRelease;
    uint256 public releases;

    constructor(uint8 decimals_) ERC20("Probe", "PROBE") {
        _decimals = decimals_;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function setKernel(address kernel_) external {
        kernel = kernel_;
    }

    function _update(address from, address to, uint256 value) internal override {
        if (kernel != address(0) && from == kernel && to != address(0)) {
            supplyAtRelease = CandidateComponentBacking(kernel).supplyUnits();
            releases += 1;
        }
        super._update(from, to, value);
    }
}

/// @notice Stateful checks for the existing component-backing research kernel.
///         Handlers return before known revert paths, and a rejected mint or
///         redeem is attempted inside try/catch so the ledger state can be
///         compared. `fail_on_revert` is false. Weights, rounding, and transfers
///         are the contract's own rule.
/// forge-config: default.invariant.runs = 256
/// forge-config: default.invariant.depth = 128
/// forge-config: default.invariant.fail_on_revert = false
contract CandidateComponentBackingInvariantTest is Test {
    uint256 internal constant WAD = 10 ** 18;
    uint256 internal constant DEPOSIT_CAP = 1_000_000;
    uint256 internal constant MINT_CAP = 10_000;
    uint256 internal constant PREFUND = 10 ** 24;

    BackingReleaseProbe internal probe;
    MockCollateral internal second;
    CandidateComponentBacking internal book;
    uint256 internal minted;
    uint256 internal burned;
    uint256 internal lastSupplyAtRelease;
    uint256 internal lastSupplyBeforeRelease;
    bool internal sawRelease;

    function setUp() public {
        probe = new BackingReleaseProbe(18);
        second = new MockCollateral(18);
        address[] memory tokens = new address[](2);
        uint256[] memory weights = new uint256[](2);
        uint8[] memory decimals_ = new uint8[](2);
        tokens[0] = address(probe);
        tokens[1] = address(second);
        weights[0] = WAD / 2;
        weights[1] = WAD / 2;
        decimals_[0] = 18;
        decimals_[1] = 18;
        book = new CandidateComponentBacking(tokens, weights, decimals_);
        probe.setKernel(address(book));
        probe.mint(address(this), PREFUND);
        second.mint(address(this), PREFUND);
        probe.approve(address(book), type(uint256).max);
        second.approve(address(book), type(uint256).max);

        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = this.deposit.selector;
        selectors[1] = this.mint.selector;
        selectors[2] = this.redeem.selector;
        targetSelector(FuzzSelector({addr: address(this), selectors: selectors}));
        targetContract(address(this));
        targetSender(address(this));
        excludeContract(address(book));
        excludeContract(address(probe));
        excludeContract(address(second));
    }

    function deposit(uint96 firstAmount, uint96 secondAmount) external {
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = bound(uint256(firstAmount), 0, DEPOSIT_CAP);
        amounts[1] = bound(uint256(secondAmount), 0, DEPOSIT_CAP);
        uint256 supplyBefore = book.supplyUnits();
        book.deposit(amounts);
        assertEq(book.supplyUnits(), supplyBefore);
    }

    function mint(uint96 quantity) external {
        uint256 q = bound(uint256(quantity), 0, MINT_CAP);
        if (q == 0 || book.supplyUnits() + q < book.supplyUnits()) {
            _rejectMint(q);
            return;
        }
        uint256[] memory requirement = book.requiredRaw(book.supplyUnits() + q);
        uint256 count = book.componentCount();
        for (uint256 i; i < count; ++i) {
            if (book.backingRaw(i) < requirement[i]) {
                _rejectMint(q);
                return;
            }
        }
        uint256 supplyBefore = book.supplyUnits();
        book.mint(q);
        minted += q;
        assertEq(book.supplyUnits(), supplyBefore + q);
    }

    function redeem(uint96 quantity) external {
        uint256 held = book.balanceOf(address(this));
        uint256 q = bound(uint256(quantity), 0, MINT_CAP);
        if (q == 0 || q > held) {
            _rejectRedeem(q);
            return;
        }
        uint256 supplyBefore = book.supplyUnits();
        uint256 releasesBefore = probe.releases();
        book.redeem(q);
        burned += q;
        assertEq(book.supplyUnits(), supplyBefore - q);
        if (probe.releases() != releasesBefore) {
            assertEq(probe.supplyAtRelease(), supplyBefore - q);
            lastSupplyAtRelease = probe.supplyAtRelease();
            lastSupplyBeforeRelease = supplyBefore;
            sawRelease = true;
        }
    }

    function invariant_supplyIncreasesOnlyThroughMint() public view {
        assertEq(book.supplyUnits(), minted - burned);
        assertEq(book.balanceOf(address(this)), book.supplyUnits());
    }

    function invariant_backingCoversOwnRequirement() public view {
        uint256[] memory requirement = book.requiredRaw(book.supplyUnits());
        uint256 count = requirement.length;
        for (uint256 i; i < count; ++i) {
            assertGe(book.backingRaw(i), requirement[i]);
        }
    }

    function invariant_redeemDecreasesSupplyBeforeRelease() public view {
        if (!sawRelease) return;
        assertLt(lastSupplyAtRelease, lastSupplyBeforeRelease);
    }

    function _rejectMint(uint256 quantity) internal {
        uint256 supplyBefore = book.supplyUnits();
        uint256 heldBefore = book.balanceOf(address(this));
        try book.mint(quantity) {
            assertEq(supplyBefore, type(uint256).max, "underbacked mint succeeded");
        } catch {
            assertEq(book.supplyUnits(), supplyBefore);
            assertEq(book.balanceOf(address(this)), heldBefore);
        }
    }

    function _rejectRedeem(uint256 quantity) internal {
        uint256 supplyBefore = book.supplyUnits();
        uint256 heldBefore = book.balanceOf(address(this));
        uint256 backing0 = book.backingRaw(0);
        uint256 backing1 = book.backingRaw(1);
        try book.redeem(quantity) returns (uint256[] memory) {
            assertEq(supplyBefore, type(uint256).max, "invalid redeem succeeded");
        } catch {
            assertEq(book.supplyUnits(), supplyBefore);
            assertEq(book.balanceOf(address(this)), heldBefore);
            assertEq(book.backingRaw(0), backing0);
            assertEq(book.backingRaw(1), backing1);
        }
    }
}
