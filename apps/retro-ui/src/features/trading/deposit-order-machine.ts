// "Deposit & place order" orchestration (campaign decision 3=A, gated).
// Composes two EXISTING prepared writes (SDK prepareMarginDeposit → prepareKuruLimitOrder/MarketOrder),
// each executed through the existing tx pipeline with its own wallet signature. No new ABI calls, no new math:
// the required collateral is the same quantity the SDK prepare step checks against the margin balance.

export type WriteResult = { kind: 'success'; hash: string } | { kind: 'failed'; reason: string; failure: 'rejected' | 'revert' | 'rpc' | 'unknown' };

export type FlowState =
  | { step: 'idle' }
  | { step: 'depositing' }
  | { step: 'refreshing'; depositHash: string }
  | { step: 'deposited'; depositHash: string }
  | { step: 'ordering'; depositHash: string | null }
  | { step: 'done'; depositHash: string | null; orderHash: string }
  | { step: 'deposit-failed'; reason: string; rejected: boolean }
  | { step: 'order-failed'; depositHash: string | null; reason: string; rejected: boolean };

export interface FlowDeps {
  /** Exact collateral the order needs in the funding asset (quote for buys, base for sells). */
  required: bigint;
  /** Fresh authoritative margin balance read (new block each call). */
  readMargin: () => Promise<bigint>;
  /** Execute the SDK-prepared deposit of exactly `amount`. Must resolve only after the receipt. */
  deposit: (amount: bigint) => Promise<WriteResult>;
  /** Re-prepare (re-validates margin, tick, size, quote freshness) and execute the order. */
  placeOrder: () => Promise<WriteResult>;
  onState: (state: FlowState) => void;
}

export function shortfall(required: bigint, margin: bigint): bigint {
  return required > margin ? required - margin : 0n;
}

/**
 * Runs the sequence from `from`. Never re-deposits once a deposit succeeded: a retry from
 * `deposited`/`order-failed` re-reads margin and goes straight to the order step.
 */
export async function runDepositThenOrder(deps: FlowDeps, from: FlowState = { step: 'idle' }): Promise<FlowState> {
  const set = (s: FlowState) => { deps.onState(s); return s; };
  let depositHash: string | null = 'depositHash' in from ? from.depositHash : null;
  // A deposit that already succeeded in this flow is never repeated automatically.
  const alreadyDeposited = depositHash !== null;

  if (!alreadyDeposited) {
    const margin = await deps.readMargin();
    const gap = shortfall(deps.required, margin);
    if (gap > 0n) {
      set({ step: 'depositing' });
      const result = await deps.deposit(gap);
      if (result.kind === 'failed') return set({ step: 'deposit-failed', reason: result.reason, rejected: result.failure === 'rejected' });
      depositHash = result.hash;
      set({ step: 'refreshing', depositHash });
    }
  }

  // Refresh authoritative margin after the deposit receipt (or before a retry) and recompute the shortfall.
  const refreshed = await deps.readMargin();
  if (shortfall(deps.required, refreshed) > 0n) {
    return set({ step: 'order-failed', depositHash, reason: 'Margin balance is still below the order requirement. No order was placed.', rejected: false });
  }
  if (depositHash) set({ step: 'deposited', depositHash });
  set({ step: 'ordering', depositHash });
  const order = await deps.placeOrder();
  if (order.kind === 'failed') return set({ step: 'order-failed', depositHash, reason: order.reason, rejected: order.failure === 'rejected' });
  return set({ step: 'done', depositHash, orderHash: order.hash });
}

export function flowBusy(state: FlowState): boolean {
  return state.step === 'depositing' || state.step === 'refreshing' || state.step === 'ordering';
}

export function flowMessage(state: FlowState, depositLabel: string): string | null {
  switch (state.step) {
    case 'depositing': return `Step 1/2 · Confirm the ${depositLabel} deposit in your wallet`;
    case 'refreshing': return 'Step 1/2 · Deposit confirmed. Refreshing margin balance…';
    case 'deposited': return 'Step 1/2 complete · Margin deposited';
    case 'ordering': return 'Step 2/2 · Confirm the order in your wallet';
    case 'done': return 'Order placed';
    case 'deposit-failed': return state.rejected ? 'Deposit request rejected in wallet. Nothing was submitted.' : `Deposit failed: ${state.reason}. No order was placed.`;
    case 'order-failed': return state.depositHash ? `Margin deposited; order not placed. ${state.rejected ? 'The order request was rejected in your wallet.' : state.reason}` : (state.rejected ? 'Order request rejected in wallet.' : state.reason);
    default: return null;
  }
}
