// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {CandidatePayoffTransform} from "../../src/prism/CandidatePayoffTransform.sol";

/// @notice Differential check against partial_resolution.py fixtures.
///         A mismatch is COUNTEREXAMPLE_FOUND. Do not edit the Python transform to fit Solidity.
///         This is not MATH-1 PASS and it is not CONTRACT-1.
contract CandidatePayoffTransformDifferentialTest is Test {
    bytes32 private constant EXPECT_OK = keccak256("ok");
    bytes32 private constant EXPECT_REJECT = keccak256("reject");
    bytes32 private constant ERR_BAD = keccak256("bad_component");
    bytes32 private constant ERR_NONEQ = keccak256("nonequivalent");
    bytes32 private constant ERR_REPEAT = keccak256("already_resolved");

    function test_matches_python_fixtures() public {
        string memory json = _load();
        uint256 n = vm.parseJsonUint(json, ".case_count");
        for (uint256 i; i < n; ++i) {
            _replay(json, string.concat(".cases[", vm.toString(i), "]"));
        }
        _replay(json, ".reorder_backward");
    }

    function test_negative_control_is_not_equivalent() public {
        string memory json = _load();
        CandidatePayoffTransform book = _deploy(json);
        assertFalse(_equivalent(json, book, ".negative_control"));
        assertTrue(_equivalent(json, book, ".positive_control"));
        assertEq(book.supplyUnits(), vm.parseJsonUint(json, ".initial.supply"));
        assertEq(book.transformed(), 0);
    }

    function _replay(string memory json, string memory prefix) internal {
        CandidatePayoffTransform book = _deploy(json);
        uint256 steps = vm.parseJsonUint(json, string.concat(prefix, ".step_count"));
        for (uint256 s; s < steps; ++s) {
            _step(json, book, string.concat(prefix, ".steps[", vm.toString(s), "]"));
        }
    }

    function _step(string memory json, CandidatePayoffTransform book, string memory prefix) internal {
        bytes32 expect = keccak256(bytes(vm.parseJsonString(json, string.concat(prefix, ".expect"))));
        uint256 index = _field(json, prefix, ".index");
        uint256 payout = _field(json, prefix, ".payout");
        if (expect == EXPECT_REJECT) _armReject(json, prefix, index, payout);
        if (expect == EXPECT_OK) {
            uint256 cashAdded = book.transformComponent(index, payout);
            assertEq(cashAdded, _field(json, prefix, ".cash_added"));
        } else {
            book.transformComponent(index, payout);
        }
        _assertState(json, book, prefix);
    }

    function _armReject(string memory json, string memory prefix, uint256 index, uint256 payout) internal {
        bytes32 code = keccak256(bytes(vm.parseJsonString(json, string.concat(prefix, ".error"))));
        if (code == ERR_BAD) {
            vm.expectRevert(abi.encodeWithSelector(CandidatePayoffTransform.BadComponent.selector, index));
        } else if (code == ERR_NONEQ) {
            vm.expectRevert(abi.encodeWithSelector(CandidatePayoffTransform.Nonequivalent.selector, index, payout));
        } else if (code == ERR_REPEAT) {
            vm.expectRevert(abi.encodeWithSelector(CandidatePayoffTransform.AlreadyResolved.selector, index));
        } else {
            revert("unclassified reject");
        }
    }

    function _assertState(string memory json, CandidatePayoffTransform book, string memory prefix) internal view {
        assertEq(book.supplyUnits(), _field(json, prefix, ".supply"));
        assertEq(book.transformed(), _field(json, prefix, ".transformed"));
        assertEq(book.possibleMask(), _field(json, prefix, ".possible_mask"));
        assertEq(book.resolvedMask(), _field(json, prefix, ".resolved_mask"));
        uint256 n = book.componentCount();
        for (uint256 i; i < n; ++i) {
            assertEq(book.backing(i), _at(json, prefix, ".backing[", i));
            assertEq(book.weightWad(i), _at(json, prefix, ".weights_wad[", i));
        }
    }

    function _equivalent(string memory json, CandidatePayoffTransform book, string memory prefix)
        internal
        view
        returns (bool)
    {
        uint256 n = book.componentCount();
        uint256[] memory oldBacking = new uint256[](n);
        uint256[] memory newBacking = new uint256[](n);
        for (uint256 i; i < n; ++i) {
            oldBacking[i] = _at(json, prefix, ".old_backing[", i);
            newBacking[i] = _at(json, prefix, ".new_backing[", i);
        }
        return book.payoffEquivalent(
            oldBacking,
            _field(json, prefix, ".old_cash"),
            newBacking,
            _field(json, prefix, ".new_cash"),
            _field(json, prefix, ".remaining_mask")
        );
    }

    function _deploy(string memory json) internal returns (CandidatePayoffTransform book) {
        uint256 components = vm.parseJsonUint(json, ".component_count");
        uint256 states = vm.parseJsonUint(json, ".state_count");
        uint256[] memory payoff = new uint256[](components * states);
        uint256[] memory weights = new uint256[](components);
        uint256[] memory backing_ = new uint256[](components);
        for (uint256 s; s < states; ++s) {
            for (uint256 c; c < components; ++c) {
                payoff[s * components + c] =
                    vm.parseJsonUint(json, string.concat(".payoff[", vm.toString(s), "][", vm.toString(c), "]"));
            }
        }
        for (uint256 c; c < components; ++c) {
            weights[c] = vm.parseJsonUint(json, string.concat(".initial.weights_wad[", vm.toString(c), "]"));
            backing_[c] = vm.parseJsonUint(json, string.concat(".initial.backing[", vm.toString(c), "]"));
        }
        book =
            new CandidatePayoffTransform(payoff, states, weights, backing_, vm.parseJsonUint(json, ".initial.supply"));
        assertEq(book.possibleMask(), vm.parseJsonUint(json, ".initial.possible_mask"));
        assertEq(book.resolvedMask(), vm.parseJsonUint(json, ".initial.resolved_mask"));
        assertEq(book.transformed(), vm.parseJsonUint(json, ".initial.transformed"));
    }

    function _load() internal view returns (string memory) {
        return vm.readFile("../prism-model/fixtures/partial_resolution.json");
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
