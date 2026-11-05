// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {Test} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {RetroPickQuoteAssetRegistryV2} from "../../../src/v2/RetroPickQuoteAssetRegistryV2.sol";
import {QuoteAssetConfig, GraduationVenue} from "../../../src/v2/interfaces/IGraduationExecutorV2.sol";

contract RegistryQuoteFixtureV2 is ERC20 {
    constructor() ERC20("Verified fixture", "FIX") {}

    function decimals() public pure override returns (uint8) {
        return 6;
    }
}

contract QuoteAssetRegistryV2Test is Test {
    RetroPickQuoteAssetRegistryV2 registry;

    function setUp() public {
        vm.chainId(10143);
        registry = new RetroPickQuoteAssetRegistryV2(address(this));
    }

    function config(uint8 decimals) private pure returns (QuoteAssetConfig memory c) {
        c = QuoteAssetConfig(
            true,
            decimals,
            3,
            1,
            10 ** decimals,
            10 ** decimals,
            50 * 10 ** decimals,
            keccak256("TESTNET_POLICY_V1"),
            bytes32(0)
        );
    }

    function testAdmissionVersionAndVenueSnapshot() public {
        QuoteAssetConfig memory c = config(18);
        assertFalse(registry.isSupportedQuote(address(0)));
        registry.configure(address(0), c);
        QuoteAssetConfig memory old = registry.admitted(address(0), GraduationVenue.KURU);
        assertEq(old.policyVersion, 1);
        assertTrue(old.policyHash != bytes32(0));
        vm.expectRevert(RetroPickQuoteAssetRegistryV2.InvalidQuoteConfig.selector);
        registry.configure(address(0), c);
        c.policyVersion = 2;
        c.venueMask = 1;
        registry.configure(address(0), c);
        assertEq(registry.admitted(address(0), GraduationVenue.UNISWAP_V4).policyVersion, 2);
        vm.expectRevert(RetroPickQuoteAssetRegistryV2.UnsupportedQuote.selector);
        registry.admitted(address(0), GraduationVenue.KURU);
        assertEq(old.policyVersion, 1);
    }

    function testExactIdentityAndOwnerAdmissionRequired() public {
        address quote = address(new RegistryQuoteFixtureV2());
        vm.expectRevert(RetroPickQuoteAssetRegistryV2.UnsupportedQuote.selector);
        registry.admitted(quote, GraduationVenue.KURU);
        QuoteAssetConfig memory c = config(18);
        vm.expectRevert(RetroPickQuoteAssetRegistryV2.InvalidQuoteConfig.selector);
        registry.configure(quote, c);
        c = config(6);
        vm.prank(address(0xBAD));
        vm.expectRevert();
        registry.configure(quote, c);
        registry.configure(quote, c);
        registry.validateQuote(quote, 6);
        vm.expectRevert(RetroPickQuoteAssetRegistryV2.UnsupportedQuote.selector);
        registry.validateQuote(quote, 18);
        c.policyVersion = 2;
        c.enabled = false;
        registry.configure(quote, c);
        assertFalse(registry.isSupportedQuote(quote));
        vm.expectRevert(RetroPickQuoteAssetRegistryV2.UnsupportedQuote.selector);
        registry.admitted(quote, GraduationVenue.KURU);
    }

    function testChainAndPolicyHashFailClosed() public {
        QuoteAssetConfig memory c = config(18);
        c.policyHash = bytes32(uint256(1));
        vm.expectRevert(RetroPickQuoteAssetRegistryV2.InvalidQuoteConfig.selector);
        registry.configure(address(0), c);
        c.policyHash = bytes32(0);
        registry.configure(address(0), c);
        vm.chainId(143);
        assertFalse(registry.isSupportedQuote(address(0)));
        vm.expectRevert(RetroPickQuoteAssetRegistryV2.UnsupportedQuote.selector);
        registry.admitted(address(0), GraduationVenue.KURU);
        vm.expectRevert(RetroPickQuoteAssetRegistryV2.WrongChain.selector);
        new RetroPickQuoteAssetRegistryV2(address(this));
    }
}
