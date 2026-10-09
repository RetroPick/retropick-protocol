import { NextRequest, NextResponse } from 'next/server';

// This endpoint is read-only. Wallets broadcast directly through their provider.
const methods = new Set(['eth_chainId', 'eth_blockNumber', 'eth_call', 'eth_getBalance', 'eth_getCode', 'eth_getTransactionReceipt', 'eth_getTransactionByHash', 'eth_getBlockByNumber', 'eth_getLogs']);
let nextReadAt = 0;
const reads = new Map<string, { expires: number; promise: Promise<Record<string, unknown>> }>();
async function forward(call: { method: string; params?: unknown[]; id?: unknown }) {
  const key = JSON.stringify([call.method, call.params || []]);
  const cacheable = !(call.method === 'eth_call' && ['latest','pending'].includes(String(call.params?.[1] || 'latest')));
  const cached = cacheable ? reads.get(key) : undefined;
  if (cached && cached.expires > Date.now()) return { ...await cached.promise, id: call.id };
  const promise = (async () => {
    // Pace bursts, including each member of a JSON-RPC batch, below the qualified provider limit.
    const due = Math.max(Date.now(), nextReadAt); nextReadAt = due + 110;
    if (due > Date.now()) await new Promise(resolve => setTimeout(resolve, due - Date.now()));
    const upstream = await fetch(process.env.MONAD_TESTNET_RPC_URL || 'https://testnet-rpc.monad.xyz', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({jsonrpc:'2.0', id:1, method:call.method, params:call.params || []}), signal: AbortSignal.timeout(12000), cache: 'no-store' });
    if (!upstream.ok) throw Error();
    const body = await upstream.text(); if (body.length > 2_000_000) throw Error();
    const result = JSON.parse(body) as Record<string, unknown>;
    if (result.error) reads.delete(key);
    return result;
  })();
  if (reads.size > 1000) reads.clear();
  if(cacheable) reads.set(key, {expires:Date.now()+2000, promise});
  try { return {...await promise, id:call.id}; } catch (error) {reads.delete(key);throw error;}
}
export async function POST(request: NextRequest) {
  const raw = await request.text();
  if (raw.length > 65536) return NextResponse.json({ error: 'Request too large' }, { status: 413 });
  let payload: unknown;
  try { payload = JSON.parse(raw); } catch { return NextResponse.json({ error: 'Invalid JSON' }, { status: 400 }); }
  const calls = Array.isArray(payload) ? payload : [payload];
  if (!calls.length || calls.length > 40) return NextResponse.json({ error: 'Invalid batch' }, { status: 400 });
  for (const call of calls) {
    if (!call || call.jsonrpc !== '2.0' || !methods.has(call.method) || (call.params !== undefined && !Array.isArray(call.params))) return NextResponse.json({ error: 'Read-only RPC method required' }, { status: 400 });
    if (call.method === 'eth_getLogs') {
      const filter = call.params[0];
      try {
        if (!filter?.address || Array.isArray(filter.address) || !/^0x[\da-f]{40}$/i.test(filter.address)) throw Error();
        const from = BigInt(filter.fromBlock), to = BigInt(filter.toBlock);
        if (from < 0n || to < from || to - from > 2000n) throw Error();
      } catch { return NextResponse.json({ error: 'Logs require one address and a range of at most 2000 blocks' }, { status: 400 }); }
    }
  }
  try {
    const responses = await Promise.all(calls.map(forward));
    return NextResponse.json(Array.isArray(payload) ? responses : responses[0], {headers:{'Cache-Control':'no-store'}});
  } catch { return NextResponse.json({ error: 'Monad RPC unavailable; retry shortly' }, { status: 502 }); }
}
