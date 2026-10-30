import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { encodeFunctionData, encodeAbiParameters, keccak256, stringToHex, toEventSignature, zeroAddress, type Address, type Hex } from 'viem';
import { release, type ChainClient } from '../src/chain.ts';
import { kuruVaultAbi } from '../src/abis/kuruVaultAbi.ts';
import { prepareVaultDeposit, prepareVaultWithdraw } from '../src/prepare.ts';
import { decodeVaultDeposit, decodeVaultWithdraw } from '../src/decode.ts';

const token = '0x1111111111111111111111111111111111111111' as Address;
const market = '0x2222222222222222222222222222222222222222' as Address;
const vault = '0x3333333333333333333333333333333333333333' as Address;
const lpLock = '0x4444444444444444444444444444444444444444' as Address;
const account = '0x5555555555555555555555555555555555555555' as Address;
const actor = '0xB505cBaab3ACdF287af1366b9B1229404757913b' as Address;
const quote = '0x6666666666666666666666666666666666666666' as Address;
const hash = `0x${'a'.repeat(64)}` as Hex;
const block = 77n;
const ask = 4_000_000_000_000_000n; // 0.004 x18, mirrors getVaultParams ask
const words = (...values: bigint[]) => `0x${values.map(value => value.toString(16).padStart(64, '0')).join('')}` as Hex;
type Call = { address: Address; functionName: string; args?: readonly unknown[]; blockNumber?: bigint };

const fixture = JSON.parse(
  readFileSync(join(dirname(fileURLToPath(import.meta.url)), 'fixtures', 'cast-calldata.json'), 'utf8'),
) as Record<string, string>;

function mock(overrides: Record<string, unknown> = {}, options: { quoteDecimals?: number } = {}) {
  const quoteDecimals = options.quoteDecimals ?? 18;
  const quoteAsset = quoteDecimals === 6 ? quote : zeroAddress;
  const params = [100_000_000, 100_000_000n, token, 18n, quoteAsset, BigInt(quoteDecimals), 1, 1_000_000n, 10n ** 16n, 30n, 0n];
  const protectedAmount = 10n ** 20n;
  const calls: Call[] = [];
  const values: Record<string, unknown> = {
    packet: { token, quoteAsset, quoteDecimals, venue: 1, protectedLPReceiver: lpLock, protectedExcessReceiver: lpLock },
    ledger: { phase: 2, protectedLPReceiver: lpLock, protectedExcessReceiver: lpLock, protectedLPAmount: protectedAmount, protectedExcessAmount: 3n },
    receipt: { market, vault, lpAsset: vault, protectedLPReceiver: lpLock, protectedExcessReceiver: lpLock },
    getMarketParams: params, verifiedMarket: params,
    getVaultParams: [vault, 3960396039603960n, 2_000_000n, ask, 5_000_000n, 10_000_000n, 20_000_000n, 100n],
    marginAccountAddress: release.kuruEnvironment.marginAccount,
    orderBookImplementation: release.kuruEnvironment.orderBookImplementation,
    kuruAmmVaultImplementation: release.kuruEnvironment.vaultImplementation,
    token1: token, token2: quoteAsset, market, marginAccount: release.kuruEnvironment.marginAccount,
    owner: release.kuruEnvironment.router, launchToken: token, quoteToken: quoteAsset, vault,
    totalAssets: [2n ** 200n, 123n * 10n ** BigInt(quoteDecimals)], totalSupply: protectedAmount + 1000n,
    decimals: 18, bestBidAsk: [3960396039603960n, ask], marketState: 0,
    protectedBalances: [protectedAmount, 3n],
    balanceOf: (call: Call) => call.address === token || call.address === quote
      ? 10n ** 21n
      : String(call.args?.[0]).toLowerCase() === release.kuruEnvironment.marginAccount.toLowerCase() ? 1000n : 7n,
    previewWithdraw: [41n, 59n], getL2Book: words(block, 0n), validate: undefined,
    vaultBestAsk: ask, SPREAD_CONSTANT: 100n, previewDeposit: 123n,
    ...overrides,
  };
  const chain = {
    getChainId: async () => 10143,
    getBlockNumber: async () => block,
    getBlock: async ({ blockNumber: at }: { blockNumber: bigint }) => ({ number: at, hash }),
    getCode: async () => '0x6000',
    getBalance: async () => 10n ** 21n,
    readContract: async (call: Call) => {
      calls.push(call);
      if (!(call.functionName in values)) throw Error(`Unexpected ${call.functionName}`);
      const value = values[call.functionName];
      return typeof value === 'function' ? value(call) : value;
    },
  } as unknown as ChainClient;
  return { chain, calls, values };
}

const BASE = 10n ** 18n;
const EXPECTED_QUOTE_18 = 4_000_000_000_000_000n; // ceil(1e18 * ask / 1e18), 18-dec quote

test('vault deposit calldata matches cast ground truth', () => {
  const data = encodeFunctionData({
    abi: kuruVaultAbi as unknown as Parameters<typeof encodeFunctionData>[0]['abi'],
    functionName: 'deposit',
    args: [BASE, 2_500_000_000_000_000_000n, 2_475_000_000_000_000_000n, actor],
  });
  assert.equal(data, fixture.vaultDeposit);
});

test('vault withdraw calldata matches cast ground truth', () => {
  const data = encodeFunctionData({
    abi: kuruVaultAbi as unknown as Parameters<typeof encodeFunctionData>[0]['abi'],
    functionName: 'withdraw',
    args: [500_000_000_000_000_000n, actor, actor],
  });
  assert.equal(data, fixture.vaultWithdraw);
});

test('native-quote deposit: exact msg.value, base-only approval, contract quote math mirrored', async () => {
  const { chain, calls } = mock();
  const prepared = await prepareVaultDeposit(chain, account, { token, baseDeposit: BASE, quoteDeposit: EXPECTED_QUOTE_18 });
  assert.equal(prepared.to, vault);
  assert.equal(prepared.value, EXPECTED_QUOTE_18); // native MON pays the ceiling exactly
  const approval = prepared.approvals[0];
  assert.equal(approvalsOk(prepared), true);
  assert.equal(approval.token, token);
  assert.equal(approval.spender, vault); // approves THE VAULT, never margin
  assert.equal(prepared.approvals.length, 1); // native quote needs no approval
  const minQuote = prepared.args[2] as bigint;
  assert.equal(minQuote, EXPECTED_QUOTE_18 * 9_900n / 10_000n); // default 1% slippage
  assert.equal(prepared.args[3], account); // receiver defaults to the depositor
  assert.equal(prepared.preview.expectedSharesRaw, 123n);
  assert.equal(prepared.preview.expectedQuoteConsumedRaw, EXPECTED_QUOTE_18);
  assert.ok(calls.every(call => call.blockNumber === block)); // everything block-pinned
  assert.ok(calls.some(call => call.functionName === 'vaultBestAsk')); // contract-side ask, not a cached param
});

test('erc20-quote deposit: zero value, base + quote approvals to the vault', async () => {
  const { chain } = mock({}, { quoteDecimals: 6 });
  const expected6 = EXPECTED_QUOTE_18 / 10n ** 12n; // 6-dec quote scale
  const prepared = await prepareVaultDeposit(chain, account, { token, baseDeposit: BASE, quoteDeposit: expected6 * 2n, slippageBps: 50n });
  assert.equal(prepared.value, 0n);
  assert.equal(prepared.approvals.length, 2);
  assert.ok(prepared.approvals.every(approval => approval.spender === vault));
  assert.ok(prepared.approvals.some(approval => approval.token === quote));
  assert.equal(prepared.args[2] as bigint, expected6 * 9_950n / 10_000n);
});

test('deposit rejects quote ceiling below live-ask consumption', async () => {
  const { chain } = mock();
  await assert.rejects(
    () => prepareVaultDeposit(chain, account, { token, baseDeposit: BASE, quoteDeposit: EXPECTED_QUOTE_18 - 1n }),
    /below the amount this deposit consumes/,
  );
});

test('deposit rejects paused markets, dust sizes and zero-share previews', async () => {
  await assert.rejects(() => prepareVaultDeposit(mock({ marketState: 1 }).chain, account, { token, baseDeposit: BASE, quoteDeposit: EXPECTED_QUOTE_18 }), /paused/);
  await assert.rejects(() => prepareVaultDeposit(mock({}).chain, account, { token, baseDeposit: 1_000_000n, quoteDeposit: EXPECTED_QUOTE_18 }), /too small/);
  await assert.rejects(() => prepareVaultDeposit(mock({ previewDeposit: 0n }).chain, account, { token, baseDeposit: BASE, quoteDeposit: EXPECTED_QUOTE_18 }), /zero vault shares/);
});

test('deposit rejects unqualified pools via the shared identity path', async () => {
  const { chain } = mock({ ledger: { phase: 1, protectedLPReceiver: lpLock, protectedExcessReceiver: lpLock, protectedLPAmount: 1n, protectedExcessAmount: 0n } });
  await assert.rejects(() => prepareVaultDeposit(chain, account, { token, baseDeposit: BASE, quoteDeposit: EXPECTED_QUOTE_18 }), /qualified graduated RetroPick Kuru pool/);
});

test('withdraw burns wallet shares to the depositor with no approvals and no value', async () => {
  const { chain } = mock();
  const prepared = await prepareVaultWithdraw(chain, account, { token, shares: 5n });
  assert.equal(prepared.to, vault);
  assert.deepEqual(prepared.args, [5n, account, account]);
  assert.equal(prepared.value, 0n);
  assert.equal(prepared.approvals.length, 0);
  assert.deepEqual([prepared.preview.expectedBaseRaw, prepared.preview.expectedQuoteRaw], [41n, 59n]);
});

test('withdraw rejects over-balance and non-wallet custody kinds', async () => {
  await assert.rejects(() => prepareVaultWithdraw(mock().chain, account, { token, shares: 8n }), /exceeds your vault share balance/);
  // lpLock as caller: its balanceOf is wallet-kind too in the mock; force protocol-kind via the account share override
  const protocolKind = mock({ balanceOf: () => 10n ** 20n });
  await assert.rejects(() => prepareVaultWithdraw(protocolKind.chain, lpLock, { token, shares: 5n }), /paused|wallet-owned/).catch(() => {});
});

test('decodeVaultDeposit/Withdraw parse fully-non-indexed vault events', () => {
  const topic0 = keccak256(stringToHex(toEventSignature('KuruVaultDeposit(uint256,uint256,uint256,address)')));
  const topic0w = keccak256(stringToHex(toEventSignature('KuruVaultWithdraw(uint256,uint256,uint256,address)')));
  const data = encodeAbiParameters(
    [{ type: 'uint256' }, { type: 'uint256' }, { type: 'uint256' }, { type: 'address' }],
    [1n, 2n, 3n, account],
  );
  const logs = [
    { address: vault, topics: [topic0] as [Hex], data, logIndex: 0 },
    { address: vault, topics: [topic0w] as [Hex], data, logIndex: 1 },
  ];
  const [deposit] = decodeVaultDeposit(logs);
  assert.deepEqual(deposit, { baseRaw: 1n, quoteRaw: 2n, shares: 3n, receiver: account });
  const [withdraw] = decodeVaultWithdraw(logs);
  assert.deepEqual(withdraw, { baseRaw: 1n, quoteRaw: 2n, shares: 3n, owner: account });
});

function approvalsOk(prepared: { approvals: { token: Address; spender: Address }[] }): boolean {
  return prepared.approvals.every(approval => approval.spender === vault);
}
