/** Legacy source fixture shape. Consumers use LaunchInstrument after normalization. */
export type LaunchKind = 'CRYPTO_TOKEN' | 'STOCK_PAIRED_TOKEN';
export type LaunchpadType = 'all' | 'prediction' | 'crypto' | 'stocks';
export type TokenLifecycle = 'CURVE' | 'GRADUATION_READY' | 'GRADUATING' | 'GRADUATED';
export type DemoProvenance = 'DEMO';

export interface LaunchpadShared {
  id: string;
  launchKind: LaunchKind;
  title: string;
  symbol: string;
  creator: string;
  icon: string;
  color: string;
  volume24h: number;
  createdAt: string;
  updatedAt: string;
  provenance: DemoProvenance;
}

export interface TokenLaunchSummary extends LaunchpadShared {
  launchKind: 'CRYPTO_TOKEN' | 'STOCK_PAIRED_TOKEN';
  description: string;
  price: number;
  change24h: number;
  marketCap: number;
  liquidity: number;
  lifetimeVolume: number;
  trades24h: number;
  quoteAsset: string;
  curveProgressBps: number;
  lifecycle: TokenLifecycle;
  primaryVenue: 'RetroPick bonding market';
  matureVenue: 'Kuru';
  stockReference?: string;
  stockQuoteAsset?: string;
}
