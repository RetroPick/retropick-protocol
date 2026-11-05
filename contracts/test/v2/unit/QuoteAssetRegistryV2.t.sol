// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {RetroPickQuoteAssetRegistryV2} from "../../../src/v2/RetroPickQuoteAssetRegistryV2.sol";
import {QuoteAssetConfig, GraduationVenue} from "../../../src/v2/interfaces/IGraduationExecutorV2.sol";

contract V4OnlyRegistryQuoteFixtureV2 is ERC20 {
    constructor() ERC20("V4-only fixture", "V4Q") {}

    function decimals() public pure override returns (uint8) {
        return 6;
    }
}

/// @notice New-stack admission. The original positive Kuru tests remain under test/legacy/v2-kuru/unit.
contract V4OnlyQuoteAssetRegistryV2Test is Test {
    RetroPickQuoteAssetRegistryV2 registry;

    function setUp() public {
        vm.chainId(10143);
        registry = new RetroPickQuoteAssetRegistryV2(address(this));
    }

    function _config(uint8 decimals) private pure returns (QuoteAssetConfig memory) {
        uint256 unit = 10 ** decimals;
        return QuoteAssetConfig(true, decimals, 1, 1, unit, unit, 50 * unit, keccak256("V4_ONLY_TEST_POLICY"), 0);
    }

    function testOwnerCannotEnableReservedKuruMask() public {
        QuoteAssetConfig memory c = _config(18);
        for (uint8 mask; mask < 4; ++mask) {
            if (mask == 1) continue;
            c.venueMask = mask;
            vm.expectRevert(RetroPickQuoteAssetRegistryV2.InvalidQuoteConfig.selector);
            registry.configure(address(0), c);
        }
        c.venueMask = 1;
        registry.configure(address(0), c);
        vm.expectRevert(RetroPickQuoteAssetRegistryV2.UnsupportedQuote.selector);
        registry.admitted(address(0), GraduationVenue.LEGACY_RESERVED);
        assertEq(uint8(GraduationVenue.UNISWAP_V4), 0);
        assertEq(uint8(GraduationVenue.LEGACY_RESERVED), 1);
    }

    function testVersionAndExistingSnapshotRemainStable() public {
        QuoteAssetConfig memory c = _config(18);
        registry.configure(address(0), c);
        QuoteAssetConfig memory original = registry.admitted(address(0), GraduationVenue.UNISWAP_V4);
        vm.expectRevert(RetroPickQuoteAssetRegistryV2.InvalidQuoteConfig.selector);
        registry.configure(address(0), c);
        c.policyVersion = 2;
        c.graduationThreshold *= 2;
        registry.configure(address(0), c);
        assertEq(registry.admitted(address(0), GraduationVenue.UNISWAP_V4).policyVersion, 2);
        assertEq(original.policyVersion, 1);
        assertTrue(original.policyHash != bytes32(0));
        assertEq(original.graduationThreshold, 1 ether);
    }

    function testNativeAndSixDecimalAdmissionIdentity() public {
        address quote = address(new V4OnlyRegistryQuoteFixtureV2());
        QuoteAssetConfig memory c = _config(18);
        vm.expectRevert(RetroPickQuoteAssetRegistryV2.InvalidQuoteConfig.selector);
        registry.configure(quote, c);
        c = _config(6);
        vm.prank(address(0xBAD));
        vm.expectRevert();
        registry.configure(quote, c);
        registry.configure(quote, c);
        registry.validateQuote(quote, 6);
        assertEq(registry.admitted(quote, GraduationVenue.UNISWAP_V4).decimals, 6);
        vm.expectRevert(RetroPickQuoteAssetRegistryV2.UnsupportedQuote.selector);
        registry.admitted(quote, GraduationVenue.LEGACY_RESERVED);
        registry.configure(address(0), _config(18));
        assertEq(registry.admitted(address(0), GraduationVenue.UNISWAP_V4).decimals, 18);
    }

    function testChainAndPolicyHashFailClosed() public {
        QuoteAssetConfig memory c = _config(18);
        c.policyHash = bytes32(uint256(1));
        vm.expectRevert(RetroPickQuoteAssetRegistryV2.InvalidQuoteConfig.selector);
        registry.configure(address(0), c);
        c.policyHash = bytes32(0);
        registry.configure(address(0), c);
        vm.chainId(143);
        assertFalse(registry.isSupportedQuote(address(0)));
        vm.expectRevert(RetroPickQuoteAssetRegistryV2.UnsupportedQuote.selector);
        registry.admitted(address(0), GraduationVenue.UNISWAP_V4);
        vm.expectRevert(RetroPickQuoteAssetRegistryV2.WrongChain.selector);
        new RetroPickQuoteAssetRegistryV2(address(this));
    }

    function testFuzzOnlyMaskOneCanBeConfigured(uint8 mask) public {
        QuoteAssetConfig memory c = _config(18);
        c.venueMask = mask;
        if (mask == 1) {
            registry.configure(address(0), c);
            assertEq(registry.getConfig(address(0)).venueMask, 1);
        } else {
            vm.expectRevert(RetroPickQuoteAssetRegistryV2.InvalidQuoteConfig.selector);
            registry.configure(address(0), c);
        }
    }
}
