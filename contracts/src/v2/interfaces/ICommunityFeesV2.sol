// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface ICommunityFeeSourceV2 {
    function token() external view returns (address);
    function pairToken() external view returns (address);
    function factory() external view returns (address);
    function communityRouter() external view returns (address);
    function communityPending() external view returns (uint256);
    function checkpointCommunityFees() external;
}

interface ICommunityFeeFundingV2 {
    function source() external view returns (ICommunityFeeSourceV2);
    function factory() external view returns (address);
    function ready() external view returns (bool);
    function activeEpoch() external view returns (uint256);
    function fund(address token, address asset, uint256 epoch, uint256 sequence, uint256 amount) external payable;
}

interface ICommunityBuilderV2 {
    function factory() external view returns (address);
    function configure(address token, address curve, address creator, bytes calldata config, bytes32 commitment)
        external
        returns (address router);
}
