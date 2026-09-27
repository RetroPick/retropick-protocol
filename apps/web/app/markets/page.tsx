import { redirect } from 'next/navigation';

type LegacyParams = { market?: string; category?: string };

/** Compatibility redirect: the old prediction dashboard must never render. */
export default async function LegacyMarkets({ searchParams }: { searchParams: Promise<LegacyParams> }) {
  const params = await searchParams;
  const type = params.market === 'prediction' || params.market === 'crypto' || params.market === 'stocks' ? params.market : 'all';
  const query = new URLSearchParams();
  if (type !== 'all') query.set('type', type);
  if (type === 'prediction' && params.category && ['Crypto', 'Macro', 'Technology', 'Sports'].includes(params.category)) query.set('predictionTopic', params.category);
  redirect(`/launchpad${query.size ? `?${query.toString()}` : ''}`);
}
