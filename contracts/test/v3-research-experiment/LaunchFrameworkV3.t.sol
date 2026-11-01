// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {VenueRegistryV3, SettlementKind} from "../../src/v3-research-experiment/VenueRegistryV3.sol";
import {QuoteVenuePolicyV3} from "../../src/v3-research-experiment/framework/QuoteVenuePolicyV3.sol";
import {LaunchCommitmentHubV3} from "../../src/v3-research-experiment/framework/LaunchCommitmentHubV3.sol";
import {AtomicGraduationEscrowV3} from "../../src/v3-research-experiment/framework/AtomicGraduationEscrowV3.sol";
import {
    LaunchBlueprintV3,
    LaunchCommitmentV3,
    AtomicExecutionContextV3,
    AtomicGraduationReceiptV3,
    IAtomicVenueExecutorV3
} from "../../src/v3-research-experiment/framework/LaunchFrameworkTypesV3.sol";

contract FrameworkTokenV3 is ERC20 {
    constructor(string memory n, string memory s) ERC20(n, s) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

/// @dev Test-only stand-in. Actual Uniswap/Kuru destination-state checks are
///      much stronger and MUST NOT be replaced by this mock.
contract FrameworkAtomicVenueV3 is IAtomicVenueExecutorV3 {
    address public immutable coordinator;
    address public immutable destination;
    bool public shouldRevert;
    bool public invalidReceipt;

    error Unauthorized();
    error SimulatedFailure();

    constructor(address coordinator_, address destination_) {
        coordinator = coordinator_;
        destination = destination_;
    }

    function configureFailure(bool value) external {
        shouldRevert = value;
    }

    function configureInvalidReceipt(bool value) external {
        invalidReceipt = value;
    }

    function validate(LaunchCommitmentV3 calldata launch) external view {
        require(launch.adapter == address(this) && launch.settlementKind == SettlementKind.ATOMIC_EVM);
    }

    function execute(AtomicExecutionContextV3 calldata context)
        external
        returns (AtomicGraduationReceiptV3 memory receipt)
    {
        if (msg.sender != coordinator) revert Unauthorized();
        if (shouldRevert) revert SimulatedFailure();

        require(IERC20(context.token).transferFrom(msg.sender, destination, context.tokenAmount));
        require(IERC20(context.quoteAsset).transferFrom(msg.sender, destination, context.quoteAmount));

        receipt.launchId = context.launchId;
        receipt.destinationId = bytes32(uint256(uint160(destination)));
        receipt.tokenSpent = context.tokenAmount;
        receipt.quoteSpent = invalidReceipt ? context.quoteAmount - 1 : context.quoteAmount;
        receipt.settlementProof = keccak256(
            abi.encode(context.launchId, context.venueConfigHash, destination, context.tokenAmount, context.quoteAmount)
        );
    }

    function verify(AtomicExecutionContextV3 calldata context, AtomicGraduationReceiptV3 calldata receipt)
        external
        view
        returns (bool)
    {
        return receipt.destinationId == bytes32(uint256(uint160(destination)))
            && IERC20(context.token).balanceOf(destination) >= context.tokenAmount
            && IERC20(context.quoteAsset).balanceOf(destination) >= context.quoteAmount;
    }
}

contract LaunchFrameworkV3Test is Test {
    bytes32 internal constant UNISWAP = keccak256("retropick.venue.uniswap-v4");
    bytes32 internal constant KURU = keccak256("retropick.venue.kuru");
    bytes32 internal constant HYPERCORE = keccak256("retropick.venue.hypercore-spot");
    bytes32 internal constant VENUE_POLICY = keccak256("approved-venue-policy");
    bytes32 internal constant QUOTE_POLICY = keccak256("approved-quote-policy");
    bytes32 internal constant CONFIG = keccak256("venue-config-v1");
    bytes32 internal constant ECONOMICS = keccak256("launch-economics-v1");

    VenueRegistryV3 internal registry;
    QuoteVenuePolicyV3 internal quotes;
    LaunchCommitmentHubV3 internal hub;
    AtomicGraduationEscrowV3 internal escrow;
    FrameworkTokenV3 internal quote;
    FrameworkTokenV3 internal tokenA;
    FrameworkTokenV3 internal tokenB;
    FrameworkAtomicVenueV3 internal uniswap;
    FrameworkAtomicVenueV3 internal kuru;
    FrameworkAtomicVenueV3 internal nativeRoute;

    function setUp() public {
        registry = new VenueRegistryV3(address(this));
        quotes = new QuoteVenuePolicyV3(address(this));
        hub = new LaunchCommitmentHubV3(address(this), registry, quotes);
        escrow = new AtomicGraduationEscrowV3(address(this), hub);
        quote = new FrameworkTokenV3("Quote", "QUOTE");
        tokenA = new FrameworkTokenV3("Community A", "A");
        tokenB = new FrameworkTokenV3("Community B", "B");
        uniswap = new FrameworkAtomicVenueV3(address(escrow), address(0xA111));
        kuru = new FrameworkAtomicVenueV3(address(escrow), address(0xB222));
        nativeRoute = new FrameworkAtomicVenueV3(address(escrow), address(0xC333));
        tokenA.mint(address(this), 1_000 ether);
        tokenB.mint(address(this), 1_000 ether);
        quote.mint(address(this), 2_000 ether);
        tokenA.approve(address(escrow), type(uint256).max);
        tokenB.approve(address(escrow), type(uint256).max);
        quote.approve(address(escrow), type(uint256).max);
    }

    function _register(bytes32 venue, uint32 version, FrameworkAtomicVenueV3 adapter, SettlementKind kind) internal {
        registry.register(venue, version, address(adapter), VENUE_POLICY, kind);
        quotes.register(venue, version, address(quote), 18, QUOTE_POLICY);
    }

    function _blueprint(FrameworkTokenV3 token, bytes32 venue, uint32 version)
        internal
        view
        returns (LaunchBlueprintV3 memory b)
    {
        b.creator = address(this);
        b.token = address(token);
        b.quoteAsset = address(quote);
        b.venueId = venue;
        b.venueVersion = version;
        b.venueConfigHash = CONFIG;
        b.economicsHash = ECONOMICS;
        b.communityPolicyHash = keccak256("community-policy");
    }

    function testNewVenueAfterCoreDeployPreservesCodehashAndExistingLaunch() public {
        bytes32 beforeCode = address(hub).codehash;
        uint256 beforeSize = address(hub).code.length;
        _register(UNISWAP, 1, uniswap, SettlementKind.ATOMIC_EVM);
        bytes32 firstId = hub.commitLaunch(_blueprint(tokenA, UNISWAP, 1));
        bytes32 firstHash = hub.commitmentHash(firstId);

        // Venue B is registered *after* the core is already deployed.
        _register(KURU, 1, kuru, SettlementKind.ATOMIC_EVM);
        bytes32 secondId = hub.commitLaunch(_blueprint(tokenB, KURU, 1));

        assertEq(address(hub).codehash, beforeCode);
        assertEq(address(hub).code.length, beforeSize);
        assertEq(hub.commitmentHash(firstId), firstHash);
        assertEq(hub.commitment(firstId).adapter, address(uniswap));
        assertEq(hub.commitment(secondId).adapter, address(kuru));
    }

    function testSecureAndCompleteFullAmountWithVerifiedReceipt() public {
        _register(KURU, 1, kuru, SettlementKind.ATOMIC_EVM);
        bytes32 id = hub.commitLaunch(_blueprint(tokenA, KURU, 1));
        escrow.secure(id, 100 ether, 200 ether);

        assertEq(escrow.assetLiability(address(tokenA)), 100 ether);
        assertEq(escrow.assetLiability(address(quote)), 200 ether);

        vm.prank(address(0xDEAD));
        AtomicGraduationReceiptV3 memory r = escrow.complete(id);

        assertEq(r.tokenSpent, 100 ether);
        assertEq(r.quoteSpent, 200 ether);
        assertEq(tokenA.balanceOf(address(0xB222)), 100 ether);
        assertEq(quote.balanceOf(address(0xB222)), 200 ether);
        assertEq(escrow.assetLiability(address(tokenA)), 0);
        assertEq(escrow.assetLiability(address(quote)), 0);
        assertEq(uint8(escrow.ledger(id).phase), uint8(AtomicGraduationEscrowV3.Phase.GRADUATED));

        vm.expectRevert(AtomicGraduationEscrowV3.WrongPhase.selector);
        escrow.complete(id);
    }

    function testAdapterFailureDoesNotEraseSecuredBalancesAndIsRetryable() public {
        _register(KURU, 1, kuru, SettlementKind.ATOMIC_EVM);
        bytes32 id = hub.commitLaunch(_blueprint(tokenA, KURU, 1));
        escrow.secure(id, 100 ether, 200 ether);

        kuru.configureFailure(true);
        vm.expectRevert(FrameworkAtomicVenueV3.SimulatedFailure.selector);
        escrow.complete(id);

        assertEq(uint8(escrow.ledger(id).phase), uint8(AtomicGraduationEscrowV3.Phase.SECURED));
        assertEq(tokenA.balanceOf(address(escrow)), 100 ether);
        assertEq(quote.balanceOf(address(escrow)), 200 ether);

        kuru.configureFailure(false);
        escrow.complete(id);
        assertEq(uint8(escrow.ledger(id).phase), uint8(AtomicGraduationEscrowV3.Phase.GRADUATED));
    }

    function testIncorrectReceiptRevertsAllTransfers() public {
        _register(UNISWAP, 1, uniswap, SettlementKind.ATOMIC_EVM);
        bytes32 id = hub.commitLaunch(_blueprint(tokenA, UNISWAP, 1));
        escrow.secure(id, 100 ether, 200 ether);
        uniswap.configureInvalidReceipt(true);

        vm.expectRevert(AtomicGraduationEscrowV3.InvalidReceipt.selector);
        escrow.complete(id);

        assertEq(tokenA.balanceOf(address(escrow)), 100 ether);
        assertEq(quote.balanceOf(address(escrow)), 200 ether);
        assertEq(tokenA.balanceOf(address(0xA111)), 0);
    }

    function testDisablingAdmissionDoesNotChangeCommittedRoute() public {
        _register(KURU, 1, kuru, SettlementKind.ATOMIC_EVM);
        bytes32 id = hub.commitLaunch(_blueprint(tokenA, KURU, 1));
        bytes32 pinned = hub.commitmentHash(id);
        registry.disable(KURU, 1);
        quotes.disable(KURU, 1, address(quote));

        vm.expectRevert(VenueRegistryV3.VenueNotAdmitted.selector);
        hub.commitLaunch(_blueprint(tokenB, KURU, 1));

        assertEq(hub.commitmentHash(id), pinned);
        escrow.secure(id, 100 ether, 200 ether);
        escrow.complete(id);
        assertEq(uint8(escrow.ledger(id).phase), uint8(AtomicGraduationEscrowV3.Phase.GRADUATED));
    }

    function testAsyncRouteCannotEnterAtomicEscrow() public {
        _register(HYPERCORE, 1, nativeRoute, SettlementKind.NATIVE_ASYNC);
        bytes32 id = hub.commitLaunch(_blueprint(tokenA, HYPERCORE, 1));
        vm.expectRevert(AtomicGraduationEscrowV3.InvalidCommitment.selector);
        escrow.secure(id, 100 ether, 200 ether);
    }

    function testUnapprovedQuoteRejectedBeforeCommitment() public {
        registry.register(KURU, 1, address(kuru), VENUE_POLICY, SettlementKind.ATOMIC_EVM);
        vm.expectRevert(QuoteVenuePolicyV3.RuleNotAdmitted.selector);
        hub.commitLaunch(_blueprint(tokenA, KURU, 1));
    }

    function testUnauthorizedSecureBlocked() public {
        _register(KURU, 1, kuru, SettlementKind.ATOMIC_EVM);
        bytes32 id = hub.commitLaunch(_blueprint(tokenA, KURU, 1));
        vm.prank(address(0xBAD));
        vm.expectRevert(AtomicGraduationEscrowV3.OnlyFactory.selector);
        escrow.secure(id, 100 ether, 200 ether);
    }

    function testMultipleLiabilitiesOnSameQuoteStayBacked() public {
        _register(KURU, 1, kuru, SettlementKind.ATOMIC_EVM);
        bytes32 idA = hub.commitLaunch(_blueprint(tokenA, KURU, 1));
        bytes32 idB = hub.commitLaunch(_blueprint(tokenB, KURU, 1));
        escrow.secure(idA, 100 ether, 100 ether);
        escrow.secure(idB, 100 ether, 100 ether);
        assertEq(escrow.assetLiability(address(quote)), 200 ether);

        escrow.complete(idA);
        assertEq(escrow.assetLiability(address(quote)), 100 ether);
        assertEq(quote.balanceOf(address(escrow)), 100 ether);

        escrow.complete(idB);
        assertEq(escrow.assetLiability(address(quote)), 0);
        assertEq(quote.balanceOf(address(escrow)), 0);
    }
}
