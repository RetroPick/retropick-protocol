#!/usr/bin/env python3
"""Generate development/fullstack-integration/abi-capabilities.json.

Campaign: RETROPICK-V2-FULLSTACK-INTEGRATION, Phase 1 (ABI_SEMANTICS_MAPPED).
Owner: CONTRACT_AGENT (SOLIDITY_FOUNDRY capability).

Reads the published ABI catalog under apps/abi/ (27 contracts), applies the
hand-authored classification embedded below, and emits a deterministic
machine-readable disposition table (sorted keys, no timestamps).

Hard guarantee: the script exits non-zero if ANY function, event or error of
ANY contract in the catalog lacks a disposition. 100% coverage is enforced,
not assumed.

Classification keys are short hints ("name/argc" plus an optional
"~substring" disambiguator) resolved mechanically against the canonical
signatures derived from the ABI JSON itself, so the emitted canonical keys
can never drift from the artifacts.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
ABI_DIR = REPO / "apps" / "abi"
MANIFEST = ABI_DIR / "manifest.json"
OUT = REPO / "development" / "fullstack-integration" / "abi-capabilities.json"

CHAIN_ID = 10143
BASELINE_COMMIT = "8d8650a"

# ---------------------------------------------------------------------------
# Canonical signature derivation (expanded tuples, Solidity-canonical form).
# ---------------------------------------------------------------------------


def canon_type(comp: dict) -> str:
    t = comp["type"]
    if t == "tuple" or t.endswith("[]") and t[:-2] == "tuple" or t.startswith("tuple["):
        inner = "(" + ",".join(canon_type(c) for c in comp.get("components", [])) + ")"
        suffix = t[len("tuple"):]
        return inner + suffix
    return t


def canonical(item: dict) -> str:
    return item["name"] + "(" + ",".join(canon_type(i) for i in item.get("inputs", [])) + ")"


def event_key(item: dict, siblings: list) -> str:
    # Event names are unique per contract in this catalog (asserted below);
    # fall back to the canonical signature only if a future artifact overloads.
    names = [e["name"] for e in siblings]
    return item["name"] if names.count(item["name"]) == 1 else canonical(item)


def error_key(item: dict, siblings: list) -> str:
    names = [e["name"] for e in siblings if e.get("type") == "error"]
    return item["name"] if names.count(item["name"]) == 1 else canonical(item)


def resolve(hint: str, items: list, contract: str, kind: str) -> dict:
    """Resolve a 'name/argc[~substr]' hint to exactly one ABI item."""
    if "~" in hint:
        head, substr = hint.split("~", 1)
    else:
        head, substr = hint, None
    name, _, argc = head.partition("/")
    cands = [i for i in items if i["name"] == name]
    if argc != "":
        cands = [i for i in cands if len(i.get("inputs", [])) == int(argc)]
    if substr is not None:
        cands = [i for i in cands if substr in canonical(i)]
    # Byte-identical duplicate declarations (e.g. KuruAMMVault's double
    # InsufficientBalance()) collapse to one disposition target.
    unique: dict = {}
    for c in cands:
        unique.setdefault(canonical(c), c)
    cands = list(unique.values())
    if len(cands) != 1:
        raise SystemExit(
            f"CLASSIFICATION ERROR: hint {hint!r} in {contract}.{kind} matched "
            f"{len(cands)} items ({[canonical(c) for c in cands]})"
        )
    return cands[0]


# ---------------------------------------------------------------------------
# Shared disposition families (applied only where the family is actually
# present in a contract's ABI; coverage check still demands every item lands).
# ---------------------------------------------------------------------------

def F(access, application, screens=None):
    return {"access": access, "application": application, "screens": screens}


def E(consumedBy, application):
    return {"consumedBy": consumedBy, "application": application}


def R(userFacing, application):
    return {"userFacing": userFacing, "application": application}


SCREENS_CREATE = ["create"]
SCREENS_TRADE = ["trade"]
SCREENS_GRAD = ["graduation"]
SCREENS_KURU = ["kuru"]
SCREENS_PORTFOLIO = ["portfolio"]
SCREENS_CLAIMS = ["claims"]
SCREENS_DISCOVER = ["discover"]

OWN2_STEP_FNS = {
    "owner/0": F("READ", "Current owner; governance transparency only."),
    "pendingOwner/0": F("READ", "Two-step ownership handoff state."),
    "acceptOwnership/0": F("ADMIN_ONLY", "Incoming owner accepts handoff; not surfaced."),
    "transferOwnership/1": F("ADMIN_ONLY", "Owner-only; never surfaced."),
    "renounceOwnership/0": F("ADMIN_ONLY", "Disabled or admin-only across V2 contracts; never surfaced."),
}
OWN2_STEP_EV = {
    "OwnershipTransferStarted": E("NONE", "Admin lifecycle; indexer may archive."),
    "OwnershipTransferred": E("NONE", "Admin lifecycle; indexer may archive."),
}

ERC20_READ_FNS = {
    "name/0": F("READ", "Token display metadata."),
    "symbol/0": F("READ", "Token display metadata."),
    "decimals/0": F("READ", "Exact bigint display scaling."),
    "totalSupply/0": F("READ", "Supply stat for discover/portfolio."),
    "balanceOf/1": F("READ", "Wallet balance for portfolio/trade screens."),
    "allowance/2": F("READ", "Pre-write allowance check (approval prerequisite)."),
}
ERC20_WRITE_FNS = {
    "approve/2": F("USER_WRITE", "Allowance prerequisite for curve sell (spender=curve), ERC20-quote curve buy (spender=curve on pairToken), Kuru margin deposit (spender=MarginAccount) and non-margin Kuru market sell (spender=market)."),
    "transfer/2": F("NOT_SURFACED_WRITE", "Standard ERC20 transfer; wallet-native, out of app scope v1."),
    "transferFrom/3": F("NOT_SURFACED_WRITE", "Spender path not used by the app."),
}
ERC20_EV = {
    "Approval": E("BOTH", "Confirms allowance prerequisites."),
    "Transfer": E("BOTH", "Core token ledger for indexer and tx receipts."),
}

# ---------------------------------------------------------------------------
# Hand-authored classification (per contract -> dispositions).
# ---------------------------------------------------------------------------
# fn hints: "name/argc" (+ optional "~substr" when overloads need it)
# ---------------------------------------------------------------------------

CLASS: dict = {}

CLASS["RetroPickLaunchFactoryV2"] = {
    "role": "SURFACED",
    "summary": "Launch/config and fee administration authority; the app's entrypoint for token creation (msg.value == launchFee), graduation phase 1 (graduate) and the permissionless pool-seed completion (createGraduatedPool).",
    "fn": {
        # -- user launch surfaces -------------------------------------------------
        "launchToken/4~uint8)": F(
            "USER_WRITE",
            "Primary launch overload: TokenParams + launchConfigId + pairToken + GraduationVenue (UNISWAP_V4=0, KURU=1). payable msg.value == launchFee exactly.",
            SCREENS_CREATE),
        "launchToken/4~address[]": F(
            "USER_WRITE",
            "Launch overload with creator-declared snipe-tax exemption list (max 32); UNISWAP_V4 venue only.",
            SCREENS_CREATE),
        "launchToken/3": F(
            "NOT_SURFACED_WRITE",
            "Plain overload hardwired to UNISWAP_V4; subsumed by the venue overload passing venue=0."),
        "launchTokenFor/5": F(
            "PROTOCOL_INTERNAL",
            "Trusted launchForwarder router only (NotLaunchForwarder otherwise); must NOT be exposed."),
        # -- graduation lifecycle -------------------------------------------------
        "graduate/1": F(
            "LIFECYCLE_WRITE",
            "Permissionless graduation phase 1: drains curve into Coordinator (secure). Recovery path when AutoGraduationFailed.",
            SCREENS_GRAD),
        "createGraduatedPool/1": F(
            "LIFECYCLE_WRITE",
            "Permissionless graduation phase 2: seeds the venue pool via coordinator.complete and returns positionId. Retryable until success.",
            SCREENS_GRAD),
        "secureCurve/1": F(
            "PROTOCOL_INTERNAL",
            "One-hop callback only the Coordinator may invoke during secure()."),
        # -- reads the UI needs ---------------------------------------------------
        "launchConfigCount/0": F("READ", "Populates launch-config dropdown.", SCREENS_CREATE),
        "getLaunchConfig/1": F("READ", "Config fields (supply/fees/pool params) shown pre-launch.", SCREENS_CREATE),
        "previewLaunchEconomics/2": F("READ", "Quote economics digest for expectedEconomics pin (UNISWAP_V4 venue).", SCREENS_CREATE),
        "previewVenueEconomics/3": F("READ", "Economics digest per venue; the pin source for launchToken.", SCREENS_CREATE),
        "canLaunch/1": F("READ", "Gate the create form for the connected wallet.", SCREENS_CREATE),
        "launchEnabled/0": F("READ", "Public launch gate status.", SCREENS_CREATE),
        "whitelistedLaunchers/1": F("READ", "Whitelist check backing canLaunch.", SCREENS_CREATE),
        "launchFee/0": F("READ", "Exact payable amount for the create flow.", SCREENS_CREATE),
        "getLaunchedToken/1": F("READ", "Launch record + phase for detail/portfolio screens.", SCREENS_DISCOVER + SCREENS_TRADE),
        "getLaunchFeePolicy/1": F("READ", "Frozen fee split shown on token detail.", SCREENS_DISCOVER),
        "pendingCreatorFeeRecipient/1": F("READ", "Timelocked override visibility."),
        "maxCreatorTaxBps/0": F("READ", "Create-form validation bound.", SCREENS_CREATE),
        "snipeTaxStartBps/0": F("READ", "Display anti-snipe terms.", SCREENS_DISCOVER),
        "snipeTaxSeconds/0": F("READ", "Display anti-snipe decay window.", SCREENS_DISCOVER),
        "CREATOR_FEE_RECIPIENT_EXECUTION_WINDOW/0": F("READ", "Constant; documentation only."),
        "CREATOR_FEE_RECIPIENT_TIMELOCK/0": F("READ", "Constant; documentation only."),
        "GRADUATION_RESCUE_DELAY/0": F("READ", "Constant; documentation only."),
        "graduationCoordinator/0": F("READ", "Wiring address for SDK resolution."),
        "launchDeployer/0": F("READ", "Wiring address."),
        "launchForwarder/0": F("READ", "Wiring address; forwarder is not surfaced."),
        "permit2/0": F("READ", "Wiring address (external infra reference)."),
        "poolManager/0": F("READ", "Wiring address (external infra reference)."),
        "positionManager/0": F("READ", "Wiring address (external infra reference)."),
        "locker/0": F("READ", "Wiring address."),
        "memeHook/0": F("READ", "Wiring address."),
        "feeEscrow/0": F("READ", "Wiring address for claims flow."),
        "buybackVault/0": F("READ", "Wiring address for claims flow."),
        "quoteAssetPolicy/0": F("READ", "Wiring address."),
        "quoteRegistry/0": F("READ", "Wiring address."),
        "owner/0": OWN2_STEP_FNS["owner/0"],
        "pendingOwner/0": OWN2_STEP_FNS["pendingOwner/0"],
        # -- creator/owner operations not surfaced in v1 ---------------------------
        "transferCreatorFeeRecipient/2": F("NOT_SURFACED_WRITE", "Creator self-service recipient handoff; future creator-settings screen."),
        "setBuybackEnabled/2": F("NOT_SURFACED_WRITE", "Creator may enable / owner may disable buyback routing; future creator-settings screen."),
        "executeCreatorFeeRecipientChange/1": F("NOT_SURFACED_WRITE", "Permissionless execution of a matured owner proposal; keep out of v1 UI."),
        # -- admin-only ------------------------------------------------------------
        "addLaunchConfig/1": F("ADMIN_ONLY", "Owner adds launch configs."),
        "updateLaunchConfig/2": F("ADMIN_ONLY", "Owner replaces a config."),
        "setLaunchFee/1": F("ADMIN_ONLY", "Owner fee change."),
        "setLaunchEnabled/1": F("ADMIN_ONLY", "Owner public-gate switch."),
        "setWhitelistedLauncher/2": F("ADMIN_ONLY", "Owner whitelist edit."),
        "setMaxCreatorTaxBps/1": F("ADMIN_ONLY", "Owner ceiling change."),
        "setSnipeTaxStartBps/1": F("ADMIN_ONLY", "Owner snipe-tax term."),
        "setSnipeTaxSeconds/1": F("ADMIN_ONLY", "Owner snipe-tax window."),
        "configureVenueExecutor/2": F("ADMIN_ONLY", "Owner wires venue executors via coordinator."),
        "setLaunchDeployer/1": F("ADMIN_ONLY", "One-time deployer wiring."),
        "setLaunchForwarder/1": F("ADMIN_ONLY", "Owner router rotation."),
        "setCreatorFeeRecipient/2": F("ADMIN_ONLY", "Owner timelocked override proposal."),
        "cancelCreatorFeeRecipientChange/1": F("ADMIN_ONLY", "Owner cancels pending override."),
        "rescueCurveFees/1": F("ADMIN_ONLY", "Owner-only fee rescue for a wedged quote asset."),
        "acceptOwnership/0": OWN2_STEP_FNS["acceptOwnership/0"],
        "transferOwnership/1": OWN2_STEP_FNS["transferOwnership/1"],
        "renounceOwnership/0": OWN2_STEP_FNS["renounceOwnership/0"],
    },
    "ev": {
        "TokenLaunched": E("BOTH", "Discovery anchor: token+curve+deployer+pairToken+configId+threshold."),
        "PoolGraduated": E("BOTH", "V4 venue completion: positionId and seeded amounts."),
        "LaunchSwept": E("INDEXER", "Phase-1 intermediate (curve drained to factory)."),
        "LaunchForceSwept": E("INDEXER", "Historical force path."),
        "LaunchGraduationRescued": E("INDEXER", "Owner rescue of swept reserves."),
        "GraduationTokensPermanentlyLocked": E("INDEXER", "V4 locker permanence signal."),
        "BuybackEnabledUpdated": E("INDEXER", "Buyback flag change."),
        "CreatorFeeRecipientUpdated": E("INDEXER", "Creator fee routing change."),
        "CreatorFeeRecipientChangeProposed": E("INDEXER", "Timelock notice."),
        "CreatorFeeRecipientChangeCancelled": E("INDEXER", "Timelock cancel."),
        "LaunchConfigAdded": E("INDEXER", "Config catalog growth."),
        "LaunchConfigUpdated": E("INDEXER", "Config change (new launches only)."),
        "LaunchFeeUpdated": E("INDEXER", "Fee change alert for create flow."),
        "LaunchEnabledUpdated": E("INDEXER", "Public gate toggle."),
        "WhitelistedLauncherUpdated": E("INDEXER", "Whitelist edit."),
        "MaxCreatorTaxUpdated": E("INDEXER", "Ceiling change."),
        "SnipeTaxStartBpsUpdated": E("INDEXER", "Snipe term change."),
        "SnipeTaxSecondsUpdated": E("INDEXER", "Snipe window change."),
        "GraduationExecutorSet": E("INDEXER", "Venue wiring change."),
        "LaunchDeployerSet": E("NONE", "One-time wiring."),
        "LaunchForwarderSet": E("NONE", "Router wiring."),
        "PairTokenApprovalUpdated": E("INDEXER", "Quote admission change."),
        "PairTokenEconomicsUpdated": E("INDEXER", "Quote economics change."),
        **OWN2_STEP_EV,
    },
    "err": {
        "NotWhitelisted": R(True, "Create form: wallet may not launch (gate closed, not whitelisted)."),
        "LaunchFeeNotPaid": R(True, "Create form: msg.value must equal launchFee exactly."),
        "InvalidLaunchConfigId": R(True, "Create form: chosen config id out of range."),
        "LaunchConfigDisabled": R(True, "Create form: config disabled by owner."),
        "InvalidTokenParams": R(True, "Create form: empty name/symbol."),
        "CreatorTaxTooHigh": R(True, "Create form: creatorTaxBps exceeds maxCreatorTaxBps."),
        "CombinedFeeTooHigh": R(True, "Create form: fee legs exceed combined ceiling."),
        "CurveNotQuotable": R(True, "Create form: phantom/supply terms price a reference buy to zero."),
        "LaunchEconomicsMismatch": R(True, "Create form: expectedEconomics pin differs from current terms (owner re-pegged); re-quote."),
        "GraduationExecutorNotSet": R(True, "Venue executor unwired; pick the other venue or retry later."),
        "LaunchDeployerNotSet": R(True, "Stack wiring incomplete."),
        "LaunchDependenciesNotWired": R(True, "Stack wiring incomplete."),
        "ExemptionListTooLong": R(True, "Create form: >32 exemption wallets."),
        "TokenNotFound": R(True, "Graduation: token not launched by this factory."),
        "WrongGraduationPhase": R(True, "Graduation: launch not in the phase this action expects."),
        "GraduationStillViable": R(True, "Historical guard; decode for completeness."),
        "NothingToGraduate": R(True, "Historical guard; decode for completeness."),
        "InvalidBasisPoints": R(False, "Admin config validation."),
        "CurveFeeTooHigh": R(False, "Admin config validation."),
        "SupplyTooLow": R(False, "Admin config validation."),
        "SupplyTooHigh": R(False, "Admin config validation (int128 seed ceiling)."),
        "InvalidPhantomQuote": R(False, "Admin config validation."),
        "InvalidGraduationThreshold": R(False, "Admin config validation."),
        "InvalidTickSpacing": R(False, "Admin config validation."),
        "CoreLpFeeMustBeZero": R(False, "Admin config validation (v4 hook pool)."),
        "InvalidSnipeTaxWindow": R(False, "Admin config validation."),
        "ZeroAddress": R(False, "Generic wiring/param guard."),
        "AlreadySet": R(False, "One-time wiring guard."),
        "OwnershipCannotBeRenounced": R(False, "Disabled renounce."),
        "FeeTransferFailed": R(True, "Launch fee forward failed; retryable."),
        "NotLaunchForwarder": R(False, "launchTokenFor guard; never surfaced."),
        "NotCreatorFeeRecipient": R(False, "Creator self-service guard (not surfaced v1)."),
        "NotBuybackController": R(False, "Buyback flag guard (not surfaced v1)."),
        "NoPendingChange": R(False, "Timelock guard."),
        "TimelockNotElapsed": R(True, "Override not matured (carries effectiveAt)."),
        "TimelockExpired": R(True, "Override window passed (carries expiresAt)."),
        "InexactTransfer": R(False, "Exact-transfer guard on fee forwards."),
        "SqrtPriceOutOfBounds": R(False, "Seed preflight failure surfaced during completion."),
        "GraduationSeedNotViable": R(True, "V4 seed preflight failure during completion."),
        "GraduationRescueTooEarly": R(True, "Owner rescue before GRADUATION_RESCUE_DELAY (carries availableAt)."),
        "PairTokenNotApproved": R(True, "Quote asset rejected by registry."),
        "PairTokenValidationFailed": R(True, "Quote asset identity check failed."),
        "PairTokenEconomicsInvalid": R(False, "Admin quote economics validation."),
        "OwnableInvalidOwner": R(False, "OZ boilerplate."),
        "OwnableUnauthorizedAccount": R(False, "OZ admin guard."),
        "ReentrancyGuardReentrantCall": R(False, "Reentrancy guard tripped; indicates a non-standard caller."),
    },
}

CLASS["RetroPickQuoteAssetRegistryV2"] = {
    "role": "SUPPORTING",
    "summary": "Versioned quote-asset admission pinned to chain 10143; the app reads admission and config to validate create-form quote choices and to price displays.",
    "fn": {
        "admitted/2": F("READ", "Quote admission check per venue before launch; reverts UnsupportedQuote.", SCREENS_CREATE),
        "isSupportedQuote/1": F("READ", "Cheap boolean admission check.", SCREENS_CREATE),
        "getConfig/1": F("READ", "Full QuoteAssetConfig (phantomQuote/threshold/ceiling/venueMask) for display.", SCREENS_CREATE),
        "validateQuote/2": F("READ", "Decimals-aware validation used by integrations."),
        "CIRCLE_TEST_USDC/0": F("READ", "Canonical USDC address constant.", SCREENS_CREATE),
        "TARGET_CHAIN_ID/0": F("READ", "Chain pin constant."),
        "owner/0": OWN2_STEP_FNS["owner/0"],
        "pendingOwner/0": OWN2_STEP_FNS["pendingOwner/0"],
        "configure/2": F("ADMIN_ONLY", "Owner quote admission/parameter updates."),
        "acceptOwnership/0": OWN2_STEP_FNS["acceptOwnership/0"],
        "transferOwnership/1": OWN2_STEP_FNS["transferOwnership/1"],
        "renounceOwnership/0": OWN2_STEP_FNS["renounceOwnership/0"],
    },
    "ev": {
        "QuoteAssetConfigured": E("INDEXER", "Quote admission/parameter change; refresh create-form quote options."),
        **OWN2_STEP_EV,
    },
    "err": {
        "UnsupportedQuote": R(True, "Create form: quote not enabled or venue not in venueMask."),
        "InvalidQuoteConfig": R(False, "Admin validation."),
        "WrongChain": R(True, "Wrong network; switch to Monad Testnet 10143."),
        "OwnableInvalidOwner": R(False, "OZ boilerplate."),
        "OwnableUnauthorizedAccount": R(False, "OZ admin guard."),
    },
}

CLASS["RetroPickLauncherTokenV2"] = {
    "role": "SURFACED",
    "summary": "Per-launch fixed-supply ERC20 (template ABI resolved from TokenLaunched); full supply mints to its curve. App surfaces reads, metadata and the approve needed for curve sells and Kuru trading.",
    "fn": {
        **ERC20_READ_FNS,
        "approve/2": ERC20_WRITE_FNS["approve/2"],
        "transfer/2": ERC20_WRITE_FNS["transfer/2"],
        "transferFrom/3": ERC20_WRITE_FNS["transferFrom/3"],
        "burn/1": F("NOT_SURFACED_WRITE", "Voluntary holder burn; not part of app flows."),
        "burnFrom/2": F("NOT_SURFACED_WRITE", "Spender burn; not used."),
        "curve/0": F("READ", "Resolve the token's bonding curve for trade screen.", SCREENS_TRADE),
        "launchFactory/0": F("READ", "Attribution wiring.", SCREENS_DISCOVER),
        "deployer/0": F("READ", "Creator attribution on discover screen.", SCREENS_DISCOVER),
        "logo/0": F("READ", "Token artwork.", SCREENS_DISCOVER),
        "description/0": F("READ", "Token description.", SCREENS_DISCOVER),
        "socials/0": F("READ", "Five social fields for token detail.", SCREENS_DISCOVER),
        "getTokenInfo/0": F("READ", "Creator+metadata tuple in one call.", SCREENS_DISCOVER),
    },
    "ev": ERC20_EV,
    "err": {
        "ERC20InsufficientAllowance": R(True, "Approve prerequisite missing (curve sell / margin deposit / market sell)."),
        "ERC20InsufficientBalance": R(True, "Insufficient token balance for the write."),
        "ERC20InvalidApprover": R(False, "OZ boilerplate."),
        "ERC20InvalidReceiver": R(False, "OZ boilerplate."),
        "ERC20InvalidSender": R(False, "OZ boilerplate."),
        "ERC20InvalidSpender": R(False, "OZ boilerplate."),
        "ZeroAddress": R(False, "Constructor guard."),
    },
}

CLASS["RetroPickBondingCurveV2"] = {
    "role": "SURFACED",
    "summary": "Per-launch constant-product curve trading the launch token against its quote (native MON when pairToken==address(0)); app surfaces buy/sell plus reserve/graduation reads. Address resolved per launch from TokenLaunched.",
    "fn": {
        "buy/3": F(
            "USER_WRITE",
            "Buy launch tokens: native quote -> msg.value == quoteIn exactly; ERC20 quote -> msg.value == 0 with pairToken approved to the curve. Partial fill refunds excess.",
            SCREENS_TRADE),
        "sell/3": F(
            "USER_WRITE",
            "Sell launch tokens back: token approve -> curve, then transferFrom; minQuoteOut bounds the quote leg.",
            SCREENS_TRADE),
        "getReserves/0": F("READ", "Tradeable (quote, token) reserves for price chart.", SCREENS_TRADE),
        "quoteReserve/0": F("READ", "Tradeable quote reserve.", SCREENS_TRADE),
        "tokenReserve/0": F("READ", "Tradeable token reserve.", SCREENS_TRADE),
        "realQuoteReserve/0": F("READ", "Physical tradeable quote backing.", SCREENS_TRADE),
        "readyToGraduate/0": F("READ", "Graduation progress flag for UI state.", SCREENS_TRADE + SCREENS_GRAD),
        "graduated/0": F("READ", "Terminal flag; route UI to venue trading.", SCREENS_TRADE),
        "sellableTokens/0": F("READ", "Tokens left before graduation; progress denominator.", SCREENS_TRADE),
        "reservedTokens/0": F("READ", "Pool allocation held back for the venue seed.", SCREENS_TRADE),
        "graduationThreshold/0": F("READ", "Quote threshold for graduation progress bar.", SCREENS_TRADE),
        "graduationQuoteCeiling/0": F("READ", "Completion ceiling; buys beyond it revert."),
        "phantomQuote/0": F("READ", "Virtual reserve term for off-chain price math.", SCREENS_TRADE),
        "feeBps/0": F("READ", "Base trade fee for price preview.", SCREENS_TRADE),
        "creatorTaxBps/0": F("READ", "Creator tax for price preview.", SCREENS_TRADE),
        "quoteFeeBalance/0": F("READ", "Pending fee bucket."),
        "creatorTaxBalance/0": F("READ", "Pending creator tax bucket."),
        "buybackQuoteBalance/0": F("READ", "Buyback earmark within pending fees."),
        "buybackEnabled/0": F("READ", "Buyback routing flag shown on token detail.", SCREENS_DISCOVER),
        "buybackBurnBps/0": F("READ", "Buyback slice bps.", SCREENS_DISCOVER),
        "protocolFeeShareBps/0": F("READ", "Protocol split shown on token detail.", SCREENS_DISCOVER),
        "maxInternalPriceImpactBps/0": F("READ", "Internal buyback impact bound."),
        "protocolFeeRecipient/0": F("READ", "Split recipient."),
        "buybackCreatorRecipient/0": F("READ", "Buyback vest beneficiary."),
        "deployer/0": F("READ", "Current creator fee recipient (mutable via factory).", SCREENS_DISCOVER),
        "isNativeQuote/0": F("READ", "Drives native-vs-ERC20 branch of buy.", SCREENS_TRADE),
        "pairToken/0": F("READ", "Quote asset address (0x0 = native MON).", SCREENS_TRADE),
        "token/0": F("READ", "Launch token address.", SCREENS_TRADE),
        "factory/0": F("READ", "Wiring."),
        "feePolicy/0": F("READ", "Wiring."),
        "feeEscrow/0": F("READ", "Wiring."),
        "buybackVault/0": F("READ", "Wiring."),
        "trackedQuote/0": F("READ", "Accounting reserve (pricing invariant monitoring)."),
        "trackedTokens/0": F("READ", "Accounting reserve."),
        "completionQuote/0": F("READ", "Terminal quote math (ceiling preflight)."),
        "completionTerminalQuote/0": F("READ", "Terminal quote figure."),
        "initialize/1": F("PROTOCOL_INTERNAL", "Factory-only one-shot wiring of the token."),
        "graduate/1": F("PROTOCOL_INTERNAL", "Coordinator/factory-only sweep; the user path is factory.graduate."),
        "exemptFromSnipeTax/1": F("PROTOCOL_INTERNAL", "Factory-only exemption write."),
        "setCreatorFeeRecipient/1": F("PROTOCOL_INTERNAL", "Factory-gated forwarder."),
        "setBuybackEnabled/1": F("PROTOCOL_INTERNAL", "Factory-gated forwarder."),
        "sweepFees/1": F("NOT_SURFACED_WRITE", "Fee-sweep operator or creator; keeper/admin flow, not v1 UI."),
        "rescueFees/0": F("ADMIN_ONLY", "Factory-owner rescue path."),
    },
    "ev": {
        "CurveBuy": E("BOTH", "Trade receipt: buyer/recipient/quoteIn/tokensOut/fee/tax."),
        "CurveSell": E("BOTH", "Trade receipt: seller/recipient/tokensIn/quoteOut/fee/tax."),
        "CurveBuyRefunded": E("UI", "Partial-fill refund amount on threshold-crossing buys."),
        "CurveCompleted": E("INDEXER", "Reserves handed to graduation custody."),
        "AutoGraduationFailed": E("BOTH", "Keeper signal: launch ready but ungraduated; UI shows retry affordance."),
        "BuybackLocked": E("INDEXER", "Buyback slice locked into the vest."),
        "FeesSwept": E("INDEXER", "Fee distribution record."),
        "FeesRescued": E("INDEXER", "Owner rescue record."),
        "BuybackEnabledUpdated": E("INDEXER", "Flag change."),
        "CreatorFeeRecipientUpdated": E("INDEXER", "Routing change."),
        "Initialized": E("INDEXER", "Token wiring anchor."),
    },
    "err": {
        "CurveGraduated": R(True, "Trade: curve closed (graduated or sellable exhausted); route to venue."),
        "ZeroAmount": R(True, "Trade: zero-sized input."),
        "ZeroAddress": R(True, "Trade: zero recipient."),
        "SlippageExceeded": R(True, "Trade: price bound violated (actual, minimum)."),
        "NativeValueMismatch": R(True, "Native buy: msg.value must equal quoteIn (supplied, expected)."),
        "UnexpectedNativeValue": R(True, "ERC20-quote buy must send value 0."),
        "InexactQuoteTransfer": R(True, "Fee-on-transfer/surcharge quote asset rejected (expected, actual)."),
        "QuoteBackingDeficit": R(True, "Curve accounting broken vs physical balance; do not retry, report."),
        "CompletionCeilingExceeded": R(True, "Buy would push terminal completion beyond graduationQuoteCeiling (terminal, ceiling)."),
        "NotReadyToGraduate": R(True, "Graduation before threshold."),
        "AlreadyGraduated": R(True, "Double graduation attempt."),
        "AlreadyInitialized": R(False, "Wiring guard."),
        "NotInitialized": R(False, "Wiring guard."),
        "NotFactory": R(False, "Internal guard."),
        "NotFeeSweepOperator": R(False, "Sweep guard (not surfaced)."),
        "InternalSwapRequiresOperator": R(False, "Sweep guard (not surfaced)."),
        "InvalidFeePolicy": R(False, "Launch-time policy validation."),
        "InvalidLaunchEconomics": R(False, "Launch-time economics validation."),
        "MinimumOutputRequired": R(False, "Sweep requires explicit buyback floor."),
        "TransferFailed": R(True, "Native payout failed; retryable."),
        "CompletionOverflow": R(False, "Terminal math overflow guard."),
        "InsufficientInputAmount": R(False, "Math library guard."),
        "InsufficientLiquidity": R(False, "Math library guard."),
        "InsufficientOutputAmount": R(False, "Math library guard."),
        "InvalidCompletionState": R(False, "Completion math guard."),
        "ReentrancyGuardReentrantCall": R(False, "Reentrancy guard."),
        "SafeERC20FailedOperation": R(False, "Token transfer failure wrapper."),
    },
}

CLASS["GraduationCoordinatorV2"] = {
    "role": "SUPPORTING",
    "summary": "Sole graduation ledger: secures drained curve reserves and completes venue seeding. The app reads ledger/packet/receipt state and drives lifecycle through the factory wrappers (graduate / createGraduatedPool).",
    "fn": {
        "ledger/1": F("READ", "Phase + secured/consumed amounts; drives UI graduation state.", SCREENS_GRAD),
        "available/1": F("READ", "Unconsumed secured reserves while GRADUATING.", SCREENS_GRAD),
        "packet/1": F("READ", "Launch-time graduation commitment (venue, executor, terms).", SCREENS_GRAD),
        "receipt/1": F("READ", "Completion receipt: market/vault/positionId/protected amounts.", SCREENS_GRAD + SCREENS_KURU),
        "quoteLiability/1": F("READ", "Secured quote custody accounting."),
        "executors/1": F("READ", "Venue executor resolution (0=UNISWAP_V4, 1=KURU).", SCREENS_GRAD),
        "factory/0": F("READ", "Wiring."),
        "previewEconomics/3": F("READ", "Economics digest source backing factory previews.", SCREENS_CREATE),
        "secure/1": F("PROTOCOL_INTERNAL", "onlyFactory; user path is factory.graduate."),
        "complete/1": F("LIFECYCLE_WRITE", "Permissionless phase-2 completion; app uses factory.createGraduatedPool wrapper (returns positionId).", SCREENS_GRAD),
        "registerLaunch/5": F("PROTOCOL_INTERNAL", "onlyFactory launch registration."),
        "configureExecutor/2": F("ADMIN_ONLY", "onlyFactory (owner) executor wiring."),
        "bindFactory/1": F("ADMIN_ONLY", "Owner one-time factory binding."),
        "owner/0": OWN2_STEP_FNS["owner/0"],
        "pendingOwner/0": OWN2_STEP_FNS["pendingOwner/0"],
        "acceptOwnership/0": OWN2_STEP_FNS["acceptOwnership/0"],
        "transferOwnership/1": OWN2_STEP_FNS["transferOwnership/1"],
        "renounceOwnership/0": OWN2_STEP_FNS["renounceOwnership/0"],
    },
    "ev": {
        "LaunchCommitted": E("INDEXER", "Launch bound to its venue packet."),
        "GraduationSecured": E("BOTH", "Phase 1 done: reserves in custody (quote, launchTokens)."),
        "GraduationCompleted": E("BOTH", "Phase 2 done: destinationIdentity + receiptHash; discovery anchor for venue."),
        "ExecutorConfigured": E("INDEXER", "Venue wiring change."),
        "FactoryBound": E("NONE", "One-time wiring."),
        **OWN2_STEP_EV,
    },
    "err": {
        "WrongPhase": R(True, "Graduation action inconsistent with ledger phase."),
        "InvalidPacket": R(True, "Packet/venue terms invalid at graduation; report, do not blind-retry."),
        "InexactHandoff": R(True, "Secure handoff amount mismatch; report."),
        "InvalidReceipt": R(True, "Executor receipt validation failed; report."),
        "BackingDeficit": R(True, "Custody backing broken; report."),
        "InvalidBinding": R(False, "Wiring guard."),
        "UnsafeAllowance": R(False, "Exact-allowance guard on executor spend."),
        "Unauthorized": R(False, "onlyFactory guard."),
        "OwnableInvalidOwner": R(False, "OZ boilerplate."),
        "OwnableUnauthorizedAccount": R(False, "OZ admin guard."),
        "ReentrancyGuardReentrantCall": R(False, "Reentrancy guard."),
        "SafeERC20FailedOperation": R(False, "Token transfer failure wrapper."),
    },
}

CLASS["KuruGraduationExecutorV2"] = {
    "role": "INTERNAL_INFRA",
    "summary": "Atomic Kuru venue worker: only the Coordinator may call execute(); deploys the deterministic Kuru market+vault, deposits the seed, and deploys the per-launch KuruLiquidityLockV2 holding protected LP shares and excess tokens.",
    "fn": {
        "execute/3": F("PROTOCOL_INTERNAL", "onlyCoordinator; coordinator.complete drives it."),
        "validateLaunch/2": F("READ", "Preflight validation (view) used by coordinator registration."),
        "previewReceiver/1": F("READ", "Deterministic KuruLiquidityLockV2 address derivation."),
        "verifyReceipt/2": F("READ", "Receipt verification (view) run by the coordinator."),
        "coordinator/0": F("READ", "Wiring."),
        "environment/0": F("READ", "Wiring."),
        "donationLock/0": F("READ", "Wiring."),
        "policyHash/0": F("READ", "Pinned venue policy hash."),
    },
    "ev": {
        "UnsolicitedAssetsLocked": E("INDEXER", "Quarantined stray transfers; anomaly signal."),
    },
    "err": {
        "Unauthorized": R(False, "onlyCoordinator guard."),
        "InvalidPacket": R(False, "Packet/policy validation."),
        "InvalidMarket": R(False, "Market deployment/verification mismatch."),
        "InvalidDeposit": R(False, "Vault deposit/opening validation."),
        "ResidualOrAllowance": R(False, "Zero-residual invariant."),
        "DonationTransferFailed": R(False, "Quarantine failure."),
        "InexactAssetTransfer": R(False, "Exact-transfer guard."),
        "OutsideQualifiedDomain": R(False, "Environment pin guard."),
        "ReentrancyGuardReentrantCall": R(False, "Reentrancy guard."),
        "SafeERC20FailedOperation": R(False, "Token transfer failure wrapper."),
    },
}

CLASS["UniswapV4GraduationExecutorV2"] = {
    "role": "INTERNAL_INFRA",
    "summary": "Atomic Uniswap V4 venue worker: only the Coordinator may call execute(); initializes the v4 pool with the hook, mints the full-range position into the locker, and registers the pool with the meme hook.",
    "fn": {
        "execute/3": F("PROTOCOL_INTERNAL", "onlyCoordinator; coordinator.complete drives it."),
        "validateLaunch/2": F("READ", "Preflight validation (view)."),
        "previewReceiver/1": F("READ", "Deterministic protected receiver derivation (locker)."),
        "verifyReceipt/2": F("READ", "Receipt verification (view)."),
        "coordinator/0": F("READ", "Wiring."),
        "policyHash/0": F("READ", "Pinned venue policy hash."),
        "donationLock/0": F("READ", "Wiring."),
        "feeEscrow/0": F("READ", "Wiring."),
        "guard/0": F("READ", "Wiring (GraduationGuard)."),
        "locker/0": F("READ", "Wiring."),
        "memeHook/0": F("READ", "Wiring."),
        "permit2/0": F("READ", "Wiring."),
        "poolManager/0": F("READ", "Wiring."),
        "positionManager/0": F("READ", "Wiring."),
    },
    "ev": {
        "UnsolicitedAssetsLocked": E("INDEXER", "Quarantined stray transfers; anomaly signal."),
    },
    "err": {
        "Unauthorized": R(False, "onlyCoordinator guard."),
        "InvalidPacket": R(False, "Packet/policy validation."),
        "InvalidPosition": R(False, "V4 position validation."),
        "ResidualOrAllowance": R(False, "Zero-residual invariant."),
        "DonationTransferFailed": R(False, "Quarantine failure."),
        "InexactAssetTransfer": R(False, "Exact-transfer guard."),
        "UnsupportedPrice": R(True, "Seed price outside v4 sqrt bounds; surfaced from completion retry."),
        "ZeroAmount": R(False, "Guard."),
        "ReentrancyGuardReentrantCall": R(False, "Reentrancy guard."),
        "SafeERC20FailedOperation": R(False, "Token transfer failure wrapper."),
    },
}

CLASS["KuruEnvironmentV2"] = {
    "role": "SUPPORTING",
    "summary": "Fail-closed commitment to the qualified Kuru Monad-testnet environment (router/margin/implementations/codehashes); read-only anchor for SDK environment validation.",
    "fn": {
        "validate/0": F("READ", "Reverts EnvironmentDrift if the pinned Kuru environment changed; SDK health check."),
        "ROUTER/0": F("READ", "Pinned Kuru router address."),
        "MARGIN/0": F("READ", "Pinned MarginAccount address used by trading flows.", SCREENS_KURU),
        "ORDERBOOK_IMPL/0": F("READ", "Pinned implementation hash anchor."),
        "ORDERBOOK_HASH/0": F("READ", "Pinned bytecode hash anchor."),
        "VAULT_IMPL/0": F("READ", "Pinned implementation anchor."),
        "VAULT_HASH/0": F("READ", "Pinned bytecode hash anchor."),
        "PROXY_HASH/0": F("READ", "Pinned proxy bytecode hash anchor."),
        "ENVIRONMENT_HASH/0": F("READ", "Composite environment commitment."),
    },
    "ev": {},
    "err": {
        "EnvironmentDrift": R(True, "Kuru environment no longer matches the qualified pin; halt Kuru flows."),
    },
}

CLASS["KuruLiquidityLockV2"] = {
    "role": "SUPPORTING",
    "summary": "Per-launch permanent custody deployed by the Kuru executor: holds vault LP shares and excess launch tokens with no owner, approval or withdrawal entrypoint; read-only for the app.",
    "fn": {
        "protectedBalances/0": F("READ", "Protected LP shares + excess tokens; token-detail stats.", SCREENS_KURU + SCREENS_PORTFOLIO),
        "launchToken/0": F("READ", "Binding check.", SCREENS_KURU),
        "quoteToken/0": F("READ", "Binding check."),
        "market/0": F("READ", "Resolve the market for kuru trading.", SCREENS_KURU),
        "vault/0": F("READ", "Resolve the LP vault.", SCREENS_KURU),
    },
    "ev": {},
    "err": {
        "InvalidBinding": R(False, "Constructor guard."),
    },
}

CLASS["RetroPickFeeEscrowV2"] = {
    "role": "SURFACED",
    "summary": "Asset-segregated pull-payment ledger for launch fees and vested buyback tokens; the claims screen surfaces claim/claimToken (full and partial) against the wallet's escrow balances.",
    "fn": {
        "claim/0": F("USER_WRITE", "Claim all native (MON) escrow balance to msg.sender.", SCREENS_CLAIMS),
        "claim/1": F("USER_WRITE", "Claim a partial native amount.", SCREENS_CLAIMS),
        "claimToken/1": F("USER_WRITE", "Claim all escrowed balance of one token (e.g. vested launch tokens).", SCREENS_CLAIMS),
        "claimToken/2": F("USER_WRITE", "Claim a partial escrowed token amount.", SCREENS_CLAIMS),
        "balanceOf/1": F("READ", "Wallet's native escrow balance.", SCREENS_CLAIMS + SCREENS_PORTFOLIO),
        "balanceOfToken/2": F("READ", "Wallet's per-token escrow balance.", SCREENS_CLAIMS + SCREENS_PORTFOLIO),
        "totalNativeLiability/0": F("READ", "Escrow solvency monitor."),
        "totalTokenLiability/1": F("READ", "Escrow solvency monitor."),
        "credit/1": F("PROTOCOL_INTERNAL", "Protocol sweep credit (curve/hook/vault); not user-called."),
        "creditToken/3": F("PROTOCOL_INTERNAL", "Protocol sweep credit for ERC20 revenue."),
    },
    "ev": {
        "NativeCredited": E("INDEXER", "Revenue credited to a recipient's escrow."),
        "TokenCredited": E("INDEXER", "Token revenue credited (incl. vested buyback releases)."),
        "NativeClaimed": E("BOTH", "Claims receipt (native)."),
        "TokenClaimed": E("BOTH", "Claims receipt (token)."),
    },
    "err": {
        "ZeroAmount": R(True, "Claims: nothing to claim / zero amount requested."),
        "InsufficientCredit": R(True, "Claims: requested amount exceeds escrow balance."),
        "ZeroAddress": R(False, "Guard."),
        "TransferFailed": R(True, "Native payout failed; retryable."),
        "InexactTokenTransfer": R(True, "Token payout delta mismatch; report."),
        "PhysicalBalanceDeficit": R(True, "Escrow under-backed; report, do not retry."),
        "ReentrancyGuardReentrantCall": R(False, "Reentrancy guard."),
        "SafeERC20FailedOperation": R(False, "Token transfer failure wrapper."),
    },
}

CLASS["RetroPickBuybackVaultV2"] = {
    "role": "SURFACED",
    "summary": "Five-year weighted-average vest for bought-back launch tokens, split creator/protocol on the launch's frozen share; beneficiaries surface release() and vest progress reads.",
    "fn": {
        "release/1": F("USER_WRITE", "Release vested tokens for a launch; caller must be the vest's creator or protocol recipient (payouts land in FeeEscrow).", SCREENS_CLAIMS),
        "releasable/1": F("READ", "Currently releasable amount.", SCREENS_CLAIMS + SCREENS_PORTFOLIO),
        "vestedAmount/1": F("READ", "Vested-to-date (released or not).", SCREENS_PORTFOLIO),
        "totalLocked/1": F("READ", "Lifetime locked amount.", SCREENS_PORTFOLIO),
        "totalReleased/1": F("READ", "Lifetime released amount.", SCREENS_PORTFOLIO),
        "vestingStart/1": F("READ", "Weighted-average start (reporting only)."),
        "vestingTerms/1": F("READ", "Active epoch beneficiaries + split.", SCREENS_CLAIMS),
        "VESTING_DURATION/0": F("READ", "5-year constant for projections."),
        "factory/0": F("READ", "Wiring."),
        "feeEscrow/0": F("READ", "Wiring."),
        "feePolicy/0": F("READ", "Wiring."),
        "lock/5": F("PROTOCOL_INTERNAL", "Curve/hook-only buyback lock entrypoint."),
        "updateCreatorRecipient/2": F("PROTOCOL_INTERNAL", "Factory-gated redirect."),
        "setFactory/1": F("ADMIN_ONLY", "One-time wiring."),
        "owner/0": OWN2_STEP_FNS["owner/0"],
        "pendingOwner/0": OWN2_STEP_FNS["pendingOwner/0"],
        "acceptOwnership/0": OWN2_STEP_FNS["acceptOwnership/0"],
        "transferOwnership/1": OWN2_STEP_FNS["transferOwnership/1"],
        "renounceOwnership/0": OWN2_STEP_FNS["renounceOwnership/0"],
    },
    "ev": {
        "Locked": E("INDEXER", "New buyback deposit + shifted vesting start."),
        "Released": E("BOTH", "Release receipt with creator/protocol split."),
        "VestingTermsSnapshotted": E("INDEXER", "New epoch terms."),
        "CreatorRecipientUpdated": E("INDEXER", "Beneficiary redirect."),
        "FactorySet": E("NONE", "One-time wiring."),
        **OWN2_STEP_EV,
    },
    "err": {
        "NotVestBeneficiary": R(True, "Release: caller is neither creator nor protocol beneficiary."),
        "NotFactory": R(False, "Internal guard."),
        "NotAuthorizedLocker": R(False, "Internal guard."),
        "InvalidVestingTerms": R(False, "Lock validation."),
        "VestingTermsMismatch": R(False, "Epoch consistency guard."),
        "AlreadyInitialized": R(False, "Wiring guard."),
        "ZeroAddress": R(False, "Guard."),
        "OwnershipCannotBeRenounced": R(False, "Disabled renounce."),
        "OwnableInvalidOwner": R(False, "OZ boilerplate."),
        "OwnableUnauthorizedAccount": R(False, "OZ admin guard."),
        "ReentrancyGuardReentrantCall": R(False, "Reentrancy guard."),
        "SafeERC20FailedOperation": R(False, "Token transfer failure wrapper."),
    },
}

CLASS["MarginAccount"] = {
    "role": "SURFACED",
    "summary": "Kuru cross-market balance hub: users deposit quote/base assets (native MON via address(0) + msg.value) and markets debit/credit against those balances; the app surfaces deposit/withdraw and balance reads for Kuru trading.",
    "fn": {
        "deposit/3": F(
            "USER_WRITE",
            "Deposit for trading: (user, token, amount); native MON token=address(0) with msg.value == amount exactly; ERC20 (launch token) with msg.value == 0 and token approved to MarginAccount.",
            SCREENS_KURU),
        "withdraw/2": F("USER_WRITE", "Withdraw (amount, token) from the caller's margin balance.", SCREENS_KURU + SCREENS_PORTFOLIO),
        "batchWithdrawMaxTokens/1": F("USER_WRITE", "Sweep full balances for a token list.", SCREENS_PORTFOLIO),
        "getBalance/2": F("READ", "Trading balance per (user, token); drives order sizing.", SCREENS_KURU),
        "balances/1": F("READ", "Raw keyed balance slot (bytes32 key = keccak(user,token))."),
        "verifiedMarket/1": F("READ", "Trust check for resolved markets.", SCREENS_KURU),
        "isTrustedForwarder/1": F("READ", "ERC-2771 wiring; app must use direct EOAs."),
        "owner/0": OWN2_STEP_FNS["owner/0"],
        "debitUser/3": F("PROTOCOL_INTERNAL", "Verified-market-only debit."),
        "creditUser/4": F("PROTOCOL_INTERNAL", "Verified-market-only credit."),
        "creditUsersEncoded/1": F("PROTOCOL_INTERNAL", "Verified-market-only batch credit."),
        "creditFee/4": F("PROTOCOL_INTERNAL", "Verified-market-only fee booking."),
        "updateMarkets/1": F("PROTOCOL_INTERNAL", "Router-only market registration."),
        "initialize/4": F("ADMIN_ONLY", "Proxy initializer."),
        "setFeeCollector/1": F("ADMIN_ONLY", "Kuru owner op."),
        "toggleProtocolState/1": F("ADMIN_ONLY", "Kuru owner pause."),
        "transferOwnership/1": F("ADMIN_ONLY", "Solady ownable op."),
        "renounceOwnership/0": F("ADMIN_ONLY", "Solady ownable op."),
        "requestOwnershipHandover/0": F("ADMIN_ONLY", "Solady handover op."),
        "cancelOwnershipHandover/0": F("ADMIN_ONLY", "Solady handover op."),
        "completeOwnershipHandover/1": F("ADMIN_ONLY", "Solady handover op."),
        "ownershipHandoverExpiresAt/1": F("READ", "Solady handover state."),
        "upgradeToAndCall/2": F("ADMIN_ONLY", "UUPS upgrade."),
        "proxiableUUID/0": F("READ", "UUPS slot."),
    },
    "ev": {
        "Deposit": E("BOTH", "Margin deposit receipt (user, token, amount)."),
        "Withdrawal": E("BOTH", "Margin withdrawal receipt."),
        "ProtocolStateUpdated": E("INDEXER", "Kuru pause toggle; halt trading UI when paused."),
        "FeeCollectorUpdated": E("INDEXER", "Kuru fee routing change."),
        "Initialized": E("NONE", "Proxy lifecycle."),
        "Upgraded": E("INDEXER", "Kuru implementation change; revalidate environment."),
        "OwnershipTransferred": E("NONE", "Admin lifecycle."),
        "OwnershipHandoverRequested": E("NONE", "Admin lifecycle."),
        "OwnershipHandoverCanceled": E("NONE", "Admin lifecycle."),
    },
    "err": {
        "NativeAssetMismatch": R(True, "Deposit: msg.value must equal amount for native (0 for ERC20)."),
        "InsufficientBalance": R(True, "Withdraw/order: margin balance too low."),
        "ZeroAddressNotAllowed": R(True, "Deposit: zero user address."),
        "ProtocolPaused": R(True, "Kuru protocol paused; halt writes."),
        "OnlyVerifiedMarketsAllowed": R(False, "Internal market guard."),
        "OnlyRouterAllowed": R(False, "Internal router guard."),
        "Unauthorized": R(False, "Solady ownable guard."),
        "NewOwnerIsZeroAddress": R(False, "Solady guard."),
        "NoHandoverRequest": R(False, "Solady guard."),
        "FeeCollectorNotChanged": R(False, "Admin guard."),
        "ProtocolStateNotChanged": R(False, "Admin guard."),
        "AlreadyInitialized": R(False, "Initializer guard."),
        "InvalidInitialization": R(False, "Initializer guard."),
        "NotInitializing": R(False, "Initializer guard."),
        "UnauthorizedCallContext": R(False, "ERC-2771 guard."),
        "UpgradeFailed": R(False, "UUPS guard."),
    },
}

CLASS["OrderBook"] = {
    "role": "SURFACED",
    "summary": "Kuru CLOB market (per-launch proxy, e.g. the MON demo market 0x1F5dE7...): the app surfaces limit buy/sell, market buy/sell, cancels and L2 reads. Funds move through MarginAccount; the MON-native market is NATIVE_IN_QUOTE so market buys pay msg.value.",
    "fn": {
        "addBuyOrder/3": F(
            "USER_WRITE",
            "Limit buy: (price uint32 grid, size uint96 grid, postOnly); quotes are locked from margin balance; may match on placement.",
            SCREENS_KURU),
        "addSellOrder/3": F(
            "USER_WRITE",
            "Limit sell: (price, size, postOnly); base tokens locked from margin balance.",
            SCREENS_KURU),
        "batchCancelOrders/1": F(
            "USER_WRITE",
            "Cancel open orders by uint40 id; reverts OrderAlreadyFilledOrCancelled if any id is stale.",
            SCREENS_KURU + SCREENS_PORTFOLIO),
        "batchCancelOrdersNoRevert/1": F(
            "USER_WRITE",
            "Idempotent cancel: unfilled/cancelled ids decode as 0 in OrdersCanceled; preferred UI cancel.",
            SCREENS_KURU + SCREENS_PORTFOLIO),
        "placeAndExecuteMarketBuy/4": F(
            "USER_WRITE",
            "Market buy by quote size: NATIVE_IN_QUOTE -> msg.value bracket [cost(size), cost(size+1)); otherwise margin debit or quote transferFrom; minAmountOut slippage bound; fill-or-kill optional.",
            SCREENS_KURU),
        "placeAndExecuteMarketSell/4": F(
            "USER_WRITE",
            "Market sell by base size: msg.value == 0 on this market type; margin debit or base transferFrom to margin; minAmountOut on quote leg.",
            SCREENS_KURU),
        "getMarketParams/0": F("READ", "Grid/precision/fee params (pricePrecision, sizePrecision, tickSize, minSize, maxSize, fees) needed to encode orders.", SCREENS_KURU),
        "bestBidAsk/0": F("READ", "Best bid/ask in 1e18 vault precision for price display.", SCREENS_KURU),
        "getVaultParams/0": F("READ", "Vault quote + book state (vault address, bid/ask, sizes, spread).", SCREENS_KURU),
        "marketState/0": F("READ", "ACTIVE gate for order writes.", SCREENS_KURU),
        "getL2Book/0": F("READ", "Full depth snapshot (may be heavy); use bounded overload for UI.", SCREENS_KURU),
        "getL2Book/2~uint32,uint32": F("READ", "Bounded depth snapshot for the orderbook UI.", SCREENS_KURU),
        "s_orders/1": F("READ", "Order struct by uint40 id for open-order detail.", SCREENS_KURU + SCREENS_PORTFOLIO),
        "s_orderIdCounter/0": F("READ", "Latest issued order id."),
        "s_buyTree/0": F("READ", "Internal tree state (debug)."),
        "s_sellTree/0": F("READ", "Internal tree state (debug)."),
        "s_buyPricePoints/1": F("READ", "Internal linked-list state (debug)."),
        "s_sellPricePoints/1": F("READ", "Internal linked-list state (debug)."),
        "vaultBestAsk/0": F("READ", "AMM vault best ask (1e18)."),
        "vaultAskOrderSize/0": F("READ", "AMM vault ask size."),
        "SPREAD_CONSTANT/0": F("READ", "Vault spread bps constant."),
        "kuruAmmVault/0": F("READ", "Bound AMM vault address.", SCREENS_KURU),
        "isTrustedForwarder/1": F("READ", "ERC-2771 wiring; app uses direct EOAs."),
        "collectFees/0": F("LIFECYCLE_WRITE", "Permissionless fee flush to the margin fee collector; keeper op, not surfaced."),
        "addFlipBuyOrder/4": F("NOT_SURFACED_WRITE", "Market-maker flip primitive; excluded from v1 UI."),
        "addFlipSellOrder/4": F("NOT_SURFACED_WRITE", "Market-maker flip primitive; excluded from v1 UI."),
        "addPairedLiquidity/4": F("NOT_SURFACED_WRITE", "Market-maker paired-liquidity primitive; excluded from v1 UI."),
        "batchAddPairedLiquidity/4": F("NOT_SURFACED_WRITE", "Batch market-maker primitive; excluded from v1 UI."),
        "batchProvisionLiquidity/5": F("NOT_SURFACED_WRITE", "Batch market-maker primitive; excluded from v1 UI."),
        "batchUpdate/6": F("NOT_SURFACED_WRITE", "Bulk cancel+replace primitive; excluded from v1 UI."),
        "batchCancelFlipOrders/1": F("NOT_SURFACED_WRITE", "Flip-order cancel; excluded with flip orders."),
        "updateVaultOrdSz/5": F("PROTOCOL_INTERNAL", "Vault-side order bookkeeping."),
        "initialize/17": F("ADMIN_ONLY", "Router-driven proxy initializer."),
        "toggleMarket/1": F("ADMIN_ONLY", "Kuru owner market pause."),
        "transferOwnership/1": F("ADMIN_ONLY", "Kuru owner op."),
        "upgradeToAndCall/2": F("ADMIN_ONLY", "UUPS upgrade."),
        "proxiableUUID/0": F("READ", "UUPS slot."),
    },
    "ev": {
        "OrderCreated": E("BOTH", "New resting order: (orderId uint40, owner, size uint96, price uint32, isBuy); id also readable via s_orders."),
        "OrderCanceled": E("BOTH", "Single cancel receipt with refunded size."),
        "OrdersCanceled": E("BOTH", "Batch cancel receipt (0 ids = no-op entries in NoRevert variant)."),
        "Trade": E("BOTH", "Fill receipt: orderId, maker, isBuy, price(1e18), updatedSize, maker/taker assets, fee."),
        "FlipOrderCreated": E("INDEXER", "MM primitive (not surfaced)."),
        "FlippedOrderCreated": E("INDEXER", "MM primitive (not surfaced)."),
        "FlipOrderUpdated": E("INDEXER", "MM primitive (not surfaced)."),
        "FlipOrdersCanceled": E("INDEXER", "MM primitive (not surfaced)."),
        "MarketStateUpdated": E("BOTH", "Pause/unpause; trading UI gate."),
        "VaultParamsUpdated": E("INDEXER", "Vault order state change."),
        "Initialized": E("NONE", "Proxy lifecycle."),
        "Upgraded": E("INDEXER", "Implementation change; revalidate environment."),
    },
    "err": {
        "PriceError": R(True, "Order: price must be 0 < price < type(uint32).max."),
        "SizeError": R(True, "Order: size outside [minSize, maxSize] grid bounds."),
        "TickSizeError": R(True, "Order: price not a multiple of tickSize."),
        "MarketStateError": R(True, "Order: market not ACTIVE (or hard-paused for cancels)."),
        "PostOnlyError": R(True, "Order: post-only order would match at placement."),
        "InsufficientLiquidity": R(True, "Market order: unfilled remainder with fill-or-kill set."),
        "SlippageExceeded": R(True, "Market order: received below minAmountOut."),
        "OrderAlreadyFilledOrCancelled": R(True, "Cancel: stale id in strict batchCancelOrders; use NoRevert variant."),
        "WrongOrderTypeCancel": R(True, "Cancel: flip orders need batchCancelFlipOrders."),
        "OnlyOwnerAllowedError": R(False, "Order-owner guard."),
        "NativeAssetInsufficient": R(True, "Native market buy: msg.value below the exact bracket floor."),
        "NativeAssetSurplus": R(True, "Native market buy: msg.value at or above cost(size+1)."),
        "NativeAssetNotRequired": R(True, "Non-native path must send value 0."),
        "InvalidSpread": R(False, "Market init validation."),
        "MarketFeeError": R(False, "Market init validation."),
        "MarketSizeError": R(False, "Market init validation."),
        "LengthMismatch": R(False, "Batch param validation."),
        "ProvisionError": R(False, "Flip primitive guard (not surfaced)."),
        "OnlyVaultAllowed": R(False, "Vault callback guard."),
        "Uint32Overflow": R(False, "Arithmetic guard."),
        "Uint96Overflow": R(False, "Arithmetic guard."),
        "Unauthorized": R(False, "Ownable guard."),
        "UnauthorizedCallContext": R(False, "ERC-2771 guard."),
        "InvalidInitialization": R(False, "Initializer guard."),
        "NotInitializing": R(False, "Initializer guard."),
        "VaultInitializationPriceCrossesBook": R(False, "Market init validation."),
        "UpgradeFailed": R(False, "UUPS guard."),
        "ReentrancyGuardReentrantCall": R(False, "Reentrancy guard."),
    },
}

CLASS["KuruAMMVault"] = {
    "role": "SUPPORTING",
    "summary": "Per-market AMM vault ERC20 (LP shares) seeded at graduation and quoted by the order book; the app reads vault state and LP-share balances; deposits stay protocol-driven (graduation executor) in v1.",
    "fn": {
        "totalAssets/0": F("READ", "(base, quote) reserves backing LP shares.", SCREENS_KURU),
        "marketParams/0": F("READ", "Bound market params for price math.", SCREENS_KURU),
        "token1/0": F("READ", "Base asset (launch token).", SCREENS_KURU),
        "token2/0": F("READ", "Quote asset (0x0 = native).", SCREENS_KURU),
        "market/0": F("READ", "Bound order book.", SCREENS_KURU),
        "marginAccount/0": F("READ", "Wiring."),
        "SPREAD_CONSTANT/0": F("READ", "Spread bps constant.", SCREENS_KURU),
        "previewDeposit/2": F("READ", "Share math preview."),
        "previewMint/1": F("READ", "Share math preview."),
        "previewWithdraw/1": F("READ", "Share math preview."),
        **{k: F("READ", "ERC20 share metadata/balances for protected-LP display.") for k in (
            "name/0", "symbol/0", "decimals/0", "totalSupply/0", "balanceOf/1",
            "allowance/2", "nonces/1", "DOMAIN_SEPARATOR/0", "owner/0",
        )},
        "deposit/4": F("PROTOCOL_INTERNAL", "Graduation-executor seeding path ((base, quote, minQuoteConsumed, receiver)); not a v1 user surface."),
        "mint/2": F("PROTOCOL_INTERNAL", "Shares-out targeting variant; not a v1 user surface."),
        "withdraw/3": F("NOT_SURFACED_WRITE", "LP withdrawal; protected LP belongs to the immutable lock, so no v1 surface."),
        "permit/7": F("NOT_SURFACED_WRITE", "ERC20 permit; unused by the app."),
        "approve/2": F("NOT_SURFACED_WRITE", "Share approvals unused in v1."),
        "transfer/2": F("NOT_SURFACED_WRITE", "Share transfers unused in v1."),
        "transferFrom/3": F("NOT_SURFACED_WRITE", "Share transfers unused in v1."),
        "transferOwnership/1": F("ADMIN_ONLY", "Kuru router-owned op."),
        "setMarketParams/0": F("ADMIN_ONLY", "Router-owned parameter set."),
        "initialize/6": F("ADMIN_ONLY", "Proxy initializer."),
        "upgradeToAndCall/2": F("ADMIN_ONLY", "UUPS upgrade."),
        "proxiableUUID/0": F("READ", "UUPS slot."),
    },
    "ev": {
        "KuruVaultDeposit": E("INDEXER", "Seed/provision record (base, quote, shares, receiver)."),
        "KuruVaultWithdraw": E("INDEXER", "LP withdrawal record."),
        **ERC20_EV,
        "Initialized": E("NONE", "Proxy lifecycle."),
        "Upgraded": E("INDEXER", "Implementation change."),
    },
    "err": {
        "NativeAssetMismatch": R(False, "Deposit value guard (protocol path)."),
        "InsufficientQuoteToken": R(False, "Deposit ratio guard."),
        "InsufficientQuoteUsed": R(False, "Deposit minimum guard."),
        "InsufficientLiquidityMinted": R(False, "Share math guard."),
        "TotalSupplyOverflow": R(False, "Share math guard."),
        "InvalidVaultSize": R(False, "Vault state guard."),
        "AskPriceZero": R(False, "Price guard."),
        "Uint96Overflow": R(False, "Arithmetic guard."),
        "Unauthorized": R(False, "Ownable guard."),
        "UnauthorizedCallContext": R(False, "ERC-2771 guard."),
        "AllowanceOverflow": R(False, "ERC20 permit guard."),
        "AllowanceUnderflow": R(False, "ERC20 permit guard."),
        "InsufficientAllowance": R(False, "ERC20 guard."),
        "InsufficientBalance": R(False, "ERC20/vault guard (duplicate declaration in artifact; single disposition)."),
        "InvalidPermit": R(False, "ERC20 permit guard."),
        "PermitExpired": R(False, "ERC20 permit guard."),
        "Permit2AllowanceIsFixedAtInfinity": R(False, "Permit2 note guard."),
        "InvalidInitialization": R(False, "Initializer guard."),
        "NotInitializing": R(False, "Initializer guard."),
        "UpgradeFailed": R(False, "UUPS guard."),
        "ReentrancyGuardReentrantCall": R(False, "Reentrancy guard."),
    },
}

CLASS["RetroPickLaunchLockerV2"] = {
    "role": "INTERNAL_INFRA",
    "summary": "Custody for V4-venue graduated positions (full-range LP NFTs) and residual token supply; locked permanently, no withdrawal path; reads only.",
    "fn": {
        "isLocked/1": F("READ", "Lock flag per token."),
        "lockedTokenSupply/1": F("READ", "Permanently held supply."),
        "lockedPositions/1": F("READ", "Position ids held for a token."),
        "factory/0": F("READ", "Wiring."),
        "graduationExecutor/0": F("READ", "Wiring."),
        "positionManager/0": F("READ", "Wiring."),
        "onERC721Received/4": F("PROTOCOL_INTERNAL", "ERC721 hook for position custody."),
        "lockPosition/2": F("PROTOCOL_INTERNAL", "Executor-only."),
        "lockTokenSupply/2": F("PROTOCOL_INTERNAL", "Executor-only."),
        "setFactory/1": F("ADMIN_ONLY", "One-time wiring."),
        "setGraduationExecutor/1": F("ADMIN_ONLY", "Wiring."),
        "owner/0": OWN2_STEP_FNS["owner/0"],
        "pendingOwner/0": OWN2_STEP_FNS["pendingOwner/0"],
        "acceptOwnership/0": OWN2_STEP_FNS["acceptOwnership/0"],
        "transferOwnership/1": OWN2_STEP_FNS["transferOwnership/1"],
        "renounceOwnership/0": OWN2_STEP_FNS["renounceOwnership/0"],
    },
    "ev": {
        "PositionLocked": E("INDEXER", "V4 LP NFT locked."),
        "TokenSupplyLocked": E("INDEXER", "Residual supply locked."),
        "FactorySet": E("NONE", "One-time wiring."),
        **OWN2_STEP_EV,
    },
    "err": {
        "NotFactory": R(False, "Internal guard."),
        "NotPositionManager": R(False, "Internal guard."),
        "PositionAlreadyLocked": R(False, "Internal guard."),
        "PositionNotHeld": R(False, "Internal guard."),
        "AlreadyInitialized": R(False, "Wiring guard."),
        "InexactAssetTransfer": R(False, "Exact-transfer guard."),
        "ZeroAddress": R(False, "Guard."),
        "OwnershipCannotBeRenounced": R(False, "Disabled renounce."),
        "OwnableInvalidOwner": R(False, "OZ boilerplate."),
        "OwnableUnauthorizedAccount": R(False, "OZ admin guard."),
        "SafeERC20FailedOperation": R(False, "Token transfer failure wrapper."),
    },
}

CLASS["RetroPickMemeHookV2"] = {
    "role": "INTERNAL_INFRA",
    "summary": "Uniswap V4 hook governing every graduated v4 pool: post-graduation trade fees, internal buyback-and-lock and pool registration; all callbacks are PoolManager-driven and its admin setters stay unsurfaced.",
    "fn": {
        "currentFeePolicy/0": F("READ", "Global fee policy snapshot for display."),
        "launches/1": F("READ", "Pool registration state by poolId."),
        "pendingFees/2": F("READ", "Pending protocol/creator fee per pool."),
        "pendingBuyback/2": F("READ", "Pending buyback slice per pool."),
        "pendingCreatorTax/2": F("READ", "Pending creator tax per pool."),
        "hookFeeBps/0": F("READ", "Hook trade fee bps."),
        "buybackBurnBps/0": F("READ", "Buyback slice bps."),
        "protocolFeeShareBps/0": F("READ", "Protocol split bps."),
        "protocolFeeRecipient/0": F("READ", "Protocol recipient."),
        "maxInternalPriceImpactBps/0": F("READ", "Internal swap bound."),
        "feeSweepOperator/0": F("READ", "Trusted sweep operator."),
        "buybackVault/0": F("READ", "Wiring."),
        "feeEscrow/0": F("READ", "Wiring."),
        "factory/0": F("READ", "Wiring."),
        "poolManager/0": F("READ", "Wiring."),
        "graduationExecutor/0": F("READ", "Wiring."),
        "getHookPermissions/0": F("READ", "Hook permission bits (verification aid)."),
        "owner/0": OWN2_STEP_FNS["owner/0"],
        "pendingOwner/0": OWN2_STEP_FNS["pendingOwner/0"],
        "registerPool/7": F("PROTOCOL_INTERNAL", "Executor-only pool registration."),
        "unlockCallback/1": F("PROTOCOL_INTERNAL", "PoolManager-only callback."),
        "beforeSwap/4": F("PROTOCOL_INTERNAL", "PoolManager-driven hook callback."),
        "afterSwap/5": F("PROTOCOL_INTERNAL", "PoolManager-driven hook callback."),
        "beforeInitialize/3": F("PROTOCOL_INTERNAL", "PoolManager-driven hook callback."),
        "afterInitialize/4": F("PROTOCOL_INTERNAL", "PoolManager-driven hook callback."),
        "beforeAddLiquidity/4": F("PROTOCOL_INTERNAL", "PoolManager-driven hook callback."),
        "afterAddLiquidity/6": F("PROTOCOL_INTERNAL", "PoolManager-driven hook callback."),
        "beforeRemoveLiquidity/4": F("PROTOCOL_INTERNAL", "PoolManager-driven hook callback."),
        "afterRemoveLiquidity/6": F("PROTOCOL_INTERNAL", "PoolManager-driven hook callback."),
        "beforeDonate/5": F("PROTOCOL_INTERNAL", "PoolManager-driven hook callback."),
        "afterDonate/5": F("PROTOCOL_INTERNAL", "PoolManager-driven hook callback."),
        "sweepPoolFees/3": F("NOT_SURFACED_WRITE", "Operator/creator sweep; keeper flow, not v1 UI."),
        "rescuePoolFees/1": F("ADMIN_ONLY", "Owner rescue path."),
        "setCreatorFeeRecipient/2": F("ADMIN_ONLY", "Factory-gated forward."),
        "setBuybackEnabled/2": F("ADMIN_ONLY", "Factory-gated forward."),
        "setBuybackBurnBps/1": F("ADMIN_ONLY", "Owner policy."),
        "setHookFeeBps/1": F("ADMIN_ONLY", "Owner policy."),
        "setProtocolFeeShareBps/1": F("ADMIN_ONLY", "Owner policy."),
        "setProtocolFeeRecipient/1": F("ADMIN_ONLY", "Owner policy."),
        "setMaxInternalPriceImpactBps/1": F("ADMIN_ONLY", "Owner policy."),
        "setFeeSweepOperator/1": F("ADMIN_ONLY", "Owner policy."),
        "setBuybackVault/1": F("ADMIN_ONLY", "Owner wiring."),
        "setFactory/1": F("ADMIN_ONLY", "Owner wiring."),
        "setGraduationExecutor/1": F("ADMIN_ONLY", "Owner wiring."),
        "acceptOwnership/0": OWN2_STEP_FNS["acceptOwnership/0"],
        "transferOwnership/1": OWN2_STEP_FNS["transferOwnership/1"],
        "renounceOwnership/0": OWN2_STEP_FNS["renounceOwnership/0"],
    },
    "ev": {
        "PoolRegistered": E("INDEXER", "V4 graduation anchor (poolId, token, executor, hook)."),
        "HookFeeCollected": E("INDEXER", "Post-graduation fee record."),
        "PoolFeesSwept": E("INDEXER", "Fee sweep record."),
        "PoolFeesRescued": E("INDEXER", "Owner rescue record."),
        "PoolBuybackSkipped": E("INDEXER", "Buyback fold-back signal."),
        "PoolConversionSkipped": E("INDEXER", "Conversion skip signal."),
        "CreatorFeeRecipientUpdated": E("INDEXER", "Routing change."),
        "BuybackEnabledUpdated": E("INDEXER", "Flag change."),
        "BuybackBurnBpsUpdated": E("INDEXER", "Policy change."),
        "HookFeeBpsUpdated": E("INDEXER", "Policy change."),
        "ProtocolFeeShareUpdated": E("INDEXER", "Policy change."),
        "ProtocolFeeRecipientUpdated": E("INDEXER", "Policy change."),
        "MaxInternalPriceImpactUpdated": E("INDEXER", "Policy change."),
        "FeeSweepOperatorUpdated": E("INDEXER", "Operator change."),
        "BuybackVaultSet": E("NONE", "Wiring."),
        "FactorySet": E("NONE", "Wiring."),
        **OWN2_STEP_EV,
    },
    "err": {
        "UnknownPool": R(False, "Unregistered pool guard."),
        "AlreadyRegistered": R(False, "Registration guard."),
        "NotPoolManager": R(False, "Callback guard."),
        "NotFactory": R(False, "Forwarder guard."),
        "InvalidPoolKey": R(False, "Registration validation."),
        "InvalidBps": R(False, "Policy validation."),
        "MinimumOutputRequired": R(False, "Sweep guard."),
        "InternalSwapRequiresOperator": R(False, "Sweep guard."),
        "NotFeeSweepOperator": R(False, "Sweep guard."),
        "NothingToRescue": R(False, "Rescue guard."),
        "SlippageExceeded": R(False, "Internal buyback bound."),
        "InexactQuoteTransfer": R(False, "Exact-transfer guard."),
        "SafeCastOverflowedIntToUint": R(False, "Cast guard."),
        "SafeCastOverflowedUintToInt": R(False, "Cast guard."),
        "HookNotImplemented": R(False, "Callback coverage guard."),
        "ZeroAddress": R(False, "Guard."),
        "AlreadySet": R(False, "Wiring guard."),
        "OwnershipCannotBeRenounced": R(False, "Disabled renounce."),
        "OwnableInvalidOwner": R(False, "OZ boilerplate."),
        "OwnableUnauthorizedAccount": R(False, "OZ admin guard."),
        "ReentrancyGuardReentrantCall": R(False, "Reentrancy guard."),
        "SafeERC20FailedOperation": R(False, "Token transfer failure wrapper."),
    },
}

CLASS["RetroPickGraduationGuardV2"] = {
    "role": "INTERNAL_INFRA",
    "summary": "Stateless pure preflight modeling the V4 seed's tick/liquidity rejections; consumed by the V4 executor at launch validation, useful as an off-chain simulation aid.",
    "fn": {
        "assertSeedable/5": F("READ", "Pure preflight for one currency ordering (eth_call simulation aid)."),
        "assertSeedableEitherOrdering/3": F("READ", "Pure preflight across both orderings (launch-config checks)."),
    },
    "ev": {},
    "err": {
        "SqrtPriceOutOfBounds": R(False, "Preflight rejection (v4 seed)."),
        "GraduationSeedNotViable": R(False, "Preflight rejection (v4 seed)."),
        "UnsupportedPrice": R(False, "Preflight math guard."),
        "ZeroAmount": R(False, "Preflight math guard."),
    },
}

CLASS["RetroPickHookDeployerV2"] = {
    "role": "ADMIN_ONLY",
    "summary": "One-time CREATE2 deployer that placed the meme hook with its required permission bits; inert post-deployment.",
    "fn": {
        "deploy/4": F("ADMIN_ONLY", "Owner-only hook deployment; historical."),
        "owner/0": OWN2_STEP_FNS["owner/0"],
    },
    "ev": {},
    "err": {
        "Unauthorized": R(False, "Owner guard."),
    },
}

CLASS["RetroPickLaunchDeployerV2"] = {
    "role": "INTERNAL_INFRA",
    "summary": "Factory-only helper that deploys each curve/token pair (EIP-170 split); also enforces metadata length caps the create form should mirror client-side.",
    "fn": {
        "deployLaunch/1": F("PROTOCOL_INTERNAL", "onlyFactory launch deployment."),
        "factory/0": F("READ", "Wiring."),
    },
    "ev": {},
    "err": {
        "NotFactory": R(False, "Internal guard."),
        "MetadataTooLong": R(True, "Create form: metadata exceeds caps (name 64, symbol 16, logo 512, description 2048, socials 256)."),
    },
}

CLASS["ExecutorDonationLockV2"] = {
    "role": "INTERNAL_INFRA",
    "summary": "Immutable quarantine receiver attached to each graduation executor for unsolicited asset transfers; read-only.",
    "fn": {
        "executor/0": F("READ", "Bound executor address."),
    },
    "ev": {},
    "err": {},
}

# ----------------------------- external infra ------------------------------

_EXTERNAL_READ_NOTE = "External infrastructure read; SDK wiring/diagnostics only."

CLASS["Permit2"] = {
    "role": "EXTERNAL_INFRA",
    "summary": "Uniswap Permit2 allowance router used by the V4 graduation path; the app never calls it directly in v1 (Kuru venue needs no Permit2).",
    "fn": {
        "DOMAIN_SEPARATOR/0": F("READ", _EXTERNAL_READ_NOTE),
        "allowance/3": F("READ", _EXTERNAL_READ_NOTE),
        "nonceBitmap/2": F("READ", _EXTERNAL_READ_NOTE),
        "approve/4": F("NOT_SURFACED_WRITE", "Permit2 direct approvals; only the protocol's V4 executor path uses Permit2."),
        "permit/3~uint48)[]": F("NOT_SURFACED_WRITE", "Batch allowance permit; protocol-internal to the V4 path."),
        "permit/3~uint48),address": F("NOT_SURFACED_WRITE", "Single allowance permit; protocol-internal to the V4 path."),
        "permitTransferFrom/4~(address,uint256),address,bytes)": F("NOT_SURFACED_WRITE", "Token-transfer permit; protocol-internal."),
        "permitTransferFrom/4~(address,uint256)[],address,bytes)": F("NOT_SURFACED_WRITE", "Batch transfer permit; protocol-internal."),
        "permitWitnessTransferFrom/6~(address,uint256),address,bytes32": F("NOT_SURFACED_WRITE", "Witness permit; protocol-internal."),
        "permitWitnessTransferFrom/6~(address,uint256)[],address,bytes32": F("NOT_SURFACED_WRITE", "Batch witness permit; protocol-internal."),
        "transferFrom/4~address,address,uint160": F("NOT_SURFACED_WRITE", "Direct transfer; protocol-internal."),
        "transferFrom/1": F("NOT_SURFACED_WRITE", "Batch direct transfer; protocol-internal."),
        "invalidateNonces/3": F("NOT_SURFACED_WRITE", "Safety primitive; not surfaced."),
        "invalidateUnorderedNonces/2": F("NOT_SURFACED_WRITE", "Safety primitive; not surfaced."),
        "lockdown/1": F("NOT_SURFACED_WRITE", "Safety primitive; not surfaced."),
    },
    "ev": {
        "Approval": E("NONE", "External infra; indexer may archive."),
        "Permit": E("NONE", "External infra."),
        "NonceInvalidation": E("NONE", "External infra."),
        "UnorderedNonceInvalidation": E("NONE", "External infra."),
        "Lockdown": E("NONE", "External infra."),
    },
    "err": {
        "AllowanceExpired": R(False, "Permit2 decode (protocol-internal)."),
        "ExcessiveInvalidation": R(False, "Permit2 decode."),
        "InsufficientAllowance": R(False, "Permit2 decode."),
        "InvalidAmount": R(False, "Permit2 decode."),
        "InvalidContractSignature": R(False, "Permit2 decode."),
        "InvalidNonce": R(False, "Permit2 decode."),
        "InvalidSignature": R(False, "Permit2 decode."),
        "InvalidSignatureLength": R(False, "Permit2 decode."),
        "InvalidSigner": R(False, "Permit2 decode."),
        "LengthMismatch": R(False, "Permit2 decode."),
        "SignatureExpired": R(False, "Permit2 decode."),
    },
}

CLASS["PoolManager"] = {
    "role": "EXTERNAL_INFRA",
    "summary": "Uniswap V4 core singleton holding all v4 pool state; only the graduation executor/locker/lockers interact with it. The app reads pool state indirectly; never surfaces it.",
    "fn": {
        "extsload/1~bytes32)": F("READ", _EXTERNAL_READ_NOTE),
        "extsload/2": F("READ", _EXTERNAL_READ_NOTE),
        "extsload/1~bytes32[]": F("READ", _EXTERNAL_READ_NOTE),
        "exttload/1~bytes32[]": F("READ", _EXTERNAL_READ_NOTE),
        "exttload/1~bytes32)": F("READ", _EXTERNAL_READ_NOTE),
        "balanceOf/2": F("READ", _EXTERNAL_READ_NOTE),
        "allowance/3": F("READ", _EXTERNAL_READ_NOTE),
        "isOperator/2": F("READ", _EXTERNAL_READ_NOTE),
        "owner/0": F("READ", _EXTERNAL_READ_NOTE),
        "protocolFeeController/0": F("READ", _EXTERNAL_READ_NOTE),
        "protocolFeesAccrued/1": F("READ", _EXTERNAL_READ_NOTE),
        "supportsInterface/1": F("READ", _EXTERNAL_READ_NOTE),
        "unlock/1": F("NOT_SURFACED_WRITE", "V4 flash/unlock perimeter; only whitelisted protocol actors (executor/locker) may use."),
        "initialize/2": F("PROTOCOL_INTERNAL", "Executor-driven pool initialization."),
        "modifyLiquidity/3": F("PROTOCOL_INTERNAL", "Executor/locker-driven liquidity ops."),
        "swap/3": F("NOT_SURFACED_WRITE", "V4 swap requires locked-context; not a direct app surface in v1."),
        "donate/4": F("NOT_SURFACED_WRITE", "Not surfaced."),
        "settle/0": F("PROTOCOL_INTERNAL", "Locked-context settlement."),
        "settleFor/1": F("PROTOCOL_INTERNAL", "Locked-context settlement."),
        "take/3": F("PROTOCOL_INTERNAL", "Locked-context extraction."),
        "mint/3": F("PROTOCOL_INTERNAL", "Locked-context mint."),
        "burn/3": F("PROTOCOL_INTERNAL", "Locked-context burn."),
        "clear/2": F("PROTOCOL_INTERNAL", "Locked-context clear."),
        "sync/1": F("NOT_SURFACED_WRITE", "Sync is safe but unused by the app in v1."),
        "approve/3": F("NOT_SURFACED_WRITE", "Not surfaced."),
        "transfer/3": F("NOT_SURFACED_WRITE", "Not surfaced."),
        "transferFrom/4": F("NOT_SURFACED_WRITE", "Not surfaced."),
        "setOperator/2": F("NOT_SURFACED_WRITE", "Not surfaced."),
        "transferOwnership/1": F("ADMIN_ONLY", "V4 owner op."),
        "collectProtocolFees/3": F("ADMIN_ONLY", "Fee controller op."),
        "setProtocolFee/2": F("ADMIN_ONLY", "Fee controller op."),
        "setProtocolFeeController/1": F("ADMIN_ONLY", "V4 owner op."),
        "updateDynamicLPFee/2": F("ADMIN_ONLY", "Fee controller op (hook-gated)."),
    },
    "ev": {
        "Initialize": E("INDEXER", "V4 pool creation for a graduated launch."),
        "ModifyLiquidity": E("INDEXER", "Seed position mint into the locker."),
        "Swap": E("INDEXER", "V4 post-graduation trades."),
        "Donate": E("NONE", "External infra."),
        "OperatorSet": E("NONE", "External infra."),
        "ProtocolFeeUpdated": E("NONE", "External infra."),
        "ProtocolFeeControllerUpdated": E("NONE", "External infra."),
        "OwnershipTransferred": E("NONE", "External infra."),
        "Approval": E("NONE", "External infra."),
        "Transfer": E("NONE", "External infra."),
    },
    "err": {
        "CurrenciesOutOfOrderOrEqual": R(False, "V4 pool-key guard."),
        "CurrencyNotSettled": R(False, "V4 settlement guard."),
        "PoolNotInitialized": R(False, "V4 guard."),
        "ManagerLocked": R(False, "V4 lock guard."),
        "AlreadyUnlocked": R(False, "V4 lock guard."),
        "InvalidCaller": R(False, "V4 guard."),
        "DelegateCallNotAllowed": R(False, "V4 guard."),
        "MustClearExactPositiveDelta": R(False, "V4 settlement guard."),
        "NonzeroNativeValue": R(False, "V4 guard."),
        "ProtocolFeeCurrencySynced": R(False, "V4 guard."),
        "ProtocolFeeTooLarge": R(False, "V4 guard."),
        "SwapAmountCannotBeZero": R(False, "V4 guard."),
        "TickSpacingTooLarge": R(False, "V4 guard."),
        "TickSpacingTooSmall": R(False, "V4 guard."),
        "UnauthorizedDynamicLPFeeUpdate": R(False, "V4 guard."),
    },
}

CLASS["PositionManager"] = {
    "role": "EXTERNAL_INFRA",
    "summary": "Uniswap V4 periphery NFT position manager; used by the graduation executor to mint the seeded full-range position (held by the locker). Not an app surface.",
    "fn": {
        "nextTokenId/0": F("READ", _EXTERNAL_READ_NOTE),
        "getPositionLiquidity/1": F("READ", "Seeded position liquidity for display."),
        "getPoolAndPositionInfo/1": F("READ", _EXTERNAL_READ_NOTE),
        "positionInfo/1": F("READ", _EXTERNAL_READ_NOTE),
        "poolKeys/1": F("READ", _EXTERNAL_READ_NOTE),
        "positionInfo": None,  # placeholder removed below; keep explicit entries only
        "modifyLiquidities/2": F("PROTOCOL_INTERNAL", "Executor-driven actions."),
        "modifyLiquiditiesWithoutUnlock/2": F("PROTOCOL_INTERNAL", "Trusted-caller variant used by integration paths."),
        "initializePool/2": F("PROTOCOL_INTERNAL", "Executor-driven."),
        "multicall/1": F("NOT_SURFACED_WRITE", "V4 periphery power surface; not an app surface."),
        "unlockCallback/1": F("PROTOCOL_INTERNAL", "PoolManager-only callback."),
        "subscribe/3": F("NOT_SURFACED_WRITE", "Subscriber system; not surfaced."),
        "unsubscribe/1": F("NOT_SURFACED_WRITE", "Not surfaced."),
        "permit/5": F("NOT_SURFACED_WRITE", "Not surfaced."),
        "permit/3": F("NOT_SURFACED_WRITE", "Permit2-based permit; not surfaced."),
        "permitBatch/3": F("NOT_SURFACED_WRITE", "Not surfaced."),
        "permitForAll/6": F("NOT_SURFACED_WRITE", "Not surfaced."),
        "revokeNonce/1": F("NOT_SURFACED_WRITE", "Not surfaced."),
        "approve/2": F("NOT_SURFACED_WRITE", "Not surfaced."),
        "setApprovalForAll/2": F("NOT_SURFACED_WRITE", "Not surfaced."),
        "safeTransferFrom/3": F("NOT_SURFACED_WRITE", "Locked positions never move."),
        "safeTransferFrom/4": F("NOT_SURFACED_WRITE", "Locked positions never move."),
        "transferFrom/3": F("NOT_SURFACED_WRITE", "Locked positions never move."),
        "burn": None,
        "name/0": F("READ", "ERC721 metadata."),
        "symbol/0": F("READ", "ERC721 metadata."),
        "tokenURI/1": F("READ", "ERC721 metadata."),
        "tokenDescriptor/0": F("READ", "Wiring."),
        "balanceOf/1": F("READ", "ERC721 balance (locker holdings)."),
        "ownerOf/1": F("READ", "Position owner (locker)."),
        "getApproved/1": F("READ", "ERC721 state."),
        "isApprovedForAll/2": F("READ", "ERC721 state."),
        "nonces/2": F("READ", "Permit state."),
        "DOMAIN_SEPARATOR/0": F("READ", "Permit state."),
        "WETH9/0": F("READ", "Wiring."),
        "permit2/0": F("READ", "Wiring."),
        "poolManager/0": F("READ", "Wiring."),
        "msgSender/0": F("READ", "ERC-2771 diagnostic."),
        "unsubscribeGasLimit/0": F("READ", "Subscriber config."),
        "subscriber/1": F("READ", "Subscriber state."),
        "supportsInterface/1": F("READ", "ERC165."),
    },
    "ev": {
        "ModifyPosition": E("INDEXER", "Position liquidity change for graduated pools."),
        **ERC20_EV,
        "Subscription": E("NONE", "External infra."),
        "Unsubscription": E("NONE", "External infra."),
        "ApprovalForAll": E("NONE", "External infra."),
    },
    "err": {
        "NotPoolManager": R(False, "Callback guard."),
        "PoolManagerMustBeLocked": R(False, "V4 guard."),
        "ContractLocked": R(False, "V4 guard."),
        "DeltaNotNegative": R(False, "Settlement guard."),
        "DeltaNotPositive": R(False, "Settlement guard."),
        "InvalidEthSender": R(False, "V4 guard."),
        "NoSelfPermit": R(False, "Permit guard."),
        "NonceAlreadyUsed": R(False, "Permit guard."),
        "DeadlinePassed": R(False, "Permit guard."),
        "SignatureDeadlineExpired": R(False, "Permit guard."),
        "NoCodeSubscriber": R(False, "Subscriber guard."),
        "NotSubscribed": R(False, "Subscriber guard."),
        "AlreadySubscribed": R(False, "Subscriber guard."),
        "SubscriptionReverted": R(False, "Subscriber guard."),
        "GasLimitTooLow": R(False, "Subscriber guard."),
        "UnsupportedAction": R(False, "Actions decoder guard."),
        "InputLengthMismatch": R(False, "Multicall guard."),
        "MaximumAmountExceeded": R(False, "Permit guard."),
        "MinimumAmountInsufficient": R(False, "Permit guard."),
        "InsufficientBalance": R(False, "Permit guard."),
        "NotApproved": R(False, "ERC721 guard."),
        "InvalidSignature": R(False, "Permit guard."),
        "InvalidSignatureLength": R(False, "Permit guard."),
        "InvalidSigner": R(False, "Permit guard."),
        "InvalidContractSignature": R(False, "Permit guard."),
        "BurnNotificationReverted": R(False, "ERC721 hook guard."),
        "ModifyLiquidityNotificationReverted": R(False, "ERC721 hook guard."),
        "Unauthorized": R(False, "Guard."),
    },
}

CLASS["PositionDescriptor"] = {
    "role": "EXTERNAL_INFRA",
    "summary": "V4 position NFT metadata descriptor; read-only external helper.",
    "fn": {
        "tokenURI/2": F("READ", _EXTERNAL_READ_NOTE),
        "flipRatio/2": F("READ", _EXTERNAL_READ_NOTE),
        "currencyRatioPriority/1": F("READ", _EXTERNAL_READ_NOTE),
        "nativeCurrencyLabel/0": F("READ", _EXTERNAL_READ_NOTE),
        "wrappedNative/0": F("READ", _EXTERNAL_READ_NOTE),
        "poolManager/0": F("READ", _EXTERNAL_READ_NOTE),
    },
    "ev": {},
    "err": {
        "InvalidTokenId": R(False, "Descriptor guard."),
        "InvalidAddressLength": R(False, "Descriptor guard."),
        "StringsInsufficientHexLength": R(False, "Descriptor guard."),
    },
}

CLASS["WETH"] = {
    "role": "EXTERNAL_INFRA",
    "summary": "Wrapped native reference for the V4 stack; MON-native flows never need it in v1.",
    "fn": {
        "deposit/0": F("NOT_SURFACED_WRITE", "Not needed for MON-native flows."),
        "withdraw/1": F("NOT_SURFACED_WRITE", "Not needed for MON-native flows."),
        "permit/7": F("NOT_SURFACED_WRITE", "Not surfaced."),
        "approve/2": F("NOT_SURFACED_WRITE", "Not surfaced."),
        "transfer/2": F("NOT_SURFACED_WRITE", "Not surfaced."),
        "transferFrom/3": F("NOT_SURFACED_WRITE", "Not surfaced."),
        **{k: F("READ", _EXTERNAL_READ_NOTE) for k in (
            "name/0", "symbol/0", "decimals/0", "totalSupply/0", "balanceOf/1",
            "allowance/2", "nonces/1", "DOMAIN_SEPARATOR/0",
        )},
    },
    "ev": {
        "Deposit": E("NONE", "External infra."),
        "Withdrawal": E("NONE", "External infra."),
        **ERC20_EV,
    },
    "err": {},
}

CLASS["Router"] = {
    "role": "EXTERNAL_INFRA",
    "summary": "Kuru market factory/registry owning the proxy deployment path the graduation executor drives; app surfaces none of it (markets are discovered via GraduationCompleted receipts).",
    "fn": {
        "TRUSTED_FORWARDER/0": F("READ", _EXTERNAL_READ_NOTE),
        "kuruAmmVaultImplementation/0": F("READ", _EXTERNAL_READ_NOTE),
        "orderBookImplementation/0": F("READ", _EXTERNAL_READ_NOTE),
        "marginAccountAddress/0": F("READ", "Pinned margin account cross-check.", SCREENS_KURU),
        "verifiedMarket/1": F("READ", "Trust check for a resolved market.", SCREENS_KURU),
        "computeAddress/12": F("READ", "Deterministic market address derivation (mirror of executor)."),
        "computeVaultAddress/3": F("READ", "Deterministic vault address derivation."),
        "owner/0": OWN2_STEP_FNS["owner/0"],
        "ownershipHandoverExpiresAt/1": F("READ", "Solady handover state."),
        "anyToAnySwap/7": F("NOT_SURFACED_WRITE", "Kuru router swap; v1 trades via the order book directly. Future candidate."),
        "deployProxy/11": F("ADMIN_ONLY", "Kuru owner/executor market deployment."),
        "initialize/5": F("ADMIN_ONLY", "Router initializer."),
        "toggleMarkets/2": F("ADMIN_ONLY", "Kuru owner pause."),
        "transferOwnershipForContracts/2": F("ADMIN_ONLY", "Kuru owner op."),
        "upgradeOrderBookImplementation/1": F("ADMIN_ONLY", "Kuru owner op."),
        "upgradeVaultImplementation/1": F("ADMIN_ONLY", "Kuru owner op."),
        "upgradeMultipleOrderBookProxies/2": F("ADMIN_ONLY", "Kuru owner op."),
        "upgradeMultipleVaultProxies/2": F("ADMIN_ONLY", "Kuru owner op."),
        "upgradeToAndCall/2": F("ADMIN_ONLY", "UUPS upgrade."),
        "proxiableUUID/0": F("READ", "UUPS slot."),
        "requestOwnershipHandover/0": F("ADMIN_ONLY", "Solady handover op."),
        "cancelOwnershipHandover/0": F("ADMIN_ONLY", "Solady handover op."),
        "completeOwnershipHandover/1": F("ADMIN_ONLY", "Solady handover op."),
        "renounceOwnership/0": F("ADMIN_ONLY", "Solady ownable op."),
        "transferOwnership/1": F("ADMIN_ONLY", "Solady ownable op."),
    },
    "ev": {
        "MarketRegistered": E("INDEXER", "Kuru market deployment record; cross-check with graduation receipts."),
        "KuruRouterSwap": E("INDEXER", "Router swap record (unused path in v1)."),
        "OBImplementationUpdated": E("INDEXER", "Kuru upgrade signal; revalidate environment."),
        "VaultImplementationUpdated": E("INDEXER", "Kuru upgrade signal."),
        "Initialized": E("NONE", "Proxy lifecycle."),
        "Upgraded": E("INDEXER", "Router upgrade."),
        "OwnershipTransferred": E("NONE", "Admin lifecycle."),
        "OwnershipHandoverRequested": E("NONE", "Admin lifecycle."),
        "OwnershipHandoverCanceled": E("NONE", "Admin lifecycle."),
    },
    "err": {
        "InvalidPricePrecision": R(False, "Market init validation."),
        "InvalidSizePrecision": R(False, "Market init validation."),
        "InvalidTickSize": R(False, "Market init validation."),
        "InvalidMarket": R(False, "Market init validation."),
        "MarketTypeMismatch": R(False, "Market init validation."),
        "BaseAndQuoteAssetSame": R(False, "Market init validation."),
        "Create2EmptyBytecode": R(False, "Deployment guard."),
        "FailedDeployment": R(False, "Deployment guard."),
        "ImplementationNotChanged": R(False, "Upgrade guard."),
        "NoMarketsPassed": R(False, "Batch guard."),
        "LengthMismatch": R(False, "Batch guard."),
        "SlippageExceeded": R(False, "Router swap guard (unused path)."),
        "InsufficientBalance": R(False, "Router swap guard."),
        "Uint96Overflow": R(False, "Arithmetic guard."),
        "ZeroAddressNotAllowed": R(False, "Guard."),
        "NewOwnerIsZeroAddress": R(False, "Solady guard."),
        "NoHandoverRequest": R(False, "Solady guard."),
        "Unauthorized": R(False, "Solady/ownable guard."),
        "UnauthorizedCallContext": R(False, "ERC-2771 guard."),
        "AlreadyInitialized": R(False, "Initializer guard."),
        "InvalidInitialization": R(False, "Initializer guard."),
        "NotInitializing": R(False, "Initializer guard."),
        "UpgradeFailed": R(False, "UUPS guard."),
    },
}

CLASS["ERC20MetadataInterface"] = {
    "role": "EXTERNAL_INFRA",
    "summary": "Qualified ERC20 interface for canonical Circle USDC on 10143; used for USDC-quote reads (balances/decimals) and the approve prerequisite when launching/trading against USDC.",
    "fn": {
        **ERC20_READ_FNS,
        "approve/2": F("USER_WRITE", "USDC approve prerequisite for ERC20-quote curve buys (spender = the launch's curve).", SCREENS_TRADE),
        "transfer/2": F("NOT_SURFACED_WRITE", "Wallet-native; out of app scope."),
        "transferFrom/3": F("NOT_SURFACED_WRITE", "Spender path not used."),
    },
    "ev": ERC20_EV,
    "err": {},
}

# clean accidental placeholder entries
for _c in CLASS.values():
    _c["fn"] = {k: v for k, v in _c["fn"].items() if v is not None}

# ---------------------------------------------------------------------------
# Frontend write allowlist (goes to SECURITY_AGENT).
# ---------------------------------------------------------------------------

FACTORY = "RetroPickLaunchFactoryV2"
FRONTEND_WRITES = [
    {
        "contract": FACTORY,
        "signature": "launchToken((string,string,string,string,(string,string,string,string,string),address,uint16,bool,bytes32,bytes32),uint256,address,uint8)",
        "caller": "connected wallet",
        "target": "factory 0xa7f18b9eceb0A9852b08408854A45D00fc682454",
        "accessControl": "canLaunch(msg.sender): launchEnabled || whitelistedLaunchers[msg.sender]",
        "assetMovement": "launch fee (native MON) forwarded to memeHook.protocolFeeRecipient(); no other assets move",
        "payableValueRule": "msg.value == launchFee() EXACTLY (else LaunchFeeNotPaid)",
        "allowanceSpender": None,
        "nativeOrErc20": "native-only fee regardless of quote venue",
        "slippage": "params.expectedEconomics = previewVenueEconomics(launchConfigId, pairToken, venue); bytes32(0) waives the pin",
        "eventsDecoded": ["TokenLaunched"],
        "errorsDecoded": ["NotWhitelisted", "LaunchFeeNotPaid", "InvalidLaunchConfigId", "LaunchConfigDisabled", "InvalidTokenParams", "CreatorTaxTooHigh", "CombinedFeeTooHigh", "CurveNotQuotable", "LaunchEconomicsMismatch", "GraduationExecutorNotSet", "LaunchDeployerNotSet", "LaunchDependenciesNotWired", "UnsupportedQuote", "MetadataTooLong"],
        "retryPolicy": "revert = nothing persisted, safe to fix inputs and retry; on drop, identical salt retries safely unless the pair already exists (then pick a new salt)",
        "screens": SCREENS_CREATE,
    },
    {
        "contract": FACTORY,
        "signature": "launchToken((string,string,string,string,(string,string,string,string,string),address,uint16,bool,bytes32,bytes32),uint256,address,address[])",
        "caller": "connected wallet",
        "target": "factory 0xa7f18b9eceb0A9852b08408854A45D00fc682454",
        "accessControl": "canLaunch(msg.sender); UNISWAP_V4 venue only",
        "assetMovement": "as venue overload plus snipe-tax exemptions (max 32 addresses)",
        "payableValueRule": "msg.value == launchFee() EXACTLY",
        "allowanceSpender": None,
        "nativeOrErc20": "native-only fee",
        "slippage": "expectedEconomics pin as venue overload",
        "eventsDecoded": ["TokenLaunched"],
        "errorsDecoded": ["NotWhitelisted", "LaunchFeeNotPaid", "InvalidLaunchConfigId", "LaunchConfigDisabled", "InvalidTokenParams", "CreatorTaxTooHigh", "CombinedFeeTooHigh", "CurveNotQuotable", "LaunchEconomicsMismatch", "ExemptionListTooLong", "GraduationExecutorNotSet", "MetadataTooLong"],
        "retryPolicy": "same as venue overload",
        "screens": SCREENS_CREATE,
    },
    {
        "contract": "RetroPickBondingCurveV2",
        "signature": "buy(uint256,uint256,address)",
        "caller": "connected wallet",
        "target": "per-launch curve resolved from TokenLaunched / getLaunchedToken (demo 0x454A3A449d4e65CA5203d331905d167BA218E276)",
        "accessControl": "permissionless while sellableTokens() > 0 and !graduated()",
        "assetMovement": "quote in; launch tokens out to recipient; partial-fill refund of unspent quote",
        "payableValueRule": "native MON quote: msg.value == quoteIn EXACTLY; ERC20 quote: msg.value == 0",
        "allowanceSpender": "ERC20 quote only: pairToken approve -> curve",
        "nativeOrErc20": "isNativeQuote(): pairToken == address(0) means native MON",
        "slippage": "minTokensOut acts as a PRICE bound on partial fills (spent*minTokensOut <= received*tokensOut)",
        "eventsDecoded": ["CurveBuy", "CurveBuyRefunded", "GraduationSecured", "AutoGraduationFailed"],
        "errorsDecoded": ["CurveGraduated", "ZeroAmount", "ZeroAddress", "SlippageExceeded", "NativeValueMismatch", "UnexpectedNativeValue", "InexactQuoteTransfer", "QuoteBackingDeficit", "CompletionCeilingExceeded"],
        "retryPolicy": "safe to retry after revert (state unchanged); a buy may atomically trigger graduation - re-read curve state on success",
        "screens": SCREENS_TRADE,
    },
    {
        "contract": "RetroPickBondingCurveV2",
        "signature": "sell(uint256,uint256,address)",
        "caller": "connected wallet",
        "target": "per-launch curve",
        "accessControl": "permissionless while !readyToGraduate() and !graduated()",
        "assetMovement": "launch tokens in (transferFrom); quote out to recipient",
        "payableValueRule": "nonpayable (msg.value == 0)",
        "allowanceSpender": "launch token approve -> curve (exact tokensIn or higher)",
        "nativeOrErc20": "payout follows curve quote type",
        "slippage": "minQuoteOut bounds the net quote leg",
        "eventsDecoded": ["CurveSell"],
        "errorsDecoded": ["CurveGraduated", "ZeroAmount", "ZeroAddress", "SlippageExceeded", "InexactQuoteTransfer", "QuoteBackingDeficit"],
        "retryPolicy": "safe to retry after revert; if CurveGraduated route the user to venue trading",
        "screens": SCREENS_TRADE,
    },
    {
        "contract": FACTORY,
        "signature": "graduate(address)",
        "caller": "anyone (permissionless keeper/recovery)",
        "target": "factory",
        "accessControl": "token must exist, ledger phase NONE, curve.readyToGraduate()",
        "assetMovement": "curve tradeable reserves -> GraduationCoordinatorV2 custody",
        "payableValueRule": "nonpayable",
        "allowanceSpender": None,
        "nativeOrErc20": "n/a",
        "slippage": "n/a (no conversion; exact reserve handoff)",
        "eventsDecoded": ["GraduationSecured"],
        "errorsDecoded": ["TokenNotFound", "WrongGraduationPhase", "NotReadyToGraduate", "AlreadyGraduated", "CompletionCeilingExceeded", "QuoteBackingDeficit"],
        "retryPolicy": "check ledger(token).phase first; retry safe until phase flips to GRADUATING",
        "screens": SCREENS_GRAD,
    },
    {
        "contract": FACTORY,
        "signature": "createGraduatedPool(address)",
        "caller": "anyone (permissionless completion)",
        "target": "factory",
        "accessControl": "token must exist, coordinator ledger phase GRADUATING",
        "assetMovement": "secured reserves -> venue (V4 pool seed or Kuru market+vault+lock); returns positionId",
        "payableValueRule": "nonpayable",
        "allowanceSpender": None,
        "nativeOrErc20": "n/a",
        "slippage": "n/a (deterministic seed, executor-verified)",
        "eventsDecoded": ["GraduationCompleted", "PoolGraduated (V4 venue)"],
        "errorsDecoded": ["TokenNotFound", "WrongPhase", "InvalidPacket", "InvalidReceipt", "BackingDeficit", "GraduationSeedNotViable", "SqrtPriceOutOfBounds", "EnvironmentDrift"],
        "retryPolicy": "stays GRADUATING until success: retry on transient failure; report on validation errors",
        "screens": SCREENS_GRAD,
    },
    {
        "contract": "MarginAccount",
        "signature": "deposit(address,address,uint256)",
        "caller": "connected wallet (depositor)",
        "target": "margin 0xd029C2D98ff85D8F64799017fE00a59B1159CE02",
        "accessControl": "permissionless while protocol not paused; user may be any address",
        "assetMovement": "native MON or ERC20 into the margin balance of (user, token)",
        "payableValueRule": "token == address(0): msg.value == amount EXACTLY; ERC20: msg.value == 0",
        "allowanceSpender": "ERC20 (e.g. launch token): token approve -> MarginAccount",
        "nativeOrErc20": "address(0) = native MON; otherwise ERC20 transferFrom",
        "slippage": "n/a",
        "eventsDecoded": ["Deposit"],
        "errorsDecoded": ["NativeAssetMismatch", "ZeroAddressNotAllowed", "ProtocolPaused"],
        "retryPolicy": "safe to retry after revert",
        "screens": SCREENS_KURU,
    },
    {
        "contract": "MarginAccount",
        "signature": "withdraw(uint256,address)",
        "caller": "connected wallet",
        "target": "margin 0xd029C2D98ff85D8F64799017fE00a59B1159CE02",
        "accessControl": "caller's own balance only",
        "assetMovement": "margin balance -> wallet",
        "payableValueRule": "nonpayable",
        "allowanceSpender": None,
        "nativeOrErc20": "follows token (address(0) = native MON)",
        "slippage": "n/a",
        "eventsDecoded": ["Withdrawal"],
        "errorsDecoded": ["InsufficientBalance", "ProtocolPaused"],
        "retryPolicy": "safe to retry; use batchWithdrawMaxTokens for full sweep",
        "screens": SCREENS_PORTFOLIO,
    },
    {
        "contract": "MarginAccount",
        "signature": "batchWithdrawMaxTokens(address[])",
        "caller": "connected wallet",
        "target": "margin 0xd029C2D98ff85D8F64799017fE00a59B1159CE02",
        "accessControl": "caller's own balances only",
        "assetMovement": "all listed token balances -> wallet",
        "payableValueRule": "nonpayable",
        "allowanceSpender": None,
        "nativeOrErc20": "per-token (address(0) = native MON)",
        "slippage": "n/a",
        "eventsDecoded": ["Withdrawal (one per token)"],
        "errorsDecoded": ["ProtocolPaused"],
        "retryPolicy": "idempotent per balance; safe to retry",
        "screens": SCREENS_PORTFOLIO,
    },
    {
        "contract": "OrderBook",
        "signature": "addBuyOrder(uint32,uint96,bool)",
        "caller": "connected wallet",
        "target": "per-launch market from GraduationCompleted receipt (demo 0x1F5dE72616a7fe645Cf45aC66dfce8Ac7452C57F)",
        "accessControl": "marketState == ACTIVE; funds debited from caller's margin quote balance",
        "assetMovement": "quote locked from margin (may fill against asks/vault on placement)",
        "payableValueRule": "nonpayable (pre-deposit via MarginAccount)",
        "allowanceSpender": None,
        "nativeOrErc20": "margin-balance debit (native MON booked under token address(0))",
        "slippage": "none on the entry itself: price/size are exact grid terms; postOnly guards unwanted fills",
        "eventsDecoded": ["OrderCreated", "Trade"],
        "errorsDecoded": ["PriceError", "SizeError", "TickSizeError", "MarketStateError", "PostOnlyError", "InsufficientBalance"],
        "retryPolicy": "safe to retry after revert; re-pull getMarketParams for grid bounds",
        "screens": SCREENS_KURU,
    },
    {
        "contract": "OrderBook",
        "signature": "addSellOrder(uint32,uint96,bool)",
        "caller": "connected wallet",
        "target": "per-launch market",
        "accessControl": "marketState == ACTIVE; base tokens debited from margin base balance",
        "assetMovement": "base locked from margin (may fill on placement)",
        "payableValueRule": "nonpayable",
        "allowanceSpender": None,
        "nativeOrErc20": "margin-balance debit of the launch token",
        "slippage": "exact grid terms; postOnly guards unwanted fills",
        "eventsDecoded": ["OrderCreated", "Trade"],
        "errorsDecoded": ["PriceError", "SizeError", "TickSizeError", "MarketStateError", "PostOnlyError", "InsufficientBalance"],
        "retryPolicy": "safe to retry after revert",
        "screens": SCREENS_KURU,
    },
    {
        "contract": "OrderBook",
        "signature": "batchCancelOrdersNoRevert(uint40[])",
        "caller": "connected wallet (order owner)",
        "target": "per-launch market",
        "accessControl": "order.ownerAddress must be the caller; market not HARD_PAUSED",
        "assetMovement": "locked funds credited back to margin balance",
        "payableValueRule": "nonpayable",
        "allowanceSpender": None,
        "nativeOrErc20": "n/a",
        "slippage": "n/a",
        "eventsDecoded": ["OrdersCanceled (entries of 0 = id not cancelled)"],
        "errorsDecoded": ["MarketStateError", "WrongOrderTypeCancel"],
        "retryPolicy": "idempotent by construction; preferred over strict batchCancelOrders",
        "screens": SCREENS_KURU,
    },
    {
        "contract": "OrderBook",
        "signature": "batchCancelOrders(uint40[])",
        "caller": "connected wallet (order owner)",
        "target": "per-launch market",
        "accessControl": "order.ownerAddress must be the caller; market not HARD_PAUSED",
        "assetMovement": "locked funds credited back to margin balance",
        "payableValueRule": "nonpayable",
        "allowanceSpender": None,
        "nativeOrErc20": "n/a",
        "slippage": "n/a",
        "eventsDecoded": ["OrdersCanceled"],
        "errorsDecoded": ["OrderAlreadyFilledOrCancelled", "WrongOrderTypeCancel", "MarketStateError"],
        "retryPolicy": "all-or-nothing per tx; on OrderAlreadyFilledOrCancelled fall back to NoRevert variant",
        "screens": SCREENS_KURU,
    },
    {
        "contract": "OrderBook",
        "signature": "placeAndExecuteMarketBuy(uint96,uint256,bool,bool)",
        "caller": "connected wallet",
        "target": "per-launch market (NATIVE_IN_QUOTE type for MON-native launches)",
        "accessControl": "marketState == ACTIVE; margin variant debits margin quote balance",
        "assetMovement": "quote in (native msg.value or margin debit) -> base tokens to margin/wallet; unfilled remainder refunded",
        "payableValueRule": "native non-margin: msg.value in [cost(size), cost(size+1)) exact bracket (cost = ceil(size*1e18/pricePrecision) at 18-dec quote); margin/ERC20 path: msg.value == 0",
        "allowanceSpender": "non-margin ERC20 quote only: quote approve -> market (pulls into marginAccount)",
        "nativeOrErc20": "NATIVE_IN_QUOTE market: native MON; isMargin true uses margin balance with value 0",
        "slippage": "minAmountOut on received base tokens; isFillOrKill reverts on partial",
        "eventsDecoded": ["Trade"],
        "errorsDecoded": ["NativeAssetInsufficient", "NativeAssetSurplus", "NativeAssetNotRequired", "SlippageExceeded", "InsufficientLiquidity", "MarketStateError", "InsufficientBalance"],
        "retryPolicy": "safe to retry after revert; refunds of unfilled remainder are automatic",
        "screens": SCREENS_KURU,
    },
    {
        "contract": "OrderBook",
        "signature": "placeAndExecuteMarketSell(uint96,uint256,bool,bool)",
        "caller": "connected wallet",
        "target": "per-launch market",
        "accessControl": "marketState == ACTIVE; margin variant debits margin base balance",
        "assetMovement": "base tokens in (margin debit or direct transferFrom into marginAccount) -> quote credited (native out or margin credit)",
        "payableValueRule": "msg.value == 0 on NATIVE_IN_QUOTE markets (native leg is the quote side of buys only)",
        "allowanceSpender": "non-margin: launch token approve -> market",
        "nativeOrErc20": "base leg is ERC20; quote payout is native MON (NATIVE_IN_QUOTE) or margin credit",
        "slippage": "minAmountOut on received quote; isFillOrKill reverts on partial",
        "eventsDecoded": ["Trade"],
        "errorsDecoded": ["NativeAssetNotRequired", "SlippageExceeded", "InsufficientLiquidity", "MarketStateError", "InsufficientBalance"],
        "retryPolicy": "safe to retry after revert",
        "screens": SCREENS_KURU,
    },
    {
        "contract": "RetroPickFeeEscrowV2",
        "signature": "claim()",
        "caller": "connected wallet (beneficiary)",
        "target": "escrow 0xb0312b0412c3BAa11895A6c4FeeC7CD9A01c2D96",
        "accessControl": "claims caller's own native escrow balance",
        "assetMovement": "native MON escrow balance -> wallet",
        "payableValueRule": "nonpayable",
        "allowanceSpender": None,
        "nativeOrErc20": "native MON",
        "slippage": "n/a",
        "eventsDecoded": ["NativeClaimed"],
        "errorsDecoded": ["ZeroAmount", "InsufficientCredit", "PhysicalBalanceDeficit", "TransferFailed"],
        "retryPolicy": "safe to retry; balanceOf(msg.sender) is the exact claimable",
        "screens": SCREENS_CLAIMS,
    },
    {
        "contract": "RetroPickFeeEscrowV2",
        "signature": "claimToken(address)",
        "caller": "connected wallet (beneficiary)",
        "target": "escrow 0xb0312b0412c3BAa11895A6c4FeeC7CD9A01c2D96",
        "accessControl": "claims caller's own per-token escrow balance",
        "assetMovement": "escrowed ERC20 (e.g. vested launch tokens) -> wallet",
        "payableValueRule": "nonpayable",
        "allowanceSpender": None,
        "nativeOrErc20": "ERC20",
        "slippage": "n/a",
        "eventsDecoded": ["TokenClaimed"],
        "errorsDecoded": ["ZeroAmount", "InsufficientCredit", "PhysicalBalanceDeficit", "InexactTokenTransfer"],
        "retryPolicy": "safe to retry; partial variant claimToken(token, amount) also available",
        "screens": SCREENS_CLAIMS,
    },
    {
        "contract": "RetroPickBuybackVaultV2",
        "signature": "release(address)",
        "caller": "connected wallet = vest beneficiary (creator or protocol recipient)",
        "target": "vault 0x2D746643E0BA37F127b38A4C04866a123895BE09",
        "accessControl": "msg.sender must equal vestingTerms(token).creatorRecipient or .protocolRecipient",
        "assetMovement": "vested launch tokens credited to FeeEscrow balances (claim afterwards)",
        "payableValueRule": "nonpayable",
        "allowanceSpender": None,
        "nativeOrErc20": "ERC20 via escrow credit",
        "slippage": "n/a",
        "eventsDecoded": ["Released"],
        "errorsDecoded": ["NotVestBeneficiary", "NotFactory"],
        "retryPolicy": "no-op (returns 0) when nothing newly vested; releasable(token) is the precheck",
        "screens": SCREENS_CLAIMS,
    },
    {
        "contract": "RetroPickLauncherTokenV2",
        "signature": "approve(address,uint256)",
        "caller": "connected wallet",
        "target": "per-launch token",
        "accessControl": "token holder only",
        "assetMovement": "allowance grant (no asset movement)",
        "payableValueRule": "nonpayable",
        "allowanceSpender": "spender set by the flow: curve (curve sell), MarginAccount (Kuru base deposit), market (non-margin market sell)",
        "nativeOrErc20": "ERC20",
        "slippage": "n/a",
        "eventsDecoded": ["Approval"],
        "errorsDecoded": ["ERC20InvalidSpender"],
        "retryPolicy": "idempotent overwrite",
        "screens": SCREENS_TRADE + SCREENS_KURU,
    },
    {
        "contract": "ERC20MetadataInterface",
        "signature": "approve(address,uint256)",
        "caller": "connected wallet",
        "target": "USDC 0x534b2f3A21130d7a60830c2Df862319e593943A3",
        "accessControl": "USDC holder only",
        "assetMovement": "allowance grant",
        "payableValueRule": "nonpayable",
        "allowanceSpender": "the launch's curve (ERC20-quote curve buy)",
        "nativeOrErc20": "ERC20 (qualified interface only)",
        "slippage": "n/a",
        "eventsDecoded": ["Approval"],
        "errorsDecoded": [],
        "retryPolicy": "idempotent overwrite",
        "screens": SCREENS_TRADE,
    },
]

# ---------------------------------------------------------------------------
# Generation
# ---------------------------------------------------------------------------


def main() -> int:
    manifest = json.loads(MANIFEST.read_text())
    catalog = {}
    manifest_counts = {}
    for entry in manifest["contracts"]:
        name = entry["contractName"]
        abi = json.loads((ABI_DIR / entry["abiFile"]).read_text())
        catalog[name] = abi
        manifest_counts[name] = (entry.get("functions"), entry.get("events"), entry.get("errors"))

    missing_contracts = set(catalog) - set(CLASS)
    if missing_contracts:
        print(f"COVERAGE FAILURE: unclassified contracts: {sorted(missing_contracts)}", file=sys.stderr)
        return 1
    extra = set(CLASS) - set(catalog)
    if extra:
        print(f"COVERAGE FAILURE: classification for unknown contracts: {sorted(extra)}", file=sys.stderr)
        return 1

    out_contracts = {}
    counts = {"contracts": len(catalog), "functions": 0, "events": 0, "errors": 0}
    problems = []

    for name in sorted(catalog):
        abi = catalog[name]
        spec = CLASS[name]
        fns = [i for i in abi if i.get("type") == "function" and i.get("name")]
        evs = [i for i in abi if i.get("type") == "event"]
        errs = [i for i in abi if i.get("type") == "error"]
        counts["functions"] += len(fns)
        counts["events"] += len(evs)
        counts["errors"] += len(errs)

        fn_out, ev_out, err_out = {}, {}, {}
        seen_fn, seen_ev, seen_err = set(), set(), set()

        for hint, disp in spec["fn"].items():
            try:
                item = resolve(hint, fns, name, "fn")
            except SystemExit as e:
                problems.append(str(e))
                continue
            sig = canonical(item)
            if sig in seen_fn:
                problems.append(f"{name}: duplicate classification for {sig}")
            seen_fn.add(sig)
            fn_out[sig] = {"mutability": item.get("stateMutability", "nonpayable"), **disp}
        for hint, disp in spec["ev"].items():
            try:
                item = resolve(hint, evs, name, "ev")
            except SystemExit as e:
                problems.append(str(e))
                continue
            key = event_key(item, evs)
            if key in seen_ev:
                problems.append(f"{name}: duplicate classification for event {key}")
            seen_ev.add(key)
            ev_out[key] = disp
        for hint, disp in spec["err"].items():
            try:
                item = resolve(hint, errs, name, "err")
            except SystemExit as e:
                problems.append(str(e))
                continue
            key = error_key(item, errs)
            if key in seen_err:
                problems.append(f"{name}: duplicate classification for error {key}")
            seen_err.add(key)
            err_out[key] = disp

        for f in fns:
            if canonical(f) not in seen_fn:
                problems.append(f"{name}: no disposition for function {canonical(f)}")
        for e in evs:
            if event_key(e, evs) not in seen_ev:
                problems.append(f"{name}: no disposition for event {event_key(e, evs)}")
        for e in errs:
            if error_key(e, errs) not in seen_err:
                problems.append(f"{name}: no disposition for error {error_key(e, errs)}")
        for sig in seen_fn - {canonical(f) for f in fns}:
            problems.append(f"{name}: classification targets absent function {sig}")
        for key in seen_ev - {event_key(e, evs) for e in evs}:
            problems.append(f"{name}: classification targets absent event {key}")
        for key in seen_err - {error_key(e, errs) for e in errs}:
            problems.append(f"{name}: classification targets absent error {key}")

        mf, me, mr = manifest_counts.get(name, (None, None, None))
        if (mf, me, mr) != (len(fns), len(evs), len(errs)):
            problems.append(
                f"{name}: manifest counts {mf}/{me}/{mr} != actual {len(fns)}/{len(evs)}/{len(errs)}"
            )

        ownership = next(
            (c.get("ownership") for c in manifest["contracts"] if c["contractName"] == name), None
        )
        out_contracts[name] = {
            "ownership": ownership,
            "applicationRole": spec["role"],
            "summary": spec["summary"],
            "functions": fn_out,
            "events": ev_out,
            "errors": err_out,
        }

    if problems:
        print("COVERAGE FAILURE — unresolved items:", file=sys.stderr)
        for p in problems:
            print(f"  - {p}", file=sys.stderr)
        return 1

    doc = {
        "meta": {
            "chainId": CHAIN_ID,
            "generatedFrom": "apps/abi",
            "baselineCommit": BASELINE_COMMIT,
            "counts": counts,
            "verifiedAgainst": {
                "manifestCounts": True,
                "notes": (
                    "Recomputed from the 27 artifact ABIs: 517 functions / 147 events / 325 errors "
                    "(raw ABI entries, incl. 21 constructors and 11 receive entries excluded from the "
                    "counting convention, and one byte-identical duplicate InsufficientBalance() error "
                    "declaration inside KuruAMMVault that maps to a single disposition key). "
                    "Matches apps/abi/manifest.json exactly."
                ),
            },
        },
        "dispositionLegend": {
            "USER_WRITE": "Wallet-originated financial write the application exposes on its allowlist.",
            "LIFECYCLE_WRITE": "Permissionless protocol lifecycle action surfaced as a recovery/keeper path, not a trade.",
            "ADMIN_ONLY": "Owner/admin-gated operation; must never be exposed by the frontend.",
            "PROTOCOL_INTERNAL": "Callable only by trusted protocol actors (factory/coordinator/executor/markets); reject if user-originated.",
            "READ": "View/pure call used for UI state or SDK wiring.",
            "NOT_SURFACED_WRITE": "User-reachable write deliberately excluded from the v1 allowlist (advanced MM primitives, wallet-native ops, future surfaces).",
        },
        "contracts": out_contracts,
        "frontendWrites": FRONTEND_WRITES,
    }

    OUT.write_text(json.dumps(doc, indent=2, sort_keys=True) + "\n")
    print(f"OK: wrote {OUT}")
    print(f"counts: {counts}")
    print("coverage: 100% (every function/event/error of every contract has a disposition)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
