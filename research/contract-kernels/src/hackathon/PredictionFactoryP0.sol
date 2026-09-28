// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {PredictionMarketP0} from "./PredictionMarketP0.sol";

/// @notice Hackathon P0 factory with one fixed collateral asset.
/// @dev This is a research kernel, not a production deployment factory.
contract PredictionFactoryP0 {
    address public immutable allowedCollateral;
    bytes32 public constant SEMANTIC_VERSION = keccak256("RETROPICK_PREDICTION_P0_FACTORY_V1");

    error ZeroAddress();
    error CollateralResolverOverlap();

    event MarketCreated(address indexed market, address indexed resolver, bytes32 resolutionSpecHash);

    constructor(address allowedCollateral_) {
        if (allowedCollateral_ == address(0)) revert ZeroAddress();
        allowedCollateral = allowedCollateral_;
    }

    function createMarket(
        address resolver,
        bytes32 resolutionSpecHash,
        string memory yesName,
        string memory yesSymbol,
        string memory noName,
        string memory noSymbol
    ) external returns (PredictionMarketP0 market) {
        if (resolver == address(0)) revert ZeroAddress();
        if (resolver == allowedCollateral) revert CollateralResolverOverlap();
        market = new PredictionMarketP0(
            allowedCollateral, address(this), resolver, resolutionSpecHash, yesName, yesSymbol, noName, noSymbol
        );
        emit MarketCreated(address(market), resolver, resolutionSpecHash);
    }

    function activate(PredictionMarketP0 market) external {
        market.activate();
    }
}
