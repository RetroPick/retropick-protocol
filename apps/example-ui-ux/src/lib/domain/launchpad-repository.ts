import { normalizeLaunchSources } from './launchpad-adapters';
import type { LaunchInstrument } from './instruments';
import type { LaunchpadType } from './launchpad-types';

export type InstrumentSort = 'trending' | 'volume' | 'new' | 'liquidity';
export interface InstrumentFilters {
  type?: LaunchpadType;
  predictionTopic?: string;
  watchlist?: readonly string[];
  sort?: InstrumentSort;
}

/** One identity and one read surface even when the protocol sources differ. */
export function createInstrumentRepository(sources: readonly LaunchInstrument[]): readonly LaunchInstrument[] {
  const seen = new Map<string, LaunchInstrument>();
  for (const instrument of sources) {
    const key = `${instrument.chain.chainId}:${instrument.id}`;
    const existing = seen.get(key);
    if (existing && existing.contract.family !== instrument.contract.family) {
      throw new Error(`Conflicting instrument identity: ${key}`);
    }
    if (!existing) seen.set(key, instrument);
  }
  return Object.freeze([...seen.values()]);
}

export const launchInstruments = createInstrumentRepository(normalizeLaunchSources());

export function getLaunchInstrument(id: string): LaunchInstrument | undefined {
  return launchInstruments.find((instrument) => instrument.id === id);
}

function matchesType(instrument: LaunchInstrument, type: LaunchpadType): boolean {
  if (type === 'all') return true;
  if (type === 'prediction') return instrument.kind === 'prediction';
  const reference = type === 'stocks' ? 'stock' : 'crypto';
  // For token listings the paired/reference asset identifies the tab; event
  // markets use the underlying event class, never their USDC collateral.
  return instrument.referenceClass === reference ||
    (instrument.kind === 'token' && instrument.pair?.referenceClass === reference);
}

function metric(value: number | bigint | null): number {
  return value === null ? -1 : Number(value);
}

export function queryLaunchInstruments(filters: InstrumentFilters = {}, sources: readonly LaunchInstrument[] = launchInstruments): LaunchInstrument[] {
  const type = filters.type ?? 'all';
  const items = sources.filter((item) => matchesType(item, type)
    && (type !== 'prediction' || !filters.predictionTopic || filters.predictionTopic === 'all' || item.prediction?.topic === filters.predictionTopic)
    && (!filters.watchlist || filters.watchlist.includes(item.id)));
  const sort = filters.sort ?? 'trending';
  if (sort === 'new') items.sort((a, b) => (b.createdAt ?? '').localeCompare(a.createdAt ?? ''));
  else if (sort === 'liquidity') items.sort((a, b) => metric(b.liquidity) - metric(a.liquidity));
  else items.sort((a, b) => metric(b.volume24h) - metric(a.volume24h));
  return items;
}
