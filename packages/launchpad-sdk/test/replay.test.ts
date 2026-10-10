import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createChain } from '../src/chain.ts';
import { decodeTokenLaunched, decodeGraduation } from '../src/decode.ts';
import { release } from '../src/release.ts';

/**
 * Gate 2 SDK conformance: replay the canonical historical launch transaction
 * and decode it with the application's own decode layer. Network-dependent;
 * enabled with RUN_SDK_NETWORK_TESTS=1.
 */
const enabled = process.env.RUN_SDK_NETWORK_TESTS === '1';
const options = { skip: enabled ? false : 'set RUN_SDK_NETWORK_TESTS=1 (needs Monad testnet RPC)' };

test('canonical launch transaction replays and decodes TokenLaunched', options, async () => {
  const chain = createChain(process.env.MONAD_TESTNET_RPC_URL ?? 'https://testnet-rpc.monad.xyz');
  const canonical = release.canonicalTransactions.find((entry) => entry.label === 'Launch');
  assert.ok(canonical, 'canonical Launch transaction recorded in the release bundle');
  const receipt = await chain.getTransactionReceipt({ hash: canonical.hash });
  assert.equal(receipt.status, 'success');
  const launched = decodeTokenLaunched(receipt.logs);
  assert.ok(launched, 'TokenLaunched decodable from the canonical receipt');
  assert.equal(
    (launched.args.token as string).toLowerCase(),
    release.demo.token.toLowerCase(),
    'canonical launch created the demo token',
  );
  assert.equal(
    (launched.args.curve as string).toLowerCase(),
    release.demo.curve.toLowerCase(),
  );
});

test('demo launch reads back GRADUATED via the SDK read model', options, async () => {
  const { readLaunch } = await import('../src/model.ts');
  const chain = createChain(process.env.MONAD_TESTNET_RPC_URL ?? 'https://testnet-rpc.monad.xyz');
  const launch = await readLaunch(chain, release.demo.token);
  assert.equal(Number(launch.ledger.phase), 2);
  assert.equal(launch.packet.quoteAsset, '0x0000000000000000000000000000000000000000');
  assert.ok(launch.custody, 'graduated launch exposes protected custody balances');
});
