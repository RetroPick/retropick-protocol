'use client';

import { useCallback, useEffect, useState } from 'react';
import type { Address } from 'viem';
import { readLaunch } from '@retropick/launchpad-sdk/model';
import { readKuru } from '@retropick/launchpad-sdk/kuru';
import type { LiveLaunch } from '@retropick/launchpad-sdk/model';
import type { KuruState } from '@retropick/launchpad-sdk/kuru';
import { fetchCandles, fetchLaunch, fetchTrades, IndexerUnavailableError, isStale, type IndexFreshness, type IndexedCandle, type IndexedLaunch, type IndexedTrade } from '@/lib/live/indexer-client';
import { publicClient } from '@/lib/live/public-client';
import { INDEXER_URL } from '@/lib/live/env';

export type LaunchDetailStatus = 'loading' | 'ready' | 'stale' | 'partial' | 'unavailable';

export interface LaunchDetail {
  indexed: IndexedLaunch | null;
  freshness: IndexFreshness | null;
  /** Authoritative on-chain economic state via the SDK read model. */
  launch: LiveLaunch | null;
  /** Kuru market state when the launch graduated to the Kuru venue. */
  kuru: KuruState | null;
  trades: IndexedTrade[];
  candles: IndexedCandle[];
  status: LaunchDetailStatus;
  error: string | null;
  reload: () => void;
}

/**
 * Token detail for a deployed launch: indexer for history (trades, candles,
 * discovery metadata) and direct RPC for current economic state. Route
 * addresses are verified by the SDK read model — an address that is not a
 * RetroPick V2 launch fails with status 'unavailable'.
 */
export function useLaunchDetail(token: string | null, account?: Address): LaunchDetail {
  const [detail, setDetail] = useState<LaunchDetail>({
    indexed: null, freshness: null, launch: null, kuru: null,
    trades: [], candles: [], status: 'loading', error: null, reload: () => {},
  });
  const [tick, setTick] = useState(0);
  const reload = useCallback(() => setTick((value) => value + 1), []);

  useEffect(() => {
    if (!token || !/^0x[0-9a-fA-F]{40}$/.test(token)) {
      setDetail((prev) => ({ ...prev, status: 'unavailable', error: 'Invalid token address.' }));
      return;
    }
    let alive = true;
    const address = token as `0x${string}` as Address;
    const load = async () => {
      setDetail((prev) => ({ ...prev, status: prev.launch ? prev.status : 'loading' }));
      const next: LaunchDetail = { indexed: null, freshness: null, launch: null, kuru: null, trades: [], candles: [], status: 'loading', error: null, reload };
      try {
        const onchain = await readLaunch(publicClient, address, account);
        if (!alive) return;
        next.launch = onchain;
        // Kuru identity/state only when graduated with a market receipt.
        const receiptMarket = onchain.receipt.market;
        const market: string | null = next.indexed?.market ?? (Number(onchain.ledger.phase) === 2 && receiptMarket && receiptMarket !== '0x0000000000000000000000000000000000000000' ? receiptMarket : null);
        const vault = onchain.receipt.vault;
        if (Number(onchain.ledger.phase) === 2 && market && vault && vault !== '0x0000000000000000000000000000000000000000') {
          try {
            next.kuru = await readKuru(publicClient, market as `0x${string}` as Address, address, vault as `0x${string}` as Address, account);
          } catch {
            // Identity mismatch or venue unavailable: surface the launch, not fabricated market data.
            next.kuru = null;
          }
        }
        next.status = 'ready';
      } catch (cause) {
        if (!alive) return;
        next.status = 'unavailable';
        next.error = cause instanceof Error ? cause.message : 'On-chain read failed.';
      }
      if (INDEXER_URL) {
        try {
          const [launchEnvelope, tradesEnvelope, candlesEnvelope] = await Promise.all([
            fetchLaunch(INDEXER_URL, address),
            fetchTrades(INDEXER_URL, address).catch(() => null),
            fetchCandles(INDEXER_URL, address).catch(() => null),
          ]);
          if (!alive) return;
          next.indexed = launchEnvelope.data;
          next.freshness = launchEnvelope.freshness;
          next.trades = tradesEnvelope?.data ?? [];
          next.candles = candlesEnvelope?.data ?? [];
          if (next.status === 'ready' && isStale(launchEnvelope.freshness)) next.status = 'stale';
        } catch (cause) {
          if (!alive) return;
          if (next.status === 'ready') next.status = 'partial'; // chain truth without indexer history
          next.error = next.error ?? (cause instanceof IndexerUnavailableError ? cause.message : 'Indexer unreachable.');
        }
      }
      if (alive) setDetail(next);
    };
    void load();
    return () => { alive = false; };
  }, [token, account, tick, reload]);

  return detail;
}
