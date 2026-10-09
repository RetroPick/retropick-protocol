// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {Script} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {RetroPickLaunchFactoryV2} from "../src/v2/RetroPickLaunchFactoryV2.sol";
import {RetroPickBondingCurveV2} from "../src/v2/RetroPickBondingCurveV2.sol";
import {GraduationCoordinatorV2} from "../src/v2/GraduationCoordinatorV2.sol";
import {
    GraduationVenue,
    GraduationState,
    GraduationPacket,
    GraduationLedger,
    GraduationReceipt
} from "../src/v2/interfaces/IGraduationExecutorV2.sol";

/// @notice Real testnet economic writes when invoked with --broadcast. Defaults to MON; Circle needs explicit funding.
contract SmokeV2MonadTestnet is Script {
    function run() external returns (address token, address curveAddress, address market, address vault) {
        require(block.chainid == 10143, "Monad testnet only");
        address actor = vm.envAddress("MONAD_TESTNET_ACTOR_A");
        address quote = vm.envOr("V2_SMOKE_QUOTE", address(0));
        RetroPickLaunchFactoryV2 factory = RetroPickLaunchFactoryV2(payable(vm.envAddress("V2_FACTORY")));
        GraduationCoordinatorV2 coordinator = factory.graduationCoordinator();
        require(quote == address(0) || quote == factory.quoteRegistry().CIRCLE_TEST_USDC(), "unqualified smoke asset");
        uint256 unit = quote == address(0) ? 1 ether : 1e6;
        require(actor.balance >= (quote == address(0) ? 2 ether : 0.1 ether), "MON funding required");
        if (quote != address(0)) require(IERC20(quote).balanceOf(actor) >= 2e6, "CIRCLE_LIVE_SMOKE: BLOCKED_FUNDING");
        RetroPickLaunchFactoryV2.TokenParams memory params;
        params.name = quote == address(0) ? "RetroPick V2 MON testnet" : "RetroPick V2 Circle testnet";
        params.symbol = quote == address(0) ? "RPV2M" : "RPV2C";
        params.description = "Monad TESTNET_POLICY_V1 hackathon smoke";
        params.creatorFeeRecipient = actor;
        params.expectedEconomics = factory.previewVenueEconomics(0, quote, GraduationVenue.KURU);
        params.salt = keccak256(abi.encode(actor, block.number, quote));
        vm.startBroadcast(actor);
        (token, curveAddress) = factory.launchToken(params, 0, quote, GraduationVenue.KURU);
        RetroPickBondingCurveV2 curve = RetroPickBondingCurveV2(curveAddress);
        uint256 initialBuy = unit / 10;
        if (quote == address(0)) {
            curve.buy{value: initialBuy}(initialBuy, 0, actor);
        } else {
            IERC20(quote).approve(curveAddress, initialBuy);
            curve.buy(initialBuy, 0, actor);
        }
        (uint256 terminalQuote, uint256 finalInput) = curve.completionQuote();
        if (quote == address(0)) {
            curve.buy{value: finalInput}(finalInput, curve.sellableTokens(), actor);
        } else {
            IERC20(quote).approve(curveAddress, finalInput);
            curve.buy(finalInput, curve.sellableTokens(), actor);
        }
        if (coordinator.ledger(token).phase == GraduationState.NONE) factory.graduate(token);
        require(coordinator.ledger(token).securedQuote == terminalQuote, "completion arithmetic mismatch");
        GraduationReceipt memory receipt = coordinator.complete(token);
        vm.stopBroadcast();
        GraduationPacket memory packet = coordinator.packet(token);
        GraduationLedger memory ledger = coordinator.ledger(token);
        require(
            ledger.phase == GraduationState.GRADUATED && ledger.receiptHash == keccak256(abi.encode(receipt)),
            "smoke incomplete"
        );
        require(
            ledger.consumedQuote == ledger.securedQuote && ledger.consumedLaunchTokens == ledger.securedLaunchTokens,
            "smoke ledger not conserved"
        );
        market = receipt.market;
        vault = receipt.vault;
        string memory key = "smoke";
        vm.serializeAddress(key, "factory", address(factory));
        vm.serializeAddress(key, "actor", actor);
        vm.serializeAddress(key, "quoteAsset", quote);
        vm.serializeAddress(key, "token", token);
        vm.serializeAddress(key, "curve", curveAddress);
        vm.serializeAddress(key, "market", market);
        vm.serializeAddress(key, "vault", vault);
        vm.serializeUint(key, "securedQuote", ledger.securedQuote);
        vm.serializeUint(key, "securedLaunchTokens", ledger.securedLaunchTokens);
        vm.serializeUint(key, "protectedLPAmount", ledger.protectedLPAmount);
        vm.serializeUint(key, "protectedExcessAmount", ledger.protectedExcessAmount);
        vm.serializeAddress(key, "lpLock", packet.protectedLPReceiver);
        string memory json = vm.serializeString(key, "phase", "GRADUATED");
        // Intermediate simulation/broadcast output; confirmed receipts are merged by release tooling.
        vm.writeJson(json, "./v2-smoke-result.json");
    }
}
