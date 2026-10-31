// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {CommunityFlowFixtureV2} from "./CommunityCurveFlow.t.sol";
// Explicit frozen-reference imports; the experimental side always uses experimental source.
import {RetroPickBondingCurveV2 as CanonicalCurve} from "../../../src/v2/RetroPickBondingCurveV2.sol";
import {RetroPickLauncherTokenV2 as CanonicalToken} from "../../../src/v2/RetroPickLauncherTokenV2.sol";
import {RetroPickBuybackVaultV2 as CanonicalVault} from "../../../src/v2/RetroPickBuybackVaultV2.sol";
import {
    IRetroPickFeePolicyV2 as CanonicalPolicy,
    IRetroPickFeeEscrowV2 as CanonicalEscrow
} from "../../../src/v2/interfaces/IRetroPickLaunchpadV2.sol";
import {
    RetroPickBondingCurveV2 as ExperimentalCurve
} from "../../../src/v2-research-experiment/RetroPickBondingCurveV2.sol";
import {
    RetroPickLauncherTokenV2 as ExperimentalToken
} from "../../../src/v2-research-experiment/RetroPickLauncherTokenV2.sol";
import {
    IRetroPickFeePolicyV2 as ExperimentalPolicy,
    IRetroPickFeeEscrowV2 as ExperimentalEscrow
} from "../../../src/v2-research-experiment/interfaces/IRetroPickLaunchpadV2.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CommunityLegacyDifferentialTest is CommunityFlowFixtureV2 {
    function compare(address quote, uint256 unit) internal {
        uint256 phantom = 100 * unit;
        CanonicalPolicy cp = CanonicalPolicy(hook);
        ExperimentalPolicy ep = ExperimentalPolicy(hook);
        CanonicalCurve a = new CanonicalCurve(
            quote,
            creator,
            address(this),
            cp,
            cp.currentFeePolicy(),
            CanonicalEscrow(address(escrow)),
            CanonicalVault(address(vault)),
            phantom,
            100,
            50,
            false,
            phantom,
            phantom * 50
        );
        ExperimentalCurve b = new ExperimentalCurve(
            quote,
            creator,
            address(this),
            ep,
            ep.currentFeePolicy(),
            ExperimentalEscrow(address(escrow)),
            vault,
            phantom,
            100,
            50,
            false,
            phantom,
            phantom * 50
        );
        CanonicalToken.Socials memory cs;
        ExperimentalToken.Socials memory es;
        CanonicalToken ct =
            new CanonicalToken("Legacy", "LEG", "", "", cs, creator, address(a), address(this), 1000000 ether);
        ExperimentalToken et =
            new ExperimentalToken("Legacy", "LEG", "", "", es, creator, address(b), address(this), 1000000 ether);
        a.initialize(address(ct));
        b.initialize(address(et));
        vm.deal(creator, 1000 ether);
        for (uint256 i = 1; i <= 8; ++i) {
            uint256 input = unit / i;
            vm.startPrank(creator);
            if (quote != address(0)) {
                IERC20(quote).approve(address(a), input);
                IERC20(quote).approve(address(b), input);
            }
            uint256 x = a.buy{value: quote == address(0) ? input : 0}(input, 0, creator);
            uint256 y = b.buy{value: quote == address(0) ? input : 0}(input, 0, creator);
            assertEq(x, y);
            ct.approve(address(a), x / 2);
            et.approve(address(b), y / 2);
            assertEq(a.sell(x / 2, 0, creator), b.sell(y / 2, 0, creator));
            vm.stopPrank();
            (uint256 aq, uint256 at) = a.getReserves();
            (uint256 bq, uint256 bt) = b.getReserves();
            assertEq(aq, bq);
            assertEq(at, bt);
            assertEq(a.trackedQuote(), b.trackedQuote());
            assertEq(a.quoteFeeBalance(), b.quoteFeeBalance());
            assertEq(a.creatorTaxBalance(), b.creatorTaxBalance());
            assertEq(a.readyToGraduate(), b.readyToGraduate());
            uint256 protoBefore =
                quote == address(0) ? escrow.balanceOf(protocol) : escrow.balanceOfToken(protocol, quote);
            vm.prank(feeOperator);
            a.sweepFees(0);
            uint256 protoMiddle =
                quote == address(0) ? escrow.balanceOf(protocol) : escrow.balanceOfToken(protocol, quote);
            vm.prank(feeOperator);
            b.sweepFees(0);
            uint256 protoAfter =
                quote == address(0) ? escrow.balanceOf(protocol) : escrow.balanceOfToken(protocol, quote);
            assertEq(protoMiddle - protoBefore, protoAfter - protoMiddle);
            assertEq(a.realQuoteReserve(), b.realQuoteReserve());
        }
    }

    function testLegacyNativeTradeReserveFeeDifferential() public {
        compare(address(0), 1 ether);
    }

    function testLegacyUSDCTradeReserveFeeDifferential() public {
        installQuote();
        compare(CIRCLE, 1e6);
    }
}
