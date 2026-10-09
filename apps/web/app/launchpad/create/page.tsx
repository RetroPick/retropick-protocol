import LiveCreate from '@/features/live/create';
import {liveMode} from '@/lib/live/client';
import CreateLaunch from '@/features/launchpad/create-launch';

export default async function LaunchpadCreatePage({ searchParams }: { searchParams: Promise<{ type?: string }> }) {
  const { type } = await searchParams;
  if(liveMode()) return <LiveCreate/>;
  return <CreateLaunch initialType={type}/>;
}
