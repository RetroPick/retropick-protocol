// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {CandidatePayoffTransform} from "../../src/prism/CandidatePayoffTransform.sol";

/// @notice Stateful checks for the existing payoff-transform research kernel.
///         The matrix is the differential fixture. Handlers return into try/catch
///         on known revert paths. `fail_on_revert` is false. The payoff formula
///         is the contract's own rule.
/// forge-config: default.invariant.runs = 256
/// forge-config: default.invariant.depth = 128
/// forge-config: default.invariant.fail_on_revert = false
contract CandidatePayoffTransformInvariantTest is Test {
    uint256 internal constant INITIAL_SUPPLY = 1000;
    uint256 internal constant STATE_COUNT = 4;
    uint256 internal constant COMPONENT_COUNT = 2;

    CandidatePayoffTransform internal book;
    uint256 internal resolvedSeen;
    uint256 internal compared;
    uint256[STATE_COUNT] internal valueBefore;
    uint256[STATE_COUNT] internal valueAfter;
    bool internal sawReject;
    uint256 internal rejectCashBefore;
    uint256 internal rejectCashAfter;
    uint256 internal rejectMaskBefore;
    uint256 internal rejectMaskAfter;
    uint256 internal rejectBackingBefore0;
    uint256 internal rejectBackingAfter0;
    uint256 internal rejectBackingBefore1;
    uint256 internal rejectBackingAfter1;
    bool internal sawEquivalence;
    bool internal lastEquivalent;

    function setUp() public {
        uint256[] memory payoff = new uint256[](STATE_COUNT * COMPONENT_COUNT);
        payoff[0] = 0;
        payoff[1] = 1;
        payoff[2] = 0;
        payoff[3] = 0;
        payoff[4] = 1;
        payoff[5] = 1;
        payoff[6] = 1;
        payoff[7] = 0;
        uint256[] memory weights = new uint256[](COMPONENT_COUNT);
        uint256[] memory backing_ = new uint256[](COMPONENT_COUNT);
        weights[0] = 6 * 10 ** 17;
        weights[1] = 4 * 10 ** 17;
        backing_[0] = 600;
        backing_[1] = 400;
        book = new CandidatePayoffTransform(payoff, STATE_COUNT, weights, backing_, INITIAL_SUPPLY);

        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = this.transformComponent.selector;
        targetSelector(FuzzSelector({addr: address(this), selectors: selectors}));
        targetContract(address(this));
        targetSender(address(this));
        excludeContract(address(book));
    }

    function transformComponent(uint256 index, uint256 payout) external {
        index = bound(index, 0, COMPONENT_COUNT);
        payout = bound(payout, 0, 2);
        if (index >= book.componentCount() || _resolved(index) || !_hasMatchingState(index, payout)) {
            _reject(index, payout);
            return;
        }

        uint256 matched;
        for (uint256 state; state < STATE_COUNT; ++state) {
            if (book.payoffOf(state, index) != payout) continue;
            valueBefore[matched] = _stored(state);
            matched += 1;
        }
        uint256[] memory oldBacking = _backing();
        uint256 oldCash = book.transformed();
        uint256 expectedMask = resolvedSeen | (uint256(1) << index);
        book.transformComponent(index, payout);

        uint256 seen;
        for (uint256 state; state < STATE_COUNT; ++state) {
            if (book.payoffOf(state, index) != payout) continue;
            valueAfter[seen] = _stored(state);
            seen += 1;
        }
        compared = seen;
        resolvedSeen = expectedMask;
        assertEq(book.resolvedMask(), expectedMask);
        assertEq(book.supplyUnits(), INITIAL_SUPPLY);

        uint256[] memory newBacking = _backing();
        sawEquivalence = true;
        lastEquivalent = book.payoffEquivalent(oldBacking, oldCash, newBacking, book.transformed(), book.possibleMask());
    }

    function invariant_supplyUnchanged() public view {
        assertEq(book.supplyUnits(), INITIAL_SUPPLY);
    }

    function invariant_resolvedComponentStaysResolved() public view {
        assertEq(book.resolvedMask(), resolvedSeen);
    }

    function invariant_matchingPayoffValuesUnchanged() public view {
        for (uint256 i; i < compared; ++i) {
            assertEq(valueAfter[i], valueBefore[i]);
        }
    }

    function invariant_rejectedTransformLeavesStateUnchanged() public view {
        if (!sawReject) return;
        assertEq(rejectCashAfter, rejectCashBefore);
        assertEq(rejectMaskAfter, rejectMaskBefore);
        assertEq(rejectBackingAfter0, rejectBackingBefore0);
        assertEq(rejectBackingAfter1, rejectBackingBefore1);
    }

    function invariant_successfulTransformIsPayoffEquivalent() public view {
        if (!sawEquivalence) return;
        assertTrue(lastEquivalent);
    }

    function _reject(uint256 index, uint256 payout) internal {
        rejectCashBefore = book.transformed();
        rejectMaskBefore = book.resolvedMask();
        rejectBackingBefore0 = book.backing(0);
        rejectBackingBefore1 = book.backing(1);
        try book.transformComponent(index, payout) returns (uint256) {
            assertEq(uint256(0), uint256(1), "rejected transform succeeded");
        } catch {
            rejectCashAfter = book.transformed();
            rejectMaskAfter = book.resolvedMask();
            rejectBackingAfter0 = book.backing(0);
            rejectBackingAfter1 = book.backing(1);
            sawReject = true;
        }
    }

    function _resolved(uint256 index) internal view returns (bool) {
        return (book.resolvedMask() & (uint256(1) << index)) != 0;
    }

    function _hasMatchingState(uint256 index, uint256 payout) internal view returns (bool) {
        uint256 mask = book.possibleMask();
        for (uint256 state; state < STATE_COUNT; ++state) {
            if ((mask & (uint256(1) << state)) == 0) continue;
            if (book.payoffOf(state, index) == payout) return true;
        }
        return false;
    }

    function _stored(uint256 state) internal view returns (uint256 total) {
        total = book.transformed();
        uint256 count = book.componentCount();
        for (uint256 component; component < count; ++component) {
            total += book.backing(component) * book.payoffOf(state, component);
        }
    }

    function _backing() internal view returns (uint256[] memory amounts) {
        amounts = new uint256[](COMPONENT_COUNT);
        amounts[0] = book.backing(0);
        amounts[1] = book.backing(1);
    }
}
