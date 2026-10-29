// Live Kuru Orders tab (Section 19): the connected wallet's orders from the indexer, open orders re-validated
// against the chain, Cancel through the existing SDK prepareKuruCancel + tx pipeline. Cursor pagination is
// respected: a page is never presented as the complete history.
import { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import type { Address } from 'viem';
import type { IndexedOrder } from '@retropick/launchpad-sdk/read-model';
import { prepareKuruCancel } from '@retropick/launchpad-sdk/prepare';
import { readKuruOrder } from '@retropick/launchpad-sdk/orders';
import { INDEXER_URL } from '@/lib/live/env';
import { queryPath, request } from '@/lib/live/indexer-client';
import { launchKeys, queryClient } from '@/lib/live/queries';
import { publicClient } from '@/lib/live/public-client';
import { executePreparedWrite } from '@/services/tx-pipeline';
import { useWallet } from '@/wallet/provider';
import { AddressChip, DataTable, EmptyState, ErrorState, SegmentedControl, cx, type Column } from '@/components/trading/primitives';
import { ageFrom, formatPriceX18, formatRawCompact, orderSizeRaw } from '@/lib/view-models/token-terminal';
import { toast } from 'sonner';

export function LiveOrdersPanel({ token, market, quoteSymbol }: { token: string; market: string | null; quoteSymbol: string }) {
  const wallet = useWallet(), account = wallet.account;
  const [filter, setFilter] = useState<'open' | 'filled' | 'cancelled'>('open');
  const [cursor, setCursor] = useState<string | undefined>();
  const [cancelling, setCancelling] = useState<string | null>(null);
  const status = filter === 'open' ? 'open' : 'all';
  const orders = useQuery({
    queryKey: launchKeys.resource(token, 'orders-tab', { owner: account ?? '', status, cursor: cursor ?? '' }),
    enabled: !!INDEXER_URL && !!account,
    queryFn: ({ signal }) => request<IndexedOrder[]>(INDEXER_URL!, queryPath(`/v1/launches/${token}/orders`, { owner: account ?? undefined, status, limit: 100, cursor }), signal),
    refetchInterval: cursor ? false : 5000,
  });
  const rows = useMemo(() => (orders.data?.data ?? []).filter((o) => filter === 'open' ? ['OPEN', 'PARTIALLY_FILLED'].includes(o.status) : filter === 'filled' ? o.status === 'FILLED' : o.status === 'CANCELLED'), [orders.data, filter]);
  const openIds = filter === 'open' ? rows.map((o) => o.orderId).join(',') : '';
  // Indexed open orders are re-validated on chain before Cancel is offered (same rule as the former ticket list).
  const validated = useQuery({
    queryKey: launchKeys.resource(token, 'validated-orders-tab', { owner: account ?? '', ids: openIds }),
    enabled: !!market && !!account && !!openIds,
    queryFn: async () => {
      const blockNumber = await publicClient.getBlockNumber({ cacheTime: 0 });
      const raw = await Promise.all(rows.map((o) => readKuruOrder(publicClient, market as Address, Number(o.orderId), blockNumber)));
      return Object.fromEntries(rows.map((o, i) => [o.orderId, raw[i].active && raw[i].order[1] > 0n && raw[i].order[0].toLowerCase() === account!.toLowerCase() ? String(raw[i].order[1]) : null]));
    },
    refetchInterval: 3000,
  });
  const cancel = async (order: IndexedOrder) => {
    if (!wallet.wallet || !account || !market || cancelling) return;
    setCancelling(order.orderId);
    try {
      const prepared = await prepareKuruCancel(publicClient, market as Address, account, [Number(order.orderId)]);
      const result = await executePreparedWrite(publicClient, wallet.wallet, prepared);
      if (result.kind === 'failed') toast.error(result.failure === 'rejected' ? 'Cancel rejected in wallet' : result.reason);
      else { toast.success('Cancel confirmed on-chain; awaiting indexing', { description: result.hash }); await queryClient.invalidateQueries({ queryKey: launchKeys.all }); }
    } catch (cause) { toast.error(cause instanceof Error ? cause.message : 'Cancel failed'); }
    finally { setCancelling(null); }
  };
  if (!account) return <EmptyState title="Connect a wallet to see your orders" text="Orders are read for the connected wallet only."/>;
  const cols: Column<IndexedOrder>[] = [
    { key: 'side', header: 'Side', cell: (o) => <span className={cx('rp-side-tag', o.side === 'buy' ? 'rp-up' : 'rp-down')}>{o.side === 'buy' ? 'Buy' : 'Sell'}</span> },
    { key: 'price', header: 'Limit price', align: 'right', cell: (o) => `${formatPriceX18(o.priceX18)} ${quoteSymbol}` },
    { key: 'size', header: 'Size', align: 'right', cell: (o) => formatRawCompact(orderSizeRaw(o.originalSizeUnits, o.baseDecimals, o.sizePrecision), o.baseDecimals) },
    { key: 'filled', header: 'Filled', align: 'right', priority: 2, cell: (o) => { const remaining = validated.data?.[o.orderId] ?? o.remainingSizeUnits; return formatRawCompact(orderSizeRaw((BigInt(o.originalSizeUnits) - BigInt(remaining)).toString(), o.baseDecimals, o.sizePrecision), o.baseDecimals); } },
    { key: 'status', header: 'Status', cell: (o) => filter === 'open' && validated.data && validated.data[o.orderId] === null ? 'not active on-chain' : o.status.replaceAll('_', ' ').toLowerCase() },
    { key: 'created', header: 'Created', priority: 3, cell: (o) => ageFrom(o.createdAt, Date.now()) },
    { key: 'id', header: 'Order ID', priority: 3, cell: (o) => <span className="rp-mono">#{o.orderId} <AddressChip value={o.transactionHash} kind="tx" label="order transaction"/></span> },
    { key: 'cancel', header: <span className="rp-sr">Actions</span>, cell: (o) => filter === 'open' && validated.data?.[o.orderId] ? <button className="rp-btn rp-btn-ghost rp-btn-sm" disabled={!!cancelling || !wallet.wallet} onClick={() => void cancel(o)}>{cancelling === o.orderId ? 'Cancelling…' : 'Cancel'}</button> : null },
  ];
  return <div>
    <SegmentedControl label="Order status" size="sm" value={filter} onChange={(v) => { setFilter(v); setCursor(undefined); }} options={[{ value: 'open', label: 'Open' }, { value: 'filled', label: 'Filled' }, { value: 'cancelled', label: 'Cancelled' }]}/>
    {orders.isError ? <ErrorState title="Order history unavailable" text="The indexer did not return your orders." onRetry={() => void orders.refetch()}/>
      : <DataTable caption="Your Kuru orders" columns={cols} rows={rows} rowKey={(o) => `${o.market}:${o.orderId}`} empty={orders.isLoading ? <p className="rp-note" role="status">Loading orders…</p> : <EmptyState title={`No ${filter} orders on this page`}/>}/>}
    <div className="rp-pager">
      <span className="rp-muted">{orders.data?.nextCursor ? 'More orders on the next page — this list is not complete.' : 'End of list'}</span>
      {cursor && <button className="rp-btn rp-btn-ghost rp-btn-sm" onClick={() => setCursor(undefined)}>First page</button>}
      {orders.data?.nextCursor && <button className="rp-btn rp-btn-ghost rp-btn-sm" onClick={() => setCursor(orders.data!.nextCursor!)}>Next page</button>}
    </div>
  </div>;
}
