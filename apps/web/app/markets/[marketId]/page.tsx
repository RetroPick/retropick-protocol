import { redirect } from 'next/navigation';

export default async function LegacyMarketDetail({ params, searchParams }: { params: Promise<{ marketId: string }>; searchParams: Promise<Record<string, string | string[] | undefined>> }) {
  const [{ marketId }, queryValues] = await Promise.all([params, searchParams]);
  const query = new URLSearchParams();
  for (const [key, value] of Object.entries(queryValues)) if (typeof value === 'string') query.set(key, value);
  redirect(`/launchpad/prediction/${encodeURIComponent(marketId)}${query.size ? `?${query.toString()}` : ''}`);
}
