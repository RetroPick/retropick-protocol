// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title Candidate payoff-equivalent backing transform
/// @notice Research kernel of `research/prism-model/partial_resolution.py`.
/// @dev These are research-kernel semantics. This contract is not an accepted oracle,
///      not MATH-1 PASS, not CONTRACT-1, and not wired to prediction tokens.
///      Replacing component `i` with `backing[i] * payout` settlement value is applied
///      only when at least one still-feasible terminal state pays `payout` on that
///      component and every such state has the same backing value before and after.
///      Supply and weights are unchanged. There is no fee, governance, upgrade path,
///      or leverage.
contract CandidatePayoffTransform {
    uint256 public immutable componentCount;
    uint256 public immutable stateCount;
    uint256 public immutable supplyUnits;

    uint256[] internal _weightsWad;
    uint256[] internal _payoff;
    uint256[] public backing;
    uint256 public transformed;
    uint256 public possibleMask;
    uint256 public resolvedMask;

    error DimensionMismatch(uint256 payoffEntries, uint256 states, uint256 components);
    error TooManyStates(uint256 states);
    error BadComponent(uint256 index);
    error AlreadyResolved(uint256 index);
    error Nonequivalent(uint256 index, uint256 payout);

    event Transformed(uint256 indexed index, uint256 payout, uint256 cashAdded, uint256 possibleMask);

    constructor(
        uint256[] memory payoff,
        uint256 stateCount_,
        uint256[] memory weightsWad,
        uint256[] memory backing_,
        uint256 supplyUnits_
    ) {
        uint256 components = weightsWad.length;
        if (stateCount_ == 0 || stateCount_ > 256) revert TooManyStates(stateCount_);
        if (components == 0 || backing_.length != components || payoff.length != stateCount_ * components) {
            revert DimensionMismatch(payoff.length, stateCount_, components);
        }
        componentCount = components;
        stateCount = stateCount_;
        supplyUnits = supplyUnits_;
        possibleMask = (uint256(1) << stateCount_) - 1;
        for (uint256 i; i < components; ++i) {
            _weightsWad.push(weightsWad[i]);
            backing.push(backing_[i]);
        }
        for (uint256 i; i < payoff.length; ++i) {
            _payoff.push(payoff[i]);
        }
    }

    function weightWad(uint256 index) external view returns (uint256) {
        return _weightsWad[index];
    }

    function payoffOf(uint256 state, uint256 component) external view returns (uint256) {
        return _payoff[state * componentCount + component];
    }

    /// @notice True when every state in `remainingMask` has the same terminal backing value.
    /// @dev An empty mask is not a preserving transform.
    function payoffEquivalent(
        uint256[] calldata oldBacking,
        uint256 oldCash,
        uint256[] calldata newBacking,
        uint256 newCash,
        uint256 remainingMask
    ) external view returns (bool) {
        uint256 count = componentCount;
        if (oldBacking.length != count || newBacking.length != count || remainingMask == 0) return false;
        bool any;
        uint256 states = stateCount;
        for (uint256 s; s < states; ++s) {
            if ((remainingMask & (uint256(1) << s)) == 0) continue;
            any = true;
            if (_rowValue(s, oldBacking, oldCash) != _rowValue(s, newBacking, newCash)) return false;
        }
        return any;
    }

    /// @notice Convert component `index` into settlement value `backing[index] * payout`.
    /// @dev Checks the remaining-state equality before any backing write.
    function transformComponent(uint256 index, uint256 payout) external returns (uint256 cashAdded) {
        if (index >= componentCount) revert BadComponent(index);
        if ((resolvedMask & (uint256(1) << index)) != 0) revert AlreadyResolved(index);

        uint256 count = componentCount;
        uint256 states = stateCount;
        uint256 mask = possibleMask;
        cashAdded = backing[index] * payout;
        uint256 newMask;
        bool any;
        for (uint256 s; s < states; ++s) {
            if ((mask & (uint256(1) << s)) == 0) continue;
            if (_payoff[s * count + index] != payout) continue;
            any = true;
            if (_storedValue(s) != _storedValueReplacing(s, index, cashAdded)) revert Nonequivalent(index, payout);
            newMask |= uint256(1) << s;
        }
        if (!any) revert Nonequivalent(index, payout);

        backing[index] = 0;
        transformed += cashAdded;
        possibleMask = newMask;
        resolvedMask |= uint256(1) << index;
        emit Transformed(index, payout, cashAdded, newMask);
    }

    function _rowValue(uint256 state, uint256[] calldata amounts, uint256 cash) internal view returns (uint256 total) {
        total = cash;
        uint256 count = componentCount;
        for (uint256 i; i < count; ++i) {
            total += amounts[i] * _payoff[state * count + i];
        }
    }

    function _storedValue(uint256 state) internal view returns (uint256 total) {
        total = transformed;
        uint256 count = componentCount;
        for (uint256 i; i < count; ++i) {
            total += backing[i] * _payoff[state * count + i];
        }
    }

    function _storedValueReplacing(uint256 state, uint256 index, uint256 cashAdded)
        internal
        view
        returns (uint256 total)
    {
        total = transformed + cashAdded;
        uint256 count = componentCount;
        for (uint256 i; i < count; ++i) {
            if (i == index) continue;
            total += backing[i] * _payoff[state * count + i];
        }
    }
}
