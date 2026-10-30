import { useMemo } from 'react';
import { useQuery } from '@tanstack/react-query';
import { readDiscoverySnapshot } from '@retropick/launchpad-sdk/discovery-snapshot';
import { fetchLaunches } from '@/lib/live/indexer-client';
import { launchKeys } from '@/lib/live/queries';
import { DATA_MODE, INDEXER_URL } from '@/lib/live/env';
import { demoRows } from '@/lib/view-models/discovery';

export interface LaunchStat {
  name: string; symbol: string;
  volume24hRaw: string | null; trades24h: number | null;
  priceX18: string | null;
  quoteSymbol: string; quoteDecimals: number;
}

/**
 * Token → real launch stats (24h volume, trades, last price) for liquidity
 * surfaces. Live mode reads the same complete discovery snapshot the
 * Launchpad page uses (shared query cache); demo mode maps the deterministic
 * demo rows. Nothing is aggregated across quote denominations.
 */
export function useLaunchStats(): { stats: Record<string, LaunchStat>; status: 'loading' | 'ready' | 'unavailable' } {
  const q = useQuery({
    queryKey: [...launchKeys.all, 'complete-discovery'],
    enabled: DATA_MODE === 'live' && !!INDEXER_URL,
    queryFn: ({ signal }) => readDiscoverySnapshot(cursor => fetchLaunches(INDEXER_URL!, { limit: 100, sort: 'new', cursor }, signal)),
    staleTime: 3000, refetchInterval: 10_000, retry: 1,
  });
  const stats = useMemo(() => {
    const map: Record<string, LaunchStat> = {};
    if (DATA_MODE !== 'live') {
      for (const r of demoRows()) map[r.id] = { name: r.name, symbol: r.symbol, volume24hRaw: r.volume24hRaw, trades24h: r.trades24h, priceX18: r.priceX18, quoteSymbol: r.quote.symbol, quoteDecimals: r.quote.decimals };
      return map;
    }
    // readDiscoverySnapshot returns the complete indexed launch list.
    for (const l of q.data?.data ?? []) {
      map[l.token] = { name: l.name, symbol: l.symbol, volume24hRaw: l.volume24hRaw, trades24h: l.trades24h, priceX18: l.priceX18 ?? l.priceRaw ?? null, quoteSymbol: l.quoteSymbol, quoteDecimals: l.quoteDecimals };
    }
    return map;
  }, [q.data]);
  const status = DATA_MODE !== 'live' ? 'ready' : q.data ? 'ready' : q.isError ? 'unavailable' : 'loading';
  return { stats, status };
}
