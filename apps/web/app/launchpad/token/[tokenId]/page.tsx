import LiveToken from '@/features/live/token';
import {liveMode} from '@/lib/live/client';
import TokenDetail from '@/features/launchpad/token-detail';

export default async function LaunchpadTokenDetail({ params }: { params: Promise<{ tokenId: string }> }) {
  const { tokenId } = await params;
  return liveMode() ? <LiveToken key={tokenId.toLowerCase()} token={tokenId}/> : <TokenDetail id={tokenId}/>;
}
