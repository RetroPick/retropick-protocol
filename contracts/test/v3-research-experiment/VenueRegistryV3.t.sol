// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {VenueRegistryV3, SettlementKind} from "../../src/v3-research-experiment/VenueRegistryV3.sol";

/// @dev Deliberately trivial: a real venue adapter needs isolated custody/receipt
///      qualification. This test proves late registration, not economic safety.
contract VenueStubV3 {}

/// @dev Models the important property of a venue-neutral factory: no venue ABI,
///      Uniswap/Kuru imports, or venue-specific bytecode is in its deployment.
contract VenueNeutralFactoryHarnessV3 {
    struct Commitment {
        bytes32 venueId;
        uint32 version;
        address adapter;
        bytes32 adapterCodeHash;
        bytes32 policyHash;
        SettlementKind settlementKind;
    }

    VenueRegistryV3 public immutable registry;
    uint256 public nextId;
    mapping(uint256 launchId => Commitment) private _commitments;

    constructor(VenueRegistryV3 registry_) {
        registry = registry_;
    }

    function commit(bytes32 venueId, uint32 version) external returns (uint256 launchId) {
        VenueRegistryV3.VenueConfig memory cfg = registry.resolve(venueId, version);
        launchId = ++nextId;
        _commitments[launchId] = Commitment({
            venueId: venueId,
            version: version,
            adapter: cfg.adapter,
            adapterCodeHash: cfg.adapterCodeHash,
            policyHash: cfg.policyHash,
            settlementKind: cfg.settlementKind
        });
    }

    function commitment(uint256 launchId) external view returns (Commitment memory) {
        return _commitments[launchId];
    }
}

contract VenueRegistryV3ProofTest is Test {
    bytes32 internal constant UNISWAP = keccak256("retropick.venue.uniswap-v4");
    bytes32 internal constant KURU = keccak256("retropick.venue.kuru");
    bytes32 internal constant HYPERCORE = keccak256("retropick.venue.hypercore");
    bytes32 internal constant POLICY1 = keccak256("approved-policy-1");
    bytes32 internal constant POLICY2 = keccak256("approved-policy-2");

    VenueRegistryV3 internal registry;
    VenueNeutralFactoryHarnessV3 internal factory;
    VenueStubV3 internal adapterA;
    VenueStubV3 internal adapterB;
    VenueStubV3 internal adapterC;

    function setUp() public {
        registry = new VenueRegistryV3(address(this));
        factory = new VenueNeutralFactoryHarnessV3(registry);
        adapterA = new VenueStubV3();
        adapterB = new VenueStubV3();
        adapterC = new VenueStubV3();
    }

    function testRegisterNewVenueAfterFactoryDeploymentWithoutFactoryBytecodeChange() public {
        bytes32 factoryCodeHash = address(factory).codehash;
        uint256 factoryCodeSize = address(factory).code.length;
        address factoryAddress = address(factory);

        registry.register(UNISWAP, 1, address(adapterA), POLICY1, SettlementKind.ATOMIC_EVM);
        uint256 originalId = factory.commit(UNISWAP, 1);
        VenueNeutralFactoryHarnessV3.Commitment memory original = factory.commitment(originalId);

        registry.register(KURU, 1, address(adapterB), POLICY1, SettlementKind.ATOMIC_EVM);
        uint256 secondId = factory.commit(KURU, 1);

        registry.register(HYPERCORE, 1, address(adapterC), POLICY2, SettlementKind.NATIVE_ASYNC);
        uint256 thirdId = factory.commit(HYPERCORE, 1);

        assertEq(address(factory), factoryAddress);
        assertEq(address(factory).codehash, factoryCodeHash);
        assertEq(address(factory).code.length, factoryCodeSize);
        assertEq(original.adapter, address(adapterA));
        assertEq(factory.commitment(secondId).adapter, address(adapterB));
        assertEq(factory.commitment(thirdId).adapter, address(adapterC));
        assertEq(uint8(factory.commitment(thirdId).settlementKind), uint8(SettlementKind.NATIVE_ASYNC));
    }

    function testDisablingVersionBlocksNewCommitmentsButDoesNotRewriteOldCommitment() public {
        registry.register(KURU, 1, address(adapterB), POLICY1, SettlementKind.ATOMIC_EVM);
        uint256 launchId = factory.commit(KURU, 1);
        bytes32 beforeHash = keccak256(abi.encode(factory.commitment(launchId)));

        registry.disable(KURU, 1);
        vm.expectRevert(VenueRegistryV3.VenueNotAdmitted.selector);
        factory.commit(KURU, 1);

        assertEq(keccak256(abi.encode(factory.commitment(launchId))), beforeHash);
        assertEq(factory.commitment(launchId).adapter, address(adapterB));
        assertFalse(registry.get(KURU, 1).enabled);
    }

    function testAdapterVersionCannotBeSilentlyReplaced() public {
        registry.register(UNISWAP, 1, address(adapterA), POLICY1, SettlementKind.ATOMIC_EVM);
        uint256 launchId = factory.commit(UNISWAP, 1);

        vm.expectRevert(VenueRegistryV3.VenueAlreadyRegistered.selector);
        registry.register(UNISWAP, 1, address(adapterB), POLICY2, SettlementKind.ATOMIC_EVM);

        registry.register(UNISWAP, 2, address(adapterB), POLICY2, SettlementKind.ATOMIC_EVM);
        uint256 newerId = factory.commit(UNISWAP, 2);

        assertEq(factory.commitment(launchId).adapter, address(adapterA));
        assertEq(factory.commitment(newerId).adapter, address(adapterB));
        assertEq(factory.commitment(launchId).policyHash, POLICY1);
    }

    function testUnauthorizedRegistryMutationRejected() public {
        vm.prank(address(0xBEEF));
        vm.expectRevert();
        registry.register(KURU, 1, address(adapterA), POLICY1, SettlementKind.ATOMIC_EVM);
    }

    function testRejectsEOAAndEmptyPolicyAndUnknownVenue() public {
        vm.expectRevert(VenueRegistryV3.InvalidVenue.selector);
        registry.register(KURU, 1, address(0xBEEF), POLICY1, SettlementKind.ATOMIC_EVM);

        vm.expectRevert(VenueRegistryV3.InvalidVenue.selector);
        registry.register(KURU, 1, address(adapterA), bytes32(0), SettlementKind.ATOMIC_EVM);

        vm.expectRevert(VenueRegistryV3.InvalidVenue.selector);
        registry.register(bytes32(0), 1, address(adapterA), POLICY1, SettlementKind.ATOMIC_EVM);

        vm.expectRevert(VenueRegistryV3.VenueNotAdmitted.selector);
        factory.commit(KURU, 99);
    }

    function testChainScopedRegistryCannotResolveAfterChainIdentityChanges() public {
        registry.register(KURU, 1, address(adapterA), POLICY1, SettlementKind.ATOMIC_EVM);
        vm.chainId(block.chainid + 1);
        vm.expectRevert(VenueRegistryV3.WrongChain.selector);
        factory.commit(KURU, 1);
    }

    function testFuzzNewVenueIdentifiersDoNotRequireFactoryChanges(bytes32 newVenue) public {
        vm.assume(newVenue != bytes32(0));
        bytes32 factoryCodeHash = address(factory).codehash;
        registry.register(newVenue, 1, address(adapterA), POLICY1, SettlementKind.ATOMIC_EVM);
        uint256 id = factory.commit(newVenue, 1);
        assertEq(factory.commitment(id).venueId, newVenue);
        assertEq(address(factory).codehash, factoryCodeHash);
    }
}
