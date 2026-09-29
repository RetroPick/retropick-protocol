// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {RetroPickBondingCurveV2} from "../../../src/v2/RetroPickBondingCurveV2.sol";
import {RetroPickLauncherTokenV2} from "../../../src/v2/RetroPickLauncherTokenV2.sol";
import {RetroPickBuybackVaultV2} from "../../../src/v2/RetroPickBuybackVaultV2.sol";
import {
    FeePolicySnapshot,
    IRetroPickFeePolicyV2,
    IRetroPickFeeEscrowV2
} from "../../../src/v2/interfaces/IRetroPickLaunchpadV2.sol";

contract CurveStateFeePolicyV2 is IRetroPickFeePolicyV2 {
    address public immutable override protocolFeeRecipient;
    address public immutable override feeSweepOperator;
    IRetroPickFeeEscrowV2 public immutable override feeEscrow;

    constructor(address protocol_, address operator_, IRetroPickFeeEscrowV2 escrow_) {
        protocolFeeRecipient = protocol_;
        feeSweepOperator = operator_;
        feeEscrow = escrow_;
    }

    function protocolFeeShareBps() external pure returns (uint256) {
        return 2_500;
    }

    function buybackBurnBps() external pure returns (uint256) {
        return 5_000;
    }

    function maxInternalPriceImpactBps() external pure returns (uint256) {
        return 500;
    }

    function currentFeePolicy() external view returns (FeePolicySnapshot memory) {
        return FeePolicySnapshot({
            protocolFeeRecipient: protocolFeeRecipient,
            protocolFeeShareBps: 2_500,
            buybackBurnBps: 5_000,
            hookFeeBps: 0,
            maxInternalPriceImpactBps: 500
        });
    }
}

contract CurveStateFeeEscrowV2 {
    mapping(address => uint256) public balanceOf;

    function credit(address recipient) external payable {
        balanceOf[recipient] += msg.value;
    }

    function creditToken(address recipient, address token, uint256 amount) external {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        balanceOf[recipient] += amount;
    }
}

/// @notice Direct CURRENT Curve/Token/fee behavioral characterization, without a V4 or Kuru mock.
contract RetroPickCurrentCurveStateV2QualificationTest is Test {
    uint256 internal constant SUPPLY = 1_000_000 ether;
    uint256 internal constant PHANTOM = 100 ether;
    uint256 internal constant THRESHOLD = 100 ether;
    uint256 internal constant FEE_BPS = 100;
    uint256 internal constant TAX_BPS = 50;
    address internal creator = makeAddr("creator");
    address internal buyer = makeAddr("buyer");
    address internal protocol = makeAddr("protocol");
    address internal operator = makeAddr("fee-operator");

    RetroPickBondingCurveV2 internal curve;
    RetroPickLauncherTokenV2 internal token;
    CurveStateFeeEscrowV2 internal escrow;

    function setUp() public {
        escrow = new CurveStateFeeEscrowV2();
        CurveStateFeePolicyV2 policy =
            new CurveStateFeePolicyV2(protocol, operator, IRetroPickFeeEscrowV2(address(escrow)));
        RetroPickBuybackVaultV2 vault = new RetroPickBuybackVaultV2(
            address(this), IRetroPickFeePolicyV2(address(policy)), IRetroPickFeeEscrowV2(address(escrow))
        );
        curve = new RetroPickBondingCurveV2(
            address(0),
            creator,
            address(this),
            IRetroPickFeePolicyV2(address(policy)),
            policy.currentFeePolicy(),
            IRetroPickFeeEscrowV2(address(escrow)),
            vault,
            PHANTOM,
            FEE_BPS,
            TAX_BPS,
            false,
            THRESHOLD
        );
        RetroPickLauncherTokenV2.Socials memory socials;
        token = new RetroPickLauncherTokenV2(
            "Launch", "LCH", "", "", socials, creator, address(curve), address(this), SUPPLY
        );
        curve.initialize(address(token));
        vm.deal(buyer, 100 ether);
    }

    function testInitialSupplyWiringAndReserve() public view {
        assertEq(token.totalSupply(), SUPPLY);
        assertEq(token.balanceOf(address(curve)), SUPPLY);
        assertEq(token.curve(), address(curve));
        assertEq(token.launchFactory(), address(this));
        assertEq(token.deployer(), creator);
        assertEq(curve.trackedTokens(), SUPPLY);
        assertEq(curve.reservedTokens(), (SUPPLY * PHANTOM) / (PHANTOM + THRESHOLD));
        assertEq(curve.sellableTokens(), SUPPLY / 2);
        assertEq(curve.realQuoteReserve(), 0);
        (uint256 quoteReserve, uint256 tokenReserve) = curve.getReserves();
        assertEq(quoteReserve, PHANTOM);
        assertEq(tokenReserve, SUPPLY);
    }

    function testBuySellAndFeeBucketsReconcileWithPhysicalBalances() public {
        uint256 quoteIn = 1 ether;
        uint256 fee = quoteIn * FEE_BPS / 10_000;
        uint256 tax = quoteIn * TAX_BPS / 10_000;
        uint256 net = quoteIn - fee - tax;
        uint256 expectedTokens = net * SUPPLY / (PHANTOM + net);

        vm.prank(buyer);
        uint256 tokensOut = curve.buy{value: quoteIn}(quoteIn, expectedTokens, buyer);
        assertEq(tokensOut, expectedTokens);
        assertEq(token.balanceOf(buyer), expectedTokens);
        assertEq(curve.trackedTokens(), SUPPLY - expectedTokens);
        assertEq(curve.quoteFeeBalance(), fee);
        assertEq(curve.creatorTaxBalance(), tax);
        assertEq(curve.buybackQuoteBalance(), 0);
        assertEq(curve.trackedQuote(), quoteIn);
        assertEq(address(curve).balance, quoteIn);
        assertEq(curve.realQuoteReserve(), quoteIn - fee - tax);
        (uint256 quoteReserve,) = curve.getReserves();
        assertEq(quoteReserve, PHANTOM + quoteIn - fee - tax);

        uint256 sellAmount = tokensOut / 2;
        vm.startPrank(buyer);
        token.approve(address(curve), sellAmount);
        uint256 buyerQuoteBefore = buyer.balance;
        uint256 quoteOut = curve.sell(sellAmount, 0, buyer);
        vm.stopPrank();
        assertEq(buyer.balance - buyerQuoteBefore, quoteOut);
        assertEq(address(curve).balance, curve.trackedQuote());
        assertEq(token.balanceOf(address(curve)), curve.trackedTokens());
        assertEq(curve.realQuoteReserve(), curve.trackedQuote() - curve.quoteFeeBalance() - curve.creatorTaxBalance());
        assertLe(quoteOut, quoteIn - fee - tax);
    }

    function testSweepDoesNotDoubleDeductBuybackEarmark() public {
        curve.setBuybackEnabled(true);
        vm.prank(buyer);
        curve.buy{value: 1 ether}(1 ether, 0, buyer);
        uint256 fee = curve.quoteFeeBalance();
        uint256 tax = curve.creatorTaxBalance();
        uint256 earmark = curve.buybackQuoteBalance();
        assertGt(earmark, 0);
        assertLe(earmark, fee);
        assertEq(curve.realQuoteReserve(), curve.trackedQuote() - fee - tax);
        // Switching off buyback changes future accrual only; pending earmark remains.
        curve.setBuybackEnabled(false);
        assertEq(curve.buybackQuoteBalance(), earmark);
    }

    function testSnipeExemptionIsCurrentlyNoOpForTradeTax() public {
        curve.exemptFromSnipeTax(buyer);
        vm.prank(buyer);
        curve.buy{value: 1 ether}(1 ether, 0, buyer);
        assertEq(curve.creatorTaxBalance(), 1 ether * TAX_BPS / 10_000);
        assertEq(curve.quoteFeeBalance(), 1 ether * FEE_BPS / 10_000);
    }

    function testPlainFeeSweepLeavesTradingReserveIntact() public {
        vm.prank(buyer);
        curve.buy{value: 1 ether}(1 ether, 0, buyer);
        uint256 realBefore = curve.realQuoteReserve();
        uint256 pending = curve.quoteFeeBalance();
        uint256 tax = curve.creatorTaxBalance();
        vm.prank(operator);
        curve.sweepFees(0);
        assertEq(curve.quoteFeeBalance(), 0);
        assertEq(curve.creatorTaxBalance(), 0);
        assertEq(curve.realQuoteReserve(), realBefore);
        assertEq(address(curve).balance, realBefore);
        assertEq(escrow.balanceOf(protocol), pending * 2_500 / 10_000);
        assertEq(escrow.balanceOf(creator), pending - pending * 2_500 / 10_000 + tax);
    }

    function testUnauthorizedAndFailedOperationsPreserveAccounting() public {
        vm.prank(buyer);
        vm.expectRevert(RetroPickBondingCurveV2.NotFactory.selector);
        curve.setBuybackEnabled(true);
        vm.prank(buyer);
        vm.expectPartialRevert(RetroPickBondingCurveV2.SlippageExceeded.selector);
        curve.buy{value: 1 ether}(1 ether, SUPPLY, buyer);
        assertEq(address(curve).balance, 0);
        assertEq(curve.trackedQuote(), 0);
        assertEq(curve.trackedTokens(), SUPPLY);
        assertEq(token.balanceOf(buyer), 0);
    }
}
