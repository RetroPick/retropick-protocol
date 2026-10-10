import { useQuery } from '@tanstack/react-query';
import { INDEXER_URL } from '@/lib/live/env';
import { fetchTrades, queryPath, request } from '@/lib/live/indexer-client';
import type { IndexedOrder } from '@retropick/launchpad-sdk/read-model';

/**
 * Confirms that a SPECIFIC confirmed transaction appears in the relevant indexer projection
 * (trade by transactionHash, order by transactionHash + owner). Indexer block height alone is never used.
 * Returns 'indexed' only on an identity match; otherwise 'pending' (the UI shows "Confirmed on-chain, awaiting indexing").
 */
export function useIndexedRecord(kind: 'trade' | 'order' | null, token: string | null, hash: string | null, owner?: string | null): 'idle' | 'pending' | 'indexed' {
  const enabled = !!INDEXER_URL && !!kind && !!token && !!hash;
  const query = useQuery({
    queryKey: ['indexed-record', kind, token, hash, owner ?? ''],
    enabled,
    refetchInterval: (q) => (q.state.data ? false : 2500),
    retry: false,
    queryFn: async ({ signal }) => {
      const want = hash!.toLowerCase();
      if (kind === 'trade') {
        const page = await fetchTrades(INDEXER_URL!, token!, { limit: 100 }, signal);
        return page.data.some((t) => t.transactionHash.toLowerCase() === want) || null;
      }
      const page = await request<IndexedOrder[]>(INDEXER_URL!, queryPath(`/v1/launches/${token}/orders`, { owner: owner ?? undefined, status: 'all', limit: 100 }), signal);
      return page.data.some((o) => o.transactionHash.toLowerCase() === want) || null;
    },
  });
  if (!enabled) return 'idle';
  return query.data ? 'indexed' : 'pending';
}
