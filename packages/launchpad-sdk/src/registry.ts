import { zeroAddress, type Address } from 'viem';
import { addresses, release, type ChainClient } from './chain.ts';
import { factoryAbi, registryAbi, tokenAbi } from './abi.ts';
import { retroPickFeeEscrowV2Abi, retroPickBuybackVaultV2Abi } from '@retropick/abi/abi';

/** GraduationVenue enum on the deployed factory: 0 = Uniswap V4, 1 = Kuru. */
export const VENUE = { UNISWAP_V4: 0, KURU: 1 } as const;
export type VenueId = (typeof VENUE)[keyof typeof VENUE];

export type LaunchConfigView = {
  id: bigint;
  supply: bigint;
  curveFeeBps: bigint;
  phantomQuote: bigint;
  graduationThreshold: bigint;
  poolFee: number;
  tickSpacing: number;
  enabled: boolean;
};

export type AdmittedQuote = {
  venue: VenueId;
  address: Address;
  symbol: string;
  decimals: number;
  phantomQuote: bigint;
  graduationThreshold: bigint;
};

export type LaunchPreconditions = {
  blockNumber: bigint;
  launchEnabled: boolean;
  canLaunch: boolean | null;
  launchFee: bigint;
  maxCreatorTaxBps: bigint;
  snipeTaxSeconds: bigint;
  snipeTaxStartBps: bigint;
  configs: LaunchConfigView[];
  quotes: AdmittedQuote[];
};

/** Static candidate quote assets; admission is verified live per venue. */
async function quoteCandidates(chain: ChainClient): Promise<{ address: Address; symbol: string; decimals: number }[]> {
  const wrapped = release.addresses.wrappedNative as Address;
  const circleUsdc = (await chain.readContract({
    address: addresses.quoteRegistry,
    abi: registryAbi,
    functionName: 'CIRCLE_TEST_USDC',
  })) as Address;
  const [wrappedDecimals, usdcDecimals] = await Promise.all([
    chain.readContract({ address: wrapped, abi: tokenAbi, functionName: 'decimals' }),
    chain.readContract({ address: circleUsdc, abi: tokenAbi, functionName: 'decimals' }),
  ]);
  return [
    { address: zeroAddress, symbol: 'MON', decimals: 18 }, // native quote sentinel
    { address: wrapped, symbol: 'WMON', decimals: Number(wrappedDecimals) },
    { address: circleUsdc, symbol: 'USDC', decimals: Number(usdcDecimals) },
  ];
}

/** Everything the create form and launch validation need, read atomically enough for review. */
export async function readLaunchPreconditions(chain: ChainClient, account?: Address): Promise<LaunchPreconditions> {
  const blockNumber = await chain.getBlockNumber({ cacheTime: 0 });
  const factory = addresses.factory;
  const [launchEnabled, launchFee, maxCreatorTaxBps, snipeTaxSeconds, snipeTaxStartBps, configCount, canLaunch, candidates] = await Promise.all([
    chain.readContract({ address: factory, abi: factoryAbi, functionName: 'launchEnabled', blockNumber }),
    chain.readContract({ address: factory, abi: factoryAbi, functionName: 'launchFee', blockNumber }),
    chain.readContract({ address: factory, abi: factoryAbi, functionName: 'maxCreatorTaxBps', blockNumber }),
    chain.readContract({ address: factory, abi: factoryAbi, functionName: 'snipeTaxSeconds', blockNumber }),
    chain.readContract({ address: factory, abi: factoryAbi, functionName: 'snipeTaxStartBps', blockNumber }),
    chain.readContract({ address: factory, abi: factoryAbi, functionName: 'launchConfigCount', blockNumber }),
    account
      ? (chain.readContract({ address: factory, abi: factoryAbi, functionName: 'canLaunch', args: [account], blockNumber }) as Promise<boolean>)
      : Promise.resolve(null),
    quoteCandidates(chain),
  ]);
  const ids = Array.from({ length: Number(configCount) }, (_, index) => BigInt(index));
  const configs = await Promise.all(ids.map((id) =>
    chain.readContract({ address: factory, abi: factoryAbi, functionName: 'getLaunchConfig', args: [id], blockNumber })
  ));
  const quotes: AdmittedQuote[] = [];
  for (const venue of [VENUE.UNISWAP_V4, VENUE.KURU] as VenueId[]) {
    for (const candidate of candidates) {
      // admitted() reverts for unsupported pairs; absence means not offered for this venue.
      const config = await chain.readContract({
        address: addresses.quoteRegistry,
        abi: registryAbi,
        functionName: 'admitted',
        args: [candidate.address, venue],
        blockNumber,
      }).catch(() => undefined) as unknown as
        | { enabled: boolean; phantomQuote: bigint; graduationThreshold: bigint; graduationQuoteCeiling: bigint }
        | undefined;
      if (config?.enabled) {
        quotes.push({ venue, ...candidate, phantomQuote: config.phantomQuote, graduationThreshold: config.graduationThreshold });
      }
    }
  }
  return {
    blockNumber,
    launchEnabled: Boolean(launchEnabled),
    canLaunch: canLaunch === null ? null : Boolean(canLaunch),
    launchFee,
    maxCreatorTaxBps,
    snipeTaxSeconds,
    snipeTaxStartBps,
    configs: configs.map((config, index) => ({
      id: ids[index],
      supply: config.supply,
      curveFeeBps: config.curveFeeBps,
      phantomQuote: config.phantomQuote,
      graduationThreshold: config.graduationThreshold,
      poolFee: Number(config.poolFee),
      tickSpacing: Number(config.tickSpacing),
      enabled: Boolean(config.enabled),
    })),
    quotes,
  };
}

/** Creator fee credit held by the escrow for `account` (native MON). */
export async function readFeeEscrowCredit(chain: ChainClient, account: Address): Promise<bigint> {
  return chain.readContract({
    address: addresses.feeEscrow,
    abi: retroPickFeeEscrowV2Abi as never,
    functionName: 'balanceOf',
    args: [account],
  });
}

/** Vested, currently releasable buyback amount for a launched token. */
export async function readBuybackReleasable(chain: ChainClient, token: Address): Promise<bigint> {
  return chain.readContract({
    address: addresses.buybackVault,
    abi: retroPickBuybackVaultV2Abi as never,
    functionName: 'releasable',
    args: [token],
  });
}
