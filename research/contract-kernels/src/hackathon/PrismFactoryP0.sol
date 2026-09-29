// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {PredictionFactoryP0} from "./PredictionFactoryP0.sol";
import {PrismSeriesP0} from "./PrismSeriesP0.sol";

/// @notice Hackathon trust boundary binding every official series to one Prediction P0 factory.
contract PrismFactoryP0 {
    PredictionFactoryP0 public immutable predictionFactory;
    mapping(address series => bool admitted) public isSeries;

    error ZeroAddress();

    event SeriesCreated(address indexed series, bytes32 indexed seriesId, bytes32 payoffHash, bytes32 replicationHash);

    constructor(address predictionFactory_) {
        if (predictionFactory_ == address(0)) revert ZeroAddress();
        predictionFactory = PredictionFactoryP0(predictionFactory_);
    }

    function createSeries(
        address[] memory tokens,
        uint128[] memory numerators,
        uint128[] memory denominators,
        string memory name,
        string memory symbol,
        bytes32 payoffHash,
        bytes32 replicationHash
    ) external returns (PrismSeriesP0 series) {
        series = new PrismSeriesP0(
            address(predictionFactory), tokens, numerators, denominators, name, symbol, payoffHash, replicationHash
        );
        isSeries[address(series)] = true;
        bytes32 seriesId = keccak256(
            abi.encode(address(predictionFactory), tokens, numerators, denominators, payoffHash, replicationHash)
        );
        emit SeriesCreated(address(series), seriesId, payoffHash, replicationHash);
    }
}
