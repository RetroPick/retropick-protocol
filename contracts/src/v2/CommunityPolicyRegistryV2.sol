// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface ICommunityControllerV2 {
    function controller() external view returns (address);
    function controllerEpoch() external view returns (uint256);
}

interface ICommunityCheckpointV2 {
    function checkpoint(uint256 oldEpoch) external;
    function pending() external view returns (uint256);
}

/// @notice Noncustodial experimental policy lifecycle. Dependencies must be qualified separately.
/// @dev A successful mock checkpoint is not proof of authentic fee settlement.
contract CommunityPolicyRegistryV2 is ReentrancyGuard {
    struct Allocation {
        address beneficiary;
        uint16 bps;
        uint8 kind;
    }

    struct Bounds {
        uint16 maxCreatorBps;
        uint16 minTreasuryBps;
        uint16 maxTradeFeeBps;
        uint64 minDelay;
    }

    struct Proposal {
        bytes32 hash;
        uint256 nonce;
        uint256 epoch;
        uint256 effectiveAt;
        address proposer;
        uint256 authorityEpoch;
    }
    error Unauthorized();
    error InvalidPolicy();
    error InvalidBinding();
    error WrongProposal();
    error OutsideWindow();
    error CheckpointIncomplete();
    event PolicyProposed(uint256 indexed nonce, bytes32 indexed hash, uint256 effectiveAt);
    event PolicyCancelled(uint256 indexed nonce);
    event PolicyActivated(uint256 indexed epoch, bytes32 indexed hash);
    address public immutable launchToken;
    ICommunityControllerV2 public immutable authority;
    ICommunityCheckpointV2 public immutable source;
    uint16 public immutable tradeFeeBps;
    uint16 public immutable maxCreatorBps;
    uint16 public immutable minTreasuryBps;
    uint16 public immutable maxTradeFeeBps;
    uint64 public immutable minDelay;
    uint256 public constant EXECUTION_WINDOW = 7 days;
    uint256 public epoch = 1;
    uint256 public nextNonce;
    bytes32 public immutable initialPolicyHash;
    Proposal public pendingPolicy;
    // Kinds: 0 creator, 1 contributor, 2 treasury, 3 rewards, 4 buyback, 5 liquidity, 6 referral.
    mapping(uint8 => address) public module;
    mapping(uint256 => Allocation[]) private policies;
    mapping(uint256 => bytes32) public policyHash;
    Allocation[] private proposed;

    constructor(
        address token,
        ICommunityControllerV2 controller_,
        ICommunityCheckpointV2 checkpoint_,
        Bounds memory bounds,
        uint16 fee,
        address[5] memory modules,
        Allocation[] memory initial
    ) {
        if (
            token == address(0) || address(controller_).code.length == 0 || address(checkpoint_).code.length == 0
                || controller_.controller() == address(0) || modules[0] == address(0) || bounds.maxCreatorBps > 10000
                || bounds.minTreasuryBps > 10000 || bounds.maxTradeFeeBps > 2000 || fee > bounds.maxTradeFeeBps
                || bounds.minDelay < 3 days
        ) revert InvalidBinding();
        launchToken = token;
        authority = controller_;
        source = checkpoint_;
        tradeFeeBps = fee;
        maxCreatorBps = bounds.maxCreatorBps;
        minTreasuryBps = bounds.minTreasuryBps;
        maxTradeFeeBps = bounds.maxTradeFeeBps;
        minDelay = bounds.minDelay;
        for (uint8 i; i < 5; ++i) {
            module[i + 2] = modules[i];
        }
        _validate(initial);
        bytes32 h = keccak256(abi.encode(initial));
        initialPolicyHash = h;
        policyHash[1] = h;
        for (uint256 i; i < initial.length; ++i) {
            policies[1].push(initial[i]);
        }
        emit PolicyActivated(1, h);
    }
    modifier onlyController() {
        if (msg.sender != authority.controller()) revert Unauthorized();
        _;
    }

    function policyAtVersion(uint256 version) external view returns (Allocation[] memory) {
        if (version == 0 || version > epoch) revert InvalidPolicy();
        return policies[version];
    }

    function proposePolicy(Allocation[] calldata allocations)
        external
        onlyController
        nonReentrant
        returns (uint256 nonce)
    {
        if (pendingPolicy.hash != bytes32(0)) revert WrongProposal();
        _validate(allocations);
        nonce = ++nextNonce;
        bytes32 h =
            keccak256(abi.encode(block.chainid, address(this), launchToken, epoch, nonce, msg.sender, allocations));
        pendingPolicy = Proposal(h, nonce, epoch, block.timestamp + minDelay, msg.sender, authority.controllerEpoch());
        delete proposed;
        for (uint256 i; i < allocations.length; ++i) {
            proposed.push(allocations[i]);
        }
        emit PolicyProposed(nonce, h, block.timestamp + minDelay);
    }

    function cancelPolicy(uint256 nonce) external onlyController nonReentrant {
        if (pendingPolicy.hash == bytes32(0) || nonce != pendingPolicy.nonce) revert WrongProposal();
        delete pendingPolicy;
        delete proposed;
        emit PolicyCancelled(nonce);
    }

    function activatePolicy(uint256 nonce) external nonReentrant {
        Proposal memory p = pendingPolicy;
        if (
            p.hash == bytes32(0) || p.nonce != nonce || p.epoch != epoch
                || (p.proposer != authority.controller() || p.authorityEpoch != authority.controllerEpoch())
        ) {
            revert WrongProposal();
        }
        if (block.timestamp < p.effectiveAt || block.timestamp > p.effectiveAt + EXECUTION_WINDOW) {
            revert OutsideWindow();
        }
        // Always checkpoint, including apparent zero balances; real adapters must enter source guards.
        source.checkpoint(epoch);
        if (source.pending() != 0) revert CheckpointIncomplete();
        if ((p.proposer != authority.controller() || p.authorityEpoch != authority.controllerEpoch())) {
            revert WrongProposal();
        }
        ++epoch;
        Allocation[] memory a = proposed;
        bytes32 h = keccak256(abi.encode(a));
        policyHash[epoch] = h;
        for (uint256 i; i < a.length; ++i) {
            policies[epoch].push(a[i]);
        }
        delete pendingPolicy;
        delete proposed;
        emit PolicyActivated(epoch, h);
    }

    function _validate(Allocation[] memory a) private view {
        if (a.length == 0 || a.length > 10) revert InvalidPolicy();
        uint256 total;
        uint256 creator;
        uint256 treasury;
        for (uint256 i; i < a.length; ++i) {
            if (a[i].beneficiary == address(0) || a[i].bps == 0 || a[i].kind > 6) revert InvalidPolicy();
            for (uint256 j; j < i; ++j) {
                if (a[j].beneficiary == a[i].beneficiary) revert InvalidPolicy();
            }
            if (a[i].kind >= 2 && (module[a[i].kind] == address(0) || module[a[i].kind] != a[i].beneficiary)) {
                revert InvalidPolicy();
            }
            total += a[i].bps;
            if (a[i].kind == 0) creator += a[i].bps;
            if (a[i].kind == 2) treasury += a[i].bps;
        }
        if (total != 10000 || creator > maxCreatorBps || treasury < minTreasuryBps) revert InvalidPolicy();
    }
}
