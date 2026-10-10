import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { createProviderPool, classifyFailure, redactEndpoint } from '../src/providers.ts';
import { acquireDbLock, rpcEndpoints } from '../src/server.ts';

const AUTH_URL = 'https://auth.invalid/v3/0123456789abcdef0123456789abcdef';
const GOOD_URL = 'https://good.invalid/';
const FLAKY_URL = 'https://flaky.invalid/';

/** Fake fetch: AUTH endpoint always 401 "no access to this network"; GOOD answers; FLAKY fails n times with 503. */
function fakeFetch(opts: { flakyFailures?: number; revert?: boolean } = {}) {
  const calls: Record<string, number> = {};
  let flaky = opts.flakyFailures ?? 0;
  const fn = (async (input: RequestInfo | URL, init?: RequestInit) => {
    const url = String(input); const host = new URL(url).host; calls[host] = (calls[host] ?? 0) + 1;
    const body = JSON.parse(String(init?.body));
    const reply = (one: { method: string; id: number }) => {
      if (opts.revert && one.method === 'eth_call') return { jsonrpc: '2.0', id: one.id, error: { code: 3, message: 'execution reverted' } };
      return { jsonrpc: '2.0', id: one.id, result: one.method === 'eth_chainId' ? '0x279f' : '0x10' };
    };
    // Real Infura behaviour: single requests → 401 text; batched requests → HTTP 200 with a non-JSON text body.
    if (host === 'auth.invalid') return Array.isArray(body) ? new Response('[project ID does not have access to this network, see https://infura.io/dashboard]', { status: 200 }) : new Response('project ID does not have access to this network', { status: 401 });
    if (host === 'flaky.invalid' && flaky > 0) { flaky--; return new Response('bad gateway', { status: 503 }); }
    return new Response(JSON.stringify(Array.isArray(body) ? body.map(reply) : reply(body)), { status: 200, headers: { 'content-type': 'application/json' } });
  }) as typeof fetch;
  return { fn, calls };
}

test('HTTP 401 "no access to this network" is classified AUTH, not rate limiting', () => {
  assert.equal(classifyFailure(Object.assign(Error('HTTP request failed. Status: 401 Details: project ID does not have access to this network'), { status: 401 })), 'AUTH');
  assert.equal(classifyFailure(Object.assign(Error('Status: 429 Too Many Requests'), { status: 429 })), 'RATE_LIMIT');
  assert.equal(classifyFailure(Error('execution reverted')), 'OTHER');
  assert.equal(redactEndpoint(AUTH_URL), 'auth.invalid/v3/<key>');
});

test('a permanently unauthorized provider is disabled once and never receives backfill requests again', async () => {
  const { fn, calls } = fakeFetch();
  const pool = createProviderPool([AUTH_URL, GOOD_URL], { chainId: 10143, fetchFn: fn });
  const t = pool.transport({ chain: undefined, retryCount: 0 });
  // Concurrent requests are JSON-RPC batched by viem: the 401 body is not JSON, which previously hid the status.
  for (let i = 0; i < 5; i++) await Promise.all(Array.from({ length: 10 }, () => t.request({ method: 'eth_blockNumber' })));
  const [auth, good] = pool.health();
  assert.equal(auth.state, 'disabled'); assert.equal(auth.lastFailure, 'AUTH');
  assert.equal(calls['auth.invalid'], 1, 'exactly one request reached the unauthorized endpoint');
  assert.equal(good.state, 'healthy'); assert.equal(good.requests, 50);
  assert.doesNotMatch(JSON.stringify(pool.health()), /0123456789abcdef/, 'no credential in health output');
});

test('transient 5xx opens a circuit and the provider recovers after the circuit window', async () => {
  const { fn } = fakeFetch({ flakyFailures: 1 });
  const pool = createProviderPool([FLAKY_URL, GOOD_URL], { chainId: 10143, fetchFn: fn, circuitMs: 20 });
  const t = pool.transport({ chain: undefined, retryCount: 0 });
  assert.equal(await t.request({ method: 'eth_blockNumber' }), '0x10');
  assert.equal(pool.health()[0].state, 'circuit-open'); assert.equal(pool.health()[0].lastFailure, 'HTTP_5XX');
  await new Promise((r) => setTimeout(r, 30));
  await t.request({ method: 'eth_blockNumber' });
  assert.equal(pool.health()[0].state, 'healthy');
});

test('a valid JSON-RPC error (revert) is returned to the caller and does not fail the provider over', async () => {
  const { fn, calls } = fakeFetch({ revert: true });
  const pool = createProviderPool([GOOD_URL, FLAKY_URL], { chainId: 10143, fetchFn: fn });
  const t = pool.transport({ chain: undefined, retryCount: 0 });
  await assert.rejects(t.request({ method: 'eth_call', params: [] }), /reverted/);
  assert.equal(pool.health()[0].state, 'healthy'); assert.equal(calls['flaky.invalid'] ?? 0, 0);
});

test('all providers unauthorized → a clear error naming each endpoint state', async () => {
  const { fn } = fakeFetch();
  const pool = createProviderPool([AUTH_URL], { chainId: 10143, fetchFn: fn });
  await assert.rejects(pool.transport({ chain: undefined, retryCount: 0 }).request({ method: 'eth_blockNumber' }), /No usable Monad RPC provider \(auth\.invalid\/v3\/<key>:disabled\/AUTH\)/);
  assert.equal(pool.health()[0].lastFailure, 'AUTH');
  await assert.rejects(pool.transport({ chain: undefined, retryCount: 0 }).request({ method: 'eth_blockNumber' }), /No usable Monad RPC provider \(auth\.invalid\/v3\/<key>:disabled\/AUTH\)/);
});

test('rpcEndpoints is provider neutral and deduplicates', () => {
  assert.deepEqual(rpcEndpoints({ MONAD_TESTNET_RPC_URLS: `${GOOD_URL}, ${AUTH_URL},${GOOD_URL}` }), [GOOD_URL, AUTH_URL]);
  assert.deepEqual(rpcEndpoints({ MONAD_TESTNET_RPC_URL: GOOD_URL, MONAD_TESTNET_RPC_FALLBACK_URL: AUTH_URL }), [GOOD_URL, AUTH_URL]);
  assert.throws(() => rpcEndpoints({}), /required/);
});

test('only one indexer process may own a database; stale locks are reclaimed', () => {
  const dir = mkdtempSync(join(tmpdir(), 'idx-lock-')); const file = join(dir, 'db.sqlite');
  try {
    const release = acquireDbLock(file);
    writeFileSync(`${file}.lock`, String(process.ppid)); // a live foreign pid
    assert.throws(() => acquireDbLock(file), /INDEXER_DB_LOCKED/);
    writeFileSync(`${file}.lock`, '2147483646'); // dead pid → stale
    const again = acquireDbLock(file); again(); release();
  } finally { rmSync(dir, { recursive: true, force: true }); }
});

test('long catch-up publishes consistent v2 snapshots progressively and reaches the head', async () => {
  const { Indexer, START_BLOCK } = await import('../src/sync.ts');
  const { Store } = await import('../src/store.ts');
  const { PROJECTION_VERSION } = await import('../src/project.ts');
  const store = new Store(':memory:'); const indexer = new Indexer(store, 'http://unused.invalid', 8, 20_000);
  const head = START_BLOCK + 45_008; const hash = `0x${'b'.repeat(64)}`;
  indexer.client = { getChainId: async () => 10143, getBlockNumber: async () => BigInt(head), getLogs: async () => [], getBlock: async () => ({ hash, timestamp: 1000n }) } as never;
  const published: number[] = [];
  try {
    for (let i = 0; i < 5 && (i === 0 || indexer.progress.catchingUp); i++) {
      await indexer.sync();
      assert.equal(indexer.error, null, indexer.progress.lastError ?? '');
      const snap = store.get<{ indexedBlock: number; projectionVersion: number }>('snapshot')!;
      assert.equal(snap.projectionVersion, PROJECTION_VERSION); published.push(snap.indexedBlock);
    }
    assert.deepEqual(published, [START_BLOCK + 20_000, START_BLOCK + 40_000, head - 8]);
    assert.equal(indexer.progress.catchingUp, false); assert.equal(indexer.progress.passes, 3);
    assert.ok(published.every((b, i) => i === 0 || b > published[i - 1]), 'monotonic progress');
    while (indexer.backfillRunning) await new Promise((r) => setTimeout(r, 5));
  } finally { store.close(); }
});
