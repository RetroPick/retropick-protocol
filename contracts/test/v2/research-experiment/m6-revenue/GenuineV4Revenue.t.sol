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
import {
    CommunityLaunchBuilderV2 as LegacyBuilder
} from "../../../../src/v2-research-experiment/CommunityLaunchBuilderV2.sol";
import {
    CommunityRevenueLaunchBuilderV2 as Builder
} from "../../../../src/v2-research-experiment/m6/CommunityRevenueLaunchBuilderV2.sol";
import {
    CommunityAssetTreasuryDeployerV2 as Deployer,
    CommunityRevenueDeployerV2 as RevenueDeployer
} from "../../../../src/v2-research-experiment/m6/CommunityRevenueDeployersV2.sol";
import {
    CommunityPolicyRegistryV2 as Registry
} from "../../../../src/v2-research-experiment/CommunityPolicyRegistryV2.sol";
import {
    CommunityRevenueRouterV2 as Router
} from "../../../../src/v2-research-experiment/m6/CommunityRevenueRouterV2.sol";
import {
    CommunityAssetTreasuryVaultV2 as Vault
} from "../../../../src/v2-research-experiment/m6/CommunityAssetTreasuryVaultV2.sol";
import {CommunityTimelockV2 as Timelock} from "../../../../src/v2-research-experiment/CommunityTimelockV2.sol";
import {
    GraduationReceipt,
    GraduationState,
    GraduationLedger
} from "../../../../src/v2/interfaces/IGraduationExecutorV2.sol";
import {GenuineV4EnvironmentFixtureV2} from "../m6-infra/GenuineV4EnvironmentFixtureV2.sol";

/// @notice Real PoolManager/PositionManager/Permit2, local modeled assets only.
/// @dev Canonical Factory/Curve are explicit unchanged references; all new financial modules are experimental.
import {RetroPickMemeHookV2 as CanonicalHook} from "../../../../src/v2/hooks/RetroPickMemeHookV2.sol";
import {ICommunityBuilderV2 as ICanonicalBuilder} from "../../../../src/v2/interfaces/ICommunityFeesV2.sol";
import {
    CommunityV4FeeHookV2 as RevenueHook
} from "../../../../src/v2-research-experiment/m6/hooks/CommunityV4FeeHookV2.sol";
import {
    CommunityV4GraduationExecutorV2 as RevenueExecutor
} from "../../../../src/v2-research-experiment/m6/CommunityV4GraduationExecutorV2.sol";
import {
    RetroPickLaunchLockerV2 as ExperimentalLocker
} from "../../../../src/v2-research-experiment/RetroPickLaunchLockerV2.sol";
import {
    IRetroPickFeeEscrowV2 as ExperimentalEscrow
} from "../../../../src/v2-research-experiment/interfaces/IRetroPickLaunchpadV2.sol";

contract M6GenuineV4RevenueTest is GenuineV4EnvironmentFixtureV2 {
    using PoolIdLibrary for PoolKey;

    function _createHook() internal override returns (CanonicalHook result) {
        bytes memory init =
            abi.encodePacked(type(RevenueHook).creationCode, abi.encode(manager, escrow, protocol, address(this)));
        bytes32 salt = _minePermissionSalt(address(this), keccak256(init));
        address deployed;
        assembly ("memory-safe") { deployed := create2(0, add(init, 32), mload(init), salt) }
        require(deployed != address(0), "revenue hook CREATE2 failed");
        assertLe(deployed.code.length, 24576);
        result = CanonicalHook(payable(deployed));
    }

    function _createExecutor() internal override returns (address) {
        RevenueExecutor worker = new RevenueExecutor(
            address(coordinator),
            manager,
            position,
            permit2,
            ExperimentalLocker(address(locker)),
            RevenueHook(payable(address(hook))),
            ExperimentalEscrow(address(escrow))
        );
        assertLe(address(worker).code.length, 24576);
        return address(worker);
    }

    function _policyAndExactOutputs(
        address token,
        address asset,
        uint256 small,
        uint256 tokensReceived,
        PoolKey memory key,
        Router router,
        Vault treasury
    ) private {
        Registry reg = router.registry();
        Registry.Allocation[] memory next = new Registry.Allocation[](3);
        next[0] = Registry.Allocation(actor, 3000, 0);
        next[1] = Registry.Allocation(contributor, 1000, 1);
        next[2] = Registry.Allocation(address(treasury), 6000, 2);
        uint256 oldQuoteCredit = router.credit(actor);
        uint256 oldTokenCredit = router.creditOf(token, actor);
        vm.prank(actor);
        uint256 nonce = reg.proposePolicy(next);
        vm.expectRevert(Registry.OutsideWindow.selector);
        reg.activatePolicy(nonce);
        vm.warp(block.timestamp + 3 days);
        reg.activatePolicy(nonce);
        assertEq(router.credit(actor), oldQuoteCredit);
        assertEq(router.creditOf(token, actor), oldTokenCredit);
        bool quote0 = Currency.unwrap(key.currency0) == asset;
        vm.startPrank(actor);
        // Both exact-output directions; the unspecified input leg funds actual in-kind fees.
        swapper.swap{value: asset == address(0) ? small : 0}(
            key,
            SwapParams(
                quote0, int256(tokensReceived / 10), quote0 ? TickMath.MIN_SQRT_PRICE + 1 : TickMath.MAX_SQRT_PRICE - 1
            ),
            small,
            tokensReceived / 10
        );
        swapper.swap(
            key,
            SwapParams(
                !quote0, int256(small / 10), !quote0 ? TickMath.MIN_SQRT_PRICE + 1 : TickMath.MAX_SQRT_PRICE - 1
            ),
            tokensReceived,
            small / 10
        );
        vm.stopPrank();
        assertGt(router.epochFundedAsset(asset, 2), 0);
        assertGt(router.epochFundedAsset(token, 2), 0);
        assertEq(router.funded(asset), router.paid(asset) + router.liability(asset));
        assertEq(router.funded(token), router.paid(token) + router.liability(token));
        assertEq(router.credit(actor) - oldQuoteCredit, router.epochFundedAsset(asset, 2) * 3000 / 10000);
        assertEq(router.creditOf(token, actor) - oldTokenCredit, router.epochFundedAsset(token, 2) * 3000 / 10000);
    }

    function _claimGenuineBeneficiaries(Router router, address quote, address token) private {
        address[2] memory beneficiaries = [actor, contributor];
        address[2] memory assets = [quote, token];
        for (uint256 i; i < 2; ++i) {
            for (uint256 j; j < 2; ++j) {
                address beneficiary = beneficiaries[i];
                address asset = assets[j];
                uint256 amount = router.creditOf(asset, beneficiary);
                assertGt(amount, 0);
                uint256 beforeBalance = asset == address(0) ? beneficiary.balance : IERC20(asset).balanceOf(beneficiary);
                vm.prank(beneficiary);
                router.claimAsset(asset, amount);
                assertEq(router.creditOf(asset, beneficiary), 0);
                assertEq(
                    (asset == address(0) ? beneficiary.balance : IERC20(asset).balanceOf(beneficiary)) - beforeBalance,
                    amount
                );
            }
        }
    }

    function runRevenue(address asset, uint256 unit) internal {
        Deployer treasuryDeployer = new Deployer(address(factory));
        RevenueDeployer revenueDeployer = new RevenueDeployer(address(factory));
        Builder builder = new Builder(address(factory), revenueDeployer, treasuryDeployer);
        factory.setCommunityBuilder(ICanonicalBuilder(address(builder)));
        LegacyBuilder.Config memory c;
        c.controller = actor;
        c.guardian = makeAddr("genuine-guardian");
        c.bounds = Registry.Bounds(6000, 4000, 150, 3 days);
        c.allocations = new Registry.Allocation[](3);
        c.allocations[0] = Registry.Allocation(actor, 4000, 0);
        c.allocations[1] = Registry.Allocation(contributor, 2000, 1);
        c.allocations[2] = Registry.Allocation(address(0), 4000, 2);
        bytes memory config = abi.encode(Builder.ConfigV2(2, c, proposer, bytes32(0)));
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
        // CE003-001 regression with the actual new Factory/Builder/Router/Vault path.
        uint64 factoryNonce = vm.getNonce(address(factory));
        uint64 revenueNonce = vm.getNonce(address(revenueDeployer));
        uint64 treasuryNonce = vm.getNonce(address(treasuryDeployer));
        bytes memory badConfig = abi.encode(Builder.ConfigV2(2, c, address(0), bytes32(0)));
        bytes32 badCommitment = keccak256(abi.encode(address(builder), address(builder).codehash, badConfig));
        vm.prank(actor);
        vm.expectRevert(Builder.InvalidLaunch.selector);
        factory.launchCommunityToken(p, 0, asset, badConfig, badCommitment);
        assertEq(vm.getNonce(address(factory)), factoryNonce);
        assertEq(vm.getNonce(address(revenueDeployer)), revenueNonce);
        assertEq(vm.getNonce(address(treasuryDeployer)), treasuryNonce);
        // Same creator/config can retry atomically and obtains a distinct launch-bound destination.
        vm.prank(actor);
        (address secondToken, address secondCurve) = factory.launchCommunityToken(p, 0, asset, config, commitment);
        address secondRouter = Curve(payable(secondCurve)).communityRouter();
        address secondVault = treasuryDeployer.vaultForRouter(secondRouter);
        assertTrue(secondToken != token && secondRouter != address(router) && secondVault != address(treasury));
        assertEq(address(Vault(payable(secondVault)).router()), secondRouter);
        assertEq(Vault(payable(secondVault)).launchToken(), secondToken);
        assertEq(router.totalFunded(), 0);
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
        assertGt(router.credit(actor), creatorCredit);
        assertGt(router.credit(address(treasury)), treasuryCredit);
        assertGt(router.venueGross(asset), 0);
        assertGt(router.venueGross(token), 0);
        assertEq(router.venueGross(asset), router.venueProtocolRemitted(asset) + router.venueCommunityFunded(asset));
        assertEq(router.venueGross(token), router.venueProtocolRemitted(token) + router.venueCommunityFunded(token));
        assertEq(router.funded(token), router.paid(token) + router.liability(token));
        assertGe(IERC20(token).balanceOf(address(router)), router.liability(token));
        treasuryCredit = router.credit(address(treasury));
        uint256 tokenCredit = router.creditOf(token, address(treasury));
        treasury.claimAssetFromRouter(token, tokenCredit);
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
        bytes32 tokenSalt = keccak256(abi.encode(token, "token-spend"));
        bytes memory tokenSpend = abi.encodeCall(Vault.spend, (token, finalRecipient, tokenCredit, tokenSalt));
        vm.prank(proposer);
        timelock.schedule(address(treasury), 0, tokenSpend, bytes32(0), tokenSalt, 72 hours);
        vm.warp(block.timestamp + 72 hours);
        timelock.execute(address(treasury), 0, tokenSpend, bytes32(0), tokenSalt);
        assertEq(IERC20(token).balanceOf(finalRecipient), tokenCredit);
        assertEq(treasury.heldAsset(token), 0);
        assertEq(treasury.claimedAsset(token), treasury.spentAsset(token));
        assertEq(position.getPositionLiquidity(receipt.positionId), liquidity);
        _policyAndExactOutputs(token, asset, small, tokensReceived, key, router, treasury);
        _claimGenuineBeneficiaries(router, asset, token);

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
        runRevenue(address(0), 1 ether);
    }

    function testGenuineV4SixDecimalCommunityGraduationAndSwaps() public {
        runRevenue(CIRCLE, 1e6);
    }
}
