// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @notice Per-venue, per-version ERC-20 quote admission for *new* launches.
/// @dev This research framework supports ERC20 quote assets only. Native quotes need
///      an explicitly qualified native/wrapped asset path; no silent MON/HYPE support.
contract QuoteVenuePolicyV3 is Ownable2Step {
    struct QuoteRule {
        uint8 decimals;
        bytes32 policyHash;
        bool enabled;
    }

    uint256 public immutable deploymentChainId;
    mapping(bytes32 venueId => mapping(uint32 version => mapping(address quote => QuoteRule))) private _rules;

    error WrongChain();
    error InvalidQuote();
    error RuleAlreadyRegistered();
    error RuleNotAdmitted();
    event QuoteRuleRegistered(
        bytes32 indexed venueId, uint32 indexed version, address indexed quote, uint8 decimals, bytes32 policyHash
    );
    event QuoteRuleDisabled(bytes32 indexed venueId, uint32 indexed version, address indexed quote);

    constructor(address initialOwner) Ownable(initialOwner) {
        deploymentChainId = block.chainid;
    }

    function register(bytes32 venueId, uint32 version, address quote, uint8 expectedDecimals, bytes32 policyHash)
        external
        onlyOwner
    {
        if (block.chainid != deploymentChainId) revert WrongChain();
        if (
            venueId == bytes32(0) || version == 0 || quote == address(0) || quote.code.length == 0
                || policyHash == bytes32(0) || expectedDecimals > 36
        ) revert InvalidQuote();
        if (_rules[venueId][version][quote].policyHash != bytes32(0)) revert RuleAlreadyRegistered();
        _checkDecimals(quote, expectedDecimals);
        _rules[venueId][version][quote] = QuoteRule({decimals: expectedDecimals, policyHash: policyHash, enabled: true});
        emit QuoteRuleRegistered(venueId, version, quote, expectedDecimals, policyHash);
    }

    /// @notice Disable new commitments; historical launches retain their pinned quote policy.
    function disable(bytes32 venueId, uint32 version, address quote) external onlyOwner {
        if (block.chainid != deploymentChainId) revert WrongChain();
        QuoteRule storage rule = _rules[venueId][version][quote];
        if (!rule.enabled) revert RuleNotAdmitted();
        rule.enabled = false;
        emit QuoteRuleDisabled(venueId, version, quote);
    }

    function resolve(bytes32 venueId, uint32 version, address quote) external view returns (QuoteRule memory rule) {
        if (block.chainid != deploymentChainId) revert WrongChain();
        rule = _rules[venueId][version][quote];
        if (!rule.enabled || rule.policyHash == bytes32(0)) revert RuleNotAdmitted();
        _checkDecimals(quote, rule.decimals);
    }

    function get(bytes32 venueId, uint32 version, address quote) external view returns (QuoteRule memory) {
        return _rules[venueId][version][quote];
    }

    function _checkDecimals(address quote, uint8 expectedDecimals) private view {
        if (quote.code.length == 0) revert InvalidQuote();
        try IERC20Metadata(quote).decimals() returns (uint8 actual) {
            if (actual != expectedDecimals) revert InvalidQuote();
        } catch {
            revert InvalidQuote();
        }
    }
}
