'use client';

import type { Address, Hex, TransactionReceipt } from 'viem';
import { encodeFunctionData, parseAbi } from 'viem';
import type { ChainClient } from '@retropick/launchpad-sdk/chain';
import type { EvmWallet } from '@retropick/launchpad-sdk/wallet';
import { classifyError, decodeEvents, type DecodedEvent } from '@retropick/launchpad-sdk/decode';
import { missingApprovals, type PreparedWrite } from '@retropick/launchpad-sdk/prepare';

export type TxPhase =
  | { kind: 'preparing' }
  | { kind: 'approving'; token: Address; amount: bigint }
  | { kind: 'simulating' }
  | { kind: 'awaiting-signature' }
  | { kind: 'broadcasting'; hash: Hex }
  | { kind: 'confirming'; hash: Hex }
  | { kind: 'success'; hash: Hex; receipt: TransactionReceipt; events: DecodedEvent[] }
  | { kind: 'failed'; reason: string; failure: 'rejected' | 'revert' | 'rpc' | 'unknown' };

export type TxPhaseListener = (phase: TxPhase) => void;

export interface ExecuteOptions {
  confirmations?: number;
  onPhase?: TxPhaseListener;
}

const approveAbi = parseAbi(['function approve(address spender, uint256 amount) returns (bool)']);

/**
 * The single sanctioned execution path for live economic writes:
 * ALLOWANCES (execute missing approvals first) → SIMULATE → SIGN →
 * BROADCAST → CONFIRMED RECEIPT → DECODE EVENTS. Preconditions, exact bigint
 * amounts and fresh reads are established by the SDK prepare* layer before
 * this runs; every failure mode maps to a classified reason.
 */
export async function executePreparedWrite(
  chain: ChainClient,
  wallet: EvmWallet,
  prepared: PreparedWrite,
  options: ExecuteOptions = {},
): Promise<Extract<TxPhase, { kind: 'success' | 'failed' }>> {
  const emit = (phase: TxPhase) => options.onPhase?.(phase);
  const fail = (reason: string, failure: 'rejected' | 'revert' | 'rpc' | 'unknown') => {
    const phase: Extract<TxPhase, { kind: 'failed' }> = { kind: 'failed', reason, failure };
    emit(phase);
    return phase;
  };

  emit({ kind: 'preparing' });
  let stage: 'approval' | 'simulate' | 'sign' | 'receipt' = 'simulate';
  try {
    // 1. Allowance freshness: approvals missing at execution time go first.
    const pending = await missingApprovals(chain, prepared);
    for (const approval of pending) {
      stage = 'approval';
      emit({ kind: 'approving', token: approval.token, amount: approval.amount });
      const approvalHash = await wallet.writeContract({
        address: approval.token,
        abi: approveAbi,
        functionName: 'approve',
        args: [approval.spender, approval.amount],
      });
      const approvalReceipt = await chain.waitForTransactionReceipt({ hash: approvalHash });
      if (approvalReceipt.status !== 'success') return fail('Token approval transaction reverted.', 'revert');
    }

    // 2. Simulate the exact call before asking for a signature.
    stage = 'simulate';
    emit({ kind: 'simulating' });
    await chain.simulateContract({
      address: prepared.to,
      abi: prepared.abi as unknown as Parameters<typeof chain.simulateContract>[0]['abi'],
      functionName: prepared.functionName,
      args: prepared.args as unknown as Parameters<typeof chain.simulateContract>[0]['args'],
      ...(prepared.value ? { value: prepared.value } : {}),
      account: prepared.account,
    } as Parameters<typeof chain.simulateContract>[0]);

    // 3. Sign + broadcast through the wallet (EIP-1193 eth_sendTransaction).
    stage = 'sign';
    emit({ kind: 'awaiting-signature' });
    const hash = await wallet.sendTransaction({
      to: prepared.to,
      data: encodeFunctionData({ abi: prepared.abi as unknown as Parameters<typeof encodeFunctionData>[0]['abi'], functionName: prepared.functionName, args: prepared.args as unknown as never[] }),
      ...(prepared.value ? { value: prepared.value } : {}),
    });

    stage = 'receipt';
    emit({ kind: 'broadcasting', hash });
    emit({ kind: 'confirming', hash });
    const receipt = await chain.waitForTransactionReceipt({ hash, confirmations: options.confirmations ?? 1 });
    if (receipt.status !== 'success') return fail('The transaction reverted on chain.', 'revert');
    const events = decodeEvents(receipt.logs);
    const success = { kind: 'success', hash, receipt, events } as const;
    emit(success);
    return success;
  } catch (error) {
    const classification = classifyError(error);
    const prefix = stage === 'approval' ? 'Approval failed: ' : stage === 'simulate' ? 'Simulation failed: ' : '';
    if (classification.kind === 'user-rejected') return fail('Request rejected in wallet.', 'rejected');
    const failure = classification.kind === 'revert' ? 'revert' : classification.kind === 'rpc' ? 'rpc' : 'unknown';
    return fail(`${prefix}${classification.message}`, failure);
  }
}
