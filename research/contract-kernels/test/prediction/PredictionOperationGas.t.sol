// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {PredictionMarket} from "../../src/prediction/PredictionMarket.sol";

/// @notice Deploys one market. This harness is not a protocol factory.
contract MarketDeployer {
    function deploy(address collateral, address resolver, address dustSink, bytes32 spec)
        external
        returns (address market, uint256 gasUsed)
    {
        bytes memory code = abi.encodePacked(
            type(PredictionMarket).creationCode,
            abi.encode(collateral, resolver, dustSink, spec, "Yes", "YES", "No", "NO")
        );
        uint256 gasBefore;
        uint256 gasAfter;
        assembly {
            gasBefore := gas()
            market := create(0, add(code, 0x20), mload(code))
            gasAfter := gas()
        }
        require(market != address(0), "market create failed");
        gasUsed = gasBefore - gasAfter;
    }

    function activate(PredictionMarket market) external {
        market.activate();
    }
}

/// @notice External caller so assembly gas() wraps each CALL. Includes CALL overhead.
contract PredictionOperationMeter {
    function measureYes(PredictionMarket market, MockCollateral token)
        external
        returns (uint256 splitGas, uint256 mergeGas, uint256 resolveYesGas, uint256 redeemWinnerGas)
    {
        token.mint(address(this), 100);
        token.approve(address(market), 100);
        splitGas = _call(address(market), abi.encodeCall(PredictionMarket.split, (100)));
        mergeGas = _call(address(market), abi.encodeCall(PredictionMarket.merge, (40)));
        _call(address(market), abi.encodeCall(PredictionMarket.closeMint, ()));
        _call(address(market), abi.encodeCall(PredictionMarket.beginResolution, ()));
        resolveYesGas =
            _call(address(market), abi.encodeCall(PredictionMarket.resolve, (PredictionMarket.Result.YES_WIN)));
        _call(address(market), abi.encodeCall(PredictionMarket.openRedemption, ()));
        redeemWinnerGas = _call(address(market), abi.encodeCall(PredictionMarket.redeemYes, (60)));
    }

    function measureInvalidRedeem(PredictionMarket market, MockCollateral token)
        external
        returns (uint256 redeemInvalidGas)
    {
        token.mint(address(this), 5);
        token.approve(address(market), 5);
        _call(address(market), abi.encodeCall(PredictionMarket.split, (5)));
        _call(address(market), abi.encodeCall(PredictionMarket.closeMint, ()));
        _call(address(market), abi.encodeCall(PredictionMarket.beginResolution, ()));
        _call(address(market), abi.encodeCall(PredictionMarket.resolve, (PredictionMarket.Result.INVALID)));
        _call(address(market), abi.encodeCall(PredictionMarket.openRedemption, ()));
        redeemInvalidGas = _call(address(market), abi.encodeCall(PredictionMarket.redeemYes, (5)));
    }

    function _call(address target, bytes memory data) private returns (uint256 gasUsed) {
        uint256 gasBefore;
        uint256 gasAfter;
        bool ok;
        assembly {
            gasBefore := gas()
            ok := call(gas(), target, 0, add(data, 0x20), mload(data), 0, 0)
            gasAfter := gas()
        }
        require(ok, "prediction call failed");
        gasUsed = gasBefore - gasAfter;
    }
}

/// @notice One local Foundry measurement of prediction CALLs. Not a percentile.
/// @dev YES path: split 100, merge 40, resolve YES, redeemYes 60 (pays 60).
///      INVALID path: split 5, resolve INVALID, redeemYes 5 (pays 2).
///      closeMint, beginResolution, and openRedemption run but are not the reported rows.
contract PredictionOperationGasTest is Test {
    function test_prediction_operation_gas() public {
        MockCollateral token = new MockCollateral(18);
        MarketDeployer deployer = new MarketDeployer();
        PredictionOperationMeter meter = new PredictionOperationMeter();
        _measureYes(token, deployer, meter);
        _measureInvalid(token, deployer, meter);
    }

    function _measureYes(MockCollateral token, MarketDeployer deployer, PredictionOperationMeter meter) private {
        (address marketAddr, uint256 deployGas) =
            deployer.deploy(address(token), address(meter), address(0xD057), bytes32("yes-path"));
        PredictionMarket market = PredictionMarket(marketAddr);
        deployer.activate(market);
        (uint256 splitGas, uint256 mergeGas, uint256 resolveYesGas, uint256 redeemWinnerGas) =
            meter.measureYes(market, token);

        emit log_named_uint("market_deploy_yes_path_gas", deployGas);
        emit log_named_uint("split_100_gas", splitGas);
        emit log_named_uint("merge_40_gas", mergeGas);
        emit log_named_uint("resolve_yes_gas", resolveYesGas);
        emit log_named_uint("redeem_yes_winner_60_gas", redeemWinnerGas);

        assertEq(market.collateralLocked(), 0);
        assertEq(market.yesSupply(), 0);
        assertEq(market.noSupply(), 60);
        assertEq(token.balanceOf(address(meter)), 100);
        assertEq(uint8(market.result()), uint8(PredictionMarket.Result.YES_WIN));
    }

    function _measureInvalid(MockCollateral token, MarketDeployer deployer, PredictionOperationMeter meter) private {
        (address marketAddr, uint256 deployGas) =
            deployer.deploy(address(token), address(meter), address(0xD057), bytes32("invalid-path"));
        PredictionMarket market = PredictionMarket(marketAddr);
        deployer.activate(market);
        uint256 redeemInvalidGas = meter.measureInvalidRedeem(market, token);

        emit log_named_uint("market_deploy_invalid_path_gas", deployGas);
        emit log_named_uint("redeem_invalid_yes_5_gas", redeemInvalidGas);

        assertEq(market.yesSupply(), 0);
        assertEq(market.noSupply(), 5);
        assertEq(market.collateralLocked(), 3);
        assertEq(token.balanceOf(address(meter)), 102);
        assertEq(uint8(market.result()), uint8(PredictionMarket.Result.INVALID));
    }
}
