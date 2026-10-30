# Current-source truth matrix

Baseline: 28a4744dcc8005da285f9e924ba7841073daee0b. Both lanes: 31 Solidity files; 30 identical pairs, one trailing blank-line difference in interfaces/IKuruV2.sol. Full SHA-256 pairs, declaration locations, test/script lists and tracked ABI-consumer candidates are in inventory.json. Declaration extraction is lexical and must be reconciled with compiler ABIs before Phase 0 closes.

| Feature / supplied claim | Source result | Test evidence | Fork verified in this campaign | Deployment evidence | Gap |
|---|---|---|---|---|---|
| Fixed issuance to curve | CONFIRMED: LauncherToken constructor mints once; ERC20Burnable permits supply reduction | Existing curve-state/deployer tests passed during planning | No | Historical manifests not requalified | Do not equate fixed initial issuance with unburnable supply |
| Native/ERC20 pull escrow | CONFIRMED: FeeEscrow has separate liabilities and exact sender/recipient deltas | Eight escrow tests passed during planning | No | Not requalified | External token balance destruction can still cause deficit |
| Buyback locks five years | CONFIRMED: BuybackVault VESTING_DURATION; no automatic burn | Existing lifecycle tests inventoried, not rerun here | No | Not requalified | New strategy caller is not authorized by existing vault |
| Creator ceiling can reach 10% | CONFIRMED: Factory individual ceiling 1000 BPS, combined ceiling 2000 BPS | Boundary campaign pending | No | Not requalified | Ceiling is not a recommended product fee |
| Creator immediate handoff / delayed owner override | CONFIRMED: Factory transferCreatorFeeRecipient vs three-day owner proposal | Existing qualification test inventoried | No | Not requalified | Delayed override remains broad authority |
| Anti-snipe exemption stub | CONFIRMED: Curve exemptFromSnipeTax does not update state | Existing no-op test passed during planning | No | Not requalified | Documentation must not promise anti-sniping |
| Salt omitted, ordinary new | CONFIRMED: LaunchDeployment has no salt; deployLaunch uses new | Existing salt test inventoried | No | Not requalified | Factory comments promise unavailable deterministic addresses |
| Coordinator and two executors | CONFIRMED in source | Mixed-tree setup ambiguity; scoped run passed authority tests and two coordinator invariant properties | No | Historical testnet status only | Gate requires reproduced authority/invariant tests |
| v4 hook pool-specific fees | CONFIRMED: pendingFees keyed by PoolId and currency | Complete v4 campaign pending | No | Not requalified | Fees may be launch token rather than quote |
| Kuru fee rights available | NOT ESTABLISHED; no creator-fee claim adapter | No entitlement test | No | No live collector qualification | BLOCKED_EXTERNAL_CAPABILITY |
| Existing tests provide partial coverage | CONFIRMED: 17 Solidity files, including two invariant suites | Partial measured run only | No | Not applicable | Test presence is not full qualification |

## Documentation contradictions

- docs/launchpad/GRADUATION.md describes Kuru as TARGET; current source implements it.
- Older development documents describe a future coordinator extraction that current source already contains.
- Factory salt comments name CREATE2 and predictLaunchAddresses; the current deployer implements neither.
- RetroPickQuoteAssetPolicyV2 restricts exact native/Circle identities, while the Factory's current RetroPickQuoteAssetRegistryV2 permits owner-admitted contracts satisfying configured decimals. The Circle constant alone is not enforcement.
- Several relevant ADRs remain PROPOSED. Implemented/testnet behavior does not silently accept them.

No suspected security issue in this table is classified as a verified exploit.
