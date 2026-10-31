// Experimental fixture adapted from the existing qualification fixture; real curve/factory, mocked destination only.
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IPositionManager} from "@uniswap/v4-periphery/src/interfaces/IPositionManager.sol";
import {IAllowanceTransfer} from "permit2/src/interfaces/IAllowanceTransfer.sol";
import {GraduationCoordinatorV2} from "../../../src/v2-research-experiment/GraduationCoordinatorV2.sol";
import {RetroPickQuoteAssetRegistryV2} from "../../../src/v2-research-experiment/RetroPickQuoteAssetRegistryV2.sol";
import {
    QuoteAssetConfig,
    GraduationVenue,
    GraduationState
} from "../../../src/v2-research-experiment/interfaces/IGraduationExecutorV2.sol";
import {ExactAssetV2} from "../../../src/v2-research-experiment/libraries/ExactAssetV2.sol";
import {RetroPickLaunchFactoryV2} from "../../../src/v2-research-experiment/RetroPickLaunchFactoryV2.sol";
import {RetroPickLaunchDeployerV2} from "../../../src/v2-research-experiment/RetroPickLaunchDeployerV2.sol";
import {UniswapV4GraduationExecutorV2} from "../../../src/v2-research-experiment/UniswapV4GraduationExecutorV2.sol";
import {RetroPickLaunchLockerV2} from "../../../src/v2-research-experiment/RetroPickLaunchLockerV2.sol";
import {RetroPickBondingCurveV2} from "../../../src/v2-research-experiment/RetroPickBondingCurveV2.sol";
import {RetroPickLauncherTokenV2} from "../../../src/v2-research-experiment/RetroPickLauncherTokenV2.sol";
import {RetroPickBuybackVaultV2} from "../../../src/v2-research-experiment/RetroPickBuybackVaultV2.sol";
import {RetroPickFeeEscrowV2} from "../../../src/v2-research-experiment/RetroPickFeeEscrowV2.sol";
import {RetroPickQuoteAssetPolicyV2} from "../../../src/v2-research-experiment/RetroPickQuoteAssetPolicyV2.sol";
import {
    IRetroPickQuoteAssetPolicyV2
} from "../../../src/v2-research-experiment/interfaces/IRetroPickQuoteAssetPolicyV2.sol";
import {RetroPickMemeHookV2} from "../../../src/v2-research-experiment/hooks/RetroPickMemeHookV2.sol";
import {
    FeePolicySnapshot,
    IRetroPickFeeEscrowV2,
    GraduationPhase
} from "../../../src/v2-research-experiment/interfaces/IRetroPickLaunchpadV2.sol";
import {MockERC20} from "../../mocks/MockERC20.sol";

/// @notice An ERC20 whose sender pays an additional burn on every transfer.
/// Balance-delta receipt does not protect the Curve when it is the sender.
contract SenderSurchargeQuote is ERC20 {
    constructor() ERC20("Surcharge Quote", "SQ") {}

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function _update(address from, address to, uint256 value) internal override {
        super._update(from, to, value);
        if (from != address(0) && to != address(0)) {
            super._update(from, address(0), value / 10);
        }
    }
}

/// @notice Research negative: exact during bonding, surcharge after sweep.
contract ToggleSenderSurchargeQuote is MockERC20 {
    bool public surchargeEnabled;

    constructor() MockERC20("Toggle Surcharge", "TSQ", 6) {}

    function setSurchargeEnabled(bool enabled) external {
        surchargeEnabled = enabled;
    }

    function _update(address from, address to, uint256 value) internal override {
        super._update(from, to, value);
        if (surchargeEnabled && from != address(0) && to != address(0)) {
            super._update(from, address(0), value / 10);
        }
    }
}

contract FalseReturnQuote is MockERC20 {
    constructor() MockERC20("False Return Quote", "FQ", 6) {}

    function transferFrom(address, address, uint256) public pure override returns (bool) {
        return false;
    }
}

contract ExternallyReducibleQuote is MockERC20 {
    constructor() MockERC20("Reducible Quote", "RQ", 6) {}

    function slash(address holder, uint256 amount) external {
        _burn(holder, amount);
    }
}

contract CallbackQuote is MockERC20 {
    address public targetCurve;
    uint256 public attempts;
    bool public callbackSucceeded;

    constructor() MockERC20("Callback Quote", "CQ", 6) {}

    function setTargetCurve(address curve) external {
        targetCurve = curve;
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        bool transferred = super.transferFrom(from, to, value);
        if (to == targetCurve && attempts == 0) {
            attempts = 1;
            (callbackSucceeded,) =
                targetCurve.call(abi.encodeWithSelector(RetroPickBondingCurveV2.buy.selector, 1e6, 0, from));
        }
        return transferred;
    }
}

/// @notice Deliberately permissive research fixture for malicious-token negatives.
/// It is not the production P0 quote admission policy.
contract ResearchPermissiveQuotePolicy is IRetroPickQuoteAssetPolicyV2 {
    function isSupportedQuote(address) external pure returns (bool) {
        return true;
    }

    function validateQuote(address, uint8) external pure {}
}

/// @notice Real Factory/Deployer/Token/Curve path with explicitly mocked V4-only singletons.
/// The mocks do not qualify V4 pool creation or a live Kuru destination.
abstract contract CommunityFactoryFixtureV2 is Test {
    address internal owner = address(this);
    address internal creator = makeAddr("creator");
    address internal protocol = makeAddr("protocol");
    address internal feeOperator = makeAddr("fee-operator");
    address internal poolManager = makeAddr("pool-manager");
    address internal positionManager = makeAddr("position-manager");
    address internal permit2 = makeAddr("permit2");
    address internal hook = makeAddr("hook");

    RetroPickLaunchFactoryV2 internal factory;
    GraduationCoordinatorV2 internal coordinator;
    RetroPickQuoteAssetRegistryV2 internal registry;
    RetroPickLaunchDeployerV2 internal deployer;
    UniswapV4GraduationExecutorV2 internal executor;
    RetroPickLaunchLockerV2 internal locker;
    RetroPickBuybackVaultV2 internal vault;
    RetroPickFeeEscrowV2 internal escrow;

    function setUp() public virtual {
        vm.chainId(10143);
        _configureFixture(new ResearchPermissiveQuotePolicy());
    }

    function _configureFixture(IRetroPickQuoteAssetPolicyV2) internal {
        vm.etch(positionManager, hex"00");
        vm.etch(hook, hex"00");
        vm.mockCall(positionManager, abi.encodeWithSignature("poolManager()"), abi.encode(poolManager));
        escrow = new RetroPickFeeEscrowV2();
        locker = new RetroPickLaunchLockerV2(owner, positionManager);
        vault = new RetroPickBuybackVaultV2(
            owner, RetroPickMemeHookV2(payable(hook)), IRetroPickFeeEscrowV2(address(escrow))
        );
        registry = new RetroPickQuoteAssetRegistryV2(address(this));
        coordinator = new GraduationCoordinatorV2(address(this));
        _admit(address(0), 100 ether, 100 ether, 18);
        factory = RetroPickLaunchFactoryV2(
            payable(vm.deployCode(
                    "src/v2-research-experiment/RetroPickLaunchFactoryV2.sol:RetroPickLaunchFactoryV2",
                    abi.encode(
                        owner,
                        IPoolManager(poolManager),
                        IPositionManager(positionManager),
                        IAllowanceTransfer(permit2),
                        locker,
                        RetroPickMemeHookV2(payable(hook)),
                        IRetroPickFeeEscrowV2(address(escrow)),
                        vault,
                        registry,
                        coordinator,
                        0
                    )
                ))
        );
        deployer = RetroPickLaunchDeployerV2(
            vm.deployCode(
                "src/v2-research-experiment/RetroPickLaunchDeployerV2.sol:RetroPickLaunchDeployerV2",
                abi.encode(address(factory))
            )
        );
        executor = UniswapV4GraduationExecutorV2(
            payable(vm.deployCode(
                    "src/v2-research-experiment/UniswapV4GraduationExecutorV2.sol:UniswapV4GraduationExecutorV2",
                    abi.encode(
                        address(coordinator),
                        IPoolManager(poolManager),
                        IPositionManager(positionManager),
                        IAllowanceTransfer(permit2),
                        locker,
                        RetroPickMemeHookV2(payable(hook)),
                        IRetroPickFeeEscrowV2(address(escrow))
                    )
                ))
        );
        locker.setFactory(address(factory));
        vault.setFactory(address(factory));
        factory.setLaunchDeployer(deployer);
        coordinator.bindFactory(address(factory));
        factory.configureVenueExecutor(GraduationVenue.UNISWAP_V4, address(executor));
        locker.setGraduationExecutor(address(executor));
        vm.mockCall(hook, abi.encodeWithSignature("graduationExecutor()"), abi.encode(address(executor)));

        vm.mockCall(hook, abi.encodeWithSignature("factory()"), abi.encode(address(factory)));
        vm.mockCall(hook, abi.encodeWithSignature("buybackVault()"), abi.encode(address(vault)));
        vm.mockCall(hook, abi.encodeWithSignature("poolManager()"), abi.encode(poolManager));
        vm.mockCall(hook, abi.encodeWithSignature("feeEscrow()"), abi.encode(address(escrow)));
        vm.mockCall(hook, abi.encodeWithSignature("feeSweepOperator()"), abi.encode(feeOperator));
        FeePolicySnapshot memory policy = FeePolicySnapshot(protocol, 3_000, 5_000, 100, 300);
        vm.mockCall(hook, abi.encodeWithSignature("currentFeePolicy()"), abi.encode(policy));

        factory.addLaunchConfig(_config());
        factory.setLaunchEnabled(true);
        vm.deal(creator, 10 ether);
    }

    function _config() internal pure returns (RetroPickLaunchFactoryV2.LaunchConfig memory) {
        return RetroPickLaunchFactoryV2.LaunchConfig({
            supply: 1_000_000 ether,
            curveFeeBps: 100,
            phantomQuote: 100 ether,
            graduationThreshold: 100 ether,
            poolFee: 0,
            tickSpacing: 60,
            enabled: true
        });
    }

    function _params(bytes32 salt) internal pure returns (RetroPickLaunchFactoryV2.TokenParams memory p) {
        RetroPickLauncherTokenV2.Socials memory socials;
        p = RetroPickLaunchFactoryV2.TokenParams({
            name: "Factory Launch",
            symbol: "FLCH",
            logo: "",
            description: "",
            socials: socials,
            creatorFeeRecipient: address(0),
            creatorTaxBps: 50,
            buybackEnabled: false,
            expectedEconomics: bytes32(0),
            salt: salt
        });
    }

    function _admit(address quote, uint256 phantom, uint256 threshold, uint8 decimals) internal {
        QuoteAssetConfig memory c = QuoteAssetConfig(
            true,
            decimals,
            3,
            registry.getConfig(quote).policyVersion + 1,
            phantom,
            threshold,
            threshold * 50,
            keccak256("TEST_FIXTURE_QUALIFICATION"),
            bytes32(0)
        );
        registry.configure(quote, c);
    }
}

