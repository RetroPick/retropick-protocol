# M6 executable property map

Status: local experimental evidence; no audit or global release qualification.

| Property | Current evidence | Limit |
|---|---|---|
| CE-I-001/002/004/008: funded conservation, complete BPS split, backing, no double claim | Router unit/fuzz13 tests; ghost-ledger stateful model; genuine native/Q6 lifecycle | Models use explicit source/venue doubles; genuine lifecycle is a separate action sequence |
| CE-I-003/010/026: segregated assets and launch claims | Explicit quote/token ledgers; real two-launch distinct Router/Vault bindings; protocol escrow per asset | No staking module; additional cross-launch adversarial sequence expansion remains useful |
| CE-I-005/006/013/019/020/024: temporal economic rights and constitutional authority | Registry bounds/history tests reused unchanged; real checkpoint in genuine lifecycle; old credits unchanged by activation; model proposal/cancel/activate/controller rotation | No claim that controller recovery creates Treasury spending authority |
| CE-I-007/017/021: independent recipients, failure/reentry injection | Reverting claimant, reentrant claim, false-return/deflationary token, callback activation and negative balance unit tests; actual creator/contributor claims in both genuine assets | Dedicated expanded callback matrix for the new Treasury remains pending |
| CE-I-009/022: legitimate income only | Donations never increase funded/credit; exact physical funding and source authentication; stateful ghost ledgers | No rewards module or APY claim |
| CE-I-011/012/014/027: protected reserves, atomic graduation, LP custody | Unchanged canonical Curve/Coordinator regression; real pool seed, receipt, NFT owner/liquidity and replay checks; Router rejects unfinalized/unlocked/changed-principal identity models | Live fork and new failure/retry venue campaigns remain unqualified |
| CE-I-015/016/018/028: supported capabilities and legacy behavior | V4-only Registry negatives; reserved venue1 rejection; preserved historical source/assertions; Factory/Coordinator ABI and executable-bytecode comparison | Metadata/codehash differs after source relocation/enum rename; historical deployment reproduction must use original source keys |
| CE-I-023: buyback budgets cannot be redirected | New mode rejects buybacks; old five-year buyback implementation and historical tests untouched | No new buyback execution strategy qualified |
| CE-I-025: bounded work and liveness | Registry max10 recipients; immediate allocation and pull claims; no unsettled venue epoch backlog | Maximum-cardinality gas and operator/Safe liveness still require expanded qualification |

Canonical LP supply, reserve, exact payout, fees, custody and graduation properties are retained through the unchanged financial implementations and scoped regression suites. Do not infer that every historical LP/CE property has a new independent adversarial proof merely because a broader suite passed.

The final accounting model runs256×128 for native and modeled six-decimal quote, with `fail_on_revert=true`. It explicitly reaches successful funding, settlement, claims, proposal, cancellation, activation and controller rotation before randomized actions. Expected invalid/replay/controller-generation cases assert their revert selectors; there is no catch-all suppression. Logs expose selector counts. This is not a genuine stateful PoolManager test, which remains separate from the deterministic genuine venue lifecycle.
