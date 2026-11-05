// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {Script} from "forge-std/Script.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IPositionManager} from "@uniswap/v4-periphery/src/interfaces/IPositionManager.sol";
import {IAllowanceTransfer} from "permit2/src/interfaces/IAllowanceTransfer.sol";
import {RetroPickQuoteAssetRegistryV2} from "../src/v2/RetroPickQuoteAssetRegistryV2.sol";
import {RetroPickFeeEscrowV2} from "../src/v2/RetroPickFeeEscrowV2.sol";
import {RetroPickBuybackVaultV2} from "../src/v2/RetroPickBuybackVaultV2.sol";
import {RetroPickLaunchLockerV2} from "../src/v2/RetroPickLaunchLockerV2.sol";
import {RetroPickLaunchFactoryV2} from "../src/v2/RetroPickLaunchFactoryV2.sol";
import {RetroPickLaunchDeployerV2} from "../src/v2/RetroPickLaunchDeployerV2.sol";
import {RetroPickHookDeployerV2} from "../src/v2/RetroPickHookDeployerV2.sol";
import {RetroPickMemeHookV2} from "../src/v2/hooks/RetroPickMemeHookV2.sol";
import {GraduationCoordinatorV2} from "../src/v2/GraduationCoordinatorV2.sol";
import {KuruEnvironmentV2} from "../src/v2/KuruEnvironmentV2.sol";
import {KuruGraduationExecutorV2} from "../src/v2/KuruGraduationExecutorV2.sol";
import {UniswapV4GraduationExecutorV2} from "../src/v2/UniswapV4GraduationExecutorV2.sol";
import {GraduationVenue, QuoteAssetConfig} from "../src/v2/interfaces/IGraduationExecutorV2.sol";
import {IRetroPickFeeEscrowV2} from "../src/v2/interfaces/IRetroPickLaunchpadV2.sol";

/// @notice Monad TESTNET_POLICY_V1 only. Build pinned upstream artifacts first; no key is read by this script.
contract DeployV2MonadTestnet is Script {
    struct Deployment {
        address registry;
        address feeEscrow;
        address wrappedNative;
        address permit2;
        address poolManager;
        address positionDescriptor;
        address positionManager;
        address hookDeployer;
        address hook;
        address buybackVault;
        address locker;
        address kuruEnvironment;
        address kuruExecutor;
        address v4Executor;
        address coordinator;
        address launchDeployer;
        address factory;
    }
    Deployment public deployment;
    error WrongChain();
    error DeploymentFailed();
    error HookSaltNotFound();

    function run() external returns (Deployment memory d) {
        if (block.chainid != 10143) revert WrongChain();
        address owner = vm.envAddress("MONAD_TESTNET_ACTOR_A");
        vm.startBroadcast(owner);
        RetroPickQuoteAssetRegistryV2 registry = new RetroPickQuoteAssetRegistryV2(owner);
        d.registry = address(registry);
        RetroPickFeeEscrowV2 escrow = new RetroPickFeeEscrowV2();
        d.feeEscrow = address(escrow);
        d.wrappedNative = _artifact("deployment-v4/out/WETH.sol/WETH.json", bytes(""));
        d.permit2 = _artifact("lib/v4-deployment-periphery/lib/permit2/out/Permit2.sol/Permit2.json", bytes(""));
        d.poolManager = _artifact("deployment-v4/out/PoolManager.sol/PoolManager.json", abi.encode(owner));
        d.positionDescriptor = _artifact(
            "deployment-v4/out/PositionDescriptor.sol/PositionDescriptor.json",
            abi.encode(d.poolManager, d.wrappedNative, bytes32("MON"))
        );
        d.positionManager = _artifact(
            "deployment-v4/out/PositionManager.sol/PositionManager.json",
            abi.encode(d.poolManager, d.permit2, uint256(100000), d.positionDescriptor, d.wrappedNative)
        );
        RetroPickHookDeployerV2 hookDeployer = new RetroPickHookDeployerV2(owner);
        d.hookDeployer = address(hookDeployer);
        bytes32 initHash = keccak256(
            abi.encodePacked(type(RetroPickMemeHookV2).creationCode, abi.encode(d.poolManager, escrow, owner, owner))
        );
        bytes32 salt = _mineHookSalt(address(hookDeployer), initHash);
        RetroPickMemeHookV2 hook = hookDeployer.deploy(salt, IPoolManager(d.poolManager), escrow, owner);
        d.hook = address(hook);
        RetroPickBuybackVaultV2 vault = new RetroPickBuybackVaultV2(owner, hook, escrow);
        d.buybackVault = address(vault);
        RetroPickLaunchLockerV2 locker = new RetroPickLaunchLockerV2(owner, d.positionManager);
        d.locker = address(locker);
        KuruEnvironmentV2 environment = new KuruEnvironmentV2();
        environment.validate();
        d.kuruEnvironment = address(environment);
        GraduationCoordinatorV2 coordinator = new GraduationCoordinatorV2(owner);
        d.coordinator = address(coordinator);
        KuruGraduationExecutorV2 kuru = new KuruGraduationExecutorV2(address(coordinator), environment);
        d.kuruExecutor = address(kuru);
        UniswapV4GraduationExecutorV2 v4 = new UniswapV4GraduationExecutorV2(
            address(coordinator),
            IPoolManager(d.poolManager),
            IPositionManager(d.positionManager),
            IAllowanceTransfer(d.permit2),
            locker,
            hook,
            escrow
        );
        d.v4Executor = address(v4);
        _quote(registry, address(0), 18, "MON.TESTNET_POLICY_V1");
        _quote(registry, registry.CIRCLE_TEST_USDC(), 6, "CIRCLE_USDC.10143.TESTNET_POLICY_V1");
        RetroPickLaunchFactoryV2 factory = new RetroPickLaunchFactoryV2(
            owner,
            IPoolManager(d.poolManager),
            IPositionManager(d.positionManager),
            IAllowanceTransfer(d.permit2),
            locker,
            hook,
            escrow,
            vault,
            registry,
            coordinator,
            0
        );
        d.factory = address(factory);
        RetroPickLaunchDeployerV2 launchDeployer = new RetroPickLaunchDeployerV2(address(factory));
        d.launchDeployer = address(launchDeployer);
        coordinator.bindFactory(address(factory));
        factory.setLaunchDeployer(launchDeployer);
        factory.configureVenueExecutor(GraduationVenue.UNISWAP_V4, address(v4));
        factory.configureVenueExecutor(GraduationVenue.KURU, address(kuru));
        hook.setFactory(address(factory));
        hook.setBuybackVault(vault);
        hook.setGraduationExecutor(address(v4));
        vault.setFactory(address(factory));
        locker.setFactory(address(factory));
        locker.setGraduationExecutor(address(v4));
        factory.addLaunchConfig(RetroPickLaunchFactoryV2.LaunchConfig(1000 ether, 100, 1 ether, 1 ether, 0, 60, true));
        factory.setSnipeTaxStartBps(0);
        factory.setLaunchEnabled(true);
        vm.stopBroadcast();
        deployment = d;
        _writeAddresses(d, owner);
    }

    function _quote(RetroPickQuoteAssetRegistryV2 registry, address asset, uint8 decimals, string memory id) private {
        uint256 unit = 10 ** decimals;
        registry.configure(
            asset, QuoteAssetConfig(true, decimals, 3, 1, unit, unit, 50 * unit, keccak256(bytes(id)), bytes32(0))
        );
    }

    function _artifact(string memory path, bytes memory args) private returns (address deployed) {
        bytes memory code = abi.encodePacked(vm.getCode(path), args);
        assembly ("memory-safe") { deployed := create(0, add(code, 32), mload(code)) }
        if (deployed == address(0) || deployed.code.length == 0 || deployed.code.length > 24576) {
            revert DeploymentFailed();
        }
    }

    function _mineHookSalt(address deployer, bytes32 initHash) private pure returns (bytes32) {
        for (uint256 i; i < 1_000_000; ++i) {
            address candidate =
                address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), deployer, bytes32(i), initHash)))));
            if (uint160(candidate) & 0x3fff == 0x2044) return bytes32(i);
        }
        revert HookSaltNotFound();
    }

    function _writeAddresses(Deployment memory d, address owner) private {
        string memory key = "v2";
        vm.serializeUint(key, "chainId", block.chainid);
        vm.serializeAddress(key, "owner", owner);
        vm.serializeAddress(key, "quoteRegistry", d.registry);
        vm.serializeAddress(key, "feeEscrow", d.feeEscrow);
        vm.serializeAddress(key, "wrappedNative", d.wrappedNative);
        vm.serializeAddress(key, "permit2", d.permit2);
        vm.serializeAddress(key, "poolManager", d.poolManager);
        vm.serializeAddress(key, "positionDescriptor", d.positionDescriptor);
        vm.serializeAddress(key, "positionManager", d.positionManager);
        vm.serializeAddress(key, "hookDeployer", d.hookDeployer);
        vm.serializeAddress(key, "hook", d.hook);
        vm.serializeAddress(key, "buybackVault", d.buybackVault);
        vm.serializeAddress(key, "locker", d.locker);
        vm.serializeAddress(key, "kuruEnvironment", d.kuruEnvironment);
        vm.serializeAddress(key, "kuruExecutor", d.kuruExecutor);
        vm.serializeAddress(key, "v4Executor", d.v4Executor);
        vm.serializeAddress(key, "coordinator", d.coordinator);
        vm.serializeAddress(key, "launchDeployer", d.launchDeployer);
        string memory json = vm.serializeAddress(key, "factory", d.factory);
        // Intermediate only: release tooling merges confirmed blocks/tx hashes and git SHA into the manifest.
        vm.writeJson(json, "./v2-deployment-addresses.json");
    }
}
