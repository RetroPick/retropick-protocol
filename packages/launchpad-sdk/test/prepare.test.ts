import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { encodeFunctionData, encodeAbiParameters, keccak256, toEventSignature, encodeErrorResult, type Address, type Hex } from 'viem';
import { curveAbi, factoryAbi, kuruAbi, marginAbi } from '../src/abi.ts';
import { kuruGrid, randomSalt, type KuruMarketParams } from '../src/prepare.ts';
import { retroPickFeeEscrowV2Abi } from '@retropick/abi/abi';
const feeEscrow = '0xb0312b0412c3BAa11895A6c4FeeC7CD9A01c2D96' as Address;
import { decodeEvents, decodeOrderCreated, buildErrorSelectorMap, decodeRevertData, classifyError } from '../src/decode.ts';

const actor = '0xB505cBaab3ACdF287af1366b9B1229404757913b' as Address;
const zero = '0x0000000000000000000000000000000000000000' as Address;
const fixture = JSON.parse(
  readFileSync(join(dirname(fileURLToPath(import.meta.url)), 'fixtures', 'cast-calldata.json'), 'utf8'),
) as Record<string, string>;

// --- encoding: SDK output must equal cast ground truth ----------------------

test('curve buy calldata matches cast ground truth', () => {
  const data = encodeFunctionData({ abi: curveAbi, functionName: 'buy', args: [1000000000000000000n, 990000000000000000n, actor] });
  assert.equal(data, fixture.curveBuy);
});

test('margin deposit calldata matches cast ground truth', () => {
  const data = encodeFunctionData({
    abi: marginAbi,
    functionName: 'deposit',
    args: [actor, zero, 500000000000000000n],
  });
  assert.equal(data, fixture.marginDeposit);
});

test('margin withdraw calldata matches cast ground truth', () => {
  const data = encodeFunctionData({ abi: marginAbi, functionName: 'withdraw', args: [123n, zero] });
  assert.equal(data, fixture.marginWithdraw);
});

test('orderbook addBuyOrder calldata matches cast ground truth', () => {
  const data = encodeFunctionData({ abi: kuruAbi, functionName: 'addBuyOrder', args: [100000, 500000000000000000n, true] });
  assert.equal(data, fixture.addBuyOrder);
});

test('orderbook batchCancelOrders calldata matches cast ground truth', () => {
  const data = encodeFunctionData({ abi: kuruAbi, functionName: 'batchCancelOrders', args: [[3, 7, 9]] });
  assert.equal(data, fixture.batchCancelOrders);
});

test('orderbook batchCancelOrdersNoRevert calldata matches cast ground truth', () => {
  const data = encodeFunctionData({ abi: kuruAbi, functionName: 'batchCancelOrdersNoRevert', args: [[3, 7]] });
  assert.equal(data, fixture.batchCancelOrdersNoRevert);
});

test('fee escrow claimToken calldata matches cast ground truth', () => {
  const data = encodeFunctionData({ abi: retroPickFeeEscrowV2Abi as unknown as Parameters<typeof encodeFunctionData>[0]['abi'], functionName: 'claimToken', args: [feeEscrow] });
  assert.equal(data, fixture.claimToken);
});

test('margin batchWithdrawMaxTokens calldata matches cast ground truth', () => {
  const data = encodeFunctionData({ abi: marginAbi, functionName: 'batchWithdrawMaxTokens', args: [[zero, '0x43e7e9b1b7d9A143573307b13D14B51580c18f15' as Address]] });
  assert.equal(data, fixture.batchWithdrawMaxTokens);
});

test('launchToken venue overload selects a distinct selector from the 3-arg overload', () => {
  const params = {
    name: 'x', symbol: 'X', logo: '', description: '',
    socials: { twitter: '', telegram: '', discord: '', website: '', farcaster: '' },
    creatorFeeRecipient: actor, creatorTaxBps: 100, buybackEnabled: false,
    expectedEconomics: '0x' + 'ab'.repeat(32) as Hex, salt: '0x' + 'cd'.repeat(32) as Hex,
  };
  const venue = encodeFunctionData({ abi: factoryAbi, functionName: 'launchToken', args: [params, 0n, zero, 1] });
  const threeArg = encodeFunctionData({ abi: factoryAbi, functionName: 'launchToken', args: [params, 0n, zero] });
  assert.notEqual(venue.slice(0, 10), threeArg.slice(0, 10));
});

// --- Kuru grid math ---------------------------------------------------------

const params: KuruMarketParams = {
  pricePrecision: 1_000_000n,
  sizePrecision: 1_000_000n,
  baseAsset: actor,
  baseDecimals: 18n,
  quoteAsset: '0x0000000000000000000000000000000000000000',
  quoteDecimals: 18n,
  tickSize: 100n,
  minSize: 1_000_000n,
  maxSize: 1_000_000_000_000n,
  takerFeeBps: 0n,
  makerFeeBps: 0n,
};

test('grid: size round-trips exactly through units', () => {
  const sizeRaw = 5n * 10n ** 18n;
  const units = kuruGrid.sizeToUnits(sizeRaw, params);
  assert.equal(units, 5_000_000n);
  assert.equal(kuruGrid.unitsToSize(units, params), sizeRaw);
});

test('grid: sub-precision size is rejected, not rounded', () => {
  assert.throws(() => kuruGrid.sizeToUnits(1n, params), /finer/);
});

test('grid: price snaps to tick away from crossing (pricePrecision-scaled per token)', () => {
  // fixture precision is 1e6: 1234.5 quote per token → 1234500000 units; tick 1 keeps it exact
  const priceRaw = 12345n * 10n ** 17n;
  assert.equal(kuruGrid.priceToUnits(priceRaw, params, 'buy'), 1234500000n);
  assert.equal(kuruGrid.priceToUnits(priceRaw, params, 'sell'), 1234500000n);
  // real-market precision (1e8): 0.004 MON/token → 400000 units
  const real: KuruMarketParams = { ...params, pricePrecision: 100000000n, sizePrecision: 100000000n, tickSize: 1n };
  assert.equal(kuruGrid.priceToUnits(4n * 10n ** 15n, real, 'buy'), 400000n);
  // sub-tick prices snap down (buy) / up (sell): 123.454545 → units 123454545, tick 100
  const ticked: KuruMarketParams = { ...params, tickSize: 100n };
  assert.equal(kuruGrid.priceToUnits(123454545n * 10n ** 12n, ticked, 'buy'), 123454500n);
  assert.equal(kuruGrid.priceToUnits(123454545n * 10n ** 12n, ticked, 'sell'), 123454600n);
});

test('grid: resting buy quote cost mirrors the book (ceil then scale)', () => {
  // fixture sP=1e6, pP=1e6: ceil(1000*15/1e6)=1 → 1e18/1e6 = 1e12
  assert.equal(kuruGrid.quoteCostBuy(1000n, 15n, params), 10n ** 12n);
  // real-market scale (1e8): 0.004 MON/token (4e5 units) × 0.1 token (1e7 units) → 0.0004 MON
  const real: KuruMarketParams = { ...params, pricePrecision: 100000000n, sizePrecision: 100000000n, tickSize: 1n };
  assert.equal(kuruGrid.quoteCostBuy(400000n, 10_000_000n, real), 4n * 10n ** 14n);
});

test('grid: market-buy quote units use price precision', () => {
  assert.equal(kuruGrid.quoteToUnits(10n ** 18n, params), 1_000_000n);
});

// --- decode -----------------------------------------------------------------

/** Build a synthetic EVM log for an event with the given signature and encoding. */
type AbiParamList = Parameters<typeof encodeAbiParameters>[0];
function syntheticLog(signature: string, indexed: { type: string; value: unknown }[], dataTypes: string[], dataValues: unknown[]) {
  const topics = [keccak256(toEventSignature(signature) as Hex) as Hex, ...indexed.map((entry) =>
    encodeAbiParameters([{ type: entry.type }] as AbiParamList, [entry.value] as never) as Hex,
  )] as [Hex, ...Hex[]];
  const data = dataTypes.length
    ? encodeAbiParameters(dataTypes.map((type) => ({ type })) as AbiParamList, dataValues as never)
    : ('0x' as Hex);
  return { address: actor, topics, data, logIndex: 0 };
}

test('OrderCreated logs decode to numeric order ids (no indexed params: all in data)', () => {
  const sig = 'OrderCreated(uint40,address,uint96,uint32,bool)';
  const data = encodeAbiParameters(
    [{ type: 'uint40' }, { type: 'address' }, { type: 'uint96' }, { type: 'uint32' }, { type: 'bool' }] as Parameters<typeof encodeAbiParameters>[0],
    [42n, actor, 5n, 1000n, true] as never,
  );
  const log = { address: actor, topics: [keccak256(toEventSignature(sig) as Hex) as Hex] as [Hex], data, logIndex: 0 };
  const decoded = decodeOrderCreated([log]);
  assert.equal(decoded.length, 1);
  assert.equal(decoded[0].orderId, 42);
  assert.equal(decoded[0].owner.toLowerCase(), actor.toLowerCase());
  assert.equal(decoded[0].isBuy, true);
});

test('TokenLaunched decodes from a synthetic log', () => {
  const token = '0x43e7e9b1b7d9A143573307b13D14B51580c18f15' as Address;
  const curve = '0x454A3A449d4e65CA5203d331905d167BA218E276' as Address;
  const log = syntheticLog(
    'TokenLaunched(address,address,address,address,uint256,uint256)',
    [{ type: 'address', value: token }, { type: 'address', value: curve }, { type: 'address', value: actor }],
    ['address', 'uint256', 'uint256'],
    [zero, 0n, 1000000000000000000n],
  );
  const events = decodeEvents([log]);
  const launched = events.find((event) => event.eventName === 'TokenLaunched');
  assert.ok(launched);
  assert.equal((launched.args.token as string).toLowerCase(), token.toLowerCase());
  assert.equal((launched.args.curve as string).toLowerCase(), curve.toLowerCase());
});

test('custom errors decode through the selector map', () => {
  const map = buildErrorSelectorMap();
  const data = encodeErrorResult({ abi: factoryAbi, errorName: 'LaunchEconomicsMismatch', args: ['0x' + '01'.repeat(32) as Hex, '0x' + '02'.repeat(32) as Hex] });
  const decoded = decodeRevertData(data, map);
  assert.equal(decoded?.name, 'LaunchEconomicsMismatch');
  const kuruTick = encodeErrorResult({ abi: kuruAbi, errorName: 'TickSizeError' });
  assert.equal(decodeRevertData(kuruTick, map)?.name, 'TickSizeError');
});

test('classifyError recognises user rejection and decoded reverts', () => {
  const rejected = classifyError({ name: 'UserRejectedRequestError', message: 'rejected' });
  assert.equal(rejected.kind, 'user-rejected');
  const data = encodeErrorResult({ abi: kuruAbi, errorName: 'TickSizeError' });
  const revert = classifyError({ name: 'ContractFunctionExecutionError', data, cause: undefined });
  assert.equal(revert.kind, 'revert');
  assert.equal(revert.decoded?.name, 'TickSizeError');
});

// --- misc -------------------------------------------------------------------

test('randomSalt is 32 bytes of entropy and unique', () => {
  const a = randomSalt();
  const b = randomSalt();
  assert.match(a, /^0x[0-9a-f]{64}$/);
  assert.notEqual(a, b);
});
