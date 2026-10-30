// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId} from "@uniswap/v4-core/src/types/PoolId.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {FullMath} from "@uniswap/v4-core/src/libraries/FullMath.sol";

import {IPositionManager} from "@uniswap/v4-periphery/src/interfaces/IPositionManager.sol";
import {IAllowanceTransfer} from "permit2/src/interfaces/IAllowanceTransfer.sol";

import {RetroPickLauncherTokenV2} from "./RetroPickLauncherTokenV2.sol";
import {RetroPickBondingCurveV2} from "./RetroPickBondingCurveV2.sol";
import {RetroPickBuybackVaultV2} from "./RetroPickBuybackVaultV2.sol";
import {RetroPickLaunchLockerV2} from "./RetroPickLaunchLockerV2.sol";
import {RetroPickMemeHookV2} from "./hooks/RetroPickMemeHookV2.sol";
import {GraduationCoordinatorV2} from "./GraduationCoordinatorV2.sol";
import {RetroPickQuoteAssetRegistryV2} from "./RetroPickQuoteAssetRegistryV2.sol";
import {
    GraduationVenue,
    GraduationState,
    GraduationPacket,
    GraduationLedger,
    GraduationReceipt,
    QuoteAssetConfig,
    IGraduationExecutorV2
} from "./interfaces/IGraduationExecutorV2.sol";
import {LaunchDeployment, RetroPickLaunchDeployerV2} from "./RetroPickLaunchDeployerV2.sol";

import {RetroPickGraduationMathV2} from "./libraries/RetroPickGraduationMathV2.sol";
import {RetroPickBondingCurveMathV2} from "./libraries/RetroPickBondingCurveMathV2.sol";
import {IRetroPickQuoteAssetPolicyV2} from "./interfaces/IRetroPickQuoteAssetPolicyV2.sol";
import {
    FeePolicySnapshot,
    GraduationPhase,
    IRetroPickFeeEscrowV2,
    IRetroPickLaunchFactoryV2
} from "./interfaces/IRetroPickLaunchpadV2.sol";

/// @notice Launch/config and fee administration authority. Graduation custody and lifecycle belong to the Coordinator.
contract RetroPickLaunchFactoryV2 is Ownable2Step, ReentrancyGuard, IRetroPickLaunchFactoryV2 {
    using SafeERC20 for IERC20;

    uint256 private constant BASIS_POINTS = 10_000;
    uint256 private constant MAX_CURVE_FEE_BPS = 1_000; // 10%
    uint256 private constant MAX_CREATOR_TAX_CEILING_BPS = 1_000; // 10%
    uint256 private constant MAX_TOTAL_TRADE_FEE_BPS = 2_000; // 20%
    // Ceiling on the launch-second snipe tax. Held below 100% so a taxed
    // buy always nets the buyer something even before the curve applies its
    // own combined-fee bound.
    uint256 private constant MAX_SNIPE_TAX_START_BPS = 9_900; // 99%
    // Ceiling on the snipe tax decay window. Long enough to cover several
    // blocks of sniper activity on any chain this deploys to, short enough
    // that a misconfiguration cannot leave a launch effectively closed to
    // the public for minutes.
    uint256 private constant MAX_SNIPE_TAX_SECONDS = 60;
    // Bound on the creator-declared exemption list, so a launch cannot be
    // made unaffordable to itself by an unbounded loop of exemption writes.
    uint256 private constant MAX_SNIPE_TAX_EXEMPTIONS = 32;
    // Smallest supply a launch may declare, and the reference supply the
    // quotability check assumes when it runs before any config is known.
    uint256 private constant MIN_LAUNCH_SUPPLY = 1 ether;
    // The quotability check prices a buy of one millionth of the phantom
    // reserve. Expressing the reference trade as a fraction of the reserve
    // rather than a fixed amount keeps it meaningful across quote assets of
    // different decimals, where a wei-denominated constant would be either
    // trivial or unreachable.
    uint256 private constant REFERENCE_BUY_DIVISOR = 1e6;
    // Widest ticks usable at any tick spacing, matching v4-core's own MIN/MAX_TICK.
    int24 private constant MIN_USABLE_TICK = -887272;
    int24 private constant MAX_USABLE_TICK = 887272;
    // Largest tick spacing v4-core's PoolManager will accept; a launch config
    // above this would deploy a curve and token but then revert forever at
    // pool creation, stranding the swept reserves.
    int24 private constant MAX_TICK_SPACING = 32767;
    // Largest amount either side of a seed may carry. V4 settles pool balance
    // changes through a BalanceDelta of two int128 halves, so the signed
    // maximum binds even though the PositionManager's ABI accepts a uint128.
    // Mirrors RetroPickGraduationGuardV2's own ceiling.
    // unsafe-typecast: type(int128).max is a positive compile-time constant, so both the
    // int128->uint128 and uint128->uint256 casts are provably lossless (widening / same-value).
    // forge-lint: disable-next-line(unsafe-typecast)
    uint256 private constant MAX_SEED_AMOUNT = uint256(uint128(type(int128).max));
    // Advance notice the protocol owner's creator-fee-recipient override must
    // wait out before it can be executed. The creator's own self-service
    // transferCreatorFeeRecipient is never subject to this delay.
    uint256 public constant CREATOR_FEE_RECIPIENT_TIMELOCK = 3 days;
    // How long a launch must sit in Swept before its reserves may be released
    // manually. Seeding is permissionless and retryable, so this window is
    // what separates a genuinely unseedable launch from one that merely hit a
    // transient failure, and it denies the owner a same-block escape hatch.
    uint256 public constant GRADUATION_RESCUE_DELAY = 7 days;
    // A matured override must execute during this window. Expiration prevents
    // an old, forgotten proposal from remaining executable indefinitely.
    uint256 public constant CREATOR_FEE_RECIPIENT_EXECUTION_WINDOW = 3 days;

    struct TokenParams {
        string name;
        string symbol;
        string logo;
        string description;
        RetroPickLauncherTokenV2.Socials socials;
        address creatorFeeRecipient;
        // Additional trade tax the creator charges on top of the launch
        // config's base curveFeeBps, capped by maxCreatorTaxBps at launch
        // time. Paid entirely to the creator, never split with the protocol.
        uint16 creatorTaxBps;
        // The creator chooses the initial per-launch buyback-and-lock state.
        // Both the current creator recipient and protocol owner may update it.
        bool buybackEnabled;
        // Optional guard on the economics this launch will lock in. Zero
        // waives the check. Set it to the terms quoted at signing time so an
        // owner re-peg can never land underneath an in-flight launch.
        //
        // Call previewLaunchEconomics(launchConfigId, pairToken) to obtain
        // this value rather than encoding it by hand. The preimage is
        // keccak256(abi.encode(...)) over ten values in this order:
        //
        //   uint256 phantomQuote
        //   uint256 graduationThreshold
        //   uint256 config.supply
        //   uint256 config.curveFeeBps
        //   uint24  config.poolFee
        //   int24   config.tickSpacing
        //   uint16  policy.protocolFeeShareBps
        //   uint16  policy.buybackBurnBps
        //   uint16  policy.hookFeeBps
        //   uint16  policy.maxInternalPriceImpactBps
        //
        // It spans every owner-controlled term that fixes what the creator is
        // buying, not the phantom reserve and threshold alone, so the supply,
        // the trade fee or the pool's fee tier cannot move underneath a pin.
        bytes32 expectedEconomics;
        // CREATE2 salt for the launch's curve and token. The pair's addresses
        // are derived from this together with every constructor argument, so
        // they can be computed before the launch is sent and cannot be taken
        // by a launch that lands first. Namespaced per factory-authenticated
        // initiating account, so this only has to be unique among that
        // account's own launches; an unused value is all a caller needs, and
        // mining it is how a creator chooses a vanity address.
        //
        // Reusing a value on otherwise identical terms reverts, since the pair
        // already exists at that address. Call
        // RetroPickLaunchDeployerV2.predictLaunchAddresses to check in advance.
        bytes32 salt;
    }

    /**
     * @notice Native-quote launch economics. `phantomQuote` and
     * `graduationThreshold` are in wei here; a launch against an approved
     * ERC-20 quote asset takes both from that asset's own PairTokenEconomics
     * instead, since neither figure is meaningful across decimals.
     */
    struct LaunchConfig {
        uint256 supply;
        uint256 curveFeeBps;
        uint256 phantomQuote;
        uint256 graduationThreshold;
        uint24 poolFee;
        int24 tickSpacing;
        bool enabled;
    }

    /**
     * @notice Curve economics for one approved ERC-20 quote asset, in that
     * asset's own decimals. Required before the asset may be approved,
     * because a wei-denominated phantom reserve applied to a 6-decimal
     * stablecoin would misprice the curve by twelve orders of magnitude.
     *
     * Both figures are sized off chain from a target native-quote value at a
     * chosen rate. Scaling the pair by one rate leaves the curve's shape
     * untouched, since only threshold / (threshold + phantomQuote) determines
     * the fraction of supply that reaches the graduated pool, so a custom
     * quote asset trades identically to a native launch of the same size.
     */
    struct PairTokenEconomics {
        uint256 phantomQuote;
        uint256 graduationThreshold;
        uint8 decimals;
    }

    /**
     * @notice A protocol-owner-proposed creator-fee-recipient override
     * awaiting its timelock, keyed by launch token.
     */
    // Launch and fee configuration only. Mutable graduation state exists solely in the Coordinator.
    struct LaunchRecord {
        address token;
        address curve;
        address deployer;
        address creatorFeeRecipient;
        address pairToken;
        uint256 graduationThreshold;
        uint24 poolFee;
        int24 tickSpacing;
        uint16 creatorTaxBps;
        bool buybackEnabled;
        bool exists;
        GraduationVenue venue;
    }

    struct PendingCreatorFeeRecipient {
        address newRecipient;
        uint256 effectiveAt;
        uint256 expiresAt;
    }

    error InvalidLaunchConfigId();
    error LaunchConfigDisabled();
    error InvalidBasisPoints();
    error ExemptionListTooLong();
    error InvalidSnipeTaxWindow();
    error CurveFeeTooHigh();
    error CreatorTaxTooHigh();
    error CombinedFeeTooHigh();
    error SupplyTooLow();
    error InvalidTickSpacing();
    error LaunchFeeNotPaid();
    error NotWhitelisted();
    error FeeTransferFailed();
    error ZeroAddress();
    error AlreadySet();
    error OwnershipCannotBeRenounced();
    error InvalidTokenParams();
    error TokenNotFound();
    error WrongGraduationPhase();
    error GraduationStillViable();
    error NothingToGraduate();
    error SqrtPriceOutOfBounds();
    error GraduationExecutorNotSet();
    error LaunchDeployerNotSet();
    error NotLaunchForwarder();
    error NotCreatorFeeRecipient();
    error NoPendingChange();
    error TimelockNotElapsed(uint256 effectiveAt);
    error TimelockExpired(uint256 expiresAt);
    error LaunchDependenciesNotWired();
    error PairTokenNotApproved();
    error PairTokenValidationFailed();
    error NotBuybackController();
    error CoreLpFeeMustBeZero();
    error InvalidGraduationThreshold();
    error InvalidPhantomQuote();
    error CurveNotQuotable();
    error PairTokenEconomicsInvalid();
    error LaunchEconomicsMismatch(bytes32 expected, bytes32 actual);
    error InexactTransfer(address token, uint256 expected, uint256 received);
    error GraduationSeedNotViable();
    error SupplyTooHigh();
    error GraduationRescueTooEarly(uint256 availableAt);

    event TokenLaunched(
        address indexed token,
        address indexed curve,
        address indexed deployer,
        address pairToken,
        uint256 launchConfigId,
        uint256 graduationThreshold
    );
    event LaunchSwept(address indexed token, uint256 quoteOut, uint256 tokenOut);
    event LaunchForceSwept(address indexed token);
    event CreatorFeeRecipientUpdated(
        address indexed token, address indexed previousRecipient, address indexed newRecipient
    );
    event CreatorFeeRecipientChangeProposed(
        address indexed token,
        address indexed currentRecipient,
        address indexed proposedRecipient,
        uint256 effectiveAt,
        uint256 expiresAt
    );
    event CreatorFeeRecipientChangeCancelled(address indexed token, address indexed proposedRecipient);
    event PoolGraduated(address indexed token, uint256 positionId, uint256 tokenAmount, uint256 pairTokenAmount);
    event LaunchConfigAdded(uint256 indexed id);
    event LaunchConfigUpdated(uint256 indexed id);
    event LaunchFeeUpdated(uint256 launchFee);
    event LaunchEnabledUpdated(bool enabled);
    event WhitelistedLauncherUpdated(address indexed launcher, bool enabled);
    event MaxCreatorTaxUpdated(uint256 bps);
    event SnipeTaxStartBpsUpdated(uint256 bps);
    event SnipeTaxSecondsUpdated(uint256 secondsWindow);
    event GraduationExecutorSet(address executor);
    event LaunchDeployerSet(address deployer);
    event LaunchForwarderSet(address forwarder);
    event PairTokenApprovalUpdated(address indexed pairToken, bool approved);
    event PairTokenEconomicsUpdated(
        address indexed pairToken, uint256 phantomQuote, uint256 graduationThreshold, uint8 decimals
    );
    event BuybackEnabledUpdated(address indexed token, bool enabled, address indexed controller);
    event GraduationTokensPermanentlyLocked(address indexed token, uint256 amount);
    event LaunchGraduationRescued(
        address indexed token, address indexed recipient, uint256 quoteAmount, uint256 tokenAmount
    );

    IPoolManager public immutable poolManager;
    IPositionManager public immutable positionManager;
    IAllowanceTransfer public immutable permit2;
    RetroPickLaunchLockerV2 public immutable locker;
    RetroPickMemeHookV2 public immutable memeHook;
    IRetroPickFeeEscrowV2 public immutable feeEscrow;
    IRetroPickQuoteAssetPolicyV2 public immutable quoteAssetPolicy;
    RetroPickBuybackVaultV2 public immutable buybackVault;

    // Not immutable: each helper's constructor needs this factory's
    // already-deployed address, so they are deployed afterward and wired once.
    GraduationCoordinatorV2 public immutable graduationCoordinator;
    RetroPickQuoteAssetRegistryV2 public immutable quoteRegistry;
    address private _securingToken;
    bool private _secureCallbackUsed;
    RetroPickLaunchDeployerV2 public launchDeployer;
    address public launchForwarder;

    // Ceiling on the creator-chosen trade tax, mirroring MAX_CURVE_FEE_BPS's
    // existing pattern for the protocol's own base fee.
    uint256 public maxCreatorTaxBps = 1_000; // 10%

    // Anti-snipe tax terms every new launch snapshots at creation: the tax
    // charged in the launch second, in basis points of a buy's quote leg,
    // and the window across which each curve decays it exponentially to
    // zero. Snapshotted rather than read live so retuning here governs
    // launches from that moment on while a curve already trading keeps the
    // terms it launched under. A zero starting tax disables the mechanism
    // for launches created while it is zero.
    uint256 public snipeTaxStartBps = 9_900; // 99%
    uint256 public snipeTaxSeconds = 15;

    uint256 public launchFee;
    bool public launchEnabled;

    mapping(address launcher => bool enabled) public whitelistedLaunchers;

    mapping(address token => FeePolicySnapshot policy) private _launchFeePolicies;
    mapping(address token => LaunchRecord launched) private _launchedTokens;
    mapping(address token => PendingCreatorFeeRecipient) public pendingCreatorFeeRecipient;
    LaunchConfig[] private _launchConfigs;

    constructor(
        address initialOwner,
        IPoolManager poolManager_,
        IPositionManager positionManager_,
        IAllowanceTransfer permit2_,
        RetroPickLaunchLockerV2 locker_,
        RetroPickMemeHookV2 memeHook_,
        IRetroPickFeeEscrowV2 feeEscrow_,
        RetroPickBuybackVaultV2 buybackVault_,
        RetroPickQuoteAssetRegistryV2 quoteAssetPolicy_,
        GraduationCoordinatorV2 coordinator_,
        uint256 initialLaunchFee
    ) Ownable(initialOwner) {
        if (address(poolManager_) == address(0) || address(positionManager_) == address(0)) {
            revert ZeroAddress();
        }
        if (address(permit2_) == address(0) || address(locker_) == address(0)) revert ZeroAddress();
        if (address(memeHook_) == address(0) || address(feeEscrow_) == address(0)) revert ZeroAddress();
        if (address(buybackVault_) == address(0) || address(quoteAssetPolicy_) == address(0)) revert ZeroAddress();
        if (!quoteAssetPolicy_.isSupportedQuote(address(0))) {
            revert PairTokenValidationFailed();
        }
        // The factory initializes pools on `poolManager_` but mints their
        // liquidity through `positionManager_`. If the two point at different
        // singletons every graduation reverts, so the mismatch is caught here
        // rather than once per launch: both are immutable, so one check at
        // construction covers the contract's whole lifetime.
        if (address(positionManager_.poolManager()) != address(poolManager_)) {
            revert LaunchDependenciesNotWired();
        }

        poolManager = poolManager_;
        positionManager = positionManager_;
        permit2 = permit2_;
        locker = locker_;
        memeHook = memeHook_;
        feeEscrow = feeEscrow_;
        quoteAssetPolicy = quoteAssetPolicy_;
        buybackVault = buybackVault_;
        if (address(coordinator_).code.length == 0) revert LaunchDependenciesNotWired();
        graduationCoordinator = coordinator_;
        quoteRegistry = quoteAssetPolicy_;
        launchFee = initialLaunchFee;
    }

    /**
     * @notice Returns the number of launch configurations.
     */
    function launchConfigCount() external view returns (uint256) {
        return _launchConfigs.length;
    }

    /**
     * @notice Returns one token launch configuration.
     */
    function getLaunchConfig(uint256 id) external view returns (LaunchConfig memory) {
        if (id >= _launchConfigs.length) revert InvalidLaunchConfigId();
        return _launchConfigs[id];
    }

    /**
     * @notice Returns the immutable record for a token created by this factory.
     */
    function getLaunchedToken(address token) external view override returns (LaunchedToken memory) {
        LaunchRecord memory r = _launchedTokens[token];
        GraduationLedger memory l = graduationCoordinator.ledger(token);
        return LaunchedToken(
            r.token,
            r.curve,
            r.deployer,
            r.creatorFeeRecipient,
            r.pairToken,
            r.graduationThreshold,
            r.poolFee,
            r.tickSpacing,
            r.creatorTaxBps,
            r.buybackEnabled,
            l.phase == GraduationState.GRADUATED
                ? GraduationPhase.PoolCreated
                : l.phase == GraduationState.GRADUATING ? GraduationPhase.Swept : GraduationPhase.NotGraduated,
            l.securedQuote - l.consumedQuote,
            l.securedLaunchTokens - l.consumedLaunchTokens,
            l.securedAt,
            r.exists
        );
    }

    /**
     * @notice Returns the fee policy frozen for a launch.
     */
    function getLaunchFeePolicy(address token) external view returns (FeePolicySnapshot memory) {
        return _launchFeePolicies[token];
    }

    // ---------------------------------------------------------------------
    // Owner-only configuration
    // ---------------------------------------------------------------------

    /**
     * @notice Adds a launch configuration new tokens can be deployed against.
     */
    function addLaunchConfig(LaunchConfig calldata config) external onlyOwner returns (uint256 id) {
        _validateLaunchConfig(config);
        id = _launchConfigs.length;
        _launchConfigs.push(config);
        emit LaunchConfigAdded(id);
    }

    /**
     * @notice Replaces an existing launch configuration. Already-launched
     * tokens are unaffected since their pool parameters were snapshotted.
     */
    function updateLaunchConfig(uint256 id, LaunchConfig calldata config) external onlyOwner {
        if (id >= _launchConfigs.length) revert InvalidLaunchConfigId();
        _validateLaunchConfig(config);
        _launchConfigs[id] = config;
        emit LaunchConfigUpdated(id);
    }

    /**
     * @notice Changes the fixed native launch fee.
     */
    function setLaunchFee(uint256 newLaunchFee) external onlyOwner {
        launchFee = newLaunchFee;
        emit LaunchFeeUpdated(newLaunchFee);
    }

    /**
     * @notice Opens or closes launches to non-whitelisted callers.
     */
    function setLaunchEnabled(bool enabled) external onlyOwner {
        launchEnabled = enabled;
        emit LaunchEnabledUpdated(enabled);
    }

    /**
     * @notice Grants or revokes permission to launch while the public gate is closed.
     */
    function setWhitelistedLauncher(address launcher, bool enabled) external onlyOwner {
        if (launcher == address(0)) revert ZeroAddress();
        whitelistedLaunchers[launcher] = enabled;
        emit WhitelistedLauncherUpdated(launcher, enabled);
    }

    /**
     * @notice Whether `launcher` may launch right now: true while the public
     * gate is open, and true for whitelisted addresses while it is closed.
     * The same predicate `launchToken` enforces on its caller, exposed so
     * routers like RetroPickLaunchAndBuyV2 can hold their own callers to this
     * single list instead of maintaining a second one.
     */
    function canLaunch(address launcher) public view returns (bool) {
        return launchEnabled || whitelistedLaunchers[launcher];
    }

    /**
     * @notice Adjusts the ceiling a creator's chosen trade tax is validated
     * against at launch time. Already-launched tokens keep the immutable
     * tax rate they launched with regardless of later ceiling changes.
     */
    function setMaxCreatorTaxBps(uint256 bps) external onlyOwner {
        if (bps > MAX_CREATOR_TAX_CEILING_BPS) revert InvalidBasisPoints();
        maxCreatorTaxBps = bps;
        emit MaxCreatorTaxUpdated(bps);
    }

    /**
     * @notice Sets the launch-second snipe tax that new launches snapshot
     * at creation. Curves already trading keep the figure they launched
     * under. Zero disables the tax for launches created while it is zero;
     * a nonzero figure must exceed the 20% combined base fee ceiling, so
     * the launch-window tax always dominates the ordinary fee take, and
     * stays below 100% so a taxed buy always nets the buyer something.
     */
    function setSnipeTaxStartBps(uint256 bps) external onlyOwner {
        if (bps != 0 && (bps <= MAX_TOTAL_TRADE_FEE_BPS || bps > MAX_SNIPE_TAX_START_BPS)) {
            revert InvalidBasisPoints();
        }
        snipeTaxStartBps = bps;
        emit SnipeTaxStartBpsUpdated(bps);
    }

    /**
     * @notice Sets the decay window new launches snapshot at creation, in
     * seconds. Capped at one minute so a misconfiguration cannot leave a
     * launch effectively closed to the public for minutes; disabling the
     * tax is done through `setSnipeTaxStartBps`, so a zero window is
     * refused rather than overloaded to mean off.
     */
    function setSnipeTaxSeconds(uint256 secondsWindow) external onlyOwner {
        if (secondsWindow == 0 || secondsWindow > MAX_SNIPE_TAX_SECONDS) revert InvalidSnipeTaxWindow();
        snipeTaxSeconds = secondsWindow;
        emit SnipeTaxSecondsUpdated(secondsWindow);
    }

    /**
     * @notice One-time wiring of the launch deployer, set after both are
     * deployed since the deployer's constructor needs this factory's
     * already-known address.
     */
    function configureVenueExecutor(GraduationVenue venue, address executor) external onlyOwner {
        graduationCoordinator.configureExecutor(venue, executor);
    }

    function previewVenueEconomics(uint256 id, address quote, GraduationVenue venue) public view returns (bytes32) {
        return graduationCoordinator.previewEconomics(id, quote, venue);
    }

    function launchToken(TokenParams calldata params, uint256 id, address quote, GraduationVenue venue)
        external
        payable
        nonReentrant
        returns (address token, address curve)
    {
        return _launchToken(params, id, quote, msg.sender, venue);
    }

    function setLaunchDeployer(RetroPickLaunchDeployerV2 deployer) external onlyOwner {
        if (address(launchDeployer) != address(0)) revert AlreadySet();
        if (address(deployer) == address(0)) revert ZeroAddress();
        launchDeployer = deployer;
        emit LaunchDeployerSet(address(deployer));
    }

    /**
     * @notice Sets the router allowed to preserve the initiating user across
     * an atomic launch-and-buy call. May be rotated when the router is
     * upgraded without replacing the rest of the launch stack.
     * @dev Kept separate from `whitelistedLaunchers`: that list controls who
     * may launch while the public gate is closed, whereas this address is
     * trusted to identify another account for CREATE2 namespacing and launch
     * attribution.
     */
    function setLaunchForwarder(address forwarder) external onlyOwner {
        if (forwarder == address(0)) revert ZeroAddress();
        launchForwarder = forwarder;
        emit LaunchForwarderSet(forwarder);
    }

    /**
     * @notice Permanently disabled. An ownerless factory could never approve
     * a pairToken, adjust fee ceilings, or recover a creator's fee recipient,
     * and every launch already live would keep depending on those powers.
     * Ownership can still be handed to a new owner via the two-step transfer.
     */
    function renounceOwnership() public pure override {
        revert OwnershipCannotBeRenounced();
    }

    // ---------------------------------------------------------------------
    // Launch
    // ---------------------------------------------------------------------

    /**
     * @notice Returns the economics digest a launch of `launchConfigId` in
     * `pairToken` would produce right now, for a creator to pass back as
     * TokenParams.expectedEconomics.
     * @dev Reading the digest and launching in separate transactions still
     * leaves the terms free to move in between; the pin is what makes that
     * movement revert instead of silently repricing the launch.
     */
    function previewLaunchEconomics(uint256 id, address quote) external view returns (bytes32) {
        return previewVenueEconomics(id, quote, GraduationVenue.UNISWAP_V4);
    }

    /**
     * @dev Covers every owner-controlled term that fixes what a creator is
     * buying: the curve's shape and cost, the pool the launch graduates into,
     * and the fee split that follows it. Narrowing this to the phantom
     * reserve and threshold alone would let the supply, the trade fee, or the
     * pool's own fee tier move underneath a pinned launch.
     *
     * maxCreatorTaxBps is intentionally absent. It bounds a figure the
     * creator supplies rather than one the protocol sets, so a change makes
     * the launch revert on its own rather than silently reprice.
     */

    /**
     * @notice Deploys a bonding curve and its launch token, wires them
     * together, and records the launch. Trading starts immediately on the
     * curve; the graduation pool's pairToken is fixed here, chosen by the
     * caller. The caller and their creator fee recipient are exempted from
     * the snipe tax automatically; a launch with additional bundle wallets
     * should use the overload that takes an exemption list.
     */
    function launchToken(TokenParams calldata params, uint256 launchConfigId, address pairToken)
        external
        payable
        nonReentrant
        returns (address token, address curve)
    {
        return _launchToken(params, launchConfigId, pairToken, msg.sender, GraduationVenue.UNISWAP_V4);
    }

    /**
     * @notice Same launch flow, plus a creator-declared list of wallets
     * exempted from the snipe tax before trading opens to anyone else. This
     * is the sanctioned pathway for organized teams that bundle their
     * opening buys across several wallets: declared wallets clear at the
     * untaxed price during the launch window while undeclared snipers pay
     * the decaying tax.
     */
    function launchToken(
        TokenParams calldata params,
        uint256 launchConfigId,
        address pairToken,
        address[] calldata snipeTaxExemptions
    ) external payable nonReentrant returns (address token, address curve) {
        (token, curve) = _launchToken(params, launchConfigId, pairToken, msg.sender, GraduationVenue.UNISWAP_V4);
        _exemptFromSnipeTax(curve, snipeTaxExemptions);
    }

    /**
     * @notice Launches for the initiating user of the trusted atomic
     * launch-and-buy router, with its declared opening-buy exemptions.
     * @dev Only the configured `launchForwarder` may supply `originalDeployer`.
     * This preserves the real caller without `tx.origin`, which breaks through
     * account-abstraction relayers and must never be used for authorization.
     */
    function launchTokenFor(
        TokenParams calldata params,
        uint256 launchConfigId,
        address pairToken,
        address originalDeployer,
        address[] calldata snipeTaxExemptions
    ) external payable nonReentrant returns (address token, address curve) {
        if (msg.sender != launchForwarder) revert NotLaunchForwarder();
        (token, curve) = _launchToken(params, launchConfigId, pairToken, originalDeployer, GraduationVenue.UNISWAP_V4);
        _exemptFromSnipeTax(curve, snipeTaxExemptions);
    }

    /**
     * @dev Applies the bounded opening-buy exemption list shared by direct and
     * forwarded launches.
     */
    function _exemptFromSnipeTax(address curve, address[] calldata snipeTaxExemptions) private {
        if (snipeTaxExemptions.length > MAX_SNIPE_TAX_EXEMPTIONS) revert ExemptionListTooLong();
        for (uint256 i = 0; i < snipeTaxExemptions.length; ++i) {
            // calls-loop: the list is capped by MAX_SNIPE_TAX_EXEMPTIONS above, so this is a bounded,
            //   protocol-limited iteration that untrusted callers cannot inflate into a gas DoS.
            // forge-lint: disable-next-line(calls-loop)
            RetroPickBondingCurveV2(curve).exemptFromSnipeTax(snipeTaxExemptions[i]);
        }
    }

    /**
     * @dev Shared body of the direct and trusted-forwarder entrypoints.
     * Validates the launch terms, deploys and records the pair, and exempts
     * the creator's own addresses from the snipe tax.
     */
    function _launchToken(
        TokenParams calldata params,
        uint256 launchConfigId,
        address pairToken,
        address originalDeployer,
        GraduationVenue venue
    ) private returns (address token, address curve) {
        if (address(launchDeployer) == address(0)) revert LaunchDeployerNotSet();
        _requireLaunchDependenciesWired();
        if (!canLaunch(originalDeployer)) revert NotWhitelisted();
        if (msg.value != launchFee) revert LaunchFeeNotPaid();
        if (launchConfigId >= _launchConfigs.length) revert InvalidLaunchConfigId();
        if (bytes(params.name).length == 0 || bytes(params.symbol).length == 0) revert InvalidTokenParams();
        if (params.creatorTaxBps > maxCreatorTaxBps) revert CreatorTaxTooHigh();

        LaunchConfig memory config = _launchConfigs[launchConfigId];
        FeePolicySnapshot memory policy = memeHook.currentFeePolicy();
        QuoteAssetConfig memory q = quoteRegistry.admitted(pairToken, venue);
        uint256 phantomQuote = q.phantomQuote;
        uint256 graduationThreshold = q.graduationThreshold;
        address executor = graduationCoordinator.executors(venue);
        if (executor.code.length == 0) revert GraduationExecutorNotSet();
        // Every term below is owner-updatable, so a creator may pin the whole
        // set they were quoted rather than accept whatever is current when
        // their transaction lands.
        bytes32 economics = graduationCoordinator.previewEconomics(launchConfigId, pairToken, venue);
        if (params.expectedEconomics != bytes32(0) && params.expectedEconomics != economics) {
            revert LaunchEconomicsMismatch(params.expectedEconomics, economics);
        }
        if (!config.enabled) revert LaunchConfigDisabled();
        // Unreachable while the individual ceilings stay where they are, since
        // each leg caps at 1000 bps against a 2000 bps combined limit. Kept as
        // the check that would actually bind if either ceiling were raised, so
        // the combined limit does not depend on arithmetic between constants
        // declared far apart.
        if (config.curveFeeBps + params.creatorTaxBps > MAX_TOTAL_TRADE_FEE_BPS) {
            revert CombinedFeeTooHigh();
        }
        if (policy.hookFeeBps + params.creatorTaxBps > MAX_TOTAL_TRADE_FEE_BPS) {
            revert CombinedFeeTooHigh();
        }
        // A config and a quote asset are validated separately but graduate as
        // a pair, and it is the pair that fixes the seed. Terms that imply a
        // position V4 will not mint are refused here, while the creator still
        // has their fee and nothing has been deployed.
        _requireQuotable(phantomQuote, config.supply, config.curveFeeBps);

        address creatorFeeRecipient =
            params.creatorFeeRecipient == address(0) ? originalDeployer : params.creatorFeeRecipient;

        (token, curve) = _deployPair(params, config, q, pairToken, originalDeployer, creatorFeeRecipient, policy);
        RetroPickBondingCurveV2(curve).initialize(token);

        // The creator's own addresses never count as snipers on their own
        // launch: an atomic dev buy lands in the launch second, exactly when
        // the tax peaks, and would otherwise be consumed by it.
        RetroPickBondingCurveV2(curve).exemptFromSnipeTax(originalDeployer);
        if (creatorFeeRecipient != originalDeployer) {
            RetroPickBondingCurveV2(curve).exemptFromSnipeTax(creatorFeeRecipient);
        }

        _launchedTokens[token] = LaunchRecord({
            token: token,
            curve: curve,
            deployer: originalDeployer,
            creatorFeeRecipient: creatorFeeRecipient,
            pairToken: pairToken,
            graduationThreshold: graduationThreshold,
            poolFee: config.poolFee,
            tickSpacing: config.tickSpacing,
            creatorTaxBps: params.creatorTaxBps,
            buybackEnabled: params.buybackEnabled,
            exists: true,
            venue: venue
        });
        _launchFeePolicies[token] = policy;
        graduationCoordinator.registerLaunch(token, curve, venue, config.poolFee, config.tickSpacing);

        // Last, after the launch is fully recorded: this forwards ETH to the
        // protocol recipient, which may be a contract that calls back in.
        _payLaunchFee();

        // reentrancy-events: every field logged here is finalized launch state written above; the
        //   preceding external calls are the trusted launchDeployer/_payLaunchFee, and no reentrant
        //   path can alter the immutable launch record this announces.
        // forge-lint: disable-next-line(reentrancy-events)
        emit TokenLaunched(token, curve, originalDeployer, pairToken, launchConfigId, graduationThreshold);
    }

    function _deployPair(
        TokenParams calldata params,
        LaunchConfig memory config,
        QuoteAssetConfig memory q,
        address quote,
        address originalDeployer,
        address creatorFeeRecipient,
        FeePolicySnapshot memory policy
    ) private returns (address token, address curve) {
        LaunchDeployment memory d;
        d.pairToken = quote;
        d.creatorFeeRecipient = creatorFeeRecipient;
        d.originalDeployer = originalDeployer;
        d.feePolicy = memeHook;
        d.policy = policy;
        d.feeEscrow = feeEscrow;
        d.buybackVault = buybackVault;
        d.phantomQuote = q.phantomQuote;
        d.curveFeeBps = config.curveFeeBps;
        d.creatorTaxBps = params.creatorTaxBps;
        d.buybackEnabled = params.buybackEnabled;
        d.graduationThreshold = q.graduationThreshold;
        d.graduationQuoteCeiling = q.graduationQuoteCeiling;
        d.supply = config.supply;
        d.name = params.name;
        d.symbol = params.symbol;
        d.logo = params.logo;
        d.description = params.description;
        d.socials = params.socials;
        return launchDeployer.deployLaunch(d);
    }

    // ---------------------------------------------------------------------
    // Creator fee recipient
    // ---------------------------------------------------------------------

    /**
     * @notice Lets the current creator fee recipient hand off future creator
     * fees for `token` to a new address, whether the launch is still
     * trading on its bonding curve or has already graduated into its
     * Uniswap V4 pool.
     * @dev Does not clear a pending protocol-owner override. If one is
     * outstanding, it still executes on schedule and supersedes the address
     * set here. See `setCreatorFeeRecipient`.
     */
    function transferCreatorFeeRecipient(address token, address newRecipient) external {
        LaunchRecord storage launch = _launchedTokens[token];
        if (!launch.exists) revert TokenNotFound();
        if (msg.sender != launch.creatorFeeRecipient) revert NotCreatorFeeRecipient();

        _setCreatorFeeRecipient(token, launch, newRecipient);
    }

    /**
     * @notice Enables or disables buyback-and-lock for one launch. Only the
     * current creator recipient may enable it, since the buyback slice is
     * funded from the creator's own bucket. The protocol owner may only
     * disable it (a strictly creator-favorable action), so the owner can
     * never force a creator's fees into the buyback vault to capture the
     * protocol's 30% release share against the creator's wishes.
     */
    function setBuybackEnabled(address token, bool enabled) external {
        LaunchRecord storage launch = _launchedTokens[token];
        if (!launch.exists) revert TokenNotFound();
        bool isCreator = msg.sender == launch.creatorFeeRecipient;
        bool isOwner = msg.sender == owner();
        if (!isCreator && !isOwner) revert NotBuybackController();
        // Enabling spends the creator's bucket, so only the creator may enable.
        if (enabled && !isCreator) revert NotBuybackController();

        launch.buybackEnabled = enabled;
        // Emit before the external forwarders: the reported state is fully
        // recorded above and does not depend on their result.
        emit BuybackEnabledUpdated(token, enabled, msg.sender);
        if (graduationCoordinator.ledger(token).phase == GraduationState.NONE) {
            RetroPickBondingCurveV2(launch.curve).setBuybackEnabled(enabled);
        } else if (
            graduationCoordinator.ledger(token).phase == GraduationState.GRADUATED
                && launch.venue == GraduationVenue.UNISWAP_V4
        ) {
            memeHook.setBuybackEnabled(_poolIdFor(token, launch), enabled);
        }
    }

    /**
     * @notice Proposes a protocol-owner override of a launch's creator fee
     * recipient. Its motivating case is recovery when a creator loses access
     * to their wallet, but the power is deliberately not conditioned on
     * that: the owner may redirect the recipient of any launch. Takes effect
     * only after `CREATOR_FEE_RECIPIENT_TIMELOCK` has elapsed and someone
     * calls `executeCreatorFeeRecipientChange`, giving the community advance
     * notice instead of applying instantly. A new proposal for the same
     * token replaces any earlier pending one and resets the clock.
     *
     * @dev A matured proposal takes precedence over any creator transfer made
     * while it was pending. `transferCreatorFeeRecipient` deliberately does
     * not cancel it, so the timelock is a notice period rather than a window
     * in which the creator can veto by moving the recipient themselves. The
     * override is therefore a standing protocol power over creator fee
     * routing, not a narrowly scoped lost-key recovery, and it is documented
     * as such rather than left to whichever call lands last.
     *
     * The collision is observable without extra state: this function emits
     * the recipient as it stood at proposal time, and `_setCreatorFeeRecipient`
     * emits the recipient it actually replaced. A creator transfer landing in
     * between shows up as a mismatch between the two.
     */
    function setCreatorFeeRecipient(address token, address newRecipient) external onlyOwner {
        LaunchRecord storage launch = _launchedTokens[token];
        if (!launch.exists) revert TokenNotFound();
        if (newRecipient == address(0)) revert ZeroAddress();

        uint256 effectiveAt = block.timestamp + CREATOR_FEE_RECIPIENT_TIMELOCK;
        uint256 expiresAt = effectiveAt + CREATOR_FEE_RECIPIENT_EXECUTION_WINDOW;
        pendingCreatorFeeRecipient[token] =
            PendingCreatorFeeRecipient({newRecipient: newRecipient, effectiveAt: effectiveAt, expiresAt: expiresAt});

        emit CreatorFeeRecipientChangeProposed(token, launch.creatorFeeRecipient, newRecipient, effectiveAt, expiresAt);
    }

    /**
     * @notice Applies a protocol-owner's proposed creator fee recipient
     * change once its timelock has elapsed. Permissionless: anyone can
     * execute an already-matured proposal.
     */
    function executeCreatorFeeRecipientChange(address token) external {
        PendingCreatorFeeRecipient memory pending = pendingCreatorFeeRecipient[token];
        if (pending.newRecipient == address(0)) revert NoPendingChange();
        // block-timestamp: the timelock window is a multi-day notice period (CREATOR_FEE_RECIPIENT_TIMELOCK
        //   / EXECUTION_WINDOW); seconds of miner drift cannot game a coarse days-scale window.
        // forge-lint: disable-next-line(block-timestamp)
        if (block.timestamp < pending.effectiveAt) revert TimelockNotElapsed(pending.effectiveAt);
        // block-timestamp: same multi-day expiration window; sub-minute drift is immaterial.
        // forge-lint: disable-next-line(block-timestamp)
        if (block.timestamp > pending.expiresAt) revert TimelockExpired(pending.expiresAt);

        LaunchRecord storage launch = _launchedTokens[token];
        delete pendingCreatorFeeRecipient[token];

        _setCreatorFeeRecipient(token, launch, pending.newRecipient);
    }

    /**
     * @notice Cancels a pending protocol-owner override before it takes effect.
     */
    function cancelCreatorFeeRecipientChange(address token) external onlyOwner {
        if (!_cancelPendingCreatorFeeRecipientChange(token)) revert NoPendingChange();
    }

    /**
     * @dev Updates the factory's own record and forwards the change to
     * whichever contract currently pays out creator fees: the bonding curve
     * pre-graduation, or the registered meme hook pool afterward.
     */
    function _setCreatorFeeRecipient(address token, LaunchRecord storage launch, address newRecipient) private {
        if (newRecipient == address(0)) revert ZeroAddress();

        address previousRecipient = launch.creatorFeeRecipient;
        launch.creatorFeeRecipient = newRecipient;

        // Emit before the external forwarders: previousRecipient is captured and
        // the factory's own record is updated above, so the reported values do
        // not depend on the downstream calls.
        emit CreatorFeeRecipientUpdated(token, previousRecipient, newRecipient);

        if (
            graduationCoordinator.ledger(token).phase == GraduationState.GRADUATED
                && launch.venue == GraduationVenue.UNISWAP_V4
        ) {
            memeHook.setCreatorFeeRecipient(_poolIdFor(token, launch), newRecipient);
        } else {
            RetroPickBondingCurveV2(launch.curve).setCreatorFeeRecipient(newRecipient);
        }

        // Keep the buyback vest's beneficiary aligned with the live creator
        // recipient so recovery and self-service transfers redirect vested
        // buyback tokens as well, not only immediate fee payouts.
        buybackVault.updateCreatorRecipient(token, newRecipient);
    }

    /**
     * @dev Clears a pending protocol override when present.
     */
    function _cancelPendingCreatorFeeRecipientChange(address token) private returns (bool cancelled) {
        PendingCreatorFeeRecipient memory pending = pendingCreatorFeeRecipient[token];
        if (pending.newRecipient == address(0)) return false;

        delete pendingCreatorFeeRecipient[token];
        emit CreatorFeeRecipientChangeCancelled(token, pending.newRecipient);
        return true;
    }

    /**
     * @dev Prevents launches until every singleton and helper points back to
     * this factory and to the same core dependencies. A partially wired stack
     * could otherwise accept buys but later block fee sweeps or graduation.
     */
    function _requireLaunchDependenciesWired() private view {
        if (
            launchDeployer.factory() != address(this) || graduationCoordinator.factory() != address(this)
                || memeHook.factory() != address(this) || address(memeHook.buybackVault()) != address(buybackVault)
                || buybackVault.factory() != address(this) || address(memeHook.poolManager()) != address(poolManager)
                || address(memeHook.feeEscrow()) != address(feeEscrow)
                || address(buybackVault.feePolicy()) != address(memeHook)
                || address(buybackVault.feeEscrow()) != address(feeEscrow)
        ) revert LaunchDependenciesNotWired();
    }

    /**
     * @dev Reconstructs the pool ID for an already-graduated launch from its
     * snapshotted config, since the factory does not separately store it.
     */
    function _poolIdFor(address token, LaunchRecord storage launch) private view returns (PoolId) {
        (Currency currency0, Currency currency1,) = _sortCurrencies(token, launch.pairToken);
        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: launch.poolFee,
            tickSpacing: launch.tickSpacing,
            hooks: IHooks(address(memeHook))
        });
        return key.toId();
    }

    // ---------------------------------------------------------------------
    // Graduation, phase 1: drain the curve
    // ---------------------------------------------------------------------

    /**
     * @notice Sweeps the curve's remaining quote and token reserves into this
     * factory and halts curve trading. Purely internal to the curve's own
     * balances, so it is safe for the curve to call this automatically the
     * instant a buy crosses the graduation threshold.
     */
    function graduate(address token) external nonReentrant {
        LaunchRecord storage launch = _launchedTokens[token];
        if (!launch.exists) revert TokenNotFound();
        if (_securingToken != address(0)) revert WrongGraduationPhase();
        _securingToken = token;
        _secureCallbackUsed = false;
        graduationCoordinator.secure(token);
        if (!_secureCallbackUsed) revert WrongGraduationPhase();
        delete _securingToken;
        delete _secureCallbackUsed;
    }

    /// @notice Narrow one-hop callback: the Curve continues trusting only its Factory.
    function secureCurve(address token) external returns (uint256 quoteOut, uint256 tokenOut) {
        if (
            msg.sender != address(graduationCoordinator) || token == address(0) || token != _securingToken
                || _secureCallbackUsed
        ) revert WrongGraduationPhase();
        LaunchRecord storage launch = _launchedTokens[token];
        if (
            !launch.exists || graduationCoordinator.ledger(token).phase != GraduationState.NONE
                || RetroPickBondingCurveV2(launch.curve).graduated()
        ) revert WrongGraduationPhase();
        _secureCallbackUsed = true;
        return RetroPickBondingCurveV2(launch.curve).graduate(address(graduationCoordinator));
    }

    // ---------------------------------------------------------------------
    // Graduation, phase 2: seed the V4 pool
    // ---------------------------------------------------------------------

    /**
     * @notice Initializes the V4 pool with the swept reserves, mints a
     * full-range position directly to the locker, and registers the pool with
     * the meme hook. The curve already holds the pool's quote asset, so this
     * seeds with exactly what it swept and needs no slippage bound.
     * Permissionless and retryable: a launch stays in Swept until a seed
     * succeeds, so a transient failure can never strand reserves.
     */
    function createGraduatedPool(address token) external returns (uint256 positionId) {
        if (!_launchedTokens[token].exists) revert TokenNotFound();
        GraduationReceipt memory r = graduationCoordinator.complete(token);
        return r.positionId;
    }

    /**
     * @notice Pays a still-trading launch's pending curve fees directly to the
     * protocol and creator recipients, bypassing the escrow, when its quote
     * asset has stopped delivering there.
     * @dev Also the only way to unwedge such a launch's graduation, since
     * `graduate` sweeps fees before handing over the reserves and cannot
     * succeed while that sweep reverts. Clearing the buckets makes the sweep
     * a no-op and lets graduation proceed.
     */
    function rescueCurveFees(address token) external nonReentrant onlyOwner {
        LaunchRecord storage launch = _launchedTokens[token];
        if (!launch.exists) revert TokenNotFound();
        // unused-return: rescueFees pays and emits the drained protocol/creator amounts itself; this
        //   caller only needs the buckets cleared so graduation can proceed, so the returned amounts
        //   are intentionally not consumed here.
        // forge-lint: disable-next-line(unused-return)
        RetroPickBondingCurveV2(payable(launch.curve)).rescueFees();
    }

    function _payLaunchFee() private {
        if (launchFee == 0) return;
        address recipient = memeHook.protocolFeeRecipient();
        if (recipient == address(0)) revert ZeroAddress();
        // arbitrary-send-eth: recipient is the protocol fee recipient read from the trusted memeHook
        //   (validated non-zero above), not caller-supplied, and the amount is the fixed launchFee.
        // forge-lint: disable-next-line(arbitrary-send-eth)
        (bool sent,) = payable(recipient).call{value: launchFee}("");
        if (!sent) revert FeeTransferFailed();
    }

    function _sortCurrencies(address memecoin, address pairToken)
        private
        pure
        returns (Currency currency0, Currency currency1, bool memecoinIsCurrency0)
    {
        if (pairToken < memecoin) {
            // boolean-cst: returning a constant tuple flag (memecoinIsCurrency0); not a boolean expression bug.
            // forge-lint: disable-next-line(boolean-cst)
            return (Currency.wrap(pairToken), Currency.wrap(memecoin), false);
        }
        // boolean-cst: returning a constant tuple flag (memecoinIsCurrency0); not a boolean expression bug.
        // forge-lint: disable-next-line(boolean-cst)
        return (Currency.wrap(memecoin), Currency.wrap(pairToken), true);
    }

    function _validateLaunchConfig(LaunchConfig calldata config) private pure {
        if (config.curveFeeBps > MAX_CURVE_FEE_BPS) revert CurveFeeTooHigh();
        if (config.supply < MIN_LAUNCH_SUPPLY) revert SupplyTooLow();
        // A supply above the seed ceiling would deploy a curve and token that
        // trade normally, then revert forever at graduation with the reserves
        // already swept out of the curve. The PositionManager's ABI takes the
        // amount as a uint128, but V4 core narrows it to int128, so the signed
        // bound is the one that has to be enforced here.
        if (config.supply > MAX_SEED_AMOUNT) revert SupplyTooHigh();
        if (config.phantomQuote == 0) revert InvalidPhantomQuote();
        if (config.graduationThreshold == 0) revert InvalidGraduationThreshold();
        if (config.tickSpacing <= 0 || config.tickSpacing > MAX_TICK_SPACING) revert InvalidTickSpacing();
        if (config.poolFee != 0) revert CoreLpFeeMustBeZero();
        _requireQuotable(config.phantomQuote, config.supply, config.curveFeeBps);
    }

    /**
     * @notice Reverts unless a small reference buy against a fresh curve with
     * these terms would return a non-zero amount of tokens.
     * @dev A phantom reserve set far too large against the supply prices every
     * realistic trade to zero, and the curve reverts on all of them. That
     * launch is dead on arrival but still deployable, and its creator has
     * already paid the launch fee, so the terms are rejected before any
     * contract exists rather than after.
     */
    function _requireQuotable(uint256 phantomQuote, uint256 supply, uint256 curveFeeBps) private pure {
        uint256 referenceBuy = phantomQuote / REFERENCE_BUY_DIVISOR;
        if (RetroPickBondingCurveMathV2.quoteAmountOut(referenceBuy, phantomQuote, supply, curveFeeBps) == 0) {
            revert CurveNotQuotable();
        }
    }

    /**
     * @notice Accepts native ETH swept from a graduating curve and any
     * dust refunded by the PositionManager or pairToken router.
     */
    receive() external payable {}
}
