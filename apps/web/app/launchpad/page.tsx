import LiveDiscovery from '@/features/live/discovery';
import {liveMode} from '@/lib/live/client';
import LaunchpadDiscovery from '@/features/launchpad/discovery';

export default function LaunchpadPage() {
  return liveMode() ? <LiveDiscovery/> : <LaunchpadDiscovery/>;
}
