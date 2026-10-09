// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {Script} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IKuruOrderBookV2, IKuruVaultV2} from "../src/v2/interfaces/IKuruV2.sol";

interface IKuruTradingSmoke {
    function addSellOrder(uint32, uint96, bool) external;
    function addBuyOrder(uint32, uint96, bool) external;
    function batchCancelOrders(uint40[] calldata) external;
    function s_orderIdCounter() external view returns (uint40);
}

interface IKuruMarginSmoke {
    function deposit(address, address, uint256) external payable;
    function getBalance(address, address) external view returns (uint256);
}

/// @notice Small two-actor order/fill/cancel smoke; not a market-quality claim.
contract TradeV2KuruTestnet is Script {
    struct Context {
        address a;
        address b;
        address token;
        address market;
        address vault;
        address lpLock;
        uint32 price;
        uint32 cancelPrice;
        uint40 filledOrder;
        uint40 cancelledOrder;
        uint256 protectedLP;
        uint256 protectedExcess;
        uint256 aBaseBefore;
        uint256 aQuoteBefore;
        uint256 bBaseBefore;
        uint256 bQuoteBefore;
    }

    function run() external {
        require(block.chainid == 10143, "Monad testnet only");
        Context memory c;
        c.a = vm.envAddress("MONAD_TESTNET_ACTOR_A");
        c.b = vm.envAddress("MONAD_TESTNET_ACTOR_B");
        c.token = vm.envAddress("V2_TRADE_TOKEN");
        c.market = vm.envAddress("V2_TRADE_MARKET");
        c.vault = vm.envAddress("V2_TRADE_VAULT");
        c.lpLock = vm.envAddress("V2_TRADE_LOCK");
        IKuruMarginSmoke margin = IKuruMarginSmoke(0xd029C2D98ff85D8F64799017fE00a59B1159CE02);
        IKuruTradingSmoke book = IKuruTradingSmoke(c.market);
        require(c.a != c.b && c.a.balance > 0.1 ether && c.b.balance > 0.1 ether, "funded distinct actors required");
        require(
            IKuruVaultV2(c.vault).market() == c.market && IKuruVaultV2(c.vault).token1() == c.token, "market identity"
        );
        c.protectedLP = IKuruVaultV2(c.vault).balanceOf(c.lpLock);
        c.protectedExcess = IERC20(c.token).balanceOf(c.lpLock);
        {
            (uint256 bid, uint256 ask) = IKuruOrderBookV2(c.market).bestBidAsk();
            c.price = uint32((bid + ask) / 2 / 1e10); // TESTNET_POLICY_V1 pricePrecision 1e8
            require(uint256(c.price) * 1e10 > bid && uint256(c.price) * 1e10 < ask, "no interior price tick");
            c.cancelPrice = uint32(ask / 1e10 * 105 / 100 + 1);
        }
        c.aBaseBefore = margin.getBalance(c.a, c.token);
        c.aQuoteBefore = margin.getBalance(c.a, address(0));
        c.bBaseBefore = margin.getBalance(c.b, c.token);
        c.bQuoteBefore = margin.getBalance(c.b, address(0));
        vm.startBroadcast(c.a);
        IERC20(c.token).approve(address(margin), 1 ether);
        margin.deposit(c.a, c.token, 1 ether);
        book.addSellOrder(c.price, 1e7, true); // 0.1 launch token at sizePrecision 1e8
        vm.stopBroadcast();
        c.filledOrder = book.s_orderIdCounter();
        vm.startBroadcast(c.b);
        margin.deposit{value: 0.01 ether}(c.b, address(0), 0.01 ether);
        book.addBuyOrder(c.price, 1e7, false);
        vm.stopBroadcast();
        _checkFill(c, margin);
        vm.startBroadcast(c.a);
        book.addSellOrder(c.cancelPrice, 1e7, true);
        vm.stopBroadcast();
        c.cancelledOrder = book.s_orderIdCounter();
        uint40[] memory ids = new uint40[](1);
        ids[0] = c.cancelledOrder;
        vm.startBroadcast(c.a);
        book.batchCancelOrders(ids);
        vm.stopBroadcast();
        require(margin.getBalance(c.a, c.token) == c.aBaseBefore + 0.9 ether, "cancellation refund mismatch");
        require(IERC20(c.token).allowance(c.a, address(margin)) == 0, "trader allowance remains");
        require(IKuruVaultV2(c.vault).balanceOf(c.lpLock) == c.protectedLP, "protected LP changed");
        require(IERC20(c.token).balanceOf(c.lpLock) == c.protectedExcess, "protected excess changed");
        _write(c, margin);
    }

    function _checkFill(Context memory c, IKuruMarginSmoke margin) private view {
        require(margin.getBalance(c.a, address(0)) > c.aQuoteBefore, "maker not credited");
        require(margin.getBalance(c.b, c.token) == c.bBaseBefore + 0.0997 ether, "taker fill/fee mismatch");
        require(margin.getBalance(c.a, c.token) == c.aBaseBefore + 0.9 ether, "maker base mismatch");
        require(margin.getBalance(c.b, address(0)) < c.bQuoteBefore + 0.01 ether, "taker quote not debited");
    }

    function _write(Context memory c, IKuruMarginSmoke margin) private {
        (uint256 finalBid, uint256 finalAsk) = IKuruOrderBookV2(c.market).bestBidAsk();
        require(finalBid > 0 && finalAsk > finalBid, "invalid final spread");
        string memory key = "trade";
        vm.serializeAddress(key, "market", c.market);
        vm.serializeAddress(key, "actorA", c.a);
        vm.serializeAddress(key, "actorB", c.b);
        vm.serializeUint(key, "filledOrderId", c.filledOrder);
        vm.serializeUint(key, "cancelledOrderId", c.cancelledOrder);
        vm.serializeUint(key, "fillPrice", c.price);
        vm.serializeUint(key, "size", 1e7);
        vm.serializeUint(key, "finalBestBid", finalBid);
        vm.serializeUint(key, "finalBestAsk", finalAsk);
        vm.serializeUint(key, "actorABase", margin.getBalance(c.a, c.token));
        vm.serializeUint(key, "actorAQuote", margin.getBalance(c.a, address(0)));
        vm.serializeUint(key, "actorBBase", margin.getBalance(c.b, c.token));
        vm.serializeUint(key, "actorBQuote", margin.getBalance(c.b, address(0)));
        string memory json = vm.serializeString(key, "result", "PASS");
        vm.writeJson(json, "./v2-trade-result.json");
    }
}
