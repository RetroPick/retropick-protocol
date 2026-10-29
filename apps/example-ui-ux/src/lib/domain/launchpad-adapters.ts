import { markets } from './fixtures';
import { tokenLaunches } from './launchpad-fixtures';
import { prismSeries } from './prism-fixtures';
import { hasExecutableContract } from './contract-registry';
import type { EventMarket } from './types';
import type { TokenLaunchSummary } from './launchpad-types';
import type { InstrumentAdapter, InstrumentCapabilities, InstrumentContractRef, LaunchInstrument, ReferenceClass, TradeIntent, TradeParams } from './instruments';

const monad = { chainId: 10143, name: 'Monad' } as const;
const disabled = { previewTrade: false, trade: false, claim: false, create: false } as const;

function capabilities(instrument: LaunchInstrument): InstrumentCapabilities {
  // A deployment alone is not sufficient: wallet, execution and receipt adapters are not connected.
  return { ...disabled, previewTrade: instrument.kind !== 'token' };
}

function unavailableTradeIntent(_instrument: LaunchInstrument, _params: TradeParams): Promise<TradeIntent> {
  void _instrument;
  void _params;
  return Promise.resolve({ type: 'unavailable', reason: 'NO_VERIFIED_DEPLOYMENT' });
}

function predictionReference(topic: EventMarket['category']): ReferenceClass {
  if (topic === 'Crypto') return 'crypto';
  if (topic === 'Macro') return 'macro';
  return 'event';
}

export const LaunchTokenAdapter: InstrumentAdapter<TokenLaunchSummary> = {
  family: 'launch-token',
  normalize(source) {
    const instrument: LaunchInstrument = {
      id: source.id, slug: source.id, kind: 'token',
      referenceClass: source.launchKind === 'STOCK_PAIRED_TOKEN' ? 'stock' : 'crypto',
      name: source.title, symbol: source.symbol, icon: source.icon, color: source.color,
      description: source.description, creator: source.creator,
      createdAt: source.createdAt, updatedAt: source.updatedAt, provenance: source.provenance,
      price: source.price, change24h: source.change24h, liquidity: source.liquidity,
      volume24h: source.volume24h, lifetimeVolume: source.lifetimeVolume,
      marketCap: source.marketCap, trades24h: source.trades24h,
      status: source.lifecycle,
      pair: { symbol: source.quoteAsset, referenceClass: source.launchKind === 'STOCK_PAIRED_TOKEN' ? 'stock' : 'crypto', role: 'quote' },
      chain: monad, contract: { family: 'launch-token' },
      token: { curveProgressBps: source.curveProgressBps, primaryVenue: source.primaryVenue, matureVenue: source.matureVenue, stockReference: source.stockReference },
      capabilities: { ...disabled },
    };
    instrument.capabilities = capabilities(instrument);
    return instrument;
  },
  getDetailRoute: (instrument) => `/launchpad/token/${instrument.slug}`,
  getCapabilities: capabilities,
  getTradeIntent: unavailableTradeIntent,
};

export const PredictionMarketAdapter: InstrumentAdapter<EventMarket> = {
  family: 'market-engine-v1',
  normalize(source) {
    const instrument: LaunchInstrument = {
      id: source.id, slug: source.id, kind: 'prediction', referenceClass: predictionReference(source.category),
      name: source.question, symbol: source.symbol, icon: source.icon, color: source.color,
      description: source.description, creator: source.creator,
      createdAt: source.created, updatedAt: source.created, provenance: source.provenance,
      price: source.yes, change24h: source.change, liquidity: source.depth,
      volume24h: source.volume, lifetimeVolume: null, marketCap: null, trades24h: null,
      status: source.state,
      pair: { symbol: 'USDC', referenceClass: 'crypto', role: 'quote' },
      chain: monad, contract: { family: 'market-engine-v1' },
      prediction: {
        topic: source.category, yesPrice: source.yes, noPrice: source.no,
        resolutionDate: source.expires, collateralAsset: 'USDC',
        priceChangeUnit: 'cents', resolution: source.resolution, representation: 'unverified',
      },
      capabilities: { ...disabled },
    };
    instrument.capabilities = capabilities(instrument);
    return instrument;
  },
  getDetailRoute: (instrument) => `/launchpad/prediction/${instrument.slug}`,
  getCapabilities: capabilities,
  getTradeIntent: unavailableTradeIntent,
};

export type PrismSource = (typeof prismSeries)[number];
export const PrismInstrumentAdapter: InstrumentAdapter<PrismSource> = {
  family: 'prism-state-pool',
  normalize(source) {
    const instrument: LaunchInstrument = {
      id: source.id, slug: source.id, kind: 'prism', referenceClass: 'event',
      name: source.title, symbol: source.symbol, icon: '◇', color: '#b09cfa',
      createdAt: null, updatedAt: null, provenance: source.provenance,
      price: source.price, change24h: null, liquidity: null, volume24h: null,
      lifetimeVolume: null, marketCap: null, trades24h: null, status: source.status,
      pair: { symbol: source.quoteAsset, referenceClass: 'crypto', role: 'quote' },
      chain: monad, contract: { family: 'prism-state-pool' },
      prism: { components: source.components, collateralAsset: source.collateralAsset },
      capabilities: { ...disabled },
    };
    instrument.capabilities = capabilities(instrument);
    return instrument;
  },
  getDetailRoute: (instrument) => `/prism/${instrument.slug}`,
  getCapabilities: capabilities,
  getTradeIntent: unavailableTradeIntent,
};

const adapters: Record<InstrumentContractRef['family'], InstrumentAdapter<never>> = {
  'launch-token': LaunchTokenAdapter as InstrumentAdapter<never>,
  'market-engine-v1': PredictionMarketAdapter as InstrumentAdapter<never>,
  'prism-state-pool': PrismInstrumentAdapter as InstrumentAdapter<never>,
};

export function getInstrumentAdapter(instrument: LaunchInstrument): InstrumentAdapter<never> {
  return adapters[instrument.contract.family];
}

export function getInstrumentRoute(instrument: LaunchInstrument): string {
  return getInstrumentAdapter(instrument).getDetailRoute(instrument);
}

export function getInstrumentTradeIntent(instrument: LaunchInstrument, params: TradeParams): Promise<TradeIntent> {
  if (!hasExecutableContract(instrument.chain.chainId, instrument.contract)) return unavailableTradeIntent(instrument, params);
  return getInstrumentAdapter(instrument).getTradeIntent?.(instrument, params) ?? unavailableTradeIntent(instrument, params);
}

/** Source-specific records stay behind their own adapters. */
export function normalizeLaunchSources() {
  return [
    ...tokenLaunches.map((source) => LaunchTokenAdapter.normalize(source)),
    ...markets.map((source) => PredictionMarketAdapter.normalize(source)),
    ...prismSeries.map((source) => PrismInstrumentAdapter.normalize(source)),
  ];
}
