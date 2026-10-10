#!/usr/bin/env node
/**
 * E2E session wallet bridge (Gate 5). A loopback-only JSON-RPC shim that backs
 * retro-ui's EIP-1193 session provider with the provisioned Foundry
 * keystores, so live testnet transactions originate through the application's
 * real pipeline. Keystores and password files never leave this process; the
 * page only ever sees addresses and transaction hashes.
 *
 * Required environment:
 *   MONAD_TESTNET_RPC_URL, MONAD_TESTNET_PASSWORD_FILE_A
 * Optional:
 *   E2E_BRIDGE_PORT (default 8789), E2E_KEYSTORE (default ~/.foundry/keystores/monad-testnet)
 */
import { createServer } from 'node:http';
import { execFile } from 'node:child_process';
import { homedir } from 'node:os';
import { join } from 'node:path';

const rpc = process.env.MONAD_TESTNET_RPC_URL;
const passwordFile = process.env.MONAD_TESTNET_PASSWORD_FILE_A;
const keystore = process.env.E2E_KEYSTORE ?? join(homedir(), '.foundry/keystores/monad-testnet');
const port = Number(process.env.E2E_BRIDGE_PORT ?? 8789);
if (!rpc || !passwordFile) {
  console.error('wallet-bridge: MONAD_TESTNET_RPC_URL and MONAD_TESTNET_PASSWORD_FILE_A are required');
  process.exit(1);
}

const cast = (args) => new Promise((resolve, reject) => {
  execFile('cast', args, { maxBuffer: 16 * 1024 * 1024 }, (error, stdout, stderr) => {
    if (error) reject(new Error(stderr.trim() || error.message));
    else resolve(stdout.trim());
  });
});

let cachedAccount = null;
async function account() {
  if (!cachedAccount) cachedAccount = await cast(['wallet', 'address', '--keystore', keystore, '--password-file', passwordFile]);
  return cachedAccount;
}

async function dispatch(method, params) {
  if (method === 'eth_accounts' || method === 'eth_requestAccounts') return [await account()];
  if (method === 'eth_chainId') return '0x279f'; // 10143
  if (method === 'eth_sendTransaction') {
    const tx = (Array.isArray(params) ? params[0] : params) ?? {};
    if (!tx.to || String(tx.to).toLowerCase() !== (await account()).toLowerCase()) {
      if (!tx.to) throw new Error('missing to');
      // The pipeline only sends from the connected account; anything else is a bug.
      throw new Error('from mismatch');
    }
    const args = [
      'send', tx.to,
      '--keystore', keystore, '--password-file', passwordFile,
      '--rpc-url', rpc, '--json',
    ];
    if (tx.value && tx.value !== '0x0') args.push('--value', BigInt(tx.value).toString());
    if (tx.data && tx.data !== '0x') args.push('--data', tx.data);
    const out = await cast(args);
    const receipt = JSON.parse(out);
    if (!receipt.transactionHash) throw new Error('broadcast failed');
    return receipt.transactionHash;
  }
  throw new Error(`unsupported method ${method}`);
}

createServer((req, res) => {
  res.setHeader('content-type', 'application/json');
  // Loopback-only dev bridge for the page's session provider; no secrets cross this boundary.
  res.setHeader('access-control-allow-origin', '*');
  res.setHeader('access-control-allow-methods', 'POST, OPTIONS');
  res.setHeader('access-control-allow-headers', 'content-type');
  if (req.method === 'OPTIONS') { res.statusCode = 204; res.end(); return; }
  if (req.method !== 'POST' || req.url !== '/rpc') { res.statusCode = 404; res.end(JSON.stringify({ error: { message: 'not found' } })); return; }
  let body = '';
  req.on('data', (chunk) => { body += chunk; if (body.length > 64 * 1024) req.destroy(); });
  req.on('end', () => {
    let method;
    let params;
    try { ({ method, params } = JSON.parse(body)); } catch { res.end(JSON.stringify({ error: { message: 'bad request' } })); return; }
    dispatch(method, params)
      .then((result) => res.end(JSON.stringify({ result })))
      .catch((error) => { res.statusCode = 200; res.end(JSON.stringify({ error: { message: String(error.message ?? error) } })); });
  });
}).listen(port, '127.0.0.1', () => {
  console.log(`wallet-bridge listening on 127.0.0.1:${port} (keystore ${keystore.split('/').pop()})`);
});
