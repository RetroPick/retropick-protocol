#!/usr/bin/env node
// Provider-neutral RPC diagnostics. Never prints credentials: URLs are reduced to host + redacted path.
// Usage: RPC_URLS="url1,url2" node scripts/rpc-probe.mjs [fromBlockOffset=200]
// Classifies each call: OK | AUTH (401/403, provider says no access) | RATE_LIMIT (429 / -32005) | RANGE (log range too large) |
// JSONRPC_ERROR | HTTP_ERROR | NETWORK | TIMEOUT.
const urls = (process.env.RPC_URLS ?? '').split(',').map((s) => s.trim()).filter(Boolean);
if (!urls.length) { console.error('RPC_URLS required'); process.exit(2); }
const redact = (u) => { const x = new URL(u); return `${x.host}${x.pathname.replace(/[0-9a-f]{24,}/gi, '<key>')}`; };
function classify(status, body) {
  const text = typeof body === 'string' ? body : JSON.stringify(body ?? '');
  if (status === 401 || status === 403 || /does not have access|unauthori[sz]ed|invalid project|forbidden/i.test(text)) return 'AUTH';
  if (status === 429 || /-32005|rate limit|too many requests/i.test(text)) return 'RATE_LIMIT';
  if (/range|block range|limit exceeded|too large/i.test(text) && /error/i.test(text)) return 'RANGE';
  if (status >= 400) return 'HTTP_ERROR';
  if (body && typeof body === 'object' && body.error) return 'JSONRPC_ERROR';
  return 'OK';
}
async function call(url, method, params) {
  const t0 = performance.now();
  try {
    const r = await fetch(url, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ jsonrpc: '2.0', id: 1, method, params }), signal: AbortSignal.timeout(15000) });
    const raw = await r.text(); let body; try { body = JSON.parse(raw); } catch { body = raw.slice(0, 160); }
    const cls = classify(r.status, body);
    return { method, http: r.status, ms: Math.round(performance.now() - t0), class: cls, result: cls === 'OK' ? (Array.isArray(body.result) ? `${body.result.length} logs` : body.result) : undefined, error: cls === 'OK' ? undefined : (typeof body === 'object' ? body.error?.message ?? JSON.stringify(body).slice(0, 160) : body) };
  } catch (e) { return { method, http: null, ms: Math.round(performance.now() - t0), class: e.name === 'TimeoutError' ? 'TIMEOUT' : 'NETWORK', error: String(e.message).slice(0, 160) }; }
}
const offset = Number(process.argv[2] ?? 200);
const report = [];
for (const url of urls) {
  const rows = [await call(url, 'eth_chainId', []), await call(url, 'eth_blockNumber', [])];
  const head = rows[1].class === 'OK' ? Number(rows[1].result) : null;
  if (head !== null) for (const span of [10, 100]) rows.push({ ...(await call(url, 'eth_getLogs', [{ fromBlock: '0x' + (head - offset).toString(16), toBlock: '0x' + (head - offset + span - 1).toString(16) }])), span });
  else rows.push({ method: 'eth_getLogs', class: 'SKIPPED', error: 'no head block' });
  report.push({ endpoint: redact(url), chainId: rows[0].result ? Number(rows[0].result) : null, rows });
}
console.log(JSON.stringify(report, null, 1));
