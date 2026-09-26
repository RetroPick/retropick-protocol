// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {CandidateComponentBacking} from "../../src/prism/CandidateComponentBacking.sol";
import {CandidateReservationLedger} from "../../src/prism/CandidateReservationLedger.sol";

/// @notice Observes series supply at the moment backing tokens leave the kernel.
contract ReleaseProbeToken is ERC20 {
    uint8 private immutable _decimals;
    CandidateComponentBacking public kernel;
    uint256 public supplyAtRelease;
    uint256 public backingAtRelease;
    bool public released;

    constructor(uint8 decimals_) ERC20("Probe", "PROBE") {
        _decimals = decimals_;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function setKernel(CandidateComponentBacking kernel_) external {
        kernel = kernel_;
    }

    function _update(address from, address to, uint256 value) internal override {
        if (address(kernel) != address(0) && from == address(kernel) && to != address(0)) {
            supplyAtRelease = kernel.supplyUnits();
            backingAtRelease = kernel.backingRaw(0);
            released = true;
        }
        super._update(from, to, value);
    }
}

/// @notice Differential check against fixtures generated from FixedPointSeries and ReservationLedger.
///         A mismatch is COUNTEREXAMPLE_FOUND. Do not edit the Python models to fit Solidity.
///         This is not MATH-1 PASS and it is not CONTRACT-1.
contract CandidateComponentBackingDifferentialTest is Test {
    bytes32 private constant OP_DEPOSIT = keccak256("deposit");
    bytes32 private constant OP_MINT = keccak256("mint");
    bytes32 private constant OP_REDEEM = keccak256("redeem");
    bytes32 private constant EXPECT_OK = keccak256("ok");
    bytes32 private constant EXPECT_REJECT = keccak256("reject");
    bytes32 private constant ERR_INSUFFICIENT = keccak256("insufficient_backing");
    bytes32 private constant ERR_QUANTITY = keccak256("invalid_quantity");
    bytes32 private constant ERR_ZERO = keccak256("zero_quantity");

    function test_matches_python_fixtures() public {
        string memory json = _load();
        uint256 n = vm.parseJsonUint(json, ".case_count");
        for (uint256 i; i < n; ++i) {
            _replayCase(json, i);
        }
    }

    function test_reservation_matches_fixture() public {
        string memory json = _load();
        bytes32 asset = bytes32(vm.parseJsonUint(json, ".reservation.asset_id"));
        bytes32 seriesA = bytes32(vm.parseJsonUint(json, ".reservation.series_a"));
        bytes32 seriesB = bytes32(vm.parseJsonUint(json, ".reservation.series_b"));
        CandidateReservationLedger ledger = new CandidateReservationLedger();
        uint256 deposited = _reservation(json, ".deposit");
        ledger.deposit(asset, deposited);
        assertEq(ledger.balance(asset), _reservation(json, ".balance_after_deposit"));
        vm.expectRevert(CandidateReservationLedger.EmptySeries.selector);
        ledger.reserve(bytes32(0), asset, _reservation(json, ".empty_series_amount"));
        assertEq(ledger.available(asset), _reservation(json, ".available_after_empty_reject"));
        assertEq(ledger.totalReserved(asset), _reservation(json, ".total_reserved_after_empty_reject"));
        ledger.reserve(seriesA, asset, _reservation(json, ".reserve_a"));
        uint256 freeAfterA = _reservation(json, ".available_after_a");
        assertEq(ledger.available(asset), freeAfterA);
        assertEq(ledger.totalReserved(asset), _reservation(json, ".total_reserved_after_a"));
        uint256 rejected = _reservation(json, ".reserve_b_rejected");
        vm.expectRevert(
            abi.encodeWithSelector(
                CandidateReservationLedger.InsufficientUnreserved.selector, asset, rejected, freeAfterA
            )
        );
        ledger.reserve(seriesB, asset, rejected);
        assertEq(ledger.available(asset), _reservation(json, ".available_after_reject"));
        assertEq(ledger.totalReserved(asset), _reservation(json, ".total_reserved_after_reject"));
        ledger.reserve(seriesB, asset, _reservation(json, ".reserve_b_accepted"));
        assertEq(ledger.totalReserved(asset), _reservation(json, ".total_reserved"));
        assertEq(ledger.available(asset), _reservation(json, ".available"));
        assertEq(ledger.balance(asset), deposited);
        assertEq(ledger.reservedFor(seriesA, asset), _reservation(json, ".reserved_a"));
        assertEq(ledger.reservedFor(seriesB, asset), _reservation(json, ".reserved_b"));
    }

    function test_redeem_transfers_after_supply_is_burned() public {
        string memory json = _load();
        uint256 n = vm.parseJsonUint(json, ".case_count");
        for (uint256 i; i < n; ++i) {
            string memory prefix = _casePrefix(i);
            if (keccak256(bytes(_id(json, prefix))) != keccak256("redeem_in_kind_small")) continue;
            _probeCase(json, prefix);
            return;
        }
        revert("missing redeem_in_kind_small");
    }

    function test_fee_on_transfer_deposit_does_not_credit_backing() public {
        MockCollateral first = new MockCollateral(18);
        MockCollateral second = new MockCollateral(18);
        address[] memory tokens = new address[](2);
        uint256[] memory weights = new uint256[](2);
        uint8[] memory decimals_ = new uint8[](2);
        tokens[0] = address(first);
        tokens[1] = address(second);
        weights[0] = 6 * 10 ** 17;
        weights[1] = 4 * 10 ** 17;
        decimals_[0] = 18;
        decimals_[1] = 18;
        CandidateComponentBacking book = new CandidateComponentBacking(tokens, weights, decimals_);
        first.mint(address(this), 10);
        second.mint(address(this), 10);
        first.approve(address(book), 10);
        second.approve(address(book), 10);
        first.setFeeOnTransfer(true);
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 10;
        amounts[1] = 10;
        vm.expectRevert(abi.encodeWithSelector(CandidateComponentBacking.Shortfall.selector, 0, 9, 10));
        book.deposit(amounts);
        assertEq(book.backingRaw(0), 0);
        assertEq(book.backingRaw(1), 0);
        assertEq(book.supplyUnits(), 0);
    }

    function _replayCase(string memory json, uint256 index) internal {
        string memory prefix = _casePrefix(index);
        CandidateComponentBacking book = _deploy(json, prefix);
        uint256 steps = _field(json, prefix, ".step_count");
        for (uint256 s; s < steps; ++s) {
            _step(json, prefix, book, s);
        }
    }

    function _probeCase(string memory json, string memory prefix) internal {
        ReleaseProbeToken probe = new ReleaseProbeToken(uint8(_at(json, prefix, ".decimals[", 0)));
        CandidateComponentBacking book = _deployWithProbe(json, prefix, probe);
        probe.setKernel(book);
        uint256 steps = _field(json, prefix, ".step_count");
        for (uint256 s; s < steps; ++s) {
            _step(json, prefix, book, s);
        }
        assertTrue(probe.released());
        uint256 supplyAtRelease = _field(json, prefix, ".supply_at_release");
        uint256 supplyBefore = _field(json, prefix, ".supply_before_release");
        assertEq(probe.supplyAtRelease(), supplyAtRelease);
        assertEq(probe.supplyAtRelease(), book.supplyUnits());
        assertTrue(supplyAtRelease != supplyBefore);
        assertEq(probe.backingAtRelease(), _field(json, prefix, ".backing0_at_release"));
        assertEq(probe.backingAtRelease(), book.backingRaw(0));
    }

    function _deploy(string memory json, string memory prefix) internal returns (CandidateComponentBacking book) {
        uint256 n = _field(json, prefix, ".component_count");
        address[] memory tokens = new address[](n);
        uint256[] memory weights = new uint256[](n);
        uint8[] memory decimals_ = new uint8[](n);
        for (uint256 i; i < n; ++i) {
            decimals_[i] = uint8(_at(json, prefix, ".decimals[", i));
            MockCollateral token = new MockCollateral(decimals_[i]);
            token.mint(address(this), 10 ** 40);
            tokens[i] = address(token);
            weights[i] = _at(json, prefix, ".weights_wad[", i);
        }
        book = new CandidateComponentBacking(tokens, weights, decimals_);
        _approveAll(tokens, book);
        _assertComponents(book, weights, decimals_);
    }

    function _deployWithProbe(string memory json, string memory prefix, ReleaseProbeToken probe)
        internal
        returns (CandidateComponentBacking book)
    {
        uint256 n = _field(json, prefix, ".component_count");
        address[] memory tokens = new address[](n);
        uint256[] memory weights = new uint256[](n);
        uint8[] memory decimals_ = new uint8[](n);
        for (uint256 i; i < n; ++i) {
            decimals_[i] = uint8(_at(json, prefix, ".decimals[", i));
            weights[i] = _at(json, prefix, ".weights_wad[", i);
            if (i == 0) {
                probe.mint(address(this), 10 ** 40);
                tokens[i] = address(probe);
            } else {
                MockCollateral token = new MockCollateral(decimals_[i]);
                token.mint(address(this), 10 ** 40);
                tokens[i] = address(token);
            }
        }
        book = new CandidateComponentBacking(tokens, weights, decimals_);
        _approveAll(tokens, book);
    }

    function _approveAll(address[] memory tokens, CandidateComponentBacking book) internal {
        uint256 n = tokens.length;
        for (uint256 i; i < n; ++i) {
            IERC20(tokens[i]).approve(address(book), type(uint256).max);
        }
    }

    function _assertComponents(CandidateComponentBacking book, uint256[] memory weights, uint8[] memory decimals_)
        internal
        view
    {
        uint256 n = weights.length;
        assertEq(book.componentCount(), n);
        for (uint256 i; i < n; ++i) {
            assertEq(book.weightWad(i), weights[i]);
            assertEq(uint256(book.componentDecimals(i)), uint256(decimals_[i]));
        }
    }

    function _step(string memory json, string memory prefix, CandidateComponentBacking book, uint256 index) internal {
        string memory stepPrefix = string.concat(prefix, ".steps[", vm.toString(index), "]");
        bytes32 op = keccak256(bytes(vm.parseJsonString(json, string.concat(stepPrefix, ".op"))));
        bytes32 expect = keccak256(bytes(vm.parseJsonString(json, string.concat(stepPrefix, ".expect"))));
        uint256 quantity;
        uint256[] memory amounts;
        if (op == OP_DEPOSIT) {
            amounts = _amounts(json, stepPrefix, book.componentCount());
        } else if (op == OP_MINT || op == OP_REDEEM) {
            quantity = _field(json, stepPrefix, ".quantity");
        } else {
            revert("unknown op");
        }
        if (expect == EXPECT_REJECT) _armReject(json, stepPrefix, op, quantity);
        if (op == OP_DEPOSIT) {
            book.deposit(amounts);
        } else if (op == OP_MINT) {
            book.mint(quantity);
        } else {
            uint256[] memory got = book.redeem(quantity);
            if (expect == EXPECT_OK) _assertReleased(json, stepPrefix, got);
        }
        _assertState(json, stepPrefix, book);
    }

    function _armReject(string memory json, string memory stepPrefix, bytes32 op, uint256 quantity) internal {
        if (op == OP_MINT) {
            bytes32 code = keccak256(bytes(vm.parseJsonString(json, string.concat(stepPrefix, ".error"))));
            if (code == ERR_ZERO) {
                vm.expectRevert(CandidateComponentBacking.ZeroQuantity.selector);
            } else if (code == ERR_INSUFFICIENT) {
                uint256 failIndex = _field(json, stepPrefix, ".fail_index");
                uint256 failBacking = _field(json, stepPrefix, ".fail_backing");
                uint256 failRequired = _field(json, stepPrefix, ".fail_required");
                vm.expectRevert(
                    abi.encodeWithSelector(
                        CandidateComponentBacking.InsufficientBacking.selector, failIndex, failBacking, failRequired
                    )
                );
            } else {
                revert("unclassified mint reject");
            }
        } else if (op == OP_REDEEM) {
            uint256 held = _field(json, stepPrefix, ".holder_balance");
            vm.expectRevert(abi.encodeWithSelector(CandidateComponentBacking.InvalidQuantity.selector, quantity, held));
        } else {
            revert("unclassified reject");
        }
    }

    function _assertReleased(string memory json, string memory stepPrefix, uint256[] memory got) internal pure {
        uint256 n = got.length;
        for (uint256 i; i < n; ++i) {
            assertEq(got[i], _at(json, stepPrefix, ".released[", i));
        }
        if (vm.parseJsonBool(json, string.concat(stepPrefix, ".requirement_delta_differs_from_naive_ceil"))) {
            bool differs;
            for (uint256 i; i < n; ++i) {
                if (got[i] != _at(json, stepPrefix, ".naive_ceil_of_quantity[", i)) differs = true;
            }
            assertTrue(differs);
        }
    }

    function _assertState(string memory json, string memory stepPrefix, CandidateComponentBacking book) internal view {
        assertEq(book.supplyUnits(), _field(json, stepPrefix, ".supply"));
        assertEq(book.balanceOf(address(this)), _field(json, stepPrefix, ".holder_balance"));
        uint256 n = book.componentCount();
        uint256[] memory requirement = book.requiredRaw(book.supplyUnits());
        for (uint256 i; i < n; ++i) {
            assertEq(book.backingRaw(i), _at(json, stepPrefix, ".backing[", i));
            assertEq(requirement[i], _at(json, stepPrefix, ".required[", i));
        }
    }

    function _amounts(string memory json, string memory stepPrefix, uint256 n)
        internal
        pure
        returns (uint256[] memory amounts)
    {
        amounts = new uint256[](n);
        for (uint256 i; i < n; ++i) {
            amounts[i] = _at(json, stepPrefix, ".amounts[", i);
        }
    }

    function _load() internal view returns (string memory) {
        return vm.readFile("../prism-model/fixtures/backing_kernel.json");
    }

    function _casePrefix(uint256 index) internal pure returns (string memory) {
        return string.concat(".cases[", vm.toString(index), "]");
    }

    function _id(string memory json, string memory prefix) internal pure returns (string memory) {
        return vm.parseJsonString(json, string.concat(prefix, ".id"));
    }

    function _reservation(string memory json, string memory key) internal pure returns (uint256) {
        return vm.parseJsonUint(json, string.concat(".reservation", key));
    }

    function _field(string memory json, string memory prefix, string memory key) internal pure returns (uint256) {
        return vm.parseJsonUint(json, string.concat(prefix, key));
    }

    function _at(string memory json, string memory prefix, string memory key, uint256 index)
        internal
        pure
        returns (uint256)
    {
        return vm.parseJsonUint(json, string.concat(prefix, key, vm.toString(index), "]"));
    }
}
