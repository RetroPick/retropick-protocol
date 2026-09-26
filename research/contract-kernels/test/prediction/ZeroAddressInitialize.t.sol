// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {CloneableOutcomeToken} from "../../src/prediction/CloneableOutcomeToken.sol";

/// @notice Slither missing-zero-check on CloneableOutcomeToken.initialize.
/// @dev The initializer is not edited. No split, merge, redeem, or burn.
contract ZeroAddressInitializeTest is Test {
    // forge inspect storage-layout: _initialized is slot 4.
    uint256 internal constant INITIALIZED_SLOT = 4;

    function test_initialize_stores_the_zero_market() public {
        CloneableOutcomeToken token = new CloneableOutcomeToken();

        assertEq(_initialized(token), false);
        assertEq(token.market(), address(0));
        assertEq(token.outcomeIndex(), 0);
        assertEq(token.decimals(), 0);
        assertEq(token.totalSupply(), 0);
        assertEq(token.name(), "");
        assertEq(token.symbol(), "");

        token.initialize(address(0), 1, "No", "NO", 18);

        assertEq(_initialized(token), true);
        assertEq(token.market(), address(0));
        assertEq(token.outcomeIndex(), 1);
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), 0);
        assertEq(token.name(), "No");
        assertEq(token.symbol(), "NO");

        emit log_string("classification: recorded_finding");
        emit log_named_address("market_after", token.market());
        emit log_named_uint("initialized_after", _initialized(token) ? 1 : 0);
        emit log_named_uint("outcome_index_after", token.outcomeIndex());
        emit log_named_uint("decimals_after", token.decimals());
        emit log_named_uint("total_supply_after", token.totalSupply());
    }

    function _initialized(CloneableOutcomeToken token) internal view returns (bool) {
        return vm.load(address(token), bytes32(INITIALIZED_SLOT)) != bytes32(0);
    }
}
