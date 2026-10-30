// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @notice Narrow callback a bonding curve uses to ask its factory to graduate
 * a token the instant a buy crosses the ETH threshold. Kept separate from
 * IRetroPickLaunchpadV2.sol so the curve's compile unit stays free of the factory's
 * full launch-record surface.
 */
interface IRetroPickLaunchFactoryGraduationV2 {
    function graduate(address token) external;
}
