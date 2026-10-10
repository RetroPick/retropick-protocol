import { createPublicClient, defineChain, http, custom, type Address } from 'viem';
import { release } from './release.ts';
export { release };
export const monad = defineChain({ id: 10143, name: 'Monad Testnet', nativeCurrency: { name: 'MON', symbol: 'MON', decimals: 18 }, rpcUrls: { default: { http: ['https://testnet-rpc.monad.xyz'] } }, contracts: { multicall3: { address: '0xcA11bde05977b3631167028862bE2a173976CA11', blockCreated: 251449 } }, blockExplorers: { default: { name: 'Monad Explorer', url: 'https://testnet.monadexplorer.com' } }, testnet: true });
export const addresses = Object.fromEntries(Object.entries(release.addresses).filter(([, v]) => typeof v === 'string' && v.startsWith('0x'))) as Record<string, Address>;
export type RpcHealth = { provider: number; origin: string; chainId: number | null; latencyMs: number | null; health: 'probing' | 'healthy' | 'circuit-open' | 'disabled'; failures: number; retryAfter: number };
export type ChainOptions = { timeoutMs?: number; httpBatch?: boolean; /** Enable only after independently qualifying this chain's Multicall3 runtime. */ multicall?: boolean };
/** Public endpoints only. Unauthorized/wrong-chain providers never remain in the failover path. */
export const createChain = (input: string | string[], options: ChainOptions = {}) => {
  const urls = [...new Set(Array.isArray(input) ? input : [input])];
  if (!urls.length) throw Error('A public Monad RPC endpoint is required.');
  const providers = urls.map((url, provider) => {
    const rpc = createPublicClient({ transport: http(url, { timeout: options.timeoutMs ?? 3000, retryCount: 0, batch: options.httpBatch === false ? false : { batchSize: 30, wait: 5 } }) });
    const health: RpcHealth = { provider, origin: new URL(url).origin, chainId: null, latencyMs: null, health: 'probing', failures: 0, retryAfter: 0 };
    return { rpc, health, probe: null as Promise<void> | null };
  });
  const fail = (entry: typeof providers[number], error: unknown) => {
    const text = String(error instanceof Error ? error.message : error);
    const permanent = /401|403|unauthorized|forbidden|wrong.chain/i.test(text);
    entry.health.failures++;
    entry.health.health = permanent ? 'disabled' : 'circuit-open';
    entry.health.retryAfter = permanent ? Infinity : Date.now() + 30_000;
  };
  const probe = (entry: typeof providers[number]) => {
    if (entry.probe) return entry.probe;
    entry.health.health = 'probing';
    const start = performance.now();
    entry.probe = (async () => {
      try {
        const [id] = await Promise.all([entry.rpc.getChainId(), entry.rpc.getBlockNumber({ cacheTime: 0 })]);
        entry.health.chainId = id;
        if (id !== monad.id) throw Error('Wrong chain RPC provider');
        entry.health.latencyMs = Math.round(performance.now() - start);
        entry.health.health = 'healthy'; entry.health.failures = 0; entry.health.retryAfter = 0;
      } catch (error) { fail(entry, error); }
    })().finally(() => { entry.probe = null; });
    return entry.probe;
  };
  // Probe independently: a bad fallback does not delay requests to the healthy primary.
  for (const entry of providers) void probe(entry);
  const transport = custom({ request: async ({ method, params }) => {
    let last: unknown = Error('No healthy Monad RPC provider.');
    for (const entry of providers) {
      if (entry.health.health === 'probing') await entry.probe;
      if (entry.health.health === 'disabled') continue;
      if (entry.health.health === 'circuit-open') {
        if (entry.health.retryAfter > Date.now()) continue;
        await probe(entry);
        if ((entry.health as RpcHealth).health !== 'healthy') continue;
      }
      try { return await entry.rpc.request({ method, params } as never); }
      catch (error) {
        const name = error && typeof error === 'object' && 'name' in error ? String(error.name) : '';
        const message = error instanceof Error ? error.message : String(error);
        // A contract revert is valid RPC output, not an unhealthy provider.
        if (!/HttpRequestError|TimeoutError|WebSocketRequestError/i.test(name) && !/fetch failed|failed to fetch|network error|401|403|429|502|503|rate limit/i.test(message)) throw error;
        last = error; fail(entry, error);
      }
    }
    throw last;
  } }, { retryCount: 0 });
  return createPublicClient({ chain: monad, batch: options.multicall ? { multicall: { batchSize: 4096, wait: 10 } } : undefined, transport }).extend(() => ({
    rpcHealth: () => providers.map(({ health }) => ({ ...health })),
    probeProviders: async () => { await Promise.all(providers.filter(p => p.health.health !== 'disabled').map(probe)); return providers.map(p => ({ ...p.health })); },
  }));
};
export type ChainClient = ReturnType<typeof createChain>;
export const explorer = (value: string, kind = 'address') => `${monad.blockExplorers.default.url}/${kind}/${value}`;
export const short = (value: string) => `${value.slice(0, 6)}…${value.slice(-4)}`;
export function errorText(error: unknown) { if (error && typeof error === 'object' && 'shortMessage' in error) return String(error.shortMessage); return error instanceof Error ? error.message : 'Network unavailable. Please retry.'; }
