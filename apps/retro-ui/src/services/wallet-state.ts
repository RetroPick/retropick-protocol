import { zeroAddress, type Address } from 'viem';
import { addresses, release } from '@retropick/launchpad-sdk/chain';
import { tokenAbi } from '@retropick/launchpad-sdk/abis/tokenAbi';
import { marginAbi } from '@retropick/launchpad-sdk/abis/marginAbi';
import { retroPickFeeEscrowV2Abi } from '@retropick/launchpad-sdk/abis/retroPickFeeEscrowV2Abi';
import { retroPickBuybackVaultV2Abi } from '@retropick/launchpad-sdk/abis/retroPickBuybackVaultV2Abi';
import type { IndexedWalletAsset, IndexedOrder, IndexedClaim, IndexedBuyback } from '@retropick/launchpad-sdk/read-model';
import { fetchWalletResource } from '@/lib/live/indexer-client';
import { INDEXER_URL } from '@/lib/live/env';
import { publicClient } from '@/lib/live/public-client';
export type WalletAsset = IndexedWalletAsset & { walletRaw: bigint; marginRaw: bigint; creditRaw: bigint };
export type WalletBuyback = IndexedBuyback & { releasableRaw: bigint; beneficiaryRaw: bigint; beneficiary: boolean };
export async function allWalletRows<T>(account: Address, resource: 'assets' | 'orders' | 'claims' | 'buybacks', signal?: AbortSignal): Promise<T[]> {
  if (!INDEXER_URL) return [];
  const rows: T[] = [];
  let cursor: string | undefined;
  const seen = new Set<string>();
  do {
    const envelope = await fetchWalletResource<T>(INDEXER_URL, account, resource, { cursor, limit: 100 }, signal);
    rows.push(...envelope.data);
    cursor = envelope.nextCursor ?? undefined;
    if (cursor && seen.has(cursor)) throw Error('Indexer returned a repeated wallet cursor.');
    if (cursor) seen.add(cursor);
  } while (cursor);
  return rows;
}
export async function fetchWalletState(account: Address, signal?: AbortSignal) {
  const issues: string[] = [];
  const safe = async <T>(resource: 'assets' | 'orders' | 'claims' | 'buybacks'): Promise<T[]> => {
    try { return await allWalletRows<T>(account, resource, signal); }
    catch (error) { if (signal?.aborted) throw error; issues.push(`${resource} history is temporarily unavailable`); return []; }
  };
  const blockNumber = await publicClient.getBlockNumber({ cacheTime: 0 });
  const [monRaw, nativeMarginRaw, nativeCreditRaw, candidates, orders, claims, vests] = await Promise.all([
    publicClient.getBalance({ address: account, blockNumber }),
    publicClient.readContract({ address: release.kuruEnvironment.marginAccount as Address, abi: marginAbi, functionName: 'getBalance', args: [account, zeroAddress], blockNumber }),
    publicClient.readContract({ address: addresses.feeEscrow, abi: retroPickFeeEscrowV2Abi, functionName: 'balanceOf', args: [account], blockNumber }),
    safe<IndexedWalletAsset>('assets'), safe<IndexedOrder>('orders'), safe<IndexedClaim>('claims'), safe<IndexedBuyback>('buybacks'),
  ]);
  const assets = await Promise.all(candidates.filter(row => row.token !== zeroAddress).map(async (row): Promise<WalletAsset> => {
    const token = row.token as Address;
    const [walletRaw, marginRaw, creditRaw] = await Promise.all([
      publicClient.readContract({ address: token, abi: tokenAbi, functionName: 'balanceOf', args: [account], blockNumber }),
      publicClient.readContract({ address: release.kuruEnvironment.marginAccount as Address, abi: marginAbi, functionName: 'getBalance', args: [account, token], blockNumber }),
      publicClient.readContract({ address: addresses.feeEscrow, abi: retroPickFeeEscrowV2Abi, functionName: 'balanceOfToken', args: [account, token], blockNumber }),
    ]);
    return { ...row, walletRaw, marginRaw, creditRaw };
  }));
  const buybacks = await Promise.all(vests.map(async (row): Promise<WalletBuyback> => {
    const [terms, releasableRaw] = await Promise.all([
      publicClient.readContract({ address: addresses.buybackVault, abi: retroPickBuybackVaultV2Abi, functionName: 'vestingTerms', args: [row.token as Address], blockNumber }),
      publicClient.readContract({ address: addresses.buybackVault, abi: retroPickBuybackVaultV2Abi, functionName: 'releasable', args: [row.token as Address], blockNumber }),
    ]);
    const creator = terms[0].toLowerCase() === account.toLowerCase();
    const protocol = terms[1].toLowerCase() === account.toLowerCase();
    const protocolShare = releasableRaw * BigInt(terms[2]) / 10_000n;
    return { ...row, releasableRaw, beneficiary: creator || protocol, beneficiaryRaw: (creator ? releasableRaw - protocolShare : 0n) + (protocol ? protocolShare : 0n) };
  }));
  return { monRaw, nativeMarginRaw, nativeCreditRaw, assets, orders, claims, buybacks: buybacks.filter(row => row.beneficiary), blockNumber, issues };
}
