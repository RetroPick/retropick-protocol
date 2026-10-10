import { test } from 'node:test';
import assert from 'node:assert/strict';
import { project, executionPriceX18, marketCapQuoteRaw, aggregateCandles, ZERO } from '../src/project.ts';
import { seed, graduated, event, TOKEN, CURVE, MARKET, ALICE, BOB, USDC } from './fixtures.ts';

test('curve execution prices exclude fees, preserve settlement, and agree for 6/18 decimal quotes', () => {
  const six = seed({ quoteAsset: USDC, quoteSymbol: 'USDC', quoteDecimals: 6 });
  const buy = event('CurveBuy', { buyer: ALICE, quoteIn: '1100000', tokensOut: '2000000000000000000', fee: '50000', tax: '50000' }, { logIndex: 0 });
  const sell = event('CurveSell', { seller: BOB, quoteOut: '900000', tokensIn: '1000000000000000000', fee: '50000', tax: '50000' }, { logIndex: 1 });
  const result = project([sell, buy, buy], [six], 1000);
  assert.equal(result.trades.length, 2); assert.equal(result.trades[0].priceX18, '500000000000000000'); assert.equal(result.trades[0].quoteRaw, '1100000');
  assert.equal(result.trades[1].priceX18, '1000000000000000000'); assert.equal(result.trades[1].quoteRaw, '900000');
  assert.deepEqual(result.launches[0].candles, [{ timestamp: 120, open: '500000000000000000', high: '1000000000000000000', low: '500000000000000000', close: '1000000000000000000', quoteVolumeRaw: '2000000', tradeCount: 2 }]);
  assert.equal(executionPriceX18(1_000_000n, 2n * 10n ** 18n, 18, 6), executionPriceX18(10n ** 18n, 2n * 10n ** 18n, 18, 18));
  assert.equal(marketCapQuoteRaw(5n * 10n ** 17n, 1000n * 10n ** 18n, 18, 6), 500_000_000n);
});

test('prices retain sub-atomic quote-per-token precision and enormous integer amounts', () => {
  assert.equal(executionPriceX18(1n, 10n ** 24n, 18, 6), 1_000_000n);
  const quote = 2n ** 200n; assert.equal(executionPriceX18(quote, 10n ** 18n, 18, 18), quote);
});

test('Kuru last execution replaces seeded price and normalizes actual market size precision', () => {
  const s = graduated(6); s.launch.marketParams!.sizePrecision = '10000';
  const trade = event('Trade', { orderId: 0, makerAddress: MARKET, takerAddress: ALICE, isBuy: true, price: '1500000000000000000', filledSize: '20000', updatedSize: 0 }, { address: MARKET });
  const result = project([trade], [s], 1000);
  assert.equal(result.trades[0].tokensRaw, '2000000000000000000'); assert.equal(result.trades[0].quoteRaw, '3000000');
  assert.equal(result.launches[0].priceX18, '1500000000000000000'); assert.equal(result.launches[0].priceRaw, result.launches[0].priceX18); assert.equal(result.launches[0].marketCapRaw, '1500000000');
  assert.equal(result.launches[0].priceSource, 'KURU_LAST_TRADE'); assert.equal(result.orders.length, 0); assert.equal(result.qualifyingEvents[0].actor, ALICE);
  assert.equal(project([], [graduated()], 1000).launches[0].priceSource, 'UNAVAILABLE');
});

test('UTC candle aggregation preserves first open, last close, extrema, volume and gaps', () => {
  const base = [
    { timestamp: 60, open: '9', high: '12', low: '8', close: '10', quoteVolumeRaw: '100', tradeCount: 2 },
    { timestamp: 240, open: '11', high: '13', low: '7', close: '8', quoteVolumeRaw: '200', tradeCount: 3 },
    { timestamp: 900, open: '15', high: '15', low: '15', close: '15', quoteVolumeRaw: '20', tradeCount: 1 },
  ];
  assert.deepEqual(aggregateCandles(base, '5m'), [
    { timestamp: 0, open: '9', high: '13', low: '7', close: '8', quoteVolumeRaw: '300', tradeCount: 5 },
    { timestamp: 900, open: '15', high: '15', low: '15', close: '15', quoteVolumeRaw: '20', tradeCount: 1 },
  ]);
  assert.equal(aggregateCandles(base, '1h')[0].close, '15'); assert.equal(aggregateCandles(base, '1h')[0].tradeCount, 6);
});

test('GTC projection handles partial fills, full fills, skipped IDs and cancellation without double debit', () => {
  const created = event('OrderCreated', { orderId: 7, owner: ALICE, isBuy: false, price: '150000000', size: '300000000' }, { address: MARKET });
  const partial = event('Trade', { orderId: 7, makerAddress: ALICE, takerAddress: BOB, isBuy: true, price: '1500000000000000000', filledSize: '200000000', updatedSize: '100000000' }, { address: MARKET, block: 12 });
  const partly = project([created, partial], [graduated()], 1000).orders[0];
  assert.equal(partly.originalSizeUnits, '300000000'); assert.equal(partly.remainingSizeUnits, '100000000'); assert.equal(partly.status, 'PARTIALLY_FILLED');
  const full = { ...partial, id: 'full', block: 13, args: { ...partial.args, filledSize: '100000000', updatedSize: 0 } };
  assert.equal(project([created, partial, full], [graduated()], 1000).orders[0].status, 'FILLED');
  const ignored = event('OrdersCanceled', { owner: ALICE, orderId: [0] }, { address: MARKET, block: 13 });
  assert.equal(project([created, partial, ignored], [graduated()], 1000).orders[0].status, 'PARTIALLY_FILLED');
  const cancelled = event('OrderCanceled', { owner: ALICE, orderId: 7 }, { address: MARKET, block: 14 });
  const batch = event('OrdersCanceled', { owner: ALICE, orderId: [7, 0] }, { address: MARKET, block: 14, logIndex: 1 });
  assert.equal(project([created, partial, cancelled, batch], [graduated()], 1000).orders[0].status, 'CANCELLED');
});

test('wallet candidates include arbitrary escrow tokens and margin assets; claims survive zero releasable', () => {
  const credit = event('TokenCredited', { recipient: BOB, token: USDC, amount: '1000000' });
  const claim = event('TokenClaimed', { recipient: BOB, token: USDC, amount: '500000' }, { id: 'claim', block: 12 });
  const deposit = event('Deposit', { owner: BOB, token: ZERO, amount: '2000000000000000000' }, { id: 'deposit' });
  const terms = event('VestingTermsSnapshotted', { token: TOKEN, creatorRecipient: ALICE, protocolRecipient: MARKET, protocolFeeShareBps: 500 });
  const recipient = event('CreatorRecipientUpdated', { token: TOKEN, newRecipient: BOB }, { id: 'recipient', block: 13 });
  const result = project([credit, claim, deposit, terms, recipient], [seed()], 1000, { assets: { [USDC]: { token: USDC, symbol: 'USDC', name: 'USD Coin', decimals: 6 } } });
  assert.equal(result.walletAssets[BOB].find(a => a.token === USDC)?.decimals, 6); assert.deepEqual(result.walletAssets[BOB].find(a => a.token === ZERO)?.sources, ['margin']);
  assert.equal(result.claims[0].amountRaw, '500000'); assert.equal(result.buybacks[0].creatorRecipient, BOB); assert.equal(result.buybacks[0].protocolRecipient, MARKET);
});

test('holder projection excludes zero and labels protocol custody with deterministic equal-balance ordering', () => {
  const mint = event('Transfer', { from: ZERO, to: CURVE, value: '1000000000000000000000' }, { address: TOKEN });
  const transfer = event('Transfer', { from: CURVE, to: ALICE, value: '1000000000000000000' }, { id: 'transfer', address: TOKEN, block: 12 });
  const result = project([mint, transfer], [seed()], 1000);
  assert.equal(result.holders[TOKEN].length, 2); assert.equal(result.holders[TOKEN][0].role, 'CURVE'); assert.equal(result.holders[TOKEN][1].role, 'WALLET');
  assert.equal(result.holders[TOKEN].some(h => h.address === ZERO), false);
});
