# H3 — Security Write Allowlist Handoff

```text
HANDOFF_ID: H3-SECURITY-WRITE-ALLOWLIST
FROM: SECURITY_AGENT (SMART_CONTRACT_SECURITY)
TO: SDK_AGENT + FRONTEND_AGENT + CONTRACT_AGENT + ORCHESTRATOR
PRODUCT: RetroPick Launchpad Core V2 (Monad Testnet 10143)
GOAL_ID: RETROPICK-V2-FULLSTACK-INTEGRATION
REQUIREMENTS: Phase 3 gate FRONTEND_WRITE_SECURITY — approve the exact set of contract writes the
  application may expose, and audit the SDK write-boundary implementation that produces them.
COMMIT/REF: branch codex/v2-fullstack-integration, worktree 2218389 (docs-only diff over 8d8650a)
```

## Capability / skill used

SMART_CONTRACT_SECURITY — `smart-contract-security` + `evm-security` review discipline (architecture → trust/privilege
map → asset flows → value/allowance rules → replay/retry), executed as read-only source verification against the
deployed pin.

## INPUTS_CONSUMED

- `development/fullstack-integration/abi-capabilities.json` — `frontendWrites` (20 entries) + per-contract dispositions
- `packages/launchpad-sdk/src/{prepare,wallet,decode,registry,model,math,chain,abi,release,kuru,book}.ts`
- Authoritative Solidity: `contracts/src/v2/**` at worktree (deployed pin `f0363249` — only diff since pin is
  formatting in RetroPickBuybackVaultV2.sol, semantically identical)
- Pinned Kuru source `/tmp/retropick-kuru-contracts/contracts/{OrderBook,MarginAccount}.sol`, `interfaces/IOrderBook.sol`
- `apps/abi/*` (deployed artifact ABIs, incl. event-name verification via `@retropick/abi/abi`)
- `docs/contracts/V2_APPLICATION_CAPABILITY_MAP.md` §5, `docs/frontend/RETRO_UI_REVERSE_MAP.md` (H2), handoffs H1/H2
- `.agent/HANDOFFS.md` (field contract)

## OUTPUTS_PRODUCED

1. `development/fullstack-integration/write-allowlist.md` — the signed-off decision document: per-write verification
   (caller/target, access control, asset movement, max-payable rules, spender/allowance matrix, native-vs-ERC20
   branching, slippage semantics, replay/retry, events/errors), verdicts, the binding max-payable/approval matrix,
   the explicit exclusion list, the conditions register (C-1..C-9), and the final allowlist table.
2. This handoff.
3. Two SECURITY_AGENT capability-matrix rows updated in `development/fullstack-integration/README.md`.

## VERIFICATION

- Every `msg.value` rule re-derived from source (not from docs): factory `LaunchFeeNotPaid` sol:706; curve
  `NativeValueMismatch`/`UnexpectedNativeValue` sol:582-603; MarginAccount `NativeAssetMismatch` sol:217-229;
  OrderBook native bracket vs `NativeAssetNotRequired` margin path sol:740-756/796-808.
- SDK curve math re-derived: fee-then-CFM order, floor arithmetic, remaining-cap semantics and the contract's
  price-bound slippage form (`spent·minTokensOut ≤ received·tokensOut`, curve sol:427) — SDK minimum provably passes
  every legitimate clamped fill.
- Graduation chain re-walked: factory.graduate → coordinator.secure → factory.secureCurve → curve.graduate; binding
  precondition is `readyToGraduate() ⇔ sellableTokens()==0` (curve sol:352-355,535), exposing SDK defect C-1.
- Kuru grid/funds re-derived from OrderBook: price/size/tick/min/max checks (sol:183-208,254-278), margin-only debit
  path, `getMarketParams` tuple order (sol:1334-1352), `OrderCreated` as sole id source; SDK cost estimate proven an
  upper bound of the contract debit.
- Escrow/vault claims re-derived: `claim()` = full native balance (escrow sol:63-66); `release(token)` restricted to
  the vest's creator/protocol recipient (vault sol:184-188), paying via escrow token credit → requires `claimToken`
  (missing SDK prepare → C-5); deployed event names confirmed `NativeClaimed`/`TokenClaimed`/`Released` → decode
  defect C-6.
- Wallet layer audit: only `eth_requestAccounts`, `eth_chainId`, `wallet_switchEthereumChain`,
  `wallet_addEthereumChain`; EIP-6963 discovery; no keys, no signing methods, no arbitrary passthrough.
- bigint audit: no `Number()` on any financial value; coercions limited to phase enum, bounded uint32 price, uint40
  order ids, decimals.
- Forbidden-surface scan: no admin/config/sweep/ownership function, no `launchTokenFor`, no Permit2/PoolManager/
  PositionManager/Hook surface anywhere in `prepare.ts` or the approval pipeline.

## EVIDENCE

- Decision document: `development/fullstack-integration/write-allowlist.md` (verdicts 17 APPROVED /
  3 APPROVED-WITH-CONDITIONS / 0 REJECTED; surface amendment adds `GraduationCoordinatorV2.complete(address)`).
- All file:line references in the conditions register point at the current worktree HEAD 2218389.

## INVARIANTS_NOT_CHANGED

- No source under `apps/`, `packages/`, `contracts/` modified; no git writes; no network writes; read-only review.
- Only owned artifacts written: this handoff, `write-allowlist.md`, and the two SECURITY_AGENT rows in the campaign
  README. ABI catalog untouched.

## OPEN_BLOCKERS

- For SDK_AGENT (Phase 5 gate): C-1 (graduate precondition, prepare.ts:218-220), C-5 (missing `prepareFeeClaimToken`),
  C-6 (decode.ts:77 event names), plus C-2/C-3/C-4/C-7/C-8/C-9 as specified in the allowlist §4.
- For CONTRACT_AGENT (metadata only): add `GraduationCoordinatorV2.complete(address)` to `frontendWrites`; note
  `GraduationCompleted` (both venues) vs `PoolGraduated` (V4-only) on entry 5.
- For FRONTEND_AGENT: opening-buy control must stay unsupported (confirmed: no bundled opening buy exists on any
  launch path); claims screen must surface the release→claimToken two-step.

## STATUS

**HANDOFF READY** — Phase 3 `FRONTEND_WRITE_SECURITY` allowlist decision complete (PASS with tracked SDK conditions);
Phase 7 re-verification will re-check C-1..C-9 against the shipped SDK.
