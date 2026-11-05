// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {RetroPickFactoryFixtureV2} from "../integration/RetroPickFactoryLaunchV2Qualification.t.sol";
import {RetroPickLaunchFactoryV2} from "../../../src/v2/RetroPickLaunchFactoryV2.sol";
import {RetroPickQuoteAssetRegistryV2} from "../../../src/v2/RetroPickQuoteAssetRegistryV2.sol";
import {GraduationVenue} from "../../../src/v2/interfaces/IGraduationExecutorV2.sol";

contract V4OnlyLaunchAdmissionV2Test is RetroPickFactoryFixtureV2 {
    function testReservedVenueRejectedBeforeDeploymentEvenWithConfiguredExecutor() public {
        factory.configureVenueExecutor(GraduationVenue.LEGACY_RESERVED, address(executor));
        uint64 factoryNonce = vm.getNonce(address(factory));
        uint64 deployerNonce = vm.getNonce(address(deployer));
        uint256 creatorBalance = creator.balance;
        RetroPickLaunchFactoryV2.TokenParams memory params = _params(0);
        vm.prank(creator);
        vm.expectRevert(RetroPickQuoteAssetRegistryV2.UnsupportedQuote.selector);
        factory.launchToken(params, 0, address(0), GraduationVenue.LEGACY_RESERVED);
        assertEq(vm.getNonce(address(factory)), factoryNonce);
        assertEq(vm.getNonce(address(deployer)), deployerNonce);
        assertEq(creator.balance, creatorBalance);
        assertEq(address(factory).balance, 0);
        vm.expectRevert(RetroPickQuoteAssetRegistryV2.UnsupportedQuote.selector);
        factory.previewVenueEconomics(0, address(0), GraduationVenue.LEGACY_RESERVED);
    }

    function testEveryLegacyDefaultLaunchOverloadPinsV4() public {
        RetroPickLaunchFactoryV2.TokenParams memory params = _params(0);
        address[] memory exempt = new address[](0);
        vm.startPrank(creator);
        (address direct,) = factory.launchToken(params, 0, address(0));
        (address explicitV4,) = factory.launchToken(params, 0, address(0), GraduationVenue.UNISWAP_V4);
        (address withExemptions,) = factory.launchToken(params, 0, address(0), exempt);
        vm.stopPrank();
        address forwarder = makeAddr("forwarder");
        factory.setLaunchForwarder(forwarder);
        vm.prank(forwarder);
        (address forwarded,) = factory.launchTokenFor(params, 0, address(0), creator, exempt);
        assertEq(uint8(coordinator.packet(direct).venue), 0);
        assertEq(uint8(coordinator.packet(explicitV4).venue), 0);
        assertEq(uint8(coordinator.packet(withExemptions).venue), 0);
        assertEq(uint8(coordinator.packet(forwarded).venue), 0);
    }
}
