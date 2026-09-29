// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {RetroPickLaunchDeployerV2, LaunchDeployment} from "../../../src/v2/RetroPickLaunchDeployerV2.sol";
import {RetroPickBondingCurveV2} from "../../../src/v2/RetroPickBondingCurveV2.sol";
import {RetroPickLauncherTokenV2} from "../../../src/v2/RetroPickLauncherTokenV2.sol";
import {RetroPickBuybackVaultV2} from "../../../src/v2/RetroPickBuybackVaultV2.sol";
import {IRetroPickFeePolicyV2, IRetroPickFeeEscrowV2} from "../../../src/v2/interfaces/IRetroPickLaunchpadV2.sol";
import {CurveStateFeePolicyV2, CurveStateFeeEscrowV2} from "./RetroPickCurrentCurveStateV2Qualification.t.sol";

contract RetroPickLaunchDeployerV2QualificationTest is Test {
    RetroPickLaunchDeployerV2 internal deployer;
    CurveStateFeePolicyV2 internal policy;
    CurveStateFeeEscrowV2 internal escrow;
    RetroPickBuybackVaultV2 internal vault;
    address internal creator = makeAddr("creator");
    address internal protocol = makeAddr("protocol");
    address internal operator = makeAddr("operator");

    function setUp() public {
        escrow = new CurveStateFeeEscrowV2();
        policy = new CurveStateFeePolicyV2(protocol, operator, IRetroPickFeeEscrowV2(address(escrow)));
        vault = new RetroPickBuybackVaultV2(address(this), policy, IRetroPickFeeEscrowV2(address(escrow)));
        deployer = new RetroPickLaunchDeployerV2(address(this));
    }

    function _params(address pairToken) internal view returns (LaunchDeployment memory p) {
        RetroPickLauncherTokenV2.Socials memory socials;
        p = LaunchDeployment({
            pairToken: pairToken,
            creatorFeeRecipient: creator,
            originalDeployer: creator,
            feePolicy: IRetroPickFeePolicyV2(address(policy)),
            policy: policy.currentFeePolicy(),
            feeEscrow: IRetroPickFeeEscrowV2(address(escrow)),
            buybackVault: vault,
            phantomQuote: 100 ether,
            curveFeeBps: 100,
            creatorTaxBps: 50,
            buybackEnabled: false,
            graduationThreshold: 100 ether,
            supply: 1_000_000 ether,
            name: "Launch",
            symbol: "LCH",
            logo: "",
            description: "",
            socials: socials
        });
    }

    function testDeploysFreshCurveAndTokenWithFactoryIdentity() public {
        (address tokenAddress, address curveAddress) = deployer.deployLaunch(_params(address(0)));
        RetroPickLauncherTokenV2 token = RetroPickLauncherTokenV2(tokenAddress);
        RetroPickBondingCurveV2 curve = RetroPickBondingCurveV2(payable(curveAddress));
        assertEq(curve.factory(), address(this));
        assertEq(token.launchFactory(), address(this));
        assertEq(token.curve(), curveAddress);
        assertEq(token.totalSupply(), 1_000_000 ether);
        assertEq(token.balanceOf(curveAddress), token.totalSupply());
        assertEq(curve.pairToken(), address(0));
        assertEq(curve.token(), address(0), "factory has not initialized yet");
        curve.initialize(tokenAddress);
        assertEq(curve.token(), tokenAddress);
        assertEq(curve.trackedTokens(), token.totalSupply());
    }

    function testDifferentQuoteAddressIsPassedThroughNotAdmittedHere() public {
        address unqualifiedQuote = makeAddr("unqualified-quote");
        (address tokenAddress, address curveAddress) = deployer.deployLaunch(_params(unqualifiedQuote));
        assertEq(RetroPickBondingCurveV2(payable(curveAddress)).pairToken(), unqualifiedQuote);
        assertEq(RetroPickLauncherTokenV2(tokenAddress).curve(), curveAddress);
        // The factory, not this helper, owns quote admission. This test is not
        // evidence that an arbitrary ERC20 can be launched through Factory.
    }

    function testUnauthorizedCallerCannotDeploy() public {
        LaunchDeployment memory p = _params(address(0));
        vm.prank(creator);
        vm.expectRevert(RetroPickLaunchDeployerV2.NotFactory.selector);
        deployer.deployLaunch(p);
    }

    function testMetadataBoundsRejectOverlongNameAndSocial() public {
        LaunchDeployment memory p = _params(address(0));
        p.name = new string(65);
        vm.expectRevert(RetroPickLaunchDeployerV2.MetadataTooLong.selector);
        deployer.deployLaunch(p);

        p = _params(address(0));
        p.socials.twitter = new string(257);
        vm.expectRevert(RetroPickLaunchDeployerV2.MetadataTooLong.selector);
        deployer.deployLaunch(p);
    }
}
