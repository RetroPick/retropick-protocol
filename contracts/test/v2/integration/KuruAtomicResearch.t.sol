// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {RetroPickLauncherTokenV2} from "../../../src/v2/RetroPickLauncherTokenV2.sol";
import {
    IKuruRouterResearch,
    IKuruOrderBookResearch,
    IKuruVaultResearch,
    KuruResearchNoExitLock
} from "./KuruForkResearch.t.sol";

/// @notice RESEARCH-ONLY atomic phase-2 sketch; not a production executor.
/// @dev failAt deliberately injects reverts and must never exist in production.
contract KuruAtomicResearchCoordinator {
    address public constant ROUTER = 0x7EFbE105Ca7415dE98F96622173458ac1c054630;
    address public constant MARGIN = 0xd029C2D98ff85D8F64799017fE00a59B1159CE02;
    address public constant ORDERBOOK_IMPL = 0x72caE0a99C19B574e8a6De558F43fc1D019c9374;
    address public constant VAULT_IMPL = 0x4d54e0d60CaB0cec0100cdA8e00897bC933C5Bb6;
    bytes32 public constant ORDERBOOK_HASH = 0x24c5974f233021f00d607bfa191d430f79565663fb90805ebcfca52de7333500;
    bytes32 public constant VAULT_HASH = 0xde0b16a79cf8f711403e89093c1e82ce0e7813949dd0f5041b41da324fdd3dc3;

    uint96 internal constant SIZE_PRECISION = 1e8;
    uint32 internal constant PRICE_PRECISION = 1e8;
    uint32 internal constant TICK_SIZE = 1;
    uint96 internal constant MIN_SIZE = 1e6;
    uint96 internal constant MAX_SIZE = 1e16;
    uint96 internal constant SPREAD = 100;

    enum Phase {
        ACTIVE,
        GRADUATING,
        GRADUATED
    }

    IERC20 public immutable token;
    address public immutable quoteAsset;
    uint256 public immutable quoteDecimals;
    address public immutable lock;
    uint256 public immutable terminalTokens;
    uint256 public immutable baseSeed;
    uint256 public immutable quoteSeed;
    uint256 public immutable phantomQuote;
    Phase public phase;
    address public destination;
    address public vaultAddress;
    bool private entered;

    constructor(
        IERC20 token_,
        address quoteAsset_,
        address lock_,
        uint256 terminalTokens_,
        uint256 baseSeed_,
        uint256 quoteSeed_,
        uint256 phantomQuote_
    ) {
        require(address(token_) != address(0) && lock_ != address(0));
        require(terminalTokens_ > baseSeed_ && baseSeed_ > 0 && quoteSeed_ > 0 && phantomQuote_ > 0);
        token = token_;
        quoteAsset = quoteAsset_;
        quoteDecimals = quoteAsset_ == address(0) ? 18 : IERC20Metadata(quoteAsset_).decimals();
        lock = lock_;
        terminalTokens = terminalTokens_;
        baseSeed = baseSeed_;
        quoteSeed = quoteSeed_;
        phantomQuote = phantomQuote_;
    }

    /// @notice Durable phase 1 in a separate transaction from completion.
    function secure() external payable {
        require(phase == Phase.ACTIVE);
        if (quoteAsset == address(0)) {
            require(msg.value == quoteSeed);
        } else {
            require(msg.value == 0);
            uint256 beforeBalance = IERC20(quoteAsset).balanceOf(address(this));
            require(IERC20(quoteAsset).transferFrom(msg.sender, address(this), quoteSeed));
            require(IERC20(quoteAsset).balanceOf(address(this)) - beforeBalance == quoteSeed);
        }
        require(token.transferFrom(msg.sender, address(this), terminalTokens));
        require(token.balanceOf(address(this)) == terminalTokens);
        phase = Phase.GRADUATING;
    }

    /// @notice One atomic phase-2 transaction with optional research-only fault.
    function complete(uint8 failAt) external returns (address market, address vault) {
        require(phase == Phase.GRADUATING && !entered);
        entered = true;
        IKuruRouterResearch router = IKuruRouterResearch(ROUTER);
        require(block.chainid == 10143 && ROUTER.code.length > 0);
        require(router.marginAccountAddress() == MARGIN);
        require(router.orderBookImplementation() == ORDERBOOK_IMPL && ORDERBOOK_IMPL.codehash == ORDERBOOK_HASH);
        require(router.kuruAmmVaultImplementation() == VAULT_IMPL && VAULT_IMPL.codehash == VAULT_HASH);
        if (failAt == 1) revert("fault-after-environment");

        address expectedMarket = router.computeAddress(
            address(token),
            quoteAsset,
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
        vault = router.computeVaultAddress(expectedMarket, address(0), false);
        require(expectedMarket.code.length == 0 && vault.code.length == 0);
        market = router.deployProxy(
            quoteAsset == address(0) ? 2 : 0,
            address(token),
            quoteAsset,
            SIZE_PRECISION,
            PRICE_PRECISION,
            TICK_SIZE,
            MIN_SIZE,
            MAX_SIZE,
            30,
            0,
            SPREAD
        );
        if (failAt == 2) revert("fault-after-deploy");
        require(market == expectedMarket && market.code.length > 0 && vault.code.length > 0);
        (bool marketOk, bytes memory marketData) = market.staticcall(abi.encodeWithSignature("getMarketParams()"));
        (bool routerOk, bytes memory routerData) =
            ROUTER.staticcall(abi.encodeWithSignature("verifiedMarket(address)", market));
        require(marketOk && routerOk && keccak256(marketData) == keccak256(routerData));
        require(
            keccak256(marketData)
                == keccak256(
                    abi.encode(
                        PRICE_PRECISION,
                        SIZE_PRECISION,
                        address(token),
                        uint256(18),
                        quoteAsset,
                        quoteDecimals,
                        TICK_SIZE,
                        MIN_SIZE,
                        MAX_SIZE,
                        uint256(30),
                        uint256(0)
                    )
                )
        );
        IKuruVaultResearch v = IKuruVaultResearch(vault);
        require(v.token1() == address(token) && v.token2() == quoteAsset);
        require(v.market() == market && v.marginAccount() == MARGIN);
        require(v.owner() == ROUTER && v.SPREAD_CONSTANT() == SPREAD);
        (address reportedVault,,,,,, uint96 askSizeBefore, uint96 spread) =
            IKuruOrderBookResearch(market).getVaultParams();
        require(reportedVault == vault && spread == SPREAD && askSizeBefore == 0);

        require(token.approve(vault, baseSeed));
        uint256 marginQuoteBefore;
        if (quoteAsset != address(0)) {
            marginQuoteBefore = IERC20(quoteAsset).balanceOf(MARGIN);
            require(IERC20(quoteAsset).approve(vault, quoteSeed));
        }
        if (failAt == 3) revert("fault-after-approval");
        uint256 shares =
            v.deposit{value: quoteAsset == address(0) ? quoteSeed : 0}(baseSeed, quoteSeed, quoteSeed, lock);
        if (failAt == 4) revert("fault-after-deposit");
        require(shares == Math.sqrt(baseSeed * quoteSeed) - 1_000);
        require(v.balanceOf(lock) == shares);
        (uint256 actualBase, uint256 actualQuote) = v.totalAssets();
        require(actualBase == baseSeed && actualQuote == quoteSeed);
        (address vaultFromBook, uint256 bid,, uint256 ask,, uint96 bidSize, uint96 askSize,) =
            IKuruOrderBookResearch(market).getVaultParams();
        require(vaultFromBook == vault && bid > 0 && ask > bid && bidSize > 0 && askSize > 0);
        uint256 referencePrice = Math.mulDiv(phantomQuote + quoteSeed, 1e36, terminalTokens * 10 ** quoteDecimals);
        uint256 priceError = ask > referencePrice ? ask - referencePrice : referencePrice - ask;
        require(priceError * 10_000 <= referencePrice * 5); // research-only candidate cap, not accepted policy
        require(token.transfer(lock, terminalTokens - baseSeed));
        if (failAt == 5) revert("fault-after-excess-lock");
        require(token.balanceOf(lock) == terminalTokens - baseSeed);
        require(token.balanceOf(address(this)) == 0);
        if (quoteAsset == address(0)) {
            require(address(this).balance == 0);
        } else {
            require(IERC20(quoteAsset).balanceOf(address(this)) == 0);
            require(IERC20(quoteAsset).allowance(address(this), vault) == 0);
            require(IERC20(quoteAsset).balanceOf(MARGIN) - marginQuoteBefore == quoteSeed);
        }
        require(token.allowance(address(this), vault) == 0);
        destination = market;
        vaultAddress = vault;
        phase = Phase.GRADUATED;
        entered = false;
    }
}

/// @notice Failure/retry and gas campaign on actual Kuru contracts, never broadcast.
contract KuruAtomicResearchTest is Test {
    address internal constant ROUTER = 0x7EFbE105Ca7415dE98F96622173458ac1c054630;
    address internal constant CIRCLE_USDC = 0x534b2f3A21130d7a60830c2Df862319e593943A3;
    uint256 internal constant SNAPSHOT_BLOCK = 66752717;

    function setUp() public {
        string memory rpc = vm.envOr("MONAD_TESTNET_RPC_URL", string(""));
        if (bytes(rpc).length == 0) {
            vm.skip(true, "research fork requires MONAD_TESTNET_RPC_URL");
            return;
        }
        vm.createSelectFork(rpc, SNAPSHOT_BLOCK);
    }

    function testInjectedFailuresRollbackThenSameLaunchRetriesAndCannotReplay() public {
        (
            RetroPickLauncherTokenV2 token,
            KuruResearchNoExitLock lock,
            KuruAtomicResearchCoordinator coordinator,
            address expectedMarket,
            address expectedVault
        ) = _securedLaunch();
        for (uint8 stage = 1; stage <= 5; ++stage) {
            vm.expectRevert();
            coordinator.complete(stage);
            _assertSecuredUnchanged(token, lock, coordinator, expectedMarket, expectedVault);
        }
        uint256 gasBefore = gasleft();
        (address market, address vault) = coordinator.complete(0);
        emit log_named_uint("research_atomic_phase2_gas", gasBefore - gasleft());
        assertEq(market, expectedMarket);
        assertEq(vault, expectedVault);
        assertEq(uint8(coordinator.phase()), uint8(KuruAtomicResearchCoordinator.Phase.GRADUATED));
        assertEq(coordinator.destination(), expectedMarket);
        assertEq(coordinator.vaultAddress(), expectedVault);
        assertEq(token.balanceOf(address(lock)), 250_000 ether);
        uint256 sharesBefore = IKuruVaultResearch(vault).balanceOf(address(lock));
        vm.expectRevert();
        coordinator.complete(0);
        assertEq(IKuruVaultResearch(vault).balanceOf(address(lock)), sharesBefore);
        assertEq(coordinator.destination(), expectedMarket);
    }

    /// @notice Candidate full phase-2 gas comparison, not production Core wiring.
    /// Each row deploys the real Kuru market/vault on the same pinned fork.
    function testCandidateAtomicGasMatrixNativeAndCircle() public {
        emit log_named_uint("fork_block_gas_limit", block.gaslimit);
        _measureCandidateProfile("small", address(0), 100_000 ether, 10 ether, 11 ether);
        _measureCandidateProfile("medium", address(0), 1_000_000 ether, 100 ether, 97 ether);
        _measureCandidateProfile("large", address(0), 100_000_000 ether, 1_000 ether, 1_001 ether);
        _measureCandidateProfile("small", CIRCLE_USDC, 100_000 ether, 10e6, 11e6);
        _measureCandidateProfile("medium", CIRCLE_USDC, 1_000_000 ether, 100e6, 97e6);
        _measureCandidateProfile("large", CIRCLE_USDC, 100_000_000 ether, 1_000e6, 1_001e6);
    }

    function _measureCandidateProfile(
        string memory profile,
        address quote,
        uint256 supply,
        uint256 phantom,
        uint256 quoteAmount
    ) internal {
        uint256 terminal = Math.mulDiv(supply, phantom, phantom + quoteAmount);
        uint256 base = Math.mulDiv(terminal, quoteAmount, phantom + quoteAmount);
        RetroPickLauncherTokenV2.Socials memory socials;
        RetroPickLauncherTokenV2 token = new RetroPickLauncherTokenV2(
            "RetroPick Gas Research",
            "RPGR",
            "",
            "research only",
            socials,
            address(this),
            address(this),
            address(this),
            supply
        );
        token.transfer(address(0xBEEF), supply - terminal);
        KuruResearchNoExitLock lock = new KuruResearchNoExitLock();
        KuruAtomicResearchCoordinator coordinator = new KuruAtomicResearchCoordinator(
            IERC20(address(token)), quote, address(lock), terminal, base, quoteAmount, phantom
        );
        token.approve(address(coordinator), terminal);
        if (quote == address(0)) {
            vm.deal(address(this), quoteAmount);
            coordinator.secure{value: quoteAmount}();
        } else {
            deal(quote, address(this), quoteAmount);
            IERC20(quote).approve(address(coordinator), quoteAmount);
            coordinator.secure();
        }
        string memory label = string.concat(quote == address(0) ? "mon_" : "circle_", profile);
        uint256 gasBefore = gasleft();
        vm.expectRevert();
        coordinator.complete(2); // real Router deploy occurs, then full transaction rolls back
        emit log_named_uint(string.concat(label, "_failed_gas"), gasBefore - gasleft());
        assertEq(uint8(coordinator.phase()), uint8(KuruAtomicResearchCoordinator.Phase.GRADUATING));
        assertEq(coordinator.destination(), address(0));
        assertEq(token.balanceOf(address(coordinator)), terminal);
        if (quote == address(0)) assertEq(address(coordinator).balance, quoteAmount);
        else assertEq(IERC20(quote).balanceOf(address(coordinator)), quoteAmount);

        gasBefore = gasleft();
        (address market, address vault) = coordinator.complete(0);
        emit log_named_uint(string.concat(label, "_successful_retry_gas"), gasBefore - gasleft());
        assertEq(uint8(coordinator.phase()), uint8(KuruAtomicResearchCoordinator.Phase.GRADUATED));
        assertEq(coordinator.destination(), market);
        assertEq(coordinator.vaultAddress(), vault);
        assertGt(IKuruVaultResearch(vault).balanceOf(address(lock)), 0);
        assertEq(token.balanceOf(address(lock)), terminal - base);

        uint256 shares = IKuruVaultResearch(vault).balanceOf(address(lock));
        gasBefore = gasleft();
        vm.expectRevert();
        coordinator.complete(0);
        emit log_named_uint(string.concat(label, "_replay_rejection_gas"), gasBefore - gasleft());
        assertEq(IKuruVaultResearch(vault).balanceOf(address(lock)), shares);
    }

    function testImplementationCodeDriftStopsBeforeMarketCreation() public {
        (
            RetroPickLauncherTokenV2 token,
            KuruResearchNoExitLock lock,
            KuruAtomicResearchCoordinator coordinator,
            address expectedMarket,
            address expectedVault
        ) = _securedLaunch();
        vm.etch(coordinator.ORDERBOOK_IMPL(), hex"00");
        vm.expectRevert();
        coordinator.complete(0);
        _assertSecuredUnchanged(token, lock, coordinator, expectedMarket, expectedVault);
    }

    function testWrongMarginGetterStopsBeforeMarketCreation() public {
        (
            RetroPickLauncherTokenV2 token,
            KuruResearchNoExitLock lock,
            KuruAtomicResearchCoordinator coordinator,
            address expectedMarket,
            address expectedVault
        ) = _securedLaunch();
        vm.mockCall(ROUTER, abi.encodeWithSignature("marginAccountAddress()"), abi.encode(address(0xBAD)));
        vm.expectRevert();
        coordinator.complete(0);
        _assertSecuredUnchanged(token, lock, coordinator, expectedMarket, expectedVault);
    }

    function testRouterDeploymentRevertPreservesSecuredLaunch() public {
        (
            RetroPickLauncherTokenV2 token,
            KuruResearchNoExitLock lock,
            KuruAtomicResearchCoordinator coordinator,
            address expectedMarket,
            address expectedVault
        ) = _securedLaunch();
        vm.mockCallRevert(
            ROUTER,
            abi.encodeWithSelector(IKuruRouterResearch.deployProxy.selector),
            abi.encodeWithSignature("Error(string)", "injected router failure")
        );
        vm.expectRevert();
        coordinator.complete(0);
        _assertSecuredUnchanged(token, lock, coordinator, expectedMarket, expectedVault);
        vm.clearMockedCalls();
        (address market,) = coordinator.complete(0);
        assertEq(market, expectedMarket);
    }

    function testWrongRouterRegistryDataRollsBackDeploymentAndCanRetry() public {
        (
            RetroPickLauncherTokenV2 token,
            KuruResearchNoExitLock lock,
            KuruAtomicResearchCoordinator coordinator,
            address expectedMarket,
            address expectedVault
        ) = _securedLaunch();
        vm.mockCall(
            ROUTER,
            abi.encodeWithSelector(IKuruRouterResearch.verifiedMarket.selector, expectedMarket),
            abi.encode(
                uint32(0),
                uint96(0),
                address(0),
                uint256(0),
                address(0),
                uint256(0),
                uint32(0),
                uint96(0),
                uint96(0),
                uint256(0),
                uint256(0)
            )
        );
        vm.expectRevert();
        coordinator.complete(0);
        _assertSecuredUnchanged(token, lock, coordinator, expectedMarket, expectedVault);
        vm.clearMockedCalls();
        (address market,) = coordinator.complete(0);
        assertEq(market, expectedMarket);
    }

    function testVaultImplementationCodeDriftStopsBeforeMarketCreation() public {
        (
            RetroPickLauncherTokenV2 token,
            KuruResearchNoExitLock lock,
            KuruAtomicResearchCoordinator coordinator,
            address expectedMarket,
            address expectedVault
        ) = _securedLaunch();
        vm.etch(coordinator.VAULT_IMPL(), hex"00");
        vm.expectRevert();
        coordinator.complete(0);
        _assertSecuredUnchanged(token, lock, coordinator, expectedMarket, expectedVault);
    }

    function _securedLaunch()
        internal
        returns (
            RetroPickLauncherTokenV2 token,
            KuruResearchNoExitLock lock,
            KuruAtomicResearchCoordinator coordinator,
            address expectedMarket,
            address expectedVault
        )
    {
        RetroPickLauncherTokenV2.Socials memory socials;
        token = new RetroPickLauncherTokenV2(
            "RetroPick Atomic Research",
            "RPAR",
            "",
            "research only",
            socials,
            address(this),
            address(this),
            address(this),
            1_000_000 ether
        );
        token.transfer(address(0xBEEF), 500_000 ether);
        lock = new KuruResearchNoExitLock();
        coordinator = new KuruAtomicResearchCoordinator(
            IERC20(address(token)), address(0), address(lock), 500_000 ether, 250_000 ether, 100 ether, 100 ether
        );
        token.approve(address(coordinator), 500_000 ether);
        vm.deal(address(this), 100 ether);
        coordinator.secure{value: 100 ether}();
        assertEq(uint8(coordinator.phase()), uint8(KuruAtomicResearchCoordinator.Phase.GRADUATING));
        IKuruRouterResearch router = IKuruRouterResearch(ROUTER);
        expectedMarket =
            router.computeAddress(address(token), address(0), 1e8, 1e8, 1, 1e6, 1e16, 30, 0, 100, address(0), false);
        expectedVault = router.computeVaultAddress(expectedMarket, address(0), false);
    }

    function _assertSecuredUnchanged(
        RetroPickLauncherTokenV2 token,
        KuruResearchNoExitLock lock,
        KuruAtomicResearchCoordinator coordinator,
        address market,
        address vault
    ) internal view {
        assertEq(uint8(coordinator.phase()), uint8(KuruAtomicResearchCoordinator.Phase.GRADUATING));
        assertEq(coordinator.destination(), address(0));
        assertEq(coordinator.vaultAddress(), address(0));
        assertEq(token.balanceOf(address(coordinator)), 500_000 ether);
        assertEq(address(coordinator).balance, 100 ether);
        assertEq(token.balanceOf(address(lock)), 0);
        assertEq(token.allowance(address(coordinator), vault), 0);
        assertEq(market.code.length, 0);
        assertEq(vault.code.length, 0);
    }
}
