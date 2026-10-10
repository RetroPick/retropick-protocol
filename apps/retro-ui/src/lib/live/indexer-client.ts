import type { IndexedCandle, IndexedLaunch, IndexedTrade, IndexEnvelope, IndexFreshness, IndexedHolder } from '@retropick/launchpad-sdk/read-model';
import { measureStage } from './performance';
export type { IndexedCandle, IndexedLaunch, IndexedTrade, IndexEnvelope, IndexFreshness, IndexedHolder };
export const STALE_LAG_BLOCKS = 64;
export type QueryParams = Record<string, string | number | undefined>;
export class IndexerUnavailableError extends Error {
  constructor(message: string, readonly status?: number, readonly cause?: unknown) { super(message); this.name = 'IndexerUnavailableError'; }
}
export async function request<T>(base: string, path: string, signal?: AbortSignal): Promise<IndexEnvelope<T>> {
  const finish = measureStage('indexer:response');
  const response = await fetch(base + path, { signal: signal ? AbortSignal.any([signal, AbortSignal.timeout(8000)]) : AbortSignal.timeout(8000), headers: { accept: 'application/json' } });
  if (!response.ok) throw new IndexerUnavailableError(response.status === 404 ? 'Awaiting indexer confirmation.' : 'Indexer HTTP ' + response.status, response.status);
  const payload = await response.text();
  const body = JSON.parse(payload) as IndexEnvelope<T>;
  if (!body || !('data' in body) || body.freshness?.chainId !== 10143 || body.freshness.source !== 'MONAD_EVENT_INDEXER') throw new IndexerUnavailableError('Invalid indexer freshness envelope.');
  finish({ bytes: new TextEncoder().encode(payload).length, count: 1 });
  return body;
}
export function queryPath(path: string, params: QueryParams): string {
  const query = new URLSearchParams();
  for (const [key, value] of Object.entries(params)) if (value !== undefined && value !== '') query.set(key, String(value));
  return path + (query.size ? '?' + query : '');
}
export const isStale = (freshness: IndexFreshness) => Boolean(freshness.error) || freshness.lagBlocks > STALE_LAG_BLOCKS;
export const fetchLaunches = (base: string, params: QueryParams = {}, signal?: AbortSignal) => request<IndexedLaunch[]>(base, queryPath('/v1/launches', { limit: 50, ...params }), signal);
export const fetchLaunch = (base: string, token: string, signal?: AbortSignal) => request<IndexedLaunch>(base, '/v1/launches/' + token, signal);
export const fetchTrades = (base: string, token: string, params: QueryParams | number = {}, signal?: AbortSignal) => request<IndexedTrade[]>(base, queryPath('/v1/launches/' + token + '/trades', { limit: 50, ...(typeof params === 'number' ? { limit: params } : params) }), signal);
export const fetchCandles = (base: string, token: string, params: QueryParams | number = {}, signal?: AbortSignal) => request<IndexedCandle[]>(base, queryPath('/v1/launches/' + token + '/candles', { resolution: '5m', range: '24h', ...(typeof params === 'number' ? { limit: params } : params) }), signal);
export const fetchHolders = (base: string, token: string, params: QueryParams = {}, signal?: AbortSignal) => request<IndexedHolder[]>(base, queryPath('/v1/launches/' + token + '/holders', { limit: 50, ...params }), signal);
export const fetchSearch = (base: string, q: string, signal?: AbortSignal) => request<IndexedLaunch[]>(base, queryPath('/v1/search', { q, limit: 20 }), signal);
export interface IndexedPair { quoteAsset: string; symbol: string; decimals: number; launchCount?: number }
export const fetchPairs = (base: string, signal?: AbortSignal) => request<IndexedPair[]>(base, '/v1/pairs', signal);
export const fetchWalletResource = <T>(base: string, wallet: string, resource: 'assets' | 'orders' | 'claims' | 'buybacks', params: QueryParams = {}, signal?: AbortSignal) => request<T[]>(base, queryPath('/v1/wallets/' + wallet + '/' + resource, { limit: 100, ...params }), signal);
