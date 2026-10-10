# MetaMask Best Agent Wallet Plugin — AllInOne Agent Integration Specification
**RetroPick Metropolis 2026 | Draft plan 2026-10-11 | Deadline 2026-10-14 10:59 GMT+7**
**Eligibility:** Onchain Finance & Trading. **Prize:** $2,500 single. **Status:** NOT IMPLEMENTED/NOT PROVEN unless evidence linked below. Read `00-MASTER-PLAN.md` and `09-AGENTS-HANDOFF.md` first.

## Product thesis
Risk-capped Kuru limit-order agent and cancellation assistant. Do not add a sponsor logo without the sponsor's required working feature.

## Exact integration boundary
Inspect before editing: `apps/web/lib/live/kuru.ts`, `apps/web/features/live/kuru.tsx`, `new integrations/metamask-agent-wallet/ and skills/retropick-trader/SKILL.md`.
Current V2 is live Monad Testnet 10143, Factory→Curve→Coordinator→Kuru; `deployments/monad-testnet/v2.json` is deployment registry. Do not use obsolete Base Sepolia Go/fe-v1 as patch targets. All contract names, methods and sponsor SDK method names MUST be reverified against installed versions; do not invent API signatures.

## Sponsor eligibility and proof gate
**MetaMask Best Agent Wallet Plugin** must deliver the actual integrated feature described below, not a mock. Track Onchain Finance & Trading; prize $2,500 single. Read official bounty wording captured in user portal and recheck at submission. Demo must be on deployed Monad product, with sponsor-specific working evidence. This document is a development specification, not an eligibility certification.

## Architecture and implementation plan
Install official Agent Wallet >=6.2.0 and inspect actual plugin template/manifest and mm CLI before coding; plugin read-only market discovery, verified Kuru market identity and precision, bounded quote/limit order/cancel action; simulate, check allowlist, max spend, tick, min size, expiry, slippage and account balance; all writes submitted exclusively through MetaMask Agent Wallet signing/policy/MFA; include installable plugin, SKILL.md, README, explicit user approvals.

### Agent execution checklist
1. Freeze baseline: `git rev-parse HEAD`, branch and working tree; inspect source and SDK docs; write version/chain compatibility matrix.
2. Build read-only adapter first with schema validation, typed errors, idempotency key, deadline and explicit supported-network checks.
3. Implement write flow only after simulation/quote checks and signer boundary review; record exact authorization and destination.
4. Integrate behind an independent feature flag and a truthful disabled state. No secret exposed through `NEXT_PUBLIC_*`.
5. Add telemetry for request ID, chain, block, tx hash, status, duration and sanitized failure category; redact sensitive data.
6. Add unit tests, failure/retry tests, real integration smoke and Playwright/browser or CLI E2E.
7. Record sponsor evidence under `evidence/hackathon/metropolis/sponsors/04-sponsor/`; write submission answer only after proof.
8. Disable flag or revert additive integration if test gates fail; never mutate existing V2 deployment or custody.

## State machine and security requirements
Proposed feature state: DISABLED → CHECKING → READY → ACTION_PENDING → CONFIRMED, with BLOCKED, FAILED, EXPIRED and RECOVERY_REQUIRED branches. For transaction-dependent features, distinguish submitted from confirmed and reconciled. Use onchain receipts and supported sponsor APIs as authoritative. BigInt atomic amounts, bounded allowances, chain and contract allowlists, replay/idempotency protection, retry backoff and no unbounded automated trades.

### Mandatory adversarial cases
Policy denies; MFA pending; insufficient margin; precision mismatch; stale book; partial fill; duplicate retry; network mismatch; unauthorized spend.

## Tests and acceptance
**Unit:** serialization, decimal/chain validation, stale data, state transition, wrong signature, timeout, replay, failure recovery.
**Integration:** sponsor endpoint/SDK using current pinned version, confirmed contract identity, network compatibility, provider outage.
**Onchain:** receipts and actual contract state changes where required; never represent simulated events as real transactions.
**E2E:** clean browser/profile, mobile when applicable, two-wallet flows when relevant, no inaccessible login.
**Definition of done:** Plugin install output, mm version/chains, policy denial test, real Monad order and cancel tx via Agent Wallet. Attach exact URLs/receipts, commit SHA, SDK versions, commands and outputs; fail closed if unavailable.

## Sponsor demo
Install plugin→ask agent to place capped limit order→policy/sign→confirmed→cancel, ≤5 minutes. Sponsor-specific limit is normally <=2 minutes; MetaMask permits <=5 minutes. Do not claim a successful transaction without a receipt.

## Submission response template (fill after evidence)
"RetroPick integrates MetaMask Best Agent Wallet Plugin to risk-capped kuru limit-order agent and cancellation assistant. The integration operates on Monad Testnet [chainId and verified contract address]. Our implementation uses [exact official SDK/API endpoint, pinned version] in [exact repo paths]. A user can [actual completed action], evidenced by [real tx hash / CLI simulation / GraphQL result]. Safety controls include [verified controls]. Current limitations: [actual limitations]."

## 30/60/90-day expansion
**30 days:** harden integration, run supervised external tester sessions and fix reliability gaps.
**60 days:** security review, observability and user cohort/market-quality analytics; expand only verified supported networks.
**90 days:** gated mainnet-readiness decision, commercial pilots and measured retention; no production release without risk/legal/operational gates.

## Rollback
Disable only this sponsor's feature flag, revert its isolated UI/adapter PR, retain historical proof and deployed contracts; never rollback V2 custody by changing onchain owner or withdrawing locked liquidity.

## Official starting points
https://docs.metamask.io/agent-wallet/ (plugin examples and version >=6.2.0)


---
## 2026-10-11 verified MetaMask plugin architecture, official skills and safety
**SOURCE-VERIFIED:** https://github.com/MetaMask/agent-wallet-plugin-examples , especially `plugins/sample/package.json` and `plugins/sample/src/commands/demo/submit.ts`. This is a genuine **oclif CLI plugin**, not a standalone agent `SKILL.md` pretending to be installed. Plugin manifest has `mm.schemaVersion:1`, `mm.minCliVersion:"^6.2.0"`, per-command `capabilities` such as `wallet-read`, `wallet-submit`, dataAccess scopes and oclif command entries. First-party plugin sample only obtains `this.ctx.walletExecutor(io,this.pluginCommandId)`; it does NOT demonstrate a completed arbitrary write transaction. Inspect the returned executor's TypeScript methods before implementing write calls. https://docs.metamask.io/agent-wallet/troubleshooting/ requires Node >=22.18 and `mm doctor`.

### Agent-aware installation and docs
```bash
node --version                        # >=22.18
npm install -g @metamask/agent-wallet@latest
npx skills add MetaMask/agent-skills  # official CLI skill, inspect its skill target version
mm --version
mm doctor
mm chains list --json
mm config get
# After human permission review in isolated development only:
mm config set experimentalPlugins true
mm config set experimentalAllowUnverifiedInstalls true
# clone official examples and inspect plugins/sample/package.json before using local plugin install
# mm plugins install file:<local-plugin-directory>  (interactive consent)
```
MetaMask official agent skill lives at https://github.com/MetaMask/agent-skills/blob/main/skills/metamask-agent-wallet/SKILL.md ; currently targets CLI v7.0.0 in frontmatter, but versions move. Do not blindly accept its version as installed. `mm plugins` is oclif and uses different flag handling from standard `mm` commands. Never use `--accept-permissions` before inspecting EVERY command ID, `capabilities`, and `dataAccess`. Testnet availability must come from `mm chains list --json`.

### Plugin skeleton verified by upstream (not a complete write execution)
```ts
import { type CommandIO, PluginCommand } from "@metamask/agent-wallet/plugin";
export default class RetroPickOrder extends PluginCommand<{ walletSubmit:"granted" }> {
  static override requiresAuth = true;
  protected readonly pluginCommandId = "retropick:order";
  async execute(io: CommandIO) {
    const executor = await this.ctx.walletExecutor(io, this.pluginCommandId);
    // inspect current executor methods, build simulation + explicit policy flow,
    // then use ONLY supported wallet-submit API: no private-key signing.
    void executor;
    return { walletSubmit: "granted" as const };
  }
}
```
Mirror sample `package.json#mm.commands` entry `{id:"retropick:order",capabilities:["wallet-submit"],dataAccess:[]}`, oclif manifest build and reviewed install. Add `skills/retropick-trader/SKILL.md` as an agent instruction **in addition** to the plugin, not instead of it. Pin the plugin's CLI dependency and test against exactly the installed CLI.

### RetroPick-specific safe execution path
1. User requests order size, side and market. Plugin fetches canonical `getMarketParams`, `getL2Book`, verified market identity and margin, as used in `apps/web/lib/live/kuru.ts`.
2. Convert price+size into Kuru tick/size **bigint** precision (real deployed example uses 1e8; do not reuse for all market creations), check outstanding collateral, wallet policy budget, allowance and expiry.
3. Return a **reviewable quote** with worst-case notional/fees and explicit `ALLOW/DENY/REQUIRE_MFA`. UI and plugin must both reject stale books. Never allow arbitrary contract address from an LLM prompt.
4. The user approves plugin permissions and wallet operation; invoke only supported MetaMask executor for simulation/submission (read the type declarations). Wait for tx receipt and decode `OrderCreated` / `Trade`. Cancel only if `s_orders(orderId).owner == agent wallet account`.
5. Replay protection: durable intent ID and receipt reconciliation on restart; don't submit twice because the CLI timed out, or route around MFA. `AWAITING_MFA` is pending, not failure.
6. Evidence: plugin install, command call, exact approved policy, negative denial, order/receipt and cancel receipt on chain 10143. A `walletSubmit:"granted"` return **alone is not a bounty win**.

### Sponsor-winning innovation — **Controlled Autopilot, Not Unbounded Arb**
A first-order guardrailed "market-maker copilot": monitor Kuru spreads read-only, propose maker orders under preapproved risk budget, request wallet policy/MFA for placement, offer single-command cancel and automatically STOP on stale quotes/chain drift. Display transaction and risk trace, not LLM prose. Avoid autonomous parity arbitrage claims until outcome-token YES/NO books actually exist and both legs are provably executable.
