'use client';

import { useCallback, useEffect, useRef, useState } from 'react';
import { fetchLaunches, IndexerUnavailableError, isStale, type IndexFreshness, type IndexedLaunch } from '@/lib/live/indexer-client';
import { indexedLaunchToInstrument } from '@/lib/live/live-launch-adapter';
import { INDEXER_URL } from '@/lib/live/env';
import type { LaunchInstrument } from '@/lib/domain/instruments';

export type LiveFeedStatus = 'loading' | 'ready' | 'stale' | 'unavailable';

export interface LiveLaunchFeed {
  instruments: LaunchInstrument[];
  launches: IndexedLaunch[];
  freshness: IndexFreshness | null;
  status: LiveFeedStatus;
  error: string | null;
  reload: () => void;
}

const REFRESH_MS = 15_000;

/** Live V2 launches from the RetroPick indexer (chain 10143 identity). */
export function useLiveLaunches(enabled: boolean): LiveLaunchFeed {
  const [instruments, setInstruments] = useState<LaunchInstrument[]>([]);
  const [launches, setLaunches] = useState<IndexedLaunch[]>([]);
  const [freshness, setFreshness] = useState<IndexFreshness | null>(null);
  const [status, setStatus] = useState<LiveFeedStatus>(enabled ? 'loading' : 'unavailable');
  const [error, setError] = useState<string | null>(null);
  const [tick, setTick] = useState(0);
  const alive = useRef(true);

  const reload = useCallback(() => setTick((value) => value + 1), []);

  useEffect(() => {
    alive.current = true;
    if (!enabled || !INDEXER_URL) {
      setStatus('unavailable');
      return;
    }
    let timer: ReturnType<typeof setTimeout> | undefined;
    const load = async () => {
      try {
        const envelope = await fetchLaunches(INDEXER_URL as string);
        if (!alive.current) return;
        setLaunches(envelope.data);
        setInstruments(envelope.data.map(indexedLaunchToInstrument));
        setFreshness(envelope.freshness);
        setError(null);
        setStatus(isStale(envelope.freshness) ? 'stale' : 'ready');
      } catch (cause) {
        if (!alive.current) return;
        setError(cause instanceof IndexerUnavailableError ? cause.message : 'Indexer unreachable.');
        setStatus('unavailable');
      } finally {
        if (alive.current) timer = setTimeout(load, REFRESH_MS);
      }
    };
    void load();
    return () => {
      alive.current = false;
      if (timer) clearTimeout(timer);
    };
  }, [enabled, tick]);

  return { instruments, launches, freshness, status, error, reload };
}
