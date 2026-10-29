#!/usr/bin/env node
// Gate A: Microsoft Playwright MCP server — stdio startup, initialize, tools/list, and a real browser navigation +
// accessibility snapshot + screenshot via tools/call. This proves the SERVER works; it does not prove that a Kiro
// agent session has discovered the tools (Gate B is recorded separately).
// Usage: node e2e/tools/mcp-handshake.mjs <evidenceDir> [url]
import { spawn } from 'node:child_process';
import { mkdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

const [evidence = '/tmp/mcp-handshake', url = 'https://ponsfamily.com'] = process.argv.slice(2);
const VERSION = process.env.PLAYWRIGHT_MCP_VERSION ?? '0.0.83';
mkdirSync(evidence, { recursive: true });
const child = spawn('npx', ['-y', `@playwright/mcp@${VERSION}`, '--headless', '--isolated', '--output-dir', evidence], { stdio: ['pipe', 'pipe', 'pipe'] });
let buffer = ''; const pending = new Map(); let id = 0; const log = [];
child.stdout.on('data', (d) => {
  buffer += d;
  let nl; while ((nl = buffer.indexOf('\n')) >= 0) {
    const line = buffer.slice(0, nl).trim(); buffer = buffer.slice(nl + 1);
    if (!line) continue;
    try { const msg = JSON.parse(line); if (msg.id && pending.has(msg.id)) { pending.get(msg.id)(msg); pending.delete(msg.id); } } catch { /* non-JSON */ }
  }
});
child.stderr.on('data', (d) => log.push(String(d).slice(0, 500)));
const rpc = (method, params, timeout = 90_000) => new Promise((resolve, reject) => {
  const n = ++id; pending.set(n, resolve);
  child.stdin.write(JSON.stringify({ jsonrpc: '2.0', id: n, method, params }) + '\n');
  setTimeout(() => { if (pending.has(n)) { pending.delete(n); reject(new Error(`${method} timed out`)); } }, timeout);
});
const result = { version: VERSION, url, steps: [] };
try {
  const init = await rpc('initialize', { protocolVersion: '2025-06-18', capabilities: {}, clientInfo: { name: 'retropick-mcp-gate-a', version: '1' } });
  result.steps.push({ step: 'initialize', ok: !!init.result, server: init.result?.serverInfo });
  child.stdin.write(JSON.stringify({ jsonrpc: '2.0', method: 'notifications/initialized' }) + '\n');
  const tools = await rpc('tools/list', {});
  const names = (tools.result?.tools ?? []).map((t) => t.name);
  result.steps.push({ step: 'tools/list', ok: names.length > 0, count: names.length, tools: names });
  const nav = await rpc('tools/call', { name: 'browser_navigate', arguments: { url } }, 120_000);
  const navText = (nav.result?.content ?? []).map((c) => c.text ?? '').join('\n');
  result.steps.push({ step: 'browser_navigate', ok: !nav.result?.isError, chars: navText.length });
  const snap = await rpc('tools/call', { name: 'browser_snapshot', arguments: {} }, 120_000);
  const snapText = (snap.result?.content ?? []).map((c) => c.text ?? '').join('\n');
  writeFileSync(join(evidence, 'mcp-accessibility-snapshot.md'), snapText);
  result.steps.push({ step: 'browser_snapshot', ok: !snap.result?.isError && snapText.length > 0, chars: snapText.length });
  const shot = await rpc('tools/call', { name: 'browser_take_screenshot', arguments: { filename: join(evidence, 'mcp-pons-screenshot.png'), fullPage: false } }, 120_000);
  result.steps.push({ step: 'browser_take_screenshot', ok: !shot.result?.isError, text: (shot.result?.content ?? []).filter((c) => c.type === 'text').map((c) => c.text).join(' ').slice(0, 300) });
  await rpc('tools/call', { name: 'browser_close', arguments: {} }).catch(() => {});
} catch (error) {
  result.error = String(error);
} finally {
  result.ok = result.steps.length >= 5 && result.steps.every((s) => s.ok);
  result.stderr = log.join('').slice(0, 2000);
  writeFileSync(join(evidence, 'mcp-handshake.json'), JSON.stringify(result, null, 2));
  console.log(JSON.stringify({ ok: result.ok, steps: result.steps.map((s) => `${s.step}:${s.ok}`), error: result.error }, null, 1));
  child.kill();
  process.exit(result.ok ? 0 : 1);
}
