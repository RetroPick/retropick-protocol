import CreateLaunch from '@/features/launchpad/create-launch';

export default async function LaunchpadCreatePage({ searchParams }: { searchParams: Promise<{ type?: string }> }) {
  const { type } = await searchParams;
  return <CreateLaunch initialType={type}/>;
}
