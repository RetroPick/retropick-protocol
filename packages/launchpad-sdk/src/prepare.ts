import { zeroAddress, type Abi, type Address, parseAbi } from 'viem';
import { addresses, release, type ChainClient } from './chain.ts';
import { coordinatorAbi, curveAbi, factoryAbi, kuruAbi, marginAbi, tokenAbi } from './abi.ts';
import { retroPickBuybackVaultV2Abi, retroPickFeeEscrowV2Abi } from '@retropick/abi/abi';
import { readLaunch } from './model.ts';
import { buyQuote, minOutput, sellQuote } from './math.ts';
import { VENUE, readLaunchPreconditions, readBuybackReleasable, readFeeEscrowCredit, type VenueId } from './registry.ts';

const marginAddress = release.kuruEnvironment.marginAccount as Address;

/**
 * Prepared writes are the only sanctioned way the application produces contract
 * calldata. Each prepare function performs fresh chain reads, validates every
 * precondition exactly as the deployed source requires, and returns a complete,
 * bigint-exact transaction description plus any ERC20 approvals that must
 * precede it. The UI pipeline then simulates, signs, broadcasts and decodes.
 */

export type Approval = { token: Address; spender: Address; amount: bigint; label: string };

export type PreparedWrite = {
  to: Address;
  abi: readonly unknown[];
  functionName: string;
  args: readonly unknown[];
  value: bigint;
  account: Address;
  approvals: Approval[];
  label: string;
  /** Preconditions that were verified while preparing (for the review UI). */
  checks: string[];
};

function fail(message: string): never {
  throw Error(message);
}

export function randomSalt(): `0x${string}` {
  const bytes = new Uint8Array(32);
  globalThis.crypto.getRandomValues(bytes);
  return `0x${Array.from(bytes, (b) => b.toString(16).padStart(2, '0')).join('')}` as `0x${string}`;
}

// ---------------------------------------------------------------------------
// Flow A — launchToken
// ---------------------------------------------------------------------------

export type LaunchSocials = { twitter?: string; telegram?: string; discord?: string; website?: string; farcaster?: string };

export type LaunchTokenInput = {
  name: string;
  symbol: string;
  logo: string;
  description: string;
  socials: LaunchSocials;
  creatorFeeRecipient?: Address;
  creatorTaxBps: bigint;
  buybackEnabled: boolean;
  launchConfigId: bigint;
  pairToken: Address;
  venue: VenueId;
  expectedEconomics?: `0x${string}`; // pin; read fresh from previewVenueEconomics when absent
  salt?: `0x${string}`;
};

export async function prepareLaunchToken(chain: ChainClient, account: Address, input: LaunchTokenInput): Promise<PreparedWrite> {
  const checks: string[] = [];
  if (!input.name.trim() || !input.symbol.trim()) fail('Token name and symbol are required.');
  const [preconditions, economics] = await Promise.all([
    readLaunchPreconditions(chain, account),
    chain.readContract({
      address: addresses.factory,
      abi: factoryAbi,
      functionName: 'previewVenueEconomics',
      args: [input.launchConfigId, input.pairToken, input.venue],
    }),
  ]);
  if (preconditions.canLaunch === false) fail('This wallet is not authorized to launch. Launches may be whitelist-only right now.');
  const config = preconditions.configs.find((entry) => entry.id === input.launchConfigId);
  if (!config) fail('Unknown launch configuration.');
  if (!config.enabled) fail('This launch configuration is disabled.');
  if (input.creatorTaxBps > preconditions.maxCreatorTaxBps) {
    fail(`Creator tax ${input.creatorTaxBps} bps exceeds the ${preconditions.maxCreatorTaxBps} bps limit.`);
  }
  if (config.curveFeeBps + input.creatorTaxBps > 2000n) fail('Combined curve fee and creator tax exceeds the 2000 bps protocol limit.');
  const admitted = preconditions.quotes.some((quote) => quote.venue === input.venue && quote.address.toLowerCase() === input.pairToken.toLowerCase());
  if (!admitted) fail('This quote asset is not admitted for the selected graduation venue.');
  checks.push(`launchFee ${preconditions.launchFee} wei exact`);
  checks.push(`economics pin ${economics}`);
  checks.push(`venue ${input.venue === VENUE.KURU ? 'KURU' : 'UNISWAP_V4'}`);
  return {
    to: addresses.factory,
    abi: factoryAbi,
    functionName: 'launchToken',
    // Canonical overload: launchToken(TokenParams,uint256,address,uint8)
    args: [
      {
        name: input.name,
        symbol: input.symbol,
        logo: input.logo,
        description: input.description,
        socials: {
          twitter: input.socials.twitter ?? '',
          telegram: input.socials.telegram ?? '',
          discord: input.socials.discord ?? '',
          website: input.socials.website ?? '',
          farcaster: input.socials.farcaster ?? '',
        },
        creatorFeeRecipient: input.creatorFeeRecipient ?? account,
        creatorTaxBps: input.creatorTaxBps,
        buybackEnabled: input.buybackEnabled,
        expectedEconomics: input.expectedEconomics ?? economics,
        salt: input.salt ?? randomSalt(),
      },
      input.launchConfigId,
      input.pairToken,
      input.venue,
    ],
    value: preconditions.launchFee,
    account,
    approvals: [],
    label: 'Launch token',
    checks,
  };
}

// ---------------------------------------------------------------------------
// Flow B — bonding curve buy / sell
// ---------------------------------------------------------------------------

export async function prepareCurveBuy(
  chain: ChainClient,
  token: Address,
  account: Address,
  options: { quoteIn: bigint; slippageBps?: bigint; recipient?: Address },
): Promise<PreparedWrite> {
  const launch = await readLaunch(chain, token, account);
  if (Number(launch.ledger.phase) !== 0) fail('Trading has ended: this launch is no longer in the bonding phase.');
  if (options.quoteIn <= 0n) fail('Enter a buy amount.');
  const [quoteReserve, tokenReserve] = launch.reserves;
  const expected = buyQuote(options.quoteIn, quoteReserve, tokenReserve, launch.remaining, launch.fee, launch.tax);
  if (expected <= 0n) fail('This buy would return zero tokens.');
  const minTokensOut = minOutput(expected, options.slippageBps ?? 50n);
  const native = launch.packet.quoteAsset === zeroAddress;
  if (native) {
    const balance = await chain.getBalance({ address: account, blockNumber: launch.blockNumber });
    if (balance < options.quoteIn) fail('Insufficient MON balance.');
  } else {
    const balance = await chain.readContract({
      address: launch.packet.quoteAsset,
      abi: tokenAbi,
      functionName: 'balanceOf',
      args: [account],
      blockNumber: launch.blockNumber,
    });
    if (balance < options.quoteIn) fail('Insufficient quote asset balance.');
  }
  const checks = [
    `expect ≈${expected} tokens, min ${minTokensOut} after slippage`,
    native ? 'native MON: value = quoteIn' : 'ERC20 quote: approve then buy with value 0',
  ];
  return {
    to: launch.packet.curve,
    abi: curveAbi,
    functionName: 'buy',
    args: [options.quoteIn, minTokensOut, options.recipient ?? account],
    value: native ? options.quoteIn : 0n,
    account,
    approvals: native ? [] : [{ token: launch.packet.quoteAsset, spender: launch.packet.curve, amount: options.quoteIn, label: 'Approve quote asset' }],
    label: `Buy ${launch.symbol}`,
    checks,
  };
}

export async function prepareCurveSell(
  chain: ChainClient,
  token: Address,
  account: Address,
  options: { tokensIn: bigint; slippageBps?: bigint; recipient?: Address },
): Promise<PreparedWrite> {
  const launch = await readLaunch(chain, token, account);
  if (Number(launch.ledger.phase) !== 0) fail('Trading has ended: this launch is no longer in the bonding phase.');
  if (options.tokensIn <= 0n) fail('Enter a sell amount.');
  if (launch.balance < options.tokensIn) fail('Insufficient token balance.');
  if (options.tokensIn > launch.remaining) fail('Sell exceeds the tokens still tradeable on the curve.');
  const [quoteReserve, tokenReserve] = launch.reserves;
  const expected = sellQuote(options.tokensIn, tokenReserve, quoteReserve, launch.fee, launch.tax);
  if (expected <= 0n) fail('This sell would return zero quote.');
  const minQuoteOut = minOutput(expected, options.slippageBps ?? 50n);
  return {
    to: launch.packet.curve,
    abi: curveAbi,
    functionName: 'sell',
    args: [options.tokensIn, minQuoteOut, options.recipient ?? account],
    value: 0n,
    account,
    approvals: [{ token, spender: launch.packet.curve, amount: options.tokensIn, label: 'Approve launch token' }],
    label: `Sell ${launch.symbol}`,
    checks: [`expect ≈${expected} quote, min ${minQuoteOut} after slippage`, 'token approve then sell'],
  };
}

// ---------------------------------------------------------------------------
// Flow C — graduation
// ---------------------------------------------------------------------------

/** Qualified pathway: factory.graduate(token) once the curve reached completion. */
export async function prepareFactoryGraduate(chain: ChainClient, token: Address, account: Address): Promise<PreparedWrite> {
  const launch = await readLaunch(chain, token);
  if (Number(launch.ledger.phase) !== 0) fail('Graduation has already started for this launch.');
  const graduated = await chain.readContract({
    address: launch.packet.curve,
    abi: curveAbi,
    functionName: 'graduated',
    blockNumber: launch.blockNumber,
  });
  if (graduated) fail('This curve has already graduated.');
  const [quoteNeeded] = launch.completion;
  const [quoteReserve] = launch.reserves;
  if (quoteReserve < quoteNeeded) fail('Bonding curve has not reached the graduation threshold yet.');
  return {
    to: addresses.factory,
    abi: factoryAbi,
    functionName: 'graduate',
    args: [token],
    value: 0n,
    account,
    approvals: [],
    label: 'Graduate launch',
    checks: ['coordinator phase NONE', `quote reserve ${quoteReserve} ≥ completion ${quoteNeeded}`],
  };
}

/** Recovery path: coordinator.complete(token) when a graduation is stuck in GRADUATING. */
export async function prepareCoordinatorComplete(chain: ChainClient, token: Address, account: Address): Promise<PreparedWrite> {
  const launch = await readLaunch(chain, token);
  if (Number(launch.ledger.phase) !== 1) fail('Completion is only available while a graduation is in progress.');
  return {
    to: addresses.coordinator,
    abi: coordinatorAbi,
    functionName: 'complete',
    args: [token],
    value: 0n,
    account,
    approvals: [],
    label: 'Complete graduation',
    checks: ['coordinator phase GRADUATING'],
  };
}

// ---------------------------------------------------------------------------
// Flow D — Kuru margin + orders
// ---------------------------------------------------------------------------

export type KuruMarketParams = {
  pricePrecision: bigint;
  sizePrecision: bigint;
  baseAsset: Address;
  baseDecimals: bigint;
  quoteAsset: Address;
  quoteDecimals: bigint;
  tickSize: bigint;
  minSize: bigint;
  maxSize: bigint;
  takerFeeBps: bigint;
  makerFeeBps: bigint;
};

export async function readMarketParams(chain: ChainClient, market: Address): Promise<KuruMarketParams> {
  const raw = await chain.readContract({ address: market, abi: kuruAbi, functionName: 'getMarketParams' });
  const [pricePrecision, sizePrecision, baseAsset, baseDecimals, quoteAsset, quoteDecimals, tickSize, minSize, maxSize, takerFeeBps, makerFeeBps] = raw as unknown as [bigint, bigint, Address, bigint, Address, bigint, bigint, bigint, bigint, bigint, bigint];
  return { pricePrecision, sizePrecision, baseAsset, baseDecimals, quoteAsset, quoteDecimals, tickSize, minSize, maxSize, takerFeeBps, makerFeeBps };
}

/** Grid math: real amounts ↔ Kuru uint32 price / uint96 size units. */
export const kuruGrid = {
  /** size units for an exact raw base amount; must divide evenly. */
  sizeToUnits(sizeRaw: bigint, params: KuruMarketParams): bigint {
    const scaled = sizeRaw * params.sizePrecision;
    if (scaled % 10n ** params.baseDecimals !== 0n) fail('Token amount is finer than this market supports.');
    const units = scaled / 10n ** params.baseDecimals;
    if (units <= 0n) fail('Order size rounds to zero on this market\'s grid.');
    return units;
  },
  unitsToSize(units: bigint, params: KuruMarketParams): bigint {
    return units * 10n ** params.baseDecimals / params.sizePrecision;
  },
  /** price units for a quote-per-whole-token price, rounded to tick. */
  priceToUnits(priceRaw: bigint, params: KuruMarketParams, side: 'buy' | 'sell'): bigint {
    const numerator = priceRaw * params.pricePrecision;
    const denominator = 10n ** params.quoteDecimals * params.sizePrecision;
    let units = numerator / denominator;
    // snap to tick away from crossing: down for buys, up for sells
    const remainder = numerator % denominator;
    if (side === 'sell' && remainder !== 0n) units += 1n;
    if (side === 'buy') units = units / params.tickSize * params.tickSize;
    else units = (units + params.tickSize - 1n) / params.tickSize * params.tickSize;
    if (units <= 0n || units >= 2n ** 32n) fail('Price is outside this market\'s grid.');
    return units;
  },
  unitsToPriceRaw(units: bigint, params: KuruMarketParams): bigint {
    return units * 10n ** params.quoteDecimals * params.sizePrecision / params.pricePrecision;
  },
  /** quote grid units for a raw quote amount (market-buy sizing). */
  quoteToUnits(quoteRaw: bigint, params: KuruMarketParams): bigint {
    const units = quoteRaw * params.pricePrecision / 10n ** params.quoteDecimals;
    if (units <= 0n) fail('Amount is below this market\'s quote precision.');
    return units;
  },
  /** Quote raw consumed by a resting buy (rounded up, mirroring the book). */
  quoteCostBuy(priceUnits: bigint, sizeUnits: bigint, params: KuruMarketParams): bigint {
    const numerator = priceUnits * sizeUnits * 10n ** params.quoteDecimals;
    return (numerator + params.pricePrecision - 1n) / params.pricePrecision;
  },
};

const erc20Abi = parseAbi(['function balanceOf(address) view returns (uint256)', 'function allowance(address,address) view returns (uint256)']);

export async function readAllowance(chain: ChainClient, token: Address, owner: Address, spender: Address): Promise<bigint> {
  return chain.readContract({ address: token, abi: erc20Abi, functionName: 'allowance', args: [owner, spender] });
}

/** Margin deposit. token zeroAddress = native MON (msg.value = amount). */
export async function prepareMarginDeposit(
  chain: ChainClient,
  account: Address,
  options: { token: Address; amount: bigint },
): Promise<PreparedWrite> {
  if (options.amount <= 0n) fail('Enter a deposit amount.');
  const native = options.token === zeroAddress;
  const approvals: Approval[] = [];
  if (native) {
    const balance = await chain.getBalance({ address: account });
    if (balance < options.amount) fail('Insufficient MON balance.');
  } else {
    const balance = await chain.readContract({ address: options.token, abi: erc20Abi, functionName: 'balanceOf', args: [account] });
    if (balance < options.amount) fail('Insufficient token balance.');
    approvals.push({ token: options.token, spender: marginAddress, amount: options.amount, label: 'Approve margin account' });
  }
  return {
    to: marginAddress,
    abi: marginAbi,
    functionName: 'deposit',
    args: [account, options.token, options.amount],
    value: native ? options.amount : 0n,
    account,
    approvals,
    label: 'Deposit to Kuru margin',
    checks: [native ? 'native MON: value = amount' : 'ERC20: approve then deposit'],
  };
}

/** Margin withdrawal (token zeroAddress = native MON). */
export async function prepareMarginWithdraw(
  chain: ChainClient,
  account: Address,
  options: { token: Address; amount: bigint },
): Promise<PreparedWrite> {
  if (options.amount <= 0n) fail('Enter a withdrawal amount.');
  const balance = await chain.readContract({
    address: marginAddress,
    abi: marginAbi,
    functionName: 'getBalance',
    args: [account, options.token],
  });
  if (balance < options.amount) fail('Amount exceeds margin balance.');
  return {
    to: marginAddress,
    abi: marginAbi,
    functionName: 'withdraw',
    args: [options.amount, options.token],
    value: 0n,
    account,
    approvals: [],
    label: 'Withdraw from Kuru margin',
    checks: [`margin balance ${balance}`],
  };
}

export type KuruLimitOrderInput = {
  market: Address;
  side: 'buy' | 'sell';
  /** Desired price in quote-raw per one whole base token. */
  priceRaw: bigint;
  /** Desired base size in token-raw units. */
  sizeRaw: bigint;
  postOnly: boolean;
};

/** Resting limit order; funds are held in the Kuru margin account. */
export async function prepareKuruLimitOrder(chain: ChainClient, account: Address, input: KuruLimitOrderInput): Promise<PreparedWrite> {
  const params = await readMarketParams(chain, input.market);
  const priceUnits = kuruGrid.priceToUnits(input.priceRaw, params, input.side);
  if (priceUnits % params.tickSize !== 0n) fail('Price is not on this market\'s tick grid.');
  const sizeUnits = kuruGrid.sizeToUnits(input.sizeRaw, params);
  if (sizeUnits < params.minSize) fail(`Order size is below this market's minimum (${params.minSize} grid units).`);
  if (sizeUnits > params.maxSize) fail(`Order size is above this market's maximum (${params.maxSize} grid units).`);
  if (input.side === 'buy') {
    const cost = kuruGrid.quoteCostBuy(priceUnits, sizeUnits, params);
    const balance = await chain.readContract({
      address: marginAddress, abi: marginAbi, functionName: 'getBalance', args: [account, params.quoteAsset],
    });
    if (balance < cost) fail('Insufficient quote balance in the Kuru margin account for this order.');
  } else {
    const balance = await chain.readContract({
      address: marginAddress, abi: marginAbi, functionName: 'getBalance', args: [account, params.baseAsset],
    });
    if (balance < input.sizeRaw) fail('Insufficient token balance in the Kuru margin account for this order.');
  }
  return {
    to: input.market,
    abi: kuruAbi,
    functionName: input.side === 'buy' ? 'addBuyOrder' : 'addSellOrder',
    args: [Number(priceUnits), sizeUnits, input.postOnly],
    value: 0n,
    account,
    approvals: [],
    label: `${input.side === 'buy' ? 'Buy' : 'Sell'} limit order`,
    checks: [
      `price ${priceUnits} grid units (tick ${params.tickSize})`,
      `size ${sizeUnits} grid units`,
      'funds debited from margin account',
    ],
  };
}

export type KuruMarketOrderInput = {
  market: Address;
  side: 'buy' | 'sell';
  /** Buy: quote amount raw. Sell: base amount raw. */
  amountRaw: bigint;
  /** Expected outcome used for the exact-minimum slippage bound. */
  minOutcomeRaw: bigint;
  slippageBps?: bigint;
};

/** Immediate fill-or-kill market order against the book, funded from the margin account. */
export async function prepareKuruMarketOrder(chain: ChainClient, account: Address, input: KuruMarketOrderInput): Promise<PreparedWrite> {
  const params = await readMarketParams(chain, input.market);
  const isBuy = input.side === 'buy';
  const units = isBuy
    // _quoteSize is denominated in quote grid units: raw * pricePrecision / 10^quoteDecimals
    ? kuruGrid.quoteToUnits(input.amountRaw, params)
    : kuruGrid.sizeToUnits(input.amountRaw, params);
  const balanceAsset = isBuy ? params.quoteAsset : params.baseAsset;
  const balance = await chain.readContract({
    address: marginAddress, abi: marginAbi, functionName: 'getBalance', args: [account, balanceAsset],
  });
  if (balance < input.amountRaw) fail(`Insufficient ${isBuy ? 'quote' : 'token'} balance in the Kuru margin account.`);
  return {
    to: input.market,
    abi: kuruAbi,
    functionName: isBuy ? 'placeAndExecuteMarketBuy' : 'placeAndExecuteMarketSell',
    args: [units, minOutput(input.minOutcomeRaw, input.slippageBps ?? 50n), true, true],
    value: 0n,
    account,
    approvals: [],
    label: `${isBuy ? 'Buy' : 'Sell'} market order`,
    checks: ['margin-funded, fill-or-kill', `min outcome ${input.minOutcomeRaw}`],
  };
}

/** Cancel resting orders by id (ids come from OrderCreated logs). */
export async function prepareKuruCancel(chain: ChainClient, market: Address, account: Address, orderIds: number[]): Promise<PreparedWrite> {
  if (orderIds.length === 0) fail('No orders selected.');
  return {
    to: market,
    abi: kuruAbi,
    functionName: 'batchCancelOrders',
    args: [orderIds],
    value: 0n,
    account,
    approvals: [],
    label: 'Cancel orders',
    checks: [`${orderIds.length} order(s)`],
  };
}

// ---------------------------------------------------------------------------
// Flow E — creator claims
// ---------------------------------------------------------------------------

/** Claim all native creator fees escrowed for the account. */
export async function prepareFeeClaim(chain: ChainClient, account: Address): Promise<PreparedWrite> {
  const credit = await readFeeEscrowCredit(chain, account);
  if (credit <= 0n) fail('No claimable creator fees.');
  return {
    to: addresses.feeEscrow,
    abi: retroPickFeeEscrowV2Abi as unknown as readonly unknown[],
    functionName: 'claim',
    args: [],
    value: 0n,
    account,
    approvals: [],
    label: 'Claim creator fees',
    checks: [`escrow credit ${credit} wei`],
  };
}

/** Release vested buyback proceeds for a launched token. */
export async function prepareBuybackRelease(chain: ChainClient, token: Address, account: Address): Promise<PreparedWrite> {
  const releasable = await readBuybackReleasable(chain, token);
  if (releasable <= 0n) fail('Nothing is currently releasable for this launch.');
  return {
    to: addresses.buybackVault,
    abi: retroPickBuybackVaultV2Abi as unknown as readonly unknown[],
    functionName: 'release',
    args: [token],
    value: 0n,
    account,
    approvals: [],
    label: 'Release buyback proceeds',
    checks: [`releasable ${releasable}`],
  };
}

/** Approvals that still need executing before a prepared write can land. */
export async function missingApprovals(chain: ChainClient, write: PreparedWrite): Promise<Approval[]> {
  const missing: Approval[] = [];
  for (const approval of write.approvals) {
    const current = await readAllowance(chain, approval.token, write.account, approval.spender);
    if (current < approval.amount) missing.push(approval);
  }
  return missing;
}
