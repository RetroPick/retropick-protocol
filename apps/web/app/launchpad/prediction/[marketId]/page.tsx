import MarketDetail from '@/features/markets/detail';

export default async function LaunchpadPredictionDetail({ params }: { params: Promise<{ marketId: string }> }) {
  const { marketId } = await params;
  return <MarketDetail id={marketId}/>;
}
