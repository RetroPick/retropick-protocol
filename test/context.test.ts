import test from 'node:test';
import assert from 'node:assert/strict';
import { decodeFunctionResult, encodeFunctionResult } from 'viem';
import { abis, graduationPhase, graduatedMarket, RETROPICK } from '../src/context.ts';

test('the Coordinator named tuple decodes to phase 2 rather than NaN', () => {
  const ledgerFunction = abis.coordinator.find((f) => f.name === 'ledger')!;
  const data = encodeFunctionResult({ abi: [ledgerFunction], functionName: 'ledger', result: { phase: 2, securedQuote: 1n, securedLaunchTokens: 2n, consumedQuote: 1n, consumedLaunchTokens: 2n, destinationIdentity: `0x${'11'.repeat(32)}`, receiptHash: `0x${'22'.repeat(32)}`, protectedLPReceiver: RETROPICK.tokens[0].vault, protectedLPAmount: 3n, protectedExcessReceiver: RETROPICK.tokens[0].vault, protectedExcessAmount: 4n, securedAt: 5n } });
  const ledger = decodeFunctionResult({ abi: [ledgerFunction], functionName: 'ledger', data });
  assert.equal(graduationPhase(ledger), 2);
  assert.throws(() => graduationPhase([2]), /unavailable/);
  assert.throws(() => graduationPhase({ phase: NaN }), /Invalid/);
});

test('a graduated receipt must contain the configured market', () => {
  const expected = RETROPICK.tokens[0].market;
  assert.equal(graduatedMarket({ market: expected.toLowerCase() }, expected), expected.toLowerCase());
  assert.throws(() => graduatedMarket({}, expected), /unavailable/);
  assert.throws(() => graduatedMarket({ market: RETROPICK.tokens[0].token }, expected), /differs/);
});

test('deployed getMarketParams is the exact 11-output tuple with numeric quote decimals', () => {
  const fn = abis.kuru.find((f) => f.name === 'getMarketParams')!;
  assert.deepEqual(fn.outputs.map((o) => o.type), ['uint32', 'uint96', 'address', 'uint256', 'address', 'uint256', 'uint32', 'uint96', 'uint96', 'uint256', 'uint256']);
  const result = [100000000, 100000000n, RETROPICK.tokens[0].token, 18n, '0x0000000000000000000000000000000000000000', 18n, 10, 1n, 100000000000n, 30n, 0n] as const;
  const data = encodeFunctionResult({ abi: [fn], functionName: 'getMarketParams', result });
  const decoded = decodeFunctionResult({ abi: [fn], functionName: 'getMarketParams', data });
  assert.equal(decoded.length, 11);
  assert.equal(decoded[5], 18n);
  assert.equal(decoded[6], 10);
});
