import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
const require = createRequire(import.meta.url);
const { amountOut, buyQuote, sellQuote, minOutput } = require('../.test-output/live/math.js');
const { decodeBook } = require('../.test-output/live/book.js');
test('exact fee flooring and large reserves preserve integer precision', () => {
  const reserve = 10n ** 24n;
  assert.equal(buyQuote(101n, reserve, reserve, reserve, 100n, 100n), 98n);
  assert.equal(sellQuote(101n, reserve, reserve, 100n, 100n), 98n);
  assert.equal(amountOut(0n, reserve, reserve), 0n);
  assert.equal(minOutput(100000n), 99500n);
});
test('final buy caps at the remaining sellable allocation', () => {
  assert.equal(buyQuote(10n ** 18n, 10n ** 18n, 1000n * 10n ** 18n, 2n, 100n, 0n), 2n);
});
test('Kuru L2 encoding uses a one-word side delimiter, preserving price and size', () => {
  const words = [69510121n, 400000n, 123456789012345678n, 0n, 410000n, 200000000n];
  const hex = '0x' + words.map(n => n.toString(16).padStart(64, '0')).join('');
  assert.deepEqual(decodeBook(hex), { block: 69510121n, bids: [{ price: 400000n, size: 123456789012345678n }], asks: [{ price: 410000n, size: 200000000n }] });
  assert.deepEqual(decodeBook('0x' + [1n, 0n].map(n => n.toString(16).padStart(64, '0')).join('')), { block: 1n, bids: [], asks: [] });
});
