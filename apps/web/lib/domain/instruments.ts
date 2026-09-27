import type { EventMarket, NativeState, SeriesState } from './types';
import type { TokenLifecycle } from './launchpad-types';

export type Address = `0x${string}`;
export type Hex = `0x${string}`;
export type InstrumentKind = 'token' | 'prediction' | 'prism';
export type ReferenceClass = 'crypto' | 'stock' | 'event' | 'macro' | 'other';
export type InstrumentStatus = TokenLifecycle | NativeState | SeriesState;

export interface ChainDescriptor {
  chainId: number;
  name: string;
}

export interface PairDescriptor {
  symbol: string;
  referenceClass: ReferenceClass;
  role: 'quote';
}

/** Addresses/IDs are deliberately optional until verified deployment metadata exists. */
export type InstrumentContractRef =
  | { family: 'launch-token'; tokenAddress?: Address; poolAddress?: Address; launchId?: string }
  | { family: 'market-engine-v1'; marketEngine?: Address; templateId?: Hex; epochId?: bigint }
  | { family: 'prism-state-pool'; statePool?: Address; statePoolId?: Hex; claimId?: bigint | Hex; payoffHash?: Hex };

export interface InstrumentCapabilities {
  /** A local demo ticket is distinct from an executable wallet transaction. */
  previewTrade: boolean;
  trade: boolean;
  claim: boolean;
  create: boolean;
}

export interface PredictionMetadata {
  topic: EventMarket['category'];
  yesPrice: number;
  noPrice: number;
  resolutionDate: string;
  collateralAsset: string;
  priceChangeUnit: 'cents';
  resolution: EventMarket['resolution'];
  /** No claim about ERC-20 deployment follows from this metadata. */
  representation: 'unverified';
}

export interface PrismMetadata {
  components: readonly { symbol: string; unitsPerShare: number }[];
  collateralAsset: string;
  statePoolId?: Hex;
  claimId?: bigint | Hex;
  payoffHash?: Hex;
  encoderId?: Hex;
  expiry?: string;
  stateCount?: number;
  claimToken?: Address;
}

export interface TokenMetadata {
  curveProgressBps: number;
  primaryVenue: string;
  matureVenue: string;
  stockReference?: string;
}

/** A presentation/read model. Financial state remains with each protocol family. */
export interface LaunchInstrument {
  id: string;
  slug: string;
  kind: InstrumentKind;
  referenceClass: ReferenceClass;
  name: string;
  symbol?: string;
  icon?: string;
  color?: string;
  description?: string;
  creator?: string;
  createdAt: string | null;
  updatedAt: string | null;
  provenance: 'DEMO';
  price: number | bigint | null;
  change24h: number | null;
  liquidity: number | bigint | null;
  volume24h: number | bigint | null;
  lifetimeVolume: number | bigint | null;
  marketCap: number | bigint | null;
  trades24h: number | null;
  status: InstrumentStatus;
  pair?: PairDescriptor;
  chain: ChainDescriptor;
  contract: InstrumentContractRef;
  prediction?: PredictionMetadata;
  prism?: PrismMetadata;
  token?: TokenMetadata;
  capabilities: InstrumentCapabilities;
}

export interface TradeParams {
  direction: 'buy' | 'sell';
  amount: bigint;
  outcome?: 'YES' | 'NO';
}

export type TradeIntent =
  | { type: 'unavailable'; reason: 'NO_VERIFIED_DEPLOYMENT' | 'UNSUPPORTED_INSTRUMENT' }
  | { type: 'demo-detail'; href: string };

export interface InstrumentAdapter<TSource> {
  readonly family: InstrumentContractRef['family'];
  normalize(source: TSource): LaunchInstrument;
  getDetailRoute(instrument: LaunchInstrument): string;
  getCapabilities(instrument: LaunchInstrument): InstrumentCapabilities;
  getTradeIntent?(instrument: LaunchInstrument, params: TradeParams): Promise<TradeIntent>;
}
