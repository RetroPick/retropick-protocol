// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MockERC20} from "../../../mocks/MockERC20.sol";
import {CommunityV4BehaviorFixtureV2, CEHookHarness} from "../CommunityV4Registration.t.sol";
import {CommunityLaunchBuilderV2 as LegacyBuilder} from "../../../../src/v2/CommunityLaunchBuilderV2.sol";
import {CommunityTreasuryLaunchBuilderV2 as Builder} from "../../../../src/v2/CommunityTreasuryLaunchBuilderV2.sol";
import {CommunityTreasuryDeployerV2 as Deployer} from "../../../../src/v2/CommunityTreasuryDeployerV2.sol";
import {CommunityTreasuryVaultV2 as Vault} from "../../../../src/v2/CommunityTreasuryVaultV2.sol";
import {CommunityTimelockV2 as Timelock} from "../../../../src/v2/CommunityTimelockV2.sol";
import {CommunityFeeRouterV2 as Router} from "../../../../src/v2/CommunityFeeRouterV2.sol";
import {CommunityPolicyRegistryV2 as Registry} from "../../../../src/v2/CommunityPolicyRegistryV2.sol";
import {RetroPickLaunchFactoryV2 as Factory} from "../../../../src/v2/RetroPickLaunchFactoryV2.sol";
import {RetroPickBondingCurveV2 as Curve} from "../../../../src/v2/RetroPickBondingCurveV2.sol";
import {RetroPickMemeHookV2} from "../../../../src/v2/hooks/RetroPickMemeHookV2.sol";
import {GraduationPhase} from "../../../../src/v2/interfaces/IRetroPickLaunchpadV2.sol";

/// @notice Successful Treasury + V4 **behavior seam** with real Curve/Router/Vault/Timelock.
/// @dev The PoolManager/PositionManager/Permit2 are behavioral test doubles, not real Uniswap v4.
contract CanonicalCommunityTreasuryV4SeamTest is CommunityV4BehaviorFixtureV2 {
    address internal constant CIRCLE = 0x534b2f3A21130d7a60830c2Df862319e593943A;
    address internal proposer = makeAddr("seam-proposer");
    address internal contributor = makeAddr("seam-contributor");
    address internal recipient = makeAddr("seam-recipient");

    function _run(address asset, uint256 amount) internal {
        Deployer deployer = new Deployer(address(factory));
        Builder builder = new Builder(address(factory), deployer);
        factory.setCommunityBuilder(builder);

        LegacyBuilder.Config memory community;
        community.controller = creator;
        community.guardian = address(0xCAFE);
        community.bounds = Registry.Bounds(6000, 4000, 150, 3 days);
        community.allocations = new Registry.Allocation[](3);
        community.allocations[0] = Registry.Allocation(creator, 4000, 0);
        community.allocations[1] = Registry.Allocation(contributor, 2000, 1);
        community.allocations[2] = Registry.Allocation(address(0), 4000, 2);
        bytes memory config = abi.encode(Builder.ConfigV1(1, community, proposer));
        bytes32 commitment = keccak256(abi.encode(address(builder), address(builder).codehash, config));

        uint256 launchConfig = 0;
        if (asset != address(0)) {
            _admit(asset, 100e6, 100e6, 6);
            factory.addLaunchConfig(
                Factory.LaunchConfig({
                    supply: 1_000_000 ether,
                    curveFeeBps: 100,
                    phantomQuote: 100e6,
                    graduationThreshold: 100e6,
                    poolFee: 0,
                    tickSpacing: 60,
                    enabled: true
                })
            );
            launchConfig = 1;
        }

        Factory.TokenParams memory params = _params();
        params.expectedEconomics = factory.previewLaunchEconomics(launchConfig, asset);
        vm.prank(creator);
        (address token, address curveAddress) =
            factory.launchCommunityToken(params, launchConfig, asset, config, commitment);
        Curve curve = Curve(payable(curveAddress));
        Router router = Router(payable(curve.communityRouter()));
        Vault treasury = Vault(payable(deployer.vaultForRouter(address(router))));
        assertEq(router.registry().module(2), address(treasury));
        assertEq(treasury.launchToken(), token);

        vm.startPrank(creator);
        if (asset != address(0)) IERC20(asset).approve(curveAddress, amount);
        curve.buy{value: asset == address(0) ? amount : 0}(amount, 0, creator);
        vm.stopPrank();
        assertTrue(curve.graduated());
        assertGt(router.totalFunded(), 0);
        uint256 creatorCredit = router.credit(creator);
        uint256 contributorCredit = router.credit(contributor);
        uint256 treasuryCredit = router.credit(address(treasury));
        assertGt(treasuryCredit, 0);

        factory.createGraduatedPool(token);
        assertEq(uint256(factory.getLaunchedToken(token).phase), uint256(GraduationPhase.PoolCreated));
        uint256 positionId = locker.lockedPositions(token);
        assertTrue(locker.isLocked(token));
        assertEq(position.ownerOf(positionId), address(locker));
        assertGt(position.getPositionLiquidity(positionId), 0);

        bool quoteIs0 = asset < token;
        PoolKey memory key = PoolKey(
            Currency.wrap(quoteIs0 ? asset : token),
            Currency.wrap(quoteIs0 ? token : asset),
            0,
            60,
            IHooks(hook)
        );
        RetroPickMemeHookV2.LaunchInfo memory info = CEHookHarness(payable(hook)).readInfo(key);
        assertTrue(info.registered);
        assertEq(info.creator, address(router));
        assertEq(info.hookFeeBps, 0);
        assertEq(info.creatorTaxBps, 0);
        assertFalse(info.buybackEnabled);

        treasury.claimFromRouter(treasuryCredit);
        assertEq(treasury.held(), treasuryCredit);
        assertEq(router.credit(creator), creatorCredit);
        assertEq(router.credit(contributor), contributorCredit);

        bytes32 salt = keccak256(abi.encode(address(this), token, asset));
        bytes memory payload = abi.encodeCall(Vault.spend, (asset, recipient, treasuryCredit, salt));
        Timelock governance = treasury.timelock();
        vm.prank(proposer);
        governance.schedule(address(treasury), 0, payload, bytes32(0), salt, 72 hours);
        vm.expectRevert();
        governance.execute(address(treasury), 0, payload, bytes32(0), salt);
        uint256 recipientBefore = asset == address(0) ? recipient.balance : IERC20(asset).balanceOf(recipient);
        bytes32 operation = governance.hashOperation(address(treasury), 0, payload, bytes32(0), salt);
        vm.warp(governance.getTimestamp(operation));
        governance.execute(address(treasury), 0, payload, bytes32(0), salt);
        uint256 recipientAfter = asset == address(0) ? recipient.balance : IERC20(asset).balanceOf(recipient);
        assertEq(recipientAfter - recipientBefore, treasuryCredit);
        assertEq(treasury.held(), 0);
        assertEq(treasury.spent(), treasuryCredit);

        uint256 fundedBefore = router.totalFunded();
        router.settle();
        assertEq(router.totalFunded(), fundedBefore);
        assertEq(router.totalFunded(), router.totalPaid() + router.totalLiability());
        assertEq(router.credit(creator), creatorCredit);
        assertEq(router.credit(contributor), contributorCredit);
        vm.expectRevert();
        factory.createGraduatedPool(token);
    }

    function testCENativeTreasuryCompletesSuccessfulV4BehaviorSeam() public {
        _run(address(0), 150 ether);
    }

    function testCEUSDCTreasuryCompletesSuccessfulV4BehaviorSeam() public {
        MockERC20 quoteImpl = new MockERC20("Quote6", "Q6", 6);
        vm.etch(CIRCLE, address(quoteImpl).code);
        MockERC20(CIRCLE).mint(creator, 250e6);
        _run(CIRCLE, 150e6);
    }
}
