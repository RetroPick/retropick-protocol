// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// Narrow observable Kuru interfaces; no private storage-slot access.
interface IKuruRouterV2 {
    function marginAccountAddress() external view returns (address);
    function orderBookImplementation() external view returns (address);
    function kuruAmmVaultImplementation() external view returns (address);
    function computeAddress(
        address,
        address,
        uint96,
        uint32,
        uint32,
        uint96,
        uint96,
        uint256,
        uint256,
        uint96,
        address,
        bool
    ) external view returns (address);
    function computeVaultAddress(address, address, bool) external view returns (address);
    function deployProxy(uint8, address, address, uint96, uint32, uint32, uint96, uint96, uint256, uint256, uint96)
        external
        returns (address);
    function verifiedMarket(address)
        external
        view
        returns (uint32, uint96, address, uint256, address, uint256, uint32, uint96, uint96, uint256, uint256);
}

interface IKuruOrderBookV2 {
    function getMarketParams()
        external
        view
        returns (uint32, uint96, address, uint256, address, uint256, uint32, uint96, uint96, uint256, uint256);
    function getVaultParams() external view returns (address, uint256, uint96, uint256, uint96, uint96, uint96, uint96);
    function bestBidAsk() external view returns (uint256, uint256);
}

interface IKuruVaultV2 {
    function deposit(uint256, uint256, uint256, address) external payable returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function totalAssets() external view returns (uint256, uint256);
    function token1() external view returns (address);
    function token2() external view returns (address);
    function market() external view returns (address);
    function marginAccount() external view returns (address);
    function SPREAD_CONSTANT() external view returns (uint96);
    function owner() external view returns (address);
    function withdraw(uint256, address, address) external returns (uint256, uint256);
}

interface IKuruMarketStateV2 {
    enum MarketState {
        ACTIVE,
        SOFT_PAUSED,
        HARD_PAUSED
    }

    function marketState() external view returns (MarketState);
}

