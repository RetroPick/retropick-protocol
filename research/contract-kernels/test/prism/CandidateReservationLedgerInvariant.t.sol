// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {CandidateReservationLedger} from "../../src/prism/CandidateReservationLedger.sol";

/// @notice Stateful checks for the existing reservation-ledger research kernel.
///         The kernel exposes deposit and reserve. It has no release or withdraw,
///         and this suite does not add either path. A rejected reserve is attempted
///         inside try/catch and must leave the ledger unchanged. `fail_on_revert`
///         is false.
/// forge-config: default.invariant.runs = 256
/// forge-config: default.invariant.depth = 128
/// forge-config: default.invariant.fail_on_revert = false
contract CandidateReservationLedgerInvariantTest is Test {
    uint256 internal constant AMOUNT_CAP = 1_000_000;

    CandidateReservationLedger internal ledger;
    bytes32[] internal assets;
    bytes32[] internal seriesIds;
    mapping(bytes32 asset => uint256 total) internal deposited;

    function setUp() public {
        ledger = new CandidateReservationLedger();
        assets.push(bytes32(uint256(1)));
        assets.push(bytes32(uint256(2)));
        seriesIds.push(bytes32(uint256(1)));
        seriesIds.push(bytes32(uint256(2)));
        seriesIds.push(bytes32(uint256(3)));

        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = this.deposit.selector;
        selectors[1] = this.reserve.selector;
        targetSelector(FuzzSelector({addr: address(this), selectors: selectors}));
        targetContract(address(this));
        targetSender(address(this));
        excludeContract(address(ledger));
    }

    function deposit(uint8 assetIndex, uint96 amount) external {
        bytes32 asset = assets[assetIndex % assets.length];
        uint256 add = bound(uint256(amount), 0, AMOUNT_CAP);
        uint256 balanceBefore = ledger.balance(asset);
        uint256 reservedBefore = ledger.totalReserved(asset);
        ledger.deposit(asset, add);
        deposited[asset] += add;
        assertEq(ledger.balance(asset), balanceBefore + add);
        assertEq(ledger.balance(asset), deposited[asset]);
        assertEq(ledger.totalReserved(asset), reservedBefore);
    }

    function reserve(uint8 seriesIndex, uint8 assetIndex, uint96 amount) external {
        bytes32 asset = assets[assetIndex % assets.length];
        uint256 requested = bound(uint256(amount), 0, AMOUNT_CAP);
        if (seriesIndex == 0) {
            _rejectReserve(bytes32(0), asset, requested == 0 ? 1 : requested);
            return;
        }
        bytes32 seriesId = seriesIds[(uint256(seriesIndex) - 1) % seriesIds.length];
        uint256 free = ledger.available(asset);
        if (requested > free) {
            _rejectReserve(seriesId, asset, requested);
            return;
        }
        ledger.reserve(seriesId, asset, requested);
    }

    function invariant_reservationsWithinBalance() public view {
        uint256 count = assets.length;
        for (uint256 i; i < count; ++i) {
            bytes32 asset = assets[i];
            uint256 sum = _sumReserved(asset);
            uint256 balance = ledger.balance(asset);
            assertEq(balance, deposited[asset]);
            assertEq(sum, ledger.totalReserved(asset));
            assertLe(sum, balance);
            assertEq(ledger.available(asset), balance - sum);
        }
    }

    function _rejectReserve(bytes32 seriesId, bytes32 asset, uint256 amount) internal {
        uint256 balanceBefore = ledger.balance(asset);
        uint256 reservedBefore = ledger.totalReserved(asset);
        uint256 bucketBefore = ledger.reservedFor(seriesId, asset);
        try ledger.reserve(seriesId, asset, amount) {
            assertEq(balanceBefore, type(uint256).max, "rejected reserve succeeded");
        } catch {
            assertEq(ledger.balance(asset), balanceBefore);
            assertEq(ledger.totalReserved(asset), reservedBefore);
            assertEq(ledger.reservedFor(seriesId, asset), bucketBefore);
        }
    }

    function _sumReserved(bytes32 asset) internal view returns (uint256 sum) {
        uint256 count = seriesIds.length;
        for (uint256 i; i < count; ++i) {
            sum += ledger.reservedFor(seriesIds[i], asset);
        }
    }
}
