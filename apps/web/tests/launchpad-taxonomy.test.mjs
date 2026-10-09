import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const { LaunchTokenAdapter, PredictionMarketAdapter, PrismInstrumentAdapter, getInstrumentAdapter, getInstrumentRoute, getInstrumentTradeIntent } = require('../.test-output/domain/launchpad-adapters.js');
const { createInstrumentRepository, launchInstruments, queryLaunchInstruments } = require('../.test-output/domain/launchpad-repository.js');
const { resolveContractDeployment, hasExecutableContract } = require('../.test-output/domain/contract-registry.js');
const { tokenLaunches } = require('../.test-output/domain/launchpad-fixtures.js');
const { markets } = require('../.test-output/domain/fixtures.js');
const { prismSeries } = require('../.test-output/domain/prism-fixtures.js');

const byId = (id) => launchInstruments.find((item) => item.id === id);

test('each source normalizes to one canonical instrument with distinct semantics', () => {
  const token = LaunchTokenAdapter.normalize(tokenLaunches[0]);
  const prediction = PredictionMarketAdapter.normalize(markets[0]);
  const prism = PrismInstrumentAdapter.normalize(prismSeries[0]);
  assert.equal(token.kind, 'token');
  assert.equal(token.contract.family, 'launch-token');
  assert.equal(prediction.kind, 'prediction');
  assert.equal(prediction.contract.family, 'market-engine-v1');
  assert.equal(prediction.prediction.yesPrice, markets[0].yes);
  assert.equal(prediction.prediction.noPrice, markets[0].no);
  assert.equal(prediction.prediction.representation, 'unverified');
  assert.equal(prism.kind, 'prism');
  assert.equal(prism.contract.family, 'prism-state-pool');
  assert.deepEqual(prism.prism.components.map((part) => part.unitsPerShare), [0.6, 0.4]);
  assert.equal(prism.contract.statePool, undefined);
  assert.equal(prism.marketCap, null);
});

test('kind, reference and pair are orthogonal', () => {
  const cryptoPrediction = byId('btc-150k');
  assert.equal(cryptoPrediction.kind, 'prediction');
  assert.equal(cryptoPrediction.referenceClass, 'crypto');
  assert.equal(cryptoPrediction.pair.symbol, 'USDC');
  assert.ok(queryLaunchInstruments({ type: 'crypto' }).includes(cryptoPrediction));
  const stockPrediction = PredictionMarketAdapter.normalize({ ...markets[0], id: 'stock-event', category: 'Technology', symbol: 'STOCK' });
  stockPrediction.referenceClass = 'stock';
  stockPrediction.pair = { symbol: 'TOKENIZED_STOCK', referenceClass: 'stock', role: 'quote' };
  assert.equal(stockPrediction.kind, 'prediction');
  assert.equal(queryLaunchInstruments({ type: 'stocks' }, [stockPrediction]).length, 1);
  assert.equal(queryLaunchInstruments({ type: 'prediction' }, [stockPrediction]).length, 1);
  assert.ok(queryLaunchInstruments({ type: 'crypto' }).some((item) => item.kind === 'token'));
});

test('all tabs, watchlist and prediction topics query the same dataset', () => {
  const all = queryLaunchInstruments({ type: 'all' });
  assert.equal(all.length, launchInstruments.length);
  assert.deepEqual(new Set(all.map((item) => item.kind)), new Set(['token', 'prediction', 'prism']));
  assert.ok(queryLaunchInstruments({ type: 'prediction' }).every((item) => item.kind === 'prediction'));
  assert.ok(queryLaunchInstruments({ type: 'stocks' }).every((item) => item.referenceClass === 'stock'));
  assert.ok(queryLaunchInstruments({ type: 'prediction', predictionTopic: 'Macro' }).every((item) => item.prediction.topic === 'Macro'));
  assert.deepEqual(queryLaunchInstruments({ type: 'prediction', watchlist: ['btc-150k'] }).map((item) => item.id), ['btc-150k']);
});

test('missing financial metrics remain missing', () => {
  const prediction = byId('btc-150k');
  assert.equal(prediction.marketCap, null);
  assert.equal(prediction.lifetimeVolume, null);
  assert.equal(prediction.trades24h, null);
  assert.equal(byId('pfedbtc').liquidity, null);
  assert.ok(queryLaunchInstruments({ sort: 'liquidity' }).length > 0);
});

test('family dispatch owns detail routing and unavailable trade intent', async () => {
  for (const [id, family, route] of [
    [tokenLaunches[0].id, 'launch-token', '/launchpad/token/'],
    ['btc-150k', 'market-engine-v1', '/launchpad/prediction/'],
    ['pfedbtc', 'prism-state-pool', '/prism/'],
  ]) {
    const item = byId(id);
    assert.equal(getInstrumentAdapter(item).family, family);
    assert.ok(getInstrumentRoute(item).startsWith(route));
    assert.equal((await getInstrumentTradeIntent(item, { direction: 'buy', amount: 1n })).type, 'unavailable');
    assert.equal(item.capabilities.trade, false);
  }
});

test('exact chain and family registry lookup cannot route Monad to another chain', () => {
  const baseOnly = { 84532: { 'market-engine-v1': { address: '0x123', abi: [{ type: 'function' }], sourceCommit: 'test' } } };
  assert.equal(resolveContractDeployment(143, 'market-engine-v1', baseOnly), null);
  assert.equal(resolveContractDeployment(84532, 'market-engine-v1', baseOnly).address, '0x123');
  assert.equal(hasExecutableContract(143, { family: 'market-engine-v1', marketEngine: '0x123', templateId: '0x123' }, baseOnly), false);
  assert.equal(hasExecutableContract(84532, { family: 'market-engine-v1', marketEngine: '0x456', templateId: '0x123' }, baseOnly), false);
  assert.equal(resolveContractDeployment(143, 'market-engine-v1'), null);
  assert.equal(resolveContractDeployment(84532, 'market-engine-v1'), null);
  assert.equal(hasExecutableContract(143, { family: 'market-engine-v1', marketEngine: '0x123', templateId: '0x123' }), false);
  assert.equal(hasExecutableContract(143, { family: 'prism-state-pool', statePool: '0x123', statePoolId: '0x123', claimId: 1n }), false);
});

test('repository deduplicates shared featured/feed ID and rejects conflicting identities', () => {
  const prediction = byId('btc-150k');
  assert.equal(createInstrumentRepository([prediction, prediction]).length, 1);
  assert.equal(queryLaunchInstruments({ type: 'all' }).filter((item) => item.id === prediction.id).length, 1);
  assert.throws(() => createInstrumentRepository([prediction, { ...prediction, contract: { family: 'launch-token' } }]), /Conflicting instrument identity/);
});
