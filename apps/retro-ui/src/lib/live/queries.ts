import { QueryClient } from '@tanstack/react-query';
import type { Address } from 'viem';
import { addresses } from '@retropick/launchpad-sdk/chain';
import { readLaunchEssential } from '@retropick/launchpad-sdk/model';
import { INDEXER_URL } from './env';
import { publicClient } from './public-client';
import { fetchLaunch, fetchLaunches, type QueryParams } from './indexer-client';
export const queryClient = new QueryClient({ defaultOptions: { queries: { staleTime: 3000, gcTime: 30 * 60_000, retry: 0, refetchIntervalInBackground: false, refetchOnWindowFocus: true } } });
const namespace = ['launchpad', 10143, addresses.factory] as const;
export const launchKeys = {
  all: namespace,
  feed: (params: QueryParams) => [...namespace, 'feed', params] as const,
  indexed: (token: string) => [...namespace, 'indexed', token.toLowerCase()] as const,
  essential: (token: string) => [...namespace, 'essential', token.toLowerCase()] as const,
  economic: (token: string, account?: string) => [...namespace, 'economic', token.toLowerCase(), account?.toLowerCase() ?? 'public'] as const,
  resource: (token: string, name: string, params: QueryParams = {}) => [...namespace, 'resource', token.toLowerCase(), name, params] as const,
  wallet: (account: string, resource: string) => [...namespace, 'wallet', account.toLowerCase(), resource] as const,
  seed: (token: string) => [...namespace, 'receipt-seed', token.toLowerCase()] as const,
};
export interface LaunchSeed { token: Address; curve: Address; name: string; symbol: string; description: string; logo: string; quoteSymbol: string; quoteDecimals: number; creator: Address; receiptBlock: bigint; transactionHash: string }
export function seedLaunch(seed: LaunchSeed): void { queryClient.setQueryData(launchKeys.seed(seed.token), seed); }
export async function prefetchLaunch(token: string): Promise<void> {
  if (!INDEXER_URL || !/^0x[\da-f]{40}$/i.test(token)) return;
  await Promise.allSettled([
    queryClient.prefetchQuery({ queryKey: launchKeys.indexed(token), queryFn: ({ signal }) => fetchLaunch(INDEXER_URL!, token, signal) }),
    queryClient.prefetchQuery({ queryKey: launchKeys.essential(token), queryFn: () => readLaunchEssential(publicClient, token as Address), staleTime: 2000, structuralSharing: false }),
  ]);
}
export const prefetchFeed = (params: QueryParams = {}) => INDEXER_URL && queryClient.prefetchQuery({ queryKey: launchKeys.feed(params), queryFn: ({ signal }) => fetchLaunches(INDEXER_URL!, params, signal) });
