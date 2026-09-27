import { redirect } from 'next/navigation';

export default async function LegacyCreate({ searchParams }: { searchParams: Promise<{ type?: string }> }) {
  const { type } = await searchParams;
  const launchType = type === 'crypto' || type === 'stocks' || type === 'prediction' ? type : 'prediction';
  redirect(`/launchpad/create?type=${launchType}`);
}
