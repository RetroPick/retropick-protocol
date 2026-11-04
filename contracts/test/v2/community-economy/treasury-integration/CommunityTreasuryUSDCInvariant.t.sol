// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {
    CommunityTreasuryIntegrationFixtureV2,
    TreasuryIntegrationQuote
} from "./CommunityTreasuryIntegration.t.sol";
import {CommunityTreasuryVaultV2 as Vault} from "../../../../src/v2/CommunityTreasuryVaultV2.sol";
import {CommunityTimelockV2 as Timelock} from "../../../../src/v2/CommunityTimelockV2.sol";
import {CommunityFeeRouterV2 as Router} from "../../../../src/v2/CommunityFeeRouterV2.sol";
import {RetroPickBondingCurveV2 as Curve} from "../../../../src/v2/RetroPickBondingCurveV2.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Six-decimal quote-state handler. This uses a local ERC20 fixture, NOT live Circle USDC.
contract TreasuryUSDCStateHandler is Test {
    struct Operation {
        bytes data;
        bytes32 salt;
    }

    Curve public curve;
    Router public router;
    Vault public vault;
    Timelock public timelock;
    TreasuryIntegrationQuote public quoteToken;
    address public creator;
    address public proposer;
    address public contributor;
    address public recipient;

    uint256 public trades;
    uint256 public settlements;
    uint256 public treasuryClaims;
    uint256 public beneficiaryClaims;
    uint256 public schedules;
    uint256 public executions;
    uint256 public donations;
    uint256 public rejections;
    uint256 public unauthorizedAttempts;
    uint256 public unexpectedUnauthorizedSuccess;
    uint256 public sequence;
    Operation[] internal operations;

    constructor(
        Curve curve_,
        Router router_,
        Vault vault_,
        TreasuryIntegrationQuote quote_,
        address creator_,
        address proposer_,
        address contributor_,
        address recipient_
    ) {
        curve = curve_;
        router = router_;
        vault = vault_;
        timelock = vault_.timelock();
        quoteToken = quote_;
        creator = creator_;
        proposer = proposer_;
        contributor = contributor_;
        recipient = recipient_;
    }

    /// @dev Mock mint gives the handler a durable randomized quote budget. It is not a protocol credit.
    function buy(uint96 input) public {
        uint256 amount = bound(uint256(input), 10_000, 10_000_000);
        quoteToken.mint(creator, amount);
        vm.startPrank(creator);
        quoteToken.approve(address(curve), amount);
        try curve.buy(amount, 0, creator) {
            ++trades;
        } catch {
            ++rejections;
        }
        vm.stopPrank();
    }

    function sell(uint16 share) public {
        uint256 balance = IERC20(curve.token()).balanceOf(creator);
        if (balance <= 1) return;
        uint256 amount = balance * bound(uint256(share), 1, 9_000) / 10_000;
        if (amount == 0) return;
        vm.startPrank(creator);
        IERC20(curve.token()).approve(address(curve), amount);
        try curve.sell(amount, 0, creator) {
            ++trades;
        } catch {
            ++rejections;
        }
        vm.stopPrank();
    }

    function settle() public {
        try router.settle() {
            ++settlements;
        } catch {
            ++rejections;
        }
    }

    function claimTreasury(uint96 input) public {
        uint256 amount = router.credit(address(vault));
        if (amount == 0) return;
        amount = bound(uint256(input), 1, amount);
        try vault.claimFromRouter(amount) {
            ++treasuryClaims;
        } catch {
            ++rejections;
        }
    }

    function claimBeneficiary(uint256 seed, uint96 input) public {
        address actor = seed % 2 == 0 ? creator : contributor;
        uint256 amount = router.credit(actor);
        if (amount == 0) return;
        amount = bound(uint256(input), 1, amount);
        vm.prank(actor);
        try router.claim(amount) {
            ++beneficiaryClaims;
        } catch {
            ++rejections;
        }
    }

    function scheduleSpend(uint96 input) public {
        uint256 held = vault.held();
        if (held == 0) return;
        uint256 amount = bound(uint256(input), 1, held);
        bytes32 salt = keccak256(abi.encode(address(this), ++sequence));
        bytes memory data = abi.encodeCall(Vault.spend, (address(quoteToken), recipient, amount, salt));
        vm.prank(proposer);
        try timelock.schedule(address(vault), 0, data, bytes32(0), salt, 72 hours) {
            operations.push(Operation(data, salt));
            ++schedules;
        } catch {
            ++rejections;
        }
    }

    function executeSpend(uint256 seed) public {
        if (operations.length == 0) return;
        Operation memory op = operations[seed % operations.length];
        bytes32 id = timelock.hashOperation(address(vault), 0, op.data, bytes32(0), op.salt);
        uint256 eta = timelock.getTimestamp(id);
        if (eta > 1 && eta > block.timestamp) vm.warp(eta);
        try timelock.execute(address(vault), 0, op.data, bytes32(0), op.salt) {
            ++executions;
        } catch {
            ++rejections;
        }
    }

    /// @dev Direct ERC20 transfers are quarantined as surplus; neither path may mint fee credit.
    function donate(uint64 input) public {
        uint256 amount = bound(uint256(input), 1, 1_000_000);
        quoteToken.mint(address(vault), amount);
        quoteToken.mint(address(router), amount);
        ++donations;
    }

    function unauthorized(uint96 input) public {
        ++unauthorizedAttempts;
        try vault.spend(address(quoteToken), recipient, bound(uint256(input), 1, 1_000_000), bytes32(uint256(99))) {
            ++unexpectedUnauthorizedSuccess;
        } catch {}
        try router.fund(curve.token(), address(quoteToken), router.activeEpoch(), router.sequence() + 1, 1) {
            ++unexpectedUnauthorizedSuccess;
        } catch {}
    }
}

/// @notice Adds stateful six-decimal ERC20 coverage to the previously native-only Treasury invariant campaign.
/// @dev Does not establish real USDC, Safe multisig, external venue, fork or production qualification.
contract CanonicalCommunityTreasuryUSDCInvariantTest is CommunityTreasuryIntegrationFixtureV2 {
    Curve internal curveUnderTest;
    Router internal routerUnderTest;
    Vault internal vaultUnderTest;
    TreasuryIntegrationQuote internal quoteUnderTest;
    TreasuryUSDCStateHandler internal handler;

    function setUp() public override {
        super.setUp();
        quoteUnderTest = quote();
        (curveUnderTest, routerUnderTest, vaultUnderTest) = launch(CIRCLE);
        handler = new TreasuryUSDCStateHandler(
            curveUnderTest,
            routerUnderTest,
            vaultUnderTest,
            quoteUnderTest,
            creator,
            proposer,
            contributor,
            recipient
        );

        // Deterministic reachability seeds; invariant calls are randomized afterwards.
        handler.buy(25_000_000);
        handler.sell(5_000);
        handler.settle();
        handler.claimTreasury(type(uint96).max);
        handler.claimBeneficiary(0, type(uint96).max);
        handler.scheduleSpend(1);
        handler.executeSpend(0);
        handler.donate(1);
        handler.unauthorized(1);

        targetContract(address(handler));
        bytes4[] memory selectors = new bytes4[](9);
        selectors[0] = handler.buy.selector;
        selectors[1] = handler.sell.selector;
        selectors[2] = handler.settle.selector;
        selectors[3] = handler.claimTreasury.selector;
        selectors[4] = handler.claimBeneficiary.selector;
        selectors[5] = handler.scheduleSpend.selector;
        selectors[6] = handler.executeSpend.selector;
        selectors[7] = handler.donate.selector;
        selectors[8] = handler.unauthorized.selector;
        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
    }

    function invariantCEUSDCConservationAndQuarantinedSurplus() public view {
        assertEq(quoteUnderTest.decimals(), 6);
        assertEq(vaultUnderTest.feeAsset(), address(quoteUnderTest));
        assertEq(vaultUnderTest.claimed(), vaultUnderTest.spent() + vaultUnderTest.held());
        assertGe(quoteUnderTest.balanceOf(address(vaultUnderTest)), vaultUnderTest.held());
        assertEq(vaultUnderTest.deficit(), 0);
        assertEq(vaultUnderTest.actualBalance(), vaultUnderTest.held() + vaultUnderTest.surplus());
        assertEq(routerUnderTest.totalFunded(), routerUnderTest.totalPaid() + routerUnderTest.totalLiability());
        assertGe(quoteUnderTest.balanceOf(address(routerUnderTest)), routerUnderTest.totalLiability());
        assertEq(
            routerUnderTest.credit(creator) + routerUnderTest.credit(contributor)
                + routerUnderTest.credit(address(vaultUnderTest)),
            routerUnderTest.totalLiability()
        );
        assertGe(quoteUnderTest.balanceOf(address(curveUnderTest)), curveUnderTest.trackedQuote());
        assertEq(
            curveUnderTest.realQuoteReserve(),
            curveUnderTest.trackedQuote() - curveUnderTest.quoteFeeBalance() - curveUnderTest.creatorTaxBalance()
        );
        assertEq(handler.unexpectedUnauthorizedSuccess(), 0);
        assertGt(handler.trades(), 0);
        assertGt(handler.treasuryClaims(), 0);
        assertGt(handler.executions(), 0);
        assertGt(handler.donations(), 0);
        assertGt(handler.unauthorizedAttempts(), 0);
    }

    function afterInvariant() public {
        emit log_named_uint("USDC trades (includes seed)", handler.trades());
        emit log_named_uint("USDC settlements", handler.settlements());
        emit log_named_uint("USDC treasury claims", handler.treasuryClaims());
        emit log_named_uint("USDC beneficiary claims", handler.beneficiaryClaims());
        emit log_named_uint("USDC scheduled spends", handler.schedules());
        emit log_named_uint("USDC executed spends", handler.executions());
        emit log_named_uint("USDC direct donations", handler.donations());
        emit log_named_uint("USDC caught economic rejections", handler.rejections());
        emit log_named_uint("USDC unauthorized attempts", handler.unauthorizedAttempts());
    }
}
