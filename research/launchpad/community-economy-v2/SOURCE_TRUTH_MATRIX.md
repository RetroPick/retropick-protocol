# Current-source truth matrix

Iteration 002 extends the frozen matrix below; its 31/31 count describes the original baseline, not today's experiment. Canonical files remain unchanged. Prior iteration compiler reconciliation covers 45 canonical contract/interface artifacts and archived/consumer ABI comparisons. The new scoped evidence contains compiler-derived experimental ABIs, source hashes and runtime identities. Exhaustive manual authority coverage of every venue and production release gates remains open.

| Financial authority | Actual current experiment | Rights preserved / limitation |
|---|---|---|
| Factory owner | Once-only future builder choice; existing global defaults prospective | Community curve binding immutable; legacy recipient/buyback override rejected for CE launches |
| Factory launch identity | token -> recorded curve; per-launch sealed CE flag | Arbitrary sender/token cannot register a fee source |
| Curve | Custodies tracked quote, pending F/T and token reserves | Settlement reduces tracked quote by P+C; real reserves unchanged; net graduation reserves alone secured |
| Protocol fee escrow | Original protocol P liability custody | Router does not allocate or custody P a second time |
| Community router | One immutable launch/asset/source; actual C only | Original beneficiary credits immutable except their own withdrawal; no rescue role |
| Policy registry | Delayed future allocation; immutable bounds/history/source | Source checkpoint authentic, atomic, guarded and checked before epoch changes |
| Controller / guardian | Three-day handoff / seven-day recovery; controller generation | No balance custody; controller change invalidates pending policy, not old claims |
| Treasury recipient | Fixed published module address, dust destination | EOA is allowed; no timelock guarantee until vault implementation qualifies |
| CE v4 executor | Actual registration snapshots zero hook fee/tax and disabled buyback | LP fee rights remain independent; continuous CE fee adapter blocked |

New API/event authority is in compiler-abis.json under evidence/launchpad/community-economy-v2/2026-10-31-authenticated-curve/. These are compiler evidence, not modified production ABI artifacts. Original deployment identities were not requalified.

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
