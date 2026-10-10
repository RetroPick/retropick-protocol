import type { IndexedCandle, IndexedLaunch, IndexedTrade, IndexEnvelope, IndexFreshness } from '@retropick/launchpad-sdk/read-model';

export type { IndexedCandle, IndexedLaunch, IndexedTrade, IndexEnvelope, IndexFreshness };

/** Indexer lag (blocks) beyond which live data is presented as stale, never fresh. */
export const STALE_LAG_BLOCKS = 64;

export class IndexerUnavailableError extends Error {
  constructor(message: string, readonly cause?: unknown) {
    super(message);
    this.name = 'IndexerUnavailableError';
  }
}

async function request<T>(baseUrl: string, path: string, timeoutMs = 10_000): Promise<IndexEnvelope<T>> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const response = await fetch(`${baseUrl}${path}`, {
      signal: controller.signal,
      headers: { accept: 'application/json' },
    });
    if (response.status === 404) throw new IndexerUnavailableError(`Not indexed: ${path}`);
    if (!response.ok) throw new IndexerUnavailableError(`Indexer HTTP ${response.status} for ${path}`);
    const body = (await response.json()) as IndexEnvelope<T>;
    if (!body || !('data' in body) || !body.freshness || body.freshness.chainId !== 10143 || body.freshness.source !== 'MONAD_EVENT_INDEXER') {
      throw new IndexerUnavailableError(`Malformed indexer envelope for ${path}`);
    }
    return body;
  } catch (error) {
    if (error instanceof IndexerUnavailableError) throw error;
    throw new IndexerUnavailableError(`Indexer unreachable for ${path}`, error);
  } finally {
    clearTimeout(timer);
  }
}

export function isStale(freshness: IndexFreshness): boolean {
  return Boolean(freshness.error) || freshness.lagBlocks > STALE_LAG_BLOCKS;
}

export async function fetchLaunches(baseUrl: string): Promise<IndexEnvelope<IndexedLaunch[]>> {
  return request<IndexedLaunch[]>(baseUrl, '/v1/launches?limit=100');
}

export async function fetchLaunch(baseUrl: string, token: string): Promise<IndexEnvelope<IndexedLaunch>> {
  return request<IndexedLaunch>(baseUrl, `/v1/launches/${token}`);
}

export async function fetchTrades(baseUrl: string, token: string, limit = 50): Promise<IndexEnvelope<IndexedTrade[]>> {
  return request<IndexedTrade[]>(baseUrl, `/v1/launches/${token}/trades?limit=${limit}`);
}

export async function fetchCandles(baseUrl: string, token: string, limit = 120): Promise<IndexEnvelope<IndexedCandle[]>> {
  return request<IndexedCandle[]>(baseUrl, `/v1/launches/${token}/candles?limit=${limit}`);
}
