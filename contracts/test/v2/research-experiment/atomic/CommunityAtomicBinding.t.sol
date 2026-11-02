// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {MockERC20} from "../../../mocks/MockERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {CommunityFactoryFixtureV2} from "../CommunityFactoryFixtureV2.sol";
import {CommunityLaunchBuilderV2 as L} from "../../../../src/v2-research-experiment/CommunityLaunchBuilderV2.sol";
import {
    CommunityTreasuryLaunchBuilderV2 as B,
    IAtomicTreasuryDeployerV2
} from "../../../../src/v2-research-experiment/CommunityTreasuryLaunchBuilderV2.sol";
import {CommunityFeeRouterV2 as R} from "../../../../src/v2-research-experiment/CommunityFeeRouterV2.sol";
import {CommunityPolicyRegistryV2 as P} from "../../../../src/v2-research-experiment/CommunityPolicyRegistryV2.sol";
import {RetroPickLaunchFactoryV2 as F} from "../../../../src/v2-research-experiment/RetroPickLaunchFactoryV2.sol";
import {RetroPickBondingCurveV2 as C} from "../../../../src/v2-research-experiment/RetroPickBondingCurveV2.sol";

/// @dev Noncustodial proof only: no production treasury or timelock claim.
contract BindingProbe {
    error ProbeRejected();
    R public immutable router;
    address public immutable receiver;

    constructor(R r, address to, bool reject) {
        if (reject) revert ProbeRejected();
        router = r;
        receiver = to;
    }

    function pull(uint256 n) external {
        require(router.ready() && router.registry().module(2) == address(this));
        require(router.source().communityRouter() == address(router));
        router.claimTo(receiver, n);
    }
}

contract ProbeDeployer is IAtomicTreasuryDeployerV2 {
    address public immutable factory;
    mapping(address => address) public vaultForRouter;
    mapping(address => address) public vaultForToken;
    bool public rejectCreation;
    uint256 public created;

    function injectFailure(bool enabled) external {
        rejectCreation = enabled;
    }

    constructor(address f) {
        factory = f;
    }

    function deployForLaunch(R r, address, address proposer) external returns (address v) {
        require(msg.sender == address(F(payable(factory)).communityBuilder()));
        require(
            r.factory() == factory && vaultForRouter[address(r)] == address(0)
                && vaultForToken[r.launchToken()] == address(0)
        );
        ++created;
        v = address(new BindingProbe(r, proposer, rejectCreation));
        vaultForRouter[address(r)] = v;
        vaultForToken[r.launchToken()] = v;
    }
}

contract CommunityAtomicBindingTest is CommunityFactoryFixtureV2 {
    B builder;
    ProbeDeployer deployment;
    address receiver = address(0xBEEF);

    function setUp() public override {
        super.setUp();
        deployment = new ProbeDeployer(address(factory));
        builder = new B(address(factory), deployment);
        factory.setCommunityBuilder(builder);
    }

    function cfg(bool bad, address proposed) internal view returns (bytes memory) {
        L.Config memory c;
        c.controller = creator;
        c.guardian = address(0xABCD);
        c.bounds = P.Bounds(6000, 4000, 150, 3 days);
        c.modules[0] = proposed;
        c.allocations = new P.Allocation[](2);
        c.allocations[0] = P.Allocation(creator, 6000, 0);
        c.allocations[1] = P.Allocation(proposed, bad ? 3000 : 4000, 2);
        return abi.encode(B.ConfigV1(1, c, receiver));
    }

    function launch(bytes memory config) internal returns (C c, R r, BindingProbe v) {
        return launchOn(config, address(0));
    }

    function launchOn(bytes memory config, address quote) internal returns (C c, R r, BindingProbe v) {
        F.TokenParams memory p = _params(bytes32(uint256(903)));
        p.expectedEconomics = factory.previewLaunchEconomics(0, quote);
        bytes32 h = keccak256(abi.encode(address(builder), address(builder).codehash, config));
        vm.prank(creator);
        (, address src) = factory.launchCommunityToken(p, 0, quote, config, h);
        c = C(payable(src));
        r = R(payable(c.communityRouter()));
        v = BindingProbe(deployment.vaultForRouter(address(r)));
    }

    function failLaunch(bytes memory config, bytes4 selector) internal {
        F.TokenParams memory p = _params(bytes32(uint256(903)));
        p.expectedEconomics = factory.previewLaunchEconomics(0, address(0));
        bytes32 h = keccak256(abi.encode(address(builder), address(builder).codehash, config));
        vm.prank(creator);
        vm.expectRevert(selector);
        factory.launchCommunityToken(p, 0, address(0), config, h);
    }

    function earn(C c, R r, uint256 amount) internal {
        vm.prank(creator);
        c.buy{value: amount}(amount, 0, creator);
        r.settle();
    }

    function testCEAtomicTwoLaunchesHaveDistinctClaimableDestinations() public {
        (C a, R ra, BindingProbe va) = launch(cfg(false, address(0)));
        (C b, R rb, BindingProbe vb) = launch(cfg(false, address(0)));
        assertTrue(address(va) != address(vb));
        assertTrue(address(ra) != address(rb));
        assertEq(ra.registry().module(2), address(va));
        assertEq(rb.registry().module(2), address(vb));
        earn(a, ra, 1 ether);
        earn(b, rb, 1 ether);
        uint256 ca = ra.credit(address(va));
        uint256 cb = rb.credit(address(vb));
        assertGt(ca, 0);
        assertGt(cb, 0);
        uint256 start = receiver.balance;
        va.pull(ca);
        assertEq(rb.credit(address(vb)), cb);
        vb.pull(cb);
        assertEq(receiver.balance, start + ca + cb);
        assertEq(address(va).balance, 0);
    }

    function testCEAtomicFailureRollsBackCreationNonceAndRetries() public {
        uint64 n = vm.getNonce(address(deployment));
        failLaunch(cfg(true, address(0)), P.InvalidPolicy.selector);
        assertEq(vm.getNonce(address(deployment)), n);
        (, R r, BindingProbe v) = launch(cfg(false, address(0)));
        assertEq(deployment.vaultForToken(r.launchToken()), address(v));
    }

    function testCEAtomicRejectsSharedTreasuryInput() public {
        failLaunch(cfg(false, address(0x1234)), B.InvalidLaunch.selector);
    }

    function testCEAtomicRejectsUnauthorizedCalls() public {
        (, R r,) = launch(cfg(false, address(0)));
        vm.expectRevert();
        deployment.deployForLaunch(r, creator, receiver);
        address token = r.launchToken();
        address source = address(r.source());
        vm.expectRevert(B.InvalidLaunch.selector);
        builder.configure(token, source, creator, "", bytes32(0));
    }

    function testCEAtomicRejectsWrongVersionAndChangedDeployerCode() public {
        B.ConfigV1 memory v = abi.decode(cfg(false, address(0)), (B.ConfigV1));
        v.version = 2;
        failLaunch(abi.encode(v), B.InvalidLaunch.selector);
        vm.etch(address(deployment), hex"00");
        failLaunch(cfg(false, address(0)), B.InvalidLaunch.selector);
    }

    function testCEAtomicConstructorFailureRollsBackAndRetries() public {
        deployment.injectFailure(true);
        uint64 n = vm.getNonce(address(deployment));
        uint64 bn = vm.getNonce(address(builder));
        uint64 dn = vm.getNonce(address(factory.launchDeployer()));
        failLaunch(cfg(false, address(0)), BindingProbe.ProbeRejected.selector);
        assertEq(deployment.created(), 0);
        assertEq(vm.getNonce(address(deployment)), n);
        assertEq(vm.getNonce(address(builder)), bn);
        assertEq(vm.getNonce(address(factory.launchDeployer())), dn);
        deployment.injectFailure(false);
        launch(cfg(false, address(0)));
        assertEq(deployment.created(), 1);
    }

    function testCEAtomicExactUSDCSourceAndIndependentClaim() public {
        address quote = 0x534b2f3A21130d7a60830c2Df862319e593943A3;
        MockERC20 implementation = new MockERC20("Quote", "Q", 6);
        vm.etch(quote, address(implementation).code);
        MockERC20(quote).mint(creator, 100e6);
        _admit(quote, 100e6, 100e6, 6);
        (C c, R r, BindingProbe v) = launchOn(cfg(false, address(0)), quote);
        vm.startPrank(creator);
        IERC20(quote).approve(address(c), 1e6);
        c.buy(1e6, 0, creator);
        vm.stopPrank();
        r.settle();
        uint256 debt = r.credit(address(v));
        assertGt(debt, 0);
        uint256 other = r.credit(creator);
        v.pull(debt);
        assertEq(IERC20(quote).balanceOf(receiver), debt);
        assertEq(r.credit(creator), other);
        assertEq(IERC20(quote).balanceOf(address(v)), 0);
    }

    function testFuzzCEAtomicBindingConservation(uint96 amount) public {
        amount = uint96(bound(amount, 1e8, 1 ether));
        (C c, R r, BindingProbe v) = launch(cfg(false, address(0)));
        earn(c, r, amount);
        uint256 n = r.credit(address(v));
        uint256 start = receiver.balance;
        v.pull(n);
        assertEq(receiver.balance, start + n);
        assertEq(r.credit(address(v)), 0);
        assertEq(r.totalFunded(), r.totalPaid() + r.totalLiability());
    }
}
