// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {RetroPickLaunchFactoryV2} from "../RetroPickLaunchFactoryV2.sol";
import {GraduationVenue} from "./IGraduationExecutorV2.sol";

/// @notice Unambiguous typed selector for the venue-selecting launch overload.
interface IVenueLaunchV2 {
    function launchToken(
        RetroPickLaunchFactoryV2.TokenParams calldata params,
        uint256 configId,
        address quote,
        GraduationVenue venue
    ) external payable returns (address token, address curve);
}
