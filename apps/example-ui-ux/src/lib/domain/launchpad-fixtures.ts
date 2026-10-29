import type { TokenLaunchSummary } from './launchpad-types';

export interface ApprovedPairAsset {
  id: string;
  symbol: string;
  name: string;
  assetClass: 'CRYPTO' | 'STOCK_QUOTE';
  network: 'Monad';
  provenance: 'DEMO';
}

export const approvedPairAssets: ApprovedPairAsset[] = [
  { id: 'mon', symbol: 'MON', name: 'Monad', assetClass: 'CRYPTO', network: 'Monad', provenance: 'DEMO' },
  { id: 'usdc', symbol: 'USDC', name: 'USD Coin', assetClass: 'CRYPTO', network: 'Monad', provenance: 'DEMO' },
  { id: 'wbtc', symbol: 'WBTC', name: 'Wrapped Bitcoin', assetClass: 'CRYPTO', network: 'Monad', provenance: 'DEMO' },
  { id: 'nvdax', symbol: 'NVDAx', name: 'NVIDIA reference quote token', assetClass: 'STOCK_QUOTE', network: 'Monad', provenance: 'DEMO' },
  { id: 'aaplx', symbol: 'AAPLx', name: 'Apple reference quote token', assetClass: 'STOCK_QUOTE', network: 'Monad', provenance: 'DEMO' },
];

export const tokenLaunches: TokenLaunchSummary[] = [
  {
    id: 'monad-dog', launchKind: 'CRYPTO_TOKEN', title: 'Monad Dog', symbol: 'MDOG', creator: 'monad-dog-club', icon: '◉', color: '#7f91ff', volume24h: 184_200, createdAt: '2026-09-17T09:40:00Z', updatedAt: '2026-09-17T11:54:00Z', provenance: 'DEMO',
    description: 'A fixed/capped community token using the RetroPick bonding market fixture.', price: 0.00284, change24h: 18.3, marketCap: 82_000, liquidity: 31_200, lifetimeVolume: 1_430_000, trades24h: 642, quoteAsset: 'MON', curveProgressBps: 7200, lifecycle: 'CURVE', primaryVenue: 'RetroPick bonding market', matureVenue: 'Kuru',
  },
  {
    id: 'orbit-cult', launchKind: 'CRYPTO_TOKEN', title: 'Orbit Cult', symbol: 'ORBIT', creator: 'orbit-labs', icon: '✦', color: '#5ec4d3', volume24h: 97_500, createdAt: '2026-09-16T14:15:00Z', updatedAt: '2026-09-17T11:38:00Z', provenance: 'DEMO',
    description: 'A demo fixed/capped token paired against USDC in a bonding-market lifecycle.', price: 0.0142, change24h: -4.2, marketCap: 265_000, liquidity: 42_850, lifetimeVolume: 872_000, trades24h: 318, quoteAsset: 'USDC', curveProgressBps: 9400, lifecycle: 'GRADUATION_READY', primaryVenue: 'RetroPick bonding market', matureVenue: 'Kuru',
  },
  {
    id: 'nvidia-cult', launchKind: 'STOCK_PAIRED_TOKEN', title: 'NVIDIA CULT', symbol: 'NVC', creator: 'nvc-community', icon: 'N', color: '#8bcf62', volume24h: 213_600, createdAt: '2026-09-14T10:00:00Z', updatedAt: '2026-09-17T11:50:00Z', provenance: 'DEMO',
    description: 'A normal launch token paired against an illustrative tokenized-stock quote asset.', price: 0.0112, change24h: 8.1, marketCap: 411_000, liquidity: 86_400, lifetimeVolume: 2_140_000, trades24h: 844, quoteAsset: 'NVDAx', curveProgressBps: 10000, lifecycle: 'GRADUATED', primaryVenue: 'RetroPick bonding market', matureVenue: 'Kuru', stockReference: 'NVIDIA', stockQuoteAsset: 'NVDAx',
  },
  {
    id: 'apple-signal', launchKind: 'STOCK_PAIRED_TOKEN', title: 'Apple Signal', symbol: 'ASIG', creator: 'signal-labs', icon: 'A', color: '#e0a862', volume24h: 76_800, createdAt: '2026-09-15T16:25:00Z', updatedAt: '2026-09-17T11:21:00Z', provenance: 'DEMO',
    description: 'A normal launch token paired against an illustrative tokenized-stock quote asset.', price: 0.0049, change24h: 2.7, marketCap: 154_000, liquidity: 23_700, lifetimeVolume: 635_000, trades24h: 227, quoteAsset: 'AAPLx', curveProgressBps: 5500, lifecycle: 'CURVE', primaryVenue: 'RetroPick bonding market', matureVenue: 'Kuru', stockReference: 'Apple', stockQuoteAsset: 'AAPLx',
  },
];
