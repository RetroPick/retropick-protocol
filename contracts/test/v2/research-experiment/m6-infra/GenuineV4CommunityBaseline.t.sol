// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {RetroPickBondingCurveV2 as Curve} from "../../../../src/v2/RetroPickBondingCurveV2.sol";
import {RetroPickLaunchFactoryV2 as Factory} from "../../../../src/v2/RetroPickLaunchFactoryV2.sol";
import {CommunityLaunchBuilderV2 as LegacyBuilder} from "../../../../src/v2/CommunityLaunchBuilderV2.sol";
import {CommunityTreasuryLaunchBuilderV2 as Builder} from "../../../../src/v2/CommunityTreasuryLaunchBuilderV2.sol";
import {CommunityTreasuryDeployerV2 as Deployer} from "../../../../src/v2/CommunityTreasuryDeployerV2.sol";
import {CommunityPolicyRegistryV2 as Registry} from "../../../../src/v2/CommunityPolicyRegistryV2.sol";
import {CommunityFeeRouterV2 as Router} from "../../../../src/v2/CommunityFeeRouterV2.sol";
import {CommunityTreasuryVaultV2 as Vault} from "../../../../src/v2/CommunityTreasuryVaultV2.sol";
import {CommunityTimelockV2 as Timelock} from "../../../../src/v2/CommunityTimelockV2.sol";
import {
    GraduationReceipt,
    GraduationState,
    GraduationLedger
} from "../../../../src/v2/interfaces/IGraduationExecutorV2.sol";
import {GenuineV4EnvironmentFixtureV2} from "./GenuineV4EnvironmentFixtureV2.sol";

/// @notice Real PoolManager/PositionManager/Permit2, local modeled assets only.
/// @dev Existing CE mode keeps post-graduation hook fees zero. Not continuous revenue qualification.
contract M6GenuineV4CommunityBaselineTest is GenuineV4EnvironmentFixtureV2 {
    using PoolIdLibrary for PoolKey;

    function runBaseline(address asset, uint256 unit) internal {
        Deployer treasuryDeployer = new Deployer(address(factory));
        Builder builder = new Builder(address(factory), treasuryDeployer);
        factory.setCommunityBuilder(builder);
        LegacyBuilder.Config memory c;
        c.controller = actor;
        c.guardian = makeAddr("genuine-guardian");
        c.bounds = Registry.Bounds(6000, 4000, 150, 3 days);
        c.allocations = new Registry.Allocation[](3);
        c.allocations[0] = Registry.Allocation(actor, 4000, 0);
        c.allocations[1] = Registry.Allocation(contributor, 2000, 1);
        c.allocations[2] = Registry.Allocation(address(0), 4000, 2);
        bytes memory config = abi.encode(Builder.ConfigV1(1, c, proposer));
        bytes32 commitment = keccak256(abi.encode(address(builder), address(builder).codehash, config));
        Factory.TokenParams memory p;
        p.name = "Genuine V4 local";
        p.symbol = "GV4";
        p.creatorFeeRecipient = actor;
        p.creatorTaxBps = 50;
        p.expectedEconomics = factory.previewLaunchEconomics(0, asset);
        vm.prank(actor);
        (address token, address curveAddress) = factory.launchCommunityToken(p, 0, asset, config, commitment);
        Curve curve = Curve(payable(curveAddress));
        Router router = Router(payable(curve.communityRouter()));
        Vault treasury = Vault(payable(treasuryDeployer.vaultForRouter(address(router))));
        uint256 small = unit / 100;
        vm.startPrank(actor);
        if (asset != address(0)) IERC20(asset).approve(curveAddress, type(uint256).max);
        uint256 acquired = curve.buy{value: asset == address(0) ? small : 0}(small, 0, actor);
        IERC20(token).approve(curveAddress, acquired / 2);
        curve.sell(acquired / 2, 0, actor);
        vm.stopPrank();
        router.settle();
        assertGt(router.totalFunded(), 0);
        (, uint256 gross) = curve.completionQuote();
        uint256 finalTokens = curve.sellableTokens();
        vm.prank(actor);
        curve.buy{value: asset == address(0) ? gross : 0}(gross, finalTokens, actor);
        assertTrue(curve.graduated());
        GraduationReceipt memory receipt = coordinator.complete(token);
        GraduationLedger memory ledger = coordinator.ledger(token);
        assertEq(uint8(ledger.phase), uint8(GraduationState.GRADUATED));
        assertEq(ledger.consumedQuote, receipt.seededQuote + receipt.quoteResidual);
        assertEq(ledger.consumedLaunchTokens, receipt.seededLaunchTokens + receipt.protectedExcessAmount);
        assertEq(ledger.destinationIdentity, receipt.destinationIdentity);
        assertEq(ledger.receiptHash, keccak256(abi.encode(receipt)));
        assertEq(IERC20(token).totalSupply(), 1000 ether);
        assertEq(IERC20(token).balanceOf(address(manager)), receipt.seededLaunchTokens);
        assertEq(
            asset == address(0) ? address(manager).balance : IERC20(asset).balanceOf(address(manager)),
            receipt.seededQuote
        );
        assertEq(IERC20(token).balanceOf(address(locker)), receipt.protectedExcessAmount);
        assertEq(IERC721(address(position)).ownerOf(receipt.positionId), address(locker));
        assertEq(position.getPositionLiquidity(receipt.positionId), receipt.protectedLPAmount);
        assertTrue(locker.isLocked(token));
        assertGt(receipt.protectedLPAmount, 0);
        (PoolKey memory key,) = position.getPoolAndPositionInfo(receipt.positionId);
        assertEq(PoolId.unwrap(key.toId()), receipt.destinationIdentity);
        assertEq(address(key.hooks), address(hook));
        assertEq(key.fee, 0);
        assertEq(key.tickSpacing, 60);
        uint128 liquidity = position.getPositionLiquidity(receipt.positionId);
        uint256 creatorCredit = router.credit(actor);
        uint256 treasuryCredit = router.credit(address(treasury));
        assertGt(treasuryCredit, 0);

        vm.startPrank(actor);
        IERC20(token).approve(address(swapper), type(uint256).max);
        if (asset != address(0)) IERC20(asset).approve(address(swapper), type(uint256).max);
        bool quoteIs0 = Currency.unwrap(key.currency0) == asset;
        uint256 beforeTokens = IERC20(token).balanceOf(actor);
        swapper.swap{value: asset == address(0) ? small : 0}(
            key,
            SwapParams(quoteIs0, -int256(small), quoteIs0 ? TickMath.MIN_SQRT_PRICE + 1 : TickMath.MAX_SQRT_PRICE - 1),
            small,
            1
        );
        uint256 tokensReceived = IERC20(token).balanceOf(actor) - beforeTokens;
        assertGt(tokensReceived, 0);
        uint256 quoteBefore = asset == address(0) ? actor.balance : IERC20(asset).balanceOf(actor);
        swapper.swap(
            key,
            SwapParams(
                !quoteIs0,
                -int256(tokensReceived / 2),
                !quoteIs0 ? TickMath.MIN_SQRT_PRICE + 1 : TickMath.MAX_SQRT_PRICE - 1
            ),
            tokensReceived / 2,
            1
        );
        assertGt(asset == address(0) ? actor.balance : IERC20(asset).balanceOf(actor), quoteBefore);
        vm.stopPrank();
        assertEq(position.getPositionLiquidity(receipt.positionId), liquidity);
        assertEq(IERC721(address(position)).ownerOf(receipt.positionId), address(locker));
        assertEq(router.credit(actor), creatorCredit);
        assertEq(router.credit(address(treasury)), treasuryCredit);

        treasury.claimFromRouter(treasuryCredit);
        Timelock timelock = treasury.timelock();
        bytes32 salt = keccak256(abi.encode(token, asset));
        bytes memory spend = abi.encodeCall(Vault.spend, (asset, finalRecipient, treasuryCredit, salt));
        vm.prank(proposer);
        timelock.schedule(address(treasury), 0, spend, bytes32(0), salt, 72 hours);
        bytes32 operation = timelock.hashOperation(address(treasury), 0, spend, bytes32(0), salt);
        vm.warp(timelock.getTimestamp(operation));
        uint256 beforeRecipient = asset == address(0) ? finalRecipient.balance : IERC20(asset).balanceOf(finalRecipient);
        timelock.execute(address(treasury), 0, spend, bytes32(0), salt);
        assertEq(
            (asset == address(0) ? finalRecipient.balance : IERC20(asset).balanceOf(finalRecipient)) - beforeRecipient,
            treasuryCredit
        );
        assertEq(treasury.held(), 0);
        assertEq(router.totalFunded(), router.totalPaid() + router.totalLiability());
        assertEq(treasury.claimed(), treasury.spent() + treasury.held());
        assertEq(treasury.deficit(), 0);
        emit log_named_address("quote asset (zero=native, modeled Q6 otherwise)", asset);
        emit log_named_address("genuine PoolManager", address(manager));
        emit log_named_bytes32("PoolManager runtime codehash", address(manager).codehash);
        emit log_named_address("genuine PositionManager", address(position));
        emit log_named_bytes32("PositionManager runtime codehash", address(position).codehash);
        emit log_named_address("genuine Permit2", address(permit2));
        emit log_named_bytes32("Permit2 runtime codehash", address(permit2).codehash);
        emit log_named_bytes32("genuine pool ID", receipt.destinationIdentity);
        emit log_named_bytes32("graduation receipt hash", keccak256(abi.encode(receipt)));
        emit log_named_uint("LP NFT ID owned by Locker", receipt.positionId);
        emit log_named_uint("secured LP liquidity unchanged by swaps", liquidity);
        emit log_named_uint("quote seeded into genuine PoolManager", receipt.seededQuote);
        emit log_named_uint("token seeded into genuine PoolManager", receipt.seededLaunchTokens);
        emit log_named_uint("Router funded from real curve fees", router.totalFunded());
        emit log_named_uint("Router paid plus outstanding", router.totalPaid() + router.totalLiability());
        emit log_named_uint("Treasury earned fees spent after 72h", treasuryCredit);
        vm.expectRevert();
        coordinator.complete(token);
    }

    function testGenuineV4NativeCommunityGraduationAndSwaps() public {
        runBaseline(address(0), 1 ether);
    }

    function testGenuineV4SixDecimalCommunityGraduationAndSwaps() public {
        runBaseline(CIRCLE, 1e6);
    }
}
