import type { IndexedLaunch } from '@retropick/launchpad-sdk/read-model';
import type { LaunchInstrument, Address } from '@/lib/domain/instruments';
import type { TokenLifecycle } from '@/lib/domain/launchpad-types';

const PHASE_TO_LIFECYCLE: Record<IndexedLaunch['phase'], TokenLifecycle> = {
  ACTIVE: 'CURVE',
  GRADUATION_READY: 'GRADUATION_READY',
  GRADUATING: 'GRADUATING',
  GRADUATED: 'GRADUATED',
};

import { bpsToPercent, priceToDisplay, rawToDisplay } from './format';

/**
 * Normalizes one indexer launch record into the shared LaunchInstrument read
 * model. Financial values stay exact raws where the field allows bigint; the
 * number conversions here are display-boundary only (see lib/live/format.ts).
 */
export function indexedLaunchToInstrument(launch: IndexedLaunch): LaunchInstrument {
  const decimals = launch.quoteDecimals;
  return {
    id: launch.token,
    slug: launch.token,
    kind: 'token',
    referenceClass: 'crypto',
    name: launch.name || launch.symbol || launch.token,
    symbol: launch.symbol,
    icon: '◈',
    color: '#7ef0c0',
    description: launch.description || undefined,
    creator: launch.creator,
    createdAt: launch.createdAt,
    updatedAt: launch.createdAt,
    provenance: 'LIVE',
    price: priceToDisplay(launch.priceRaw),
    change24h: bpsToPercent(launch.change24hBps),
    // Liquidity = the launch's real quote depth: curve quote reserve while
    // bonding, seeded quote after graduation. Never a fabricated number.
    liquidity: rawToDisplay(launch.quoteReserveRaw, decimals),
    volume24h: rawToDisplay(launch.volume24hRaw, decimals),
    lifetimeVolume: rawToDisplay(launch.lifetimeVolumeRaw, decimals),
    marketCap: rawToDisplay(launch.marketCapRaw, decimals),
    trades24h: launch.trades24h,
    status: PHASE_TO_LIFECYCLE[launch.phase],
    pair: { symbol: launch.quoteSymbol, referenceClass: 'crypto', role: 'quote' },
    chain: { chainId: 10143, name: 'Monad' },
    contract: {
      family: 'launch-token',
      tokenAddress: launch.token as Address,
      poolAddress: (launch.market ?? launch.curve) as Address,
    },
    token: {
      curveProgressBps: launch.bondingProgressBps,
      primaryVenue: 'RetroPick bonding market',
      matureVenue: launch.venue === 'KURU' ? 'Kuru orderbook' : 'Uniswap V4',
    },
    capabilities: { previewTrade: true, trade: false, claim: false, create: false },
  };
}
