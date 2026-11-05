// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IPositionManager} from "@uniswap/v4-periphery/src/interfaces/IPositionManager.sol";
import {IAllowanceTransfer} from "permit2/src/interfaces/IAllowanceTransfer.sol";
import {RetroPickLaunchFactoryV2 as Factory} from "../../../../src/v2/RetroPickLaunchFactoryV2.sol";
import {RetroPickLaunchDeployerV2} from "../../../../src/v2/RetroPickLaunchDeployerV2.sol";
import {RetroPickQuoteAssetRegistryV2} from "../../../../src/v2/RetroPickQuoteAssetRegistryV2.sol";
import {GraduationCoordinatorV2} from "../../../../src/v2/GraduationCoordinatorV2.sol";
import {UniswapV4GraduationExecutorV2} from "../../../../src/v2/UniswapV4GraduationExecutorV2.sol";
import {RetroPickHookDeployerV2} from "../../../../src/v2/RetroPickHookDeployerV2.sol";
import {RetroPickMemeHookV2} from "../../../../src/v2/hooks/RetroPickMemeHookV2.sol";
import {RetroPickFeeEscrowV2} from "../../../../src/v2/RetroPickFeeEscrowV2.sol";
import {RetroPickBuybackVaultV2} from "../../../../src/v2/RetroPickBuybackVaultV2.sol";
import {RetroPickLaunchLockerV2} from "../../../../src/v2/RetroPickLaunchLockerV2.sol";
import {IRetroPickFeeEscrowV2} from "../../../../src/v2/interfaces/IRetroPickLaunchpadV2.sol";
import {GraduationVenue, QuoteAssetConfig} from "../../../../src/v2/interfaces/IGraduationExecutorV2.sol";
import {MockERC20} from "../../../mocks/MockERC20.sol";
import {GenuineSwapHarnessV2} from "./GenuineSwapHarnessV2.sol";

/// @notice Genuine pinned v4 bytecode deployed locally on chain10143, with no Kuru dependency.
/// @dev No broadcast, venue mocks, or venue code etching. The quote is a local six-decimal model.
abstract contract GenuineV4EnvironmentFixtureV2 is Test {
    address internal constant CIRCLE = 0x534b2f3A21130d7a60830c2Df862319e593943A3;
    address internal actor = makeAddr("genuine-v4-actor");
    address internal protocol = makeAddr("genuine-v4-protocol");
    address internal proposer = makeAddr("genuine-v4-proposer");
    address internal contributor = makeAddr("genuine-v4-contributor");
    address internal finalRecipient = makeAddr("genuine-v4-spend-recipient");
    address internal wrappedNative;
    address internal descriptor;
    IPoolManager internal manager;
    IPositionManager internal position;
    IAllowanceTransfer internal permit2;
    Factory internal factory;
    GraduationCoordinatorV2 internal coordinator;
    UniswapV4GraduationExecutorV2 internal executor;
    RetroPickQuoteAssetRegistryV2 internal quoteRegistry;
    RetroPickMemeHookV2 internal hook;
    RetroPickFeeEscrowV2 internal escrow;
    RetroPickBuybackVaultV2 internal buyback;
    RetroPickLaunchLockerV2 internal locker;
    GenuineSwapHarnessV2 internal swapper;

    function setUp() public virtual {
        vm.chainId(10143);
        _deployGenuineInfrastructure();
        _installModeledQuote();
        _deployCore();
        swapper = new GenuineSwapHarnessV2(manager);
        vm.deal(actor, 100 ether);
        deal(CIRCLE, actor, 1000e6, true);
    }

    function _deployGenuineInfrastructure() internal {
        string memory root = vm.envOr("M6_V4_ARTIFACT_ROOT", string("/tmp/m6-genuine-v4-artifacts"));
        string memory permitRoot = vm.envOr("M6_PERMIT2_ARTIFACT_ROOT", string("/tmp/m6-genuine-permit2-artifacts"));
        wrappedNative = _artifact(string.concat(root, "/WETH.sol/WETH.json"), "");
        permit2 = IAllowanceTransfer(_artifact(string.concat(permitRoot, "/Permit2.sol/Permit2.json"), ""));
        manager = IPoolManager(
            _artifact(string.concat(root, "/PoolManager.sol/PoolManager.json"), abi.encode(address(this)))
        );
        descriptor = _artifact(
            string.concat(root, "/PositionDescriptor.sol/PositionDescriptor.json"),
            abi.encode(manager, wrappedNative, bytes32("MON"))
        );
        position = IPositionManager(
            _artifact(
                string.concat(root, "/PositionManager.sol/PositionManager.json"),
                abi.encode(manager, permit2, uint256(100_000), descriptor, wrappedNative)
            )
        );
        assertEq(address(position.poolManager()), address(manager));
    }

    function _artifact(string memory path, bytes memory args) internal returns (address deployed) {
        bytes memory creation = abi.encodePacked(vm.getCode(path), args);
        assertLe(creation.length, 49_152, "upstream initcode exceeds conservative limit");
        assembly ("memory-safe") { deployed := create(0, add(creation, 32), mload(creation)) }
        assertTrue(deployed != address(0), "genuine artifact creation failed");
        assertGt(deployed.code.length, 0);
        assertLe(deployed.code.length, 24_576, "upstream runtime exceeds conservative limit");
    }

    function _installModeledQuote() internal virtual {
        MockERC20 model = new MockERC20("Genuine venue quote model", "Q6", 6);
        vm.etch(CIRCLE, address(model).code); // Only quote-fixture code, never venue code.
    }

    function _minePermissionSalt(address deployer, bytes32 initHash) internal pure returns (bytes32) {
        for (uint256 i; i < 1_000_000; ++i) {
            bytes32 salt = bytes32(i);
            address predicted =
                address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, initHash)))));
            if ((uint160(predicted) & 0x3fff) == 0x2044) return salt;
        }
        revert("no hook salt in bounded search");
    }

    function _createHook() internal virtual returns (RetroPickMemeHookV2 result) {
        RetroPickHookDeployerV2 deployer = new RetroPickHookDeployerV2(address(this));
        bytes32 initHash = keccak256(
            abi.encodePacked(
                type(RetroPickMemeHookV2).creationCode, abi.encode(manager, escrow, protocol, address(this))
            )
        );
        bytes32 salt = _minePermissionSalt(address(deployer), initHash);
        result = deployer.deploy(salt, manager, IRetroPickFeeEscrowV2(address(escrow)), protocol);
        assertEq(uint160(address(result)) & 0x3fff, 0x2044);
    }

    function _deployCore() internal virtual {
        escrow = new RetroPickFeeEscrowV2();
        hook = _createHook();
        buyback = new RetroPickBuybackVaultV2(address(this), hook, IRetroPickFeeEscrowV2(address(escrow)));
        locker = new RetroPickLaunchLockerV2(address(this), address(position));
        quoteRegistry = new RetroPickQuoteAssetRegistryV2(address(this));
        _admit(address(0), 18);
        _admit(CIRCLE, 6);
        coordinator = new GraduationCoordinatorV2(address(this));
        factory = Factory(
            payable(vm.deployCode(
                    "src/v2/RetroPickLaunchFactoryV2.sol:RetroPickLaunchFactoryV2",
                    abi.encode(
                        address(this),
                        manager,
                        position,
                        permit2,
                        locker,
                        hook,
                        escrow,
                        buyback,
                        quoteRegistry,
                        coordinator,
                        0
                    )
                ))
        );
        RetroPickLaunchDeployerV2 launchDeployer = RetroPickLaunchDeployerV2(
            vm.deployCode(
                "src/v2/RetroPickLaunchDeployerV2.sol:RetroPickLaunchDeployerV2", abi.encode(address(factory))
            )
        );
        executor = UniswapV4GraduationExecutorV2(payable(_createExecutor()));
        coordinator.bindFactory(address(factory));
        factory.setLaunchDeployer(launchDeployer);
        factory.configureVenueExecutor(GraduationVenue.UNISWAP_V4, address(executor));
        hook.setFactory(address(factory));
        hook.setBuybackVault(buyback);
        hook.setGraduationExecutor(address(executor));
        buyback.setFactory(address(factory));
        locker.setFactory(address(factory));
        locker.setGraduationExecutor(address(executor));
        factory.addLaunchConfig(Factory.LaunchConfig(1000 ether, 100, 1 ether, 1 ether, 0, 60, true));
        factory.setSnipeTaxStartBps(0);
        factory.setLaunchEnabled(true);
    }

    function _createExecutor() internal virtual returns (address) {
        return vm.deployCode(
            "src/v2/UniswapV4GraduationExecutorV2.sol:UniswapV4GraduationExecutorV2",
            abi.encode(address(coordinator), manager, position, permit2, locker, hook, escrow)
        );
    }

    function _admit(address asset, uint8 decimals) internal {
        uint256 unit = 10 ** decimals;
        quoteRegistry.configure(
            asset,
            QuoteAssetConfig(
                true,
                decimals,
                1,
                1,
                unit,
                unit,
                50 * unit,
                keccak256(abi.encode("M6_GENUINE_LOCAL_ONLY", asset)),
                bytes32(0)
            )
        );
    }
}
