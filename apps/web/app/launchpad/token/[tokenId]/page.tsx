import TokenDetail from '@/features/launchpad/token-detail';

export default async function LaunchpadTokenDetail({ params }: { params: Promise<{ tokenId: string }> }) {
  const { tokenId } = await params;
  return <TokenDetail id={tokenId}/>;
}
