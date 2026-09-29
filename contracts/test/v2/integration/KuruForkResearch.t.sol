// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {RetroPickLauncherTokenV2} from "../../../src/v2/RetroPickLauncherTokenV2.sol";

/// @notice Only the Kuru ABI needed by this research fixture. Not production interfaces.
interface IKuruRouterResearch {
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

interface IKuruOrderBookResearch {
    function getMarketParams()
        external
        view
        returns (uint32, uint96, address, uint256, address, uint256, uint32, uint96, uint96, uint256, uint256);
    function getVaultParams() external view returns (address, uint256, uint96, uint256, uint96, uint96, uint96, uint96);
    function bestBidAsk() external view returns (uint256, uint256);
}

interface IKuruVaultResearch {
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

/// @notice Candidate permanent custody, with deliberately no external authority methods.
/// @dev A later B7 packet must still audit token and vault hooks and settle ADR-022.
contract KuruResearchNoExitLock {}

/// @notice Pinned Monad fork experiment; skipped in normal CI without RPC env.
/// No production Kuru executor or Factory integration is implied by this test.
contract KuruForkResearchTest is Test {
    struct MarketSnapshot {
        uint32 pricePrecision;
        uint96 sizePrecision;
        address base;
        uint256 baseDecimals;
        address quote;
        uint256 quoteDecimals;
        uint32 tickSize;
        uint96 minSize;
        uint96 maxSize;
        uint256 takerFeeBps;
        uint256 makerFeeBps;
    }

    address internal constant ROUTER = 0x7EFbE105Ca7415dE98F96622173458ac1c054630;
    address internal constant MARGIN = 0xd029C2D98ff85D8F64799017fE00a59B1159CE02;
    address internal constant ORDERBOOK_IMPL = 0x72caE0a99C19B574e8a6De558F43fc1D019c9374;
    address internal constant VAULT_IMPL = 0x4d54e0d60CaB0cec0100cdA8e00897bC933C5Bb6;
    address internal constant CIRCLE_USDC = 0x534b2f3A21130d7a60830c2Df862319e593943A3;
    address internal constant KURU_LISTED_USDC = 0x3bA3d39AFcf8bb994f7964B3e0171Ea2Ba361570;
    bytes32 internal constant ORDERBOOK_HASH = 0x24c5974f233021f00d607bfa191d430f79565663fb90805ebcfca52de7333500;
    bytes32 internal constant VAULT_HASH = 0xde0b16a79cf8f711403e89093c1e82ce0e7813949dd0f5041b41da324fdd3dc3;
    uint256 internal constant SNAPSHOT_BLOCK = 66752717;
    uint96 internal constant SIZE_PRECISION = 1e8;
    uint32 internal constant PRICE_PRECISION = 1e8;
    uint32 internal constant TICK_SIZE = 1;
    uint96 internal constant MIN_SIZE = 1e6;
    uint96 internal constant MAX_SIZE = 1e16;
    uint96 internal constant SPREAD = 100;

    function setUp() public {
        string memory rpc = vm.envOr("MONAD_TESTNET_RPC_URL", string(""));
        if (bytes(rpc).length == 0) {
            vm.skip(true, "research fork requires MONAD_TESTNET_RPC_URL");
            return;
        }
        vm.createSelectFork(rpc, SNAPSHOT_BLOCK);
    }

    function testPinnedNativeMarketAndFirstVaultSeed() public {
        assertEq(block.chainid, 10143);
        IKuruRouterResearch router = IKuruRouterResearch(ROUTER);
        assertGt(ROUTER.code.length, 0);
        assertEq(router.marginAccountAddress(), MARGIN);
        assertEq(router.orderBookImplementation(), ORDERBOOK_IMPL);
        assertEq(router.kuruAmmVaultImplementation(), VAULT_IMPL);
        assertEq(ORDERBOOK_IMPL.codehash, ORDERBOOK_HASH);
        assertEq(VAULT_IMPL.codehash, VAULT_HASH);

        RetroPickLauncherTokenV2.Socials memory socials;
        RetroPickLauncherTokenV2 token = new RetroPickLauncherTokenV2(
            "RetroPick Fork Research",
            "RPFR",
            "",
            "research only",
            socials,
            address(this),
            address(this),
            address(this),
            1_000_000 ether
        );
        // Current Curve's 100/100 config has terminal T=500k, not original L=1m.
        token.transfer(address(0xBEEF), 500_000 ether);
        assertEq(token.balanceOf(address(this)), 500_000 ether);
        uint256 baseSeed = 250_000 ether;
        uint256 quoteSeed = 100 ether;
        KuruResearchNoExitLock lock = new KuruResearchNoExitLock();

        address expectedMarket = router.computeAddress(
            address(token),
            address(0),
            SIZE_PRECISION,
            PRICE_PRECISION,
            TICK_SIZE,
            MIN_SIZE,
            MAX_SIZE,
            30,
            0,
            SPREAD,
            address(0),
            false
        );
        address expectedVault = router.computeVaultAddress(expectedMarket, address(0), false);
        assertEq(expectedMarket.code.length, 0);
        assertEq(expectedVault.code.length, 0);
        uint256 gasBefore = gasleft();
        address market = router.deployProxy(
            2, address(token), address(0), SIZE_PRECISION, PRICE_PRECISION, TICK_SIZE, MIN_SIZE, MAX_SIZE, 30, 0, SPREAD
        );
        emit log_named_uint("research_deploy_proxy_gas", gasBefore - gasleft());
        assertEq(market, expectedMarket);
        assertGt(market.code.length, 0);
        assertGt(expectedVault.code.length, 0);

        _assertMarketAndRouterRecord(market, address(token), address(0), 18);

        IKuruVaultResearch vault = IKuruVaultResearch(expectedVault);
        assertEq(vault.token1(), address(token));
        assertEq(vault.token2(), address(0));
        assertEq(vault.market(), market);
        assertEq(vault.marginAccount(), MARGIN);
        assertEq(vault.SPREAD_CONSTANT(), SPREAD);
        assertEq(vault.owner(), ROUTER);
        token.transfer(address(lock), 250_000 ether);
        token.approve(expectedVault, baseSeed);
        vm.deal(address(this), quoteSeed);
        gasBefore = gasleft();
        uint256 shares = vault.deposit{value: quoteSeed}(baseSeed, quoteSeed, quoteSeed, address(lock));
        emit log_named_uint("research_first_deposit_gas", gasBefore - gasleft());
        assertEq(shares, Math.sqrt(baseSeed * quoteSeed) - 1_000);
        assertEq(vault.balanceOf(address(lock)), shares);
        assertEq(token.balanceOf(address(lock)), 250_000 ether);
        assertEq(token.balanceOf(address(this)), 0);
        assertEq(address(this).balance, 0);
        (uint256 vaultBase, uint256 vaultQuote) = vault.totalAssets();
        assertEq(vaultBase, baseSeed);
        assertEq(vaultQuote, quoteSeed);
        (
            address reportedVault,
            uint256 vaultBid,
            uint96 partialBid,
            uint256 vaultAsk,
            uint96 partialAsk,
            uint96 bidSize,
            uint96 askSize,
            uint96 spread
        ) = IKuruOrderBookResearch(market).getVaultParams();
        assertEq(reportedVault, expectedVault);
        assertEq(partialBid, 0);
        assertEq(partialAsk, 0);
        assertEq(spread, SPREAD);
        assertEq(vaultAsk, 400_000_000_000_000);
        assertEq(vaultBid, (vaultAsk * 10_000 + 10_100 / 2) / 10_100);
        assertGt(askSize, 0);
        assertGt(bidSize, 0);
        (uint256 bestBid, uint256 bestAsk) = IKuruOrderBookResearch(market).bestBidAsk();
        assertEq(bestAsk, vaultAsk);
        assertEq(bestBid, vaultBid);

        address attacker = address(0xCAFE);
        vm.startPrank(attacker);
        vm.expectRevert();
        IKuruVaultResearch(expectedVault).withdraw(shares, attacker, address(lock));
        vm.expectRevert();
        token.transferFrom(address(lock), attacker, 250_000 ether);
        vm.stopPrank();
        assertEq(IERC20(expectedVault).allowance(address(lock), attacker), 0);
        (bool transferEscape,) = address(lock).call(abi.encodeWithSelector(IERC20.transfer.selector, attacker, shares));
        (bool approvalEscape,) = address(lock).call(abi.encodeWithSelector(IERC20.approve.selector, attacker, shares));
        (bool arbitraryEscape,) =
            address(lock).call(abi.encodeWithSignature("execute(address,bytes)", expectedVault, bytes("")));
        assertFalse(transferEscape);
        assertFalse(approvalEscape);
        assertFalse(arbitraryEscape);
        assertEq(vault.balanceOf(address(lock)), shares);
        assertEq(token.balanceOf(address(lock)), 250_000 ether);
    }

    function testCircleListedUsdcMarketAndFirstVaultSeed() public {
        _testUsdcMarketAndSeed(CIRCLE_USDC);
    }

    function testKuruListedUsdcMarketAndFirstVaultSeed() public {
        _testUsdcMarketAndSeed(KURU_LISTED_USDC);
    }

    function _testUsdcMarketAndSeed(address quote) internal {
        assertEq(block.chainid, 10143);
        IKuruRouterResearch router = IKuruRouterResearch(ROUTER);
        RetroPickLauncherTokenV2.Socials memory socials;
        RetroPickLauncherTokenV2 token = new RetroPickLauncherTokenV2(
            "RetroPick Fork Research",
            "RPFR",
            "",
            "research only",
            socials,
            address(this),
            address(this),
            address(this),
            1_000_000 ether
        );
        uint256 phantom = 100e6;
        uint256 quoteSeed = 97e6;
        uint256 terminalTokens = Math.mulDiv(1_000_000 ether, phantom, phantom + quoteSeed);
        uint256 baseSeed = Math.mulDiv(terminalTokens, quoteSeed, phantom + quoteSeed);
        token.transfer(address(0xBEEF), 1_000_000 ether - terminalTokens);
        KuruResearchNoExitLock lock = new KuruResearchNoExitLock();
        address expectedMarket = router.computeAddress(
            address(token),
            quote,
            SIZE_PRECISION,
            PRICE_PRECISION,
            TICK_SIZE,
            MIN_SIZE,
            MAX_SIZE,
            30,
            0,
            SPREAD,
            address(0),
            false
        );
        address expectedVault = router.computeVaultAddress(expectedMarket, address(0), false);
        uint256 gasBefore = gasleft();
        address market = router.deployProxy(
            0, address(token), quote, SIZE_PRECISION, PRICE_PRECISION, TICK_SIZE, MIN_SIZE, MAX_SIZE, 30, 0, SPREAD
        );
        emit log_named_uint("research_usdc_deploy_proxy_gas", gasBefore - gasleft());
        assertEq(market, expectedMarket);
        assertGt(market.code.length, 0);
        assertGt(expectedVault.code.length, 0);
        _assertMarketAndRouterRecord(market, address(token), quote, 6);
        IKuruVaultResearch vault = IKuruVaultResearch(expectedVault);
        assertEq(vault.token1(), address(token));
        assertEq(vault.token2(), quote);
        assertEq(vault.market(), market);
        assertEq(vault.marginAccount(), MARGIN);
        assertEq(vault.owner(), ROUTER);

        // Fork-only funding tests token transfer semantics, not Circle mint authority.
        deal(quote, address(this), quoteSeed);
        assertEq(IERC20(quote).balanceOf(address(this)), quoteSeed);
        token.transfer(address(lock), terminalTokens - baseSeed);
        token.approve(expectedVault, baseSeed);
        IERC20(quote).approve(expectedVault, quoteSeed);
        gasBefore = gasleft();
        uint256 shares = vault.deposit(baseSeed, quoteSeed, quoteSeed, address(lock));
        emit log_named_uint("research_usdc_first_deposit_gas", gasBefore - gasleft());
        assertEq(IERC20(quote).balanceOf(address(this)), 0);
        assertEq(token.balanceOf(address(this)), 0);
        assertEq(token.balanceOf(address(lock)), terminalTokens - baseSeed);
        assertEq(vault.balanceOf(address(lock)), shares);
        assertEq(shares, Math.sqrt(baseSeed * quoteSeed) - 1_000);
        (uint256 actualBase, uint256 actualQuote) = vault.totalAssets();
        assertEq(actualBase, baseSeed);
        assertEq(actualQuote, quoteSeed);
        (address reportedVault, uint256 vaultBid,, uint256 vaultAsk,, uint96 bidSize, uint96 askSize, uint96 spread) =
            IKuruOrderBookResearch(market).getVaultParams();
        assertEq(reportedVault, expectedVault);
        assertEq(spread, SPREAD);
        assertGt(vaultAsk, vaultBid);
        assertGt(bidSize, 0);
        assertGt(askSize, 0);
    }

    function _assertMarketAndRouterRecord(address market, address base, address quote, uint256 quoteDecimals)
        internal
        view
    {
        (bool marketOk, bytes memory marketData) = market.staticcall(abi.encodeWithSignature("getMarketParams()"));
        (bool routerOk, bytes memory routerData) =
            ROUTER.staticcall(abi.encodeWithSignature("verifiedMarket(address)", market));
        assertTrue(marketOk);
        assertTrue(routerOk);
        assertEq(keccak256(routerData), keccak256(marketData));
        MarketSnapshot memory p = abi.decode(marketData, (MarketSnapshot));
        assertEq(p.pricePrecision, PRICE_PRECISION);
        assertEq(p.sizePrecision, SIZE_PRECISION);
        assertEq(p.base, base);
        assertEq(p.baseDecimals, 18);
        assertEq(p.quote, quote);
        assertEq(p.quoteDecimals, quoteDecimals);
        assertEq(p.tickSize, TICK_SIZE);
        assertEq(p.minSize, MIN_SIZE);
        assertEq(p.maxSize, MAX_SIZE);
        assertEq(p.takerFeeBps, 30);
        assertEq(p.makerFeeBps, 0);
    }
}
