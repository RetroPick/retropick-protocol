// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {PredictionMarket} from "../../src/prediction/PredictionMarket.sol";

/// @notice Kernel integers loaded from the Python fixtures. A mismatch is COUNTEREXAMPLE_FOUND.
contract PredictionDifferentialTest is Test {
    MockCollateral internal collateral;
    PredictionMarket internal market;
    address internal resolver = address(0xBEEF);
    address internal dustSink = address(0xD057);
    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);

    function setUp() public {
        collateral = new MockCollateral(6);
        market = new PredictionMarket(
            address(collateral), resolver, dustSink, bytes32("fixture-hash"), "Yes", "YES", "No", "NO"
        );
        market.activate();
        collateral.mint(alice, 1_000_000);
        vm.prank(alice);
        collateral.approve(address(market), type(uint256).max);
    }

    function test_split_reads_fixture() public {
        string memory json = _load("prediction_split.json");
        uint256 amount = _step(json, 0, "collateral_locked");
        vm.prank(alice);
        market.split(amount);
        assertEq(market.yesSupply(), _step(json, 0, "yes_supply"));
        assertEq(market.noSupply(), _step(json, 0, "no_supply"));
        assertEq(market.yesToken().balanceOf(alice), _step(json, 0, "yes_supply"));
        assertEq(market.noToken().balanceOf(alice), _step(json, 0, "no_supply"));
        assertEq(market.liability(), _step(json, 0, "liability"));
    }

    function test_merge_reads_fixture() public {
        string memory splitJson = _load("prediction_split.json");
        string memory mergeJson = _load("prediction_merge.json");
        uint256 startAmount = _step(splitJson, 0, "collateral_locked");
        uint256 endAmount = _step(mergeJson, 0, "collateral_locked");
        vm.startPrank(alice);
        market.split(startAmount);
        market.merge(startAmount - endAmount);
        vm.stopPrank();
        assertEq(market.collateralLocked(), endAmount);
        assertEq(market.yesSupply(), _step(mergeJson, 0, "yes_supply"));
        assertEq(market.noSupply(), _step(mergeJson, 0, "no_supply"));
        assertEq(collateral.balanceOf(alice), 1_000_000 - endAmount);
    }

    function test_close_mint_reads_fixture() public {
        string memory json = _load("prediction_close_mint.json");
        _split(json);
        vm.prank(resolver);
        market.closeMint();
        _assertFlat(json);
    }

    function test_begin_resolution_reads_fixture() public {
        string memory json = _load("prediction_begin_resolution.json");
        _split(json);
        vm.startPrank(resolver);
        market.closeMint();
        market.beginResolution();
        vm.stopPrank();
        _assertFlat(json);
    }

    function test_resolve_yes_reads_fixture() public {
        string memory json = _load("prediction_resolve_yes_state.json");
        _split(json);
        _resolve(PredictionMarket.Result.YES_WIN);
        _assertFlat(json);
        vm.expectRevert(PredictionMarket.BadState.selector);
        vm.prank(alice);
        market.redeemYes(1);
    }

    function test_resolve_no_reads_fixture() public {
        string memory json = _load("prediction_resolve_no.json");
        _split(json);
        _resolve(PredictionMarket.Result.NO_WIN);
        _assertFlat(json);
    }

    function test_resolve_invalid_reads_fixture() public {
        string memory json = _load("prediction_resolve_invalid.json");
        _split(json);
        _resolve(PredictionMarket.Result.INVALID);
        _assertFlat(json);
    }

    function test_redeem_yes_reads_fixture() public {
        string memory json = _load("prediction_redeem_yes.json");
        vm.prank(alice);
        market.split(100);
        _resolve(PredictionMarket.Result.YES_WIN);
        market.openRedemption();
        vm.startPrank(alice);
        uint256 yesPayout = market.redeemYes(25);
        assertEq(yesPayout, _at(json, "", "payout"));
        assertEq(market.collateralLocked(), _at(json, "after_yes", "collateral_locked"));
        assertEq(market.yesSupply(), _at(json, "after_yes", "yes_supply"));
        assertEq(market.noSupply(), _at(json, "after_yes", "no_supply"));
        uint256 noPayout = market.redeemNo(10);
        vm.stopPrank();
        assertEq(noPayout, _at(json, "", "no_payout"));
        assertEq(market.collateralLocked(), _at(json, "after_no", "collateral_locked"));
        assertEq(market.yesSupply(), _at(json, "after_no", "yes_supply"));
        assertEq(market.noSupply(), _at(json, "after_no", "no_supply"));
        assertEq(market.liability(), _at(json, "after_no", "liability"));
    }

    function test_redeem_no_reads_fixture() public {
        string memory json = _load("prediction_redeem_no.json");
        _split(json);
        _resolve(PredictionMarket.Result.NO_WIN);
        market.openRedemption();
        vm.prank(alice);
        uint256 payout = market.redeemNo(_at(json, "", "redeem_amount"));
        assertEq(payout, _at(json, "", "payout"));
        _assertFlat(json);
        assertEq(market.noToken().balanceOf(alice), _at(json, "", "no_supply"));
    }

    function test_burn_worthless_and_archive_read_fixture() public {
        string memory json = _load("prediction_burn_worthless.json");
        vm.prank(alice);
        market.split(_at(json, "after_redeem", "split_amount"));
        _resolve(PredictionMarket.Result.YES_WIN);
        market.openRedemption();
        vm.startPrank(alice);
        uint256 payout = market.redeemYes(_at(json, "after_redeem", "redeem_amount"));
        assertEq(payout, _at(json, "after_redeem", "payout"));
        _assertPrefix(json, "after_redeem");
        market.burnWorthless(false, _at(json, "after_redeem", "burn_amount"));
        _assertPrefix(json, "after_burn");
        assertEq(market.noToken().balanceOf(alice), 0);
        vm.stopPrank();
        uint256 residual = market.archive();
        assertEq(residual, _at(json, "after_archive", "residual"));
        _assertPrefix(json, "after_archive");
        assertEq(collateral.balanceOf(dustSink), residual);
    }

    function test_archive_invalid_reads_fixture() public {
        string memory json = _load("prediction_archive_invalid.json");
        vm.prank(alice);
        market.split(_at(json, "before_archive", "split_amount"));
        _resolve(PredictionMarket.Result.INVALID);
        market.openRedemption();
        vm.startPrank(alice);
        market.redeemYes(5);
        market.redeemNo(5);
        vm.stopPrank();
        _assertPrefix(json, "before_archive");
        uint256 residual = market.archive();
        assertEq(residual, _at(json, "after_archive", "residual"));
        _assertPrefix(json, "after_archive");
        assertEq(collateral.balanceOf(dustSink), residual);
    }

    function test_merge_locked_reads_fixture() public {
        string memory json = _load("prediction_merge_locked.json");
        _split(json);
        vm.prank(resolver);
        market.closeMint();
        vm.prank(alice);
        market.merge(_at(json, "", "merge_amount"));
        _assertFlat(json);
        assertEq(collateral.balanceOf(alice), 1_000_000 - _at(json, "", "collateral_locked"));
    }

    function test_invalid_stream_reads_fixture() public {
        string memory json = _load("prediction_invalid_rounding.json");
        vm.prank(alice);
        market.split(5);
        _resolve(PredictionMarket.Result.INVALID);
        market.openRedemption();
        vm.startPrank(alice);
        for (uint256 i; i < 5; ++i) {
            assertEq(market.redeemYes(1), _step(json, i, "payout"));
        }
        for (uint256 i; i < 5; ++i) {
            assertEq(market.redeemNo(1), _step(json, i + 5, "payout"));
        }
        vm.stopPrank();
        assertEq(market.collateralLocked(), _at(json, "", "residual"));
        assertEq(market.liability(), 0);
    }

    function test_rejections_read_fixture() public {
        string memory json = _load("prediction_rejections.json");
        _rejectSplitAfterClose(json);
        _rejectSplitZero(json);
        _rejectMergeUnequal(json);
        _rejectMergeAfterResolution(json);
        _rejectRedeemBeforeOpen(json);
        _rejectWrongResolver(json);
        _rejectOverRedeem(json);
        _rejectInvalidBurn(json);
        _rejectFeeOnTransfer(json);
    }

    function _rejectSplitAfterClose(string memory json) private {
        _fresh();
        vm.prank(alice);
        market.split(_obj(json, "split_after_close", "split_amount"));
        vm.prank(resolver);
        market.closeMint();
        vm.prank(alice);
        vm.expectRevert(PredictionMarket.BadState.selector);
        market.split(_obj(json, "split_after_close", "attempted"));
        assertEq(market.collateralLocked(), _obj(json, "split_after_close", "collateral_locked"));
        assertEq(uint256(market.state()), _obj(json, "split_after_close", "state"));
    }

    function _rejectSplitZero(string memory json) private {
        _fresh();
        vm.prank(alice);
        market.split(_obj(json, "split_zero", "prior_split"));
        vm.prank(alice);
        vm.expectRevert(PredictionMarket.ZeroAmount.selector);
        market.split(_obj(json, "split_zero", "attempted"));
        assertEq(market.collateralLocked(), _obj(json, "split_zero", "collateral_locked"));
        assertEq(market.yesSupply(), _obj(json, "split_zero", "yes_supply"));
    }

    function _rejectMergeUnequal(string memory json) private {
        _fresh();
        vm.prank(alice);
        market.split(_obj(json, "merge_unequal", "split_amount"));
        vm.prank(bob);
        vm.expectRevert();
        market.merge(_obj(json, "merge_unequal", "attempted"));
        assertEq(market.collateralLocked(), _obj(json, "merge_unequal", "collateral_locked"));
        assertEq(market.yesToken().balanceOf(alice), _obj(json, "merge_unequal", "yes_supply"));
    }

    function _rejectMergeAfterResolution(string memory json) private {
        _fresh();
        vm.prank(alice);
        market.split(_obj(json, "merge_after_resolution", "split_amount"));
        _resolve(PredictionMarket.Result.YES_WIN);
        vm.prank(alice);
        vm.expectRevert(PredictionMarket.BadState.selector);
        market.merge(_obj(json, "merge_after_resolution", "attempted"));
        assertEq(uint256(market.state()), _obj(json, "merge_after_resolution", "state"));
        assertEq(market.collateralLocked(), _obj(json, "merge_after_resolution", "collateral_locked"));
    }

    function _rejectRedeemBeforeOpen(string memory json) private {
        _fresh();
        vm.prank(alice);
        market.split(_obj(json, "redeem_before_open", "split_amount"));
        _resolve(PredictionMarket.Result.YES_WIN);
        vm.prank(alice);
        vm.expectRevert(PredictionMarket.BadState.selector);
        market.redeemYes(_obj(json, "redeem_before_open", "attempted"));
        assertEq(uint256(market.state()), _obj(json, "redeem_before_open", "state"));
        assertEq(market.yesSupply(), _obj(json, "redeem_before_open", "yes_supply"));
    }

    function _rejectWrongResolver(string memory json) private {
        _fresh();
        vm.prank(alice);
        market.split(_obj(json, "wrong_resolver", "split_amount"));
        vm.startPrank(resolver);
        market.closeMint();
        market.beginResolution();
        vm.stopPrank();
        vm.prank(alice);
        vm.expectRevert(PredictionMarket.NotResolver.selector);
        market.resolve(PredictionMarket.Result.YES_WIN);
        assertEq(uint256(market.state()), _obj(json, "wrong_resolver", "state"));
        assertEq(uint256(market.result()), _obj(json, "wrong_resolver", "result"));
        assertEq(market.collateralLocked(), _obj(json, "wrong_resolver", "collateral_locked"));
    }

    function _rejectOverRedeem(string memory json) private {
        _fresh();
        vm.prank(alice);
        market.split(_obj(json, "over_redeem", "split_amount"));
        _resolve(PredictionMarket.Result.YES_WIN);
        market.openRedemption();
        vm.startPrank(alice);
        uint256 payout = market.redeemYes(_obj(json, "over_redeem", "redeemed"));
        assertEq(payout, _obj(json, "over_redeem", "payout"));
        vm.expectRevert();
        market.redeemYes(_obj(json, "over_redeem", "attempted"));
        vm.stopPrank();
        assertEq(market.yesSupply(), _obj(json, "over_redeem", "yes_supply"));
        assertEq(market.collateralLocked(), _obj(json, "over_redeem", "collateral_locked"));
        assertEq(market.yesRedeemed(), _obj(json, "over_redeem", "yes_redeemed"));
    }

    function _rejectInvalidBurn(string memory json) private {
        _fresh();
        vm.prank(alice);
        market.split(_obj(json, "invalid_burn", "split_amount"));
        _resolve(PredictionMarket.Result.INVALID);
        market.openRedemption();
        vm.prank(alice);
        vm.expectRevert(PredictionMarket.NotWorthless.selector);
        market.burnWorthless(true, _obj(json, "invalid_burn", "attempted"));
        assertEq(market.yesSupply(), _obj(json, "invalid_burn", "yes_supply"));
        assertEq(market.noSupply(), _obj(json, "invalid_burn", "no_supply"));
        assertEq(market.collateralLocked(), _obj(json, "invalid_burn", "collateral_locked"));
    }

    function _rejectFeeOnTransfer(string memory json) private {
        _fresh();
        collateral.setFeeOnTransfer(true);
        vm.prank(alice);
        vm.expectRevert(PredictionMarket.Shortfall.selector);
        market.split(_obj(json, "fee_on_transfer", "split_amount"));
        assertEq(market.collateralLocked(), _obj(json, "fee_on_transfer", "collateral_locked"));
        assertEq(market.yesSupply(), _obj(json, "fee_on_transfer", "yes_supply"));
        assertEq(market.noSupply(), _obj(json, "fee_on_transfer", "no_supply"));
        assertEq(uint256(market.state()), _obj(json, "fee_on_transfer", "state"));
    }

    function _fresh() private {
        collateral = new MockCollateral(6);
        market = new PredictionMarket(
            address(collateral), resolver, dustSink, bytes32("fixture-hash"), "Yes", "YES", "No", "NO"
        );
        market.activate();
        collateral.mint(alice, 1_000_000);
        vm.prank(alice);
        collateral.approve(address(market), type(uint256).max);
    }

    function _split(string memory json) private {
        vm.prank(alice);
        market.split(_at(json, "", "split_amount"));
    }

    function _resolve(PredictionMarket.Result result) private {
        vm.startPrank(resolver);
        market.closeMint();
        market.beginResolution();
        market.resolve(result);
        vm.stopPrank();
    }

    function _assertFlat(string memory json) private view {
        _assertPrefix(json, "");
    }

    function _assertPrefix(string memory json, string memory prefix) private view {
        assertEq(uint256(market.state()), _at(json, prefix, "state"));
        assertEq(uint256(market.result()), _at(json, prefix, "result"));
        assertEq(market.collateralLocked(), _at(json, prefix, "collateral_locked"));
        assertEq(market.yesSupply(), _at(json, prefix, "yes_supply"));
        assertEq(market.noSupply(), _at(json, prefix, "no_supply"));
        assertEq(market.yesRedeemed(), _at(json, prefix, "yes_redeemed"));
        assertEq(market.noRedeemed(), _at(json, prefix, "no_redeemed"));
        assertEq(market.liability(), _at(json, prefix, "liability"));
        assertEq(market.yesNumerator(), _at(json, prefix, "yes_numerator"));
        assertEq(market.noNumerator(), _at(json, prefix, "no_numerator"));
    }

    function _load(string memory name) private view returns (string memory) {
        return vm.readFile(string.concat("../prediction-model/fixtures/", name));
    }

    function _at(string memory json, string memory prefix, string memory key) private pure returns (uint256) {
        if (bytes(prefix).length == 0) return vm.parseJsonUint(json, string.concat(".", key));
        return vm.parseJsonUint(json, string.concat(".", prefix, ".", key));
    }

    function _obj(string memory json, string memory name, string memory key) private pure returns (uint256) {
        return vm.parseJsonUint(json, string.concat(".", name, ".", key));
    }

    function _step(string memory json, uint256 index, string memory key) private pure returns (uint256) {
        return vm.parseJsonUint(json, string.concat(".steps[", vm.toString(index), "].", key));
    }
}
