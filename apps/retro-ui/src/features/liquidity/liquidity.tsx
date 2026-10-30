import { useState, type ReactNode } from 'react';
import { useQuery } from '@tanstack/react-query';
import type { IndexedLiquidityPool, IndexedLPPosition, IndexFreshness } from '@retropick/launchpad-sdk/read-model';
import type { Address } from 'viem';
import { Droplets, Plus, Search } from 'lucide-react';
import Link from '@/components/product/safe-link';
import { usePathname, useSearchParams } from '@/lib/next-compat';
import { DATA_MODE, INDEXER_URL } from '@/lib/live/env';
import { launchKeys } from '@/lib/live/queries';
import { isStale } from '@/lib/live/indexer-client';
import { useWallet } from '@/wallet/provider';
import { useKuruLiquidity } from '@/hooks/use-kuru-liquidity';
import { useLaunchStats } from '@/hooks/use-launch-stats';
import { AddressChip, DataTable, DemoBadge, EmptyState, ErrorState, FreshnessIndicator } from '@/components/trading/primitives';
import { formatPriceX18, formatRaw, formatRawCompact } from '@/lib/view-models/token-terminal';
import { demoLiquidityView, liquidityView } from '@/lib/view-models/liquidity';
import { LiveMarketLiquidity, MarketLiquidity, StateValue } from './market-liquidity';
import { demoPool, demoPoolEvents, fetchLPPositions, fetchPool, fetchPoolEvents, fetchPools } from './liquidity-data';
import { AddLiquidityModal, VaultDetailModal } from './liquidity-modals';
import { MarketMaking } from './market-making';
import './liquidity.css';

const live = DATA_MODE === 'live';
const addressValid = (token: string) => /^0x[\da-f]{40}$/i.test(token);

export function LiquidityFreshness({ freshness }: { freshness?: IndexFreshness }) {
  return <FreshnessIndicator freshness={freshness ? { indexedBlock: String(freshness.indexedBlock), lagBlocks: freshness.lagBlocks, stale: isStale(freshness) } : null}/>;
}

function PageLinks({ cursor, next, onCursor }: { cursor?: string; next?: string | null; onCursor: (cursor?: string) => void }) {
  return <div className="rp-pager"><span className="rp-muted">{next ? 'More results available; this page is not the complete list.' : 'End of list'}</span>{cursor && <button className="rp-btn rp-btn-ghost rp-btn-sm" onClick={() => onCursor(undefined)}>First page</button>}{next && <button className="rp-btn rp-btn-ghost rp-btn-sm" onClick={() => onCursor(next)}>Next page</button>}</div>;
}

export default function Liquidity({ token, maker = false }: { token?: string; maker?: boolean }) {
  const pathname = usePathname(), params = useSearchParams();
  const positions = !maker && !token && params.get('tab') === 'positions';
  return <div className="rp-liquidity" data-testid="liquidity-page" data-data-mode={live ? 'live' : 'demo'}>
    <header><h1><Droplets size={25} aria-hidden/> Liquidity</h1><p className="rp-note">Pools, protected protocol liquidity and manual market making on Monad Testnet.</p>{!live && <DemoBadge/>}</header>
    <nav className="rp-liquidity-tabs" aria-label="Liquidity sections"><Link href="/liquidity" aria-current={!positions && !maker ? 'page' : undefined}>Pools</Link><Link href="/liquidity?tab=positions" aria-current={positions ? 'page' : undefined}>My Positions</Link><Link href="/liquidity/market-making" aria-current={pathname.includes('/market-making') ? 'page' : undefined}>Market Making</Link></nav>
    {maker ? <MarketMaking/> : token ? <PoolDetails key={token} token={token}/> : <PoolsOverview initialTab={positions ? 'positions' : 'explore'}/>}
  </div>;
}

/** Donor-style status chip backed by the real pool snapshot state. */
function PoolStatusChip({ pool }: { pool: IndexedLiquidityPool }) {
  const state = pool.status === 'UNAVAILABLE' ? 'unavailable' : pool.historyComplete ? 'ready' : 'backfill';
  const label = state === 'ready' ? 'Ready' : state === 'backfill' ? 'Backfill pending' : 'Unavailable';
  return <span className={`rp-status-chip ${state}`} title={state === 'backfill' ? 'Vault event history is still backfilling; aggregates may be incomplete.' : state === 'unavailable' ? 'The vault read failed at snapshot time; this does not establish zero balances.' : 'Vault snapshot read at index time.'}>{label}</span>;
}

function PairDots({ base, quote }: { base: string; quote: string }) {
  return <span className="rp-pair-icons" aria-hidden="true"><span className="rp-token-dot">{base[0] ?? '?'}</span><span className="rp-token-dot">{quote[0] ?? '?'}</span></span>;
}

function VaultCard({ pool, volume, onOpen }: { pool: IndexedLiquidityPool; volume: ReactNode; onOpen: () => void }) {
  return <button type="button" className="rp-vault-card" onClick={onOpen} aria-label={`${pool.baseSymbol} / ${pool.quoteSymbol} vault details`}>
    <span className="rp-vault-card-header">
      <span className="rp-pair-identity"><PairDots base={pool.baseSymbol} quote={pool.quoteSymbol}/><span className="rp-pair-symbol">{pool.baseSymbol}/{pool.quoteSymbol}</span></span>
      <PoolStatusChip pool={pool}/>
    </span>
    <span className="rp-vault-card-footer">
      <span className="rp-metric-item"><span className="rp-metric-label">AMM {pool.baseSymbol}</span><span className="rp-metric-value">{pool.baseAssetsRaw !== null ? formatRawCompact(pool.baseAssetsRaw, pool.baseDecimals) : '—'}</span></span>
      <span className="rp-metric-item"><span className="rp-metric-label">AMM {pool.quoteSymbol}</span><span className="rp-metric-value">{pool.quoteAssetsRaw !== null ? formatRawCompact(pool.quoteAssetsRaw, pool.quoteDecimals) : '—'}</span></span>
      <span className="rp-metric-item"><span className="rp-metric-label">Vol 24h</span><span className="rp-metric-value">{volume}</span></span>
    </span>
  </button>;
}

/**
 * Donor (example-ui-ux) liquidity overview rebuilt on real data: vault cards
 * from indexed pools, pools table with quote/base-denominated inventory, and
 * wallet-owned LP positions verified on-chain. Fee/APR/USD columns are not
 * shown — no verified source exists on testnet.
 */
function PoolsOverview({ initialTab }: { initialTab: 'explore' | 'positions' }) {
  const [cursor, setCursor] = useState<string>();
  const [sub, setSub] = useState<'explore' | 'positions'>(initialTab);
  const [search, setSearch] = useState('');
  const [addPool, setAddPool] = useState<IndexedLiquidityPool | null>(null);
  const [vaultPool, setVaultPool] = useState<IndexedLiquidityPool | null>(null);
  const q = useQuery({ queryKey: launchKeys.resource('all', 'liquidity-pools', { cursor }), enabled: live && !!INDEXER_URL, queryFn: ({ signal }) => fetchPools(INDEXER_URL!, cursor, signal), refetchInterval: cursor ? false : 15_000 });
  const { stats } = useLaunchStats();
  const wallet = useWallet(), account = wallet.account;
  const positionsCount = useQuery({ queryKey: launchKeys.wallet(account ?? 'disconnected', 'lp-positions:count'), enabled: live && !!account && !!INDEXER_URL, queryFn: ({ signal }) => fetchLPPositions(INDEXER_URL!, account!, undefined, signal), refetchInterval: 30_000 });

  const pools = live ? q.data?.data ?? [] : [demoPool];
  const term = search.trim().toLowerCase();
  const filtered = term ? pools.filter((p) => `${p.baseSymbol} ${p.quoteSymbol} ${p.token}`.toLowerCase().includes(term)) : pools;
  const volumeFor = (p: IndexedLiquidityPool) => {
    const s = stats[p.token];
    if (!s || s.volume24hRaw === null) return <span className="rp-muted">—</span>;
    return <>{formatRawCompact(s.volume24hRaw, s.quoteDecimals)} <span className="rp-unit">{s.quoteSymbol}</span></>;
  };
  const currentPriceFor = (p: IndexedLiquidityPool): number | null => {
    const s = stats[p.token];
    if (!s || !s.priceX18) return null;
    return Number(formatPriceX18(s.priceX18));
  };

  return <>
    <section className="rp-vaults-section" aria-label="Vault markets">
      <h2 className="rp-section-title">Explore vaults</h2>
      <p className="rp-note">Each graduated market runs an automated Kuru order-book vault holding permanently protected protocol liquidity. Values are chain inventory in each asset's own units — no USD conversion exists on testnet.</p>
      {live && q.isError ? <ErrorState title="Pool discovery unavailable" text={q.error.message} onRetry={() => void q.refetch()}/>
      : <div className="rp-vaults-grid">{filtered.slice(0, 6).map((p) => <VaultCard key={p.token} pool={p} volume={volumeFor(p)} onOpen={() => setVaultPool(p)}/>)}
        {!filtered.length && <EmptyState title={live && q.isPending ? 'Loading vault markets…' : 'No indexed Kuru vaults'} text="Only graduated RetroPick Kuru markets appear here."/>}</div>}
    </section>

    <section className="rp-pools-section" aria-label="Pools and positions">
      <div className="rp-pools-header-row">
        <div className="rp-subtabs-wrap" role="tablist" aria-label="Liquidity sections">
          <button type="button" role="tab" className={`rp-subtab-btn${sub === 'explore' ? ' active' : ''}`} aria-selected={sub === 'explore'} onClick={() => setSub('explore')}>Explore pools{sub === 'explore' && <span className="rp-subtab-indicator" aria-hidden="true"/>}</button>
          <button type="button" role="tab" className={`rp-subtab-btn${sub === 'positions' ? ' active' : ''}`} aria-selected={sub === 'positions'} onClick={() => setSub('positions')}>Your positions{sub === 'positions' && <span className="rp-subtab-indicator" aria-hidden="true"/>}{live && positionsCount.data?.data.length ? <span className="rp-positions-counter" title={positionsCount.data.nextCursor ? 'First page count — more positions exist' : undefined}>{positionsCount.data.data.length}</span> : null}</button>
        </div>
        {sub === 'explore' && <div className="rp-search-wrap"><span className="rp-search-icon" aria-hidden="true"><Search size={13}/></span><input className="rp-search-input" aria-label="Search pools by symbol or token" placeholder="Search pools" value={search} onChange={(e) => setSearch(e.target.value)}/></div>}
      </div>

      {sub === 'positions' ? <LPPositions/> : <>
        <div className="rp-pools-table-card">
          <div className="rp-table-responsive">
            <table className="rp-kuru-table" aria-label="Kuru liquidity pools">
              <thead><tr>
                <th scope="col" className="th-market">Market</th>
                <th scope="col" className="th-num rp-pt4">AMM base</th>
                <th scope="col" className="th-num rp-pt5">AMM quote</th>
                <th scope="col" className="th-num rp-pt1">Volume 24h</th>
                <th scope="col" className="rp-pt2">Snapshot</th>
                <th scope="col" className="th-action">Actions</th>
              </tr></thead>
              <tbody>
                {filtered.map((row) => <tr key={row.token} className="rp-pool-row">
                  <td className="td-market"><span className="rp-market-cell"><PairDots base={row.baseSymbol} quote={row.quoteSymbol}/><span className="rp-market-name-wrap"><Link className="rp-market-name" href={`/liquidity/pools/${row.token}`}>{row.baseSymbol} / {row.quoteSymbol}</Link><span className="rp-market-id" title={row.token}>{row.token}</span></span></span></td>
                  <td className="td-num rp-pt4">{row.baseAssetsRaw === null ? <span className="rp-muted">Unavailable</span> : <>{formatRaw(row.baseAssetsRaw, row.baseDecimals)} <span className="rp-unit">{row.baseSymbol}</span></>}</td>
                  <td className="td-num rp-pt5">{row.quoteAssetsRaw === null ? <span className="rp-muted">Unavailable</span> : <>{formatRaw(row.quoteAssetsRaw, row.quoteDecimals)} <span className="rp-unit">{row.quoteSymbol}</span></>}</td>
                  <td className="td-num rp-pt1">{volumeFor(row)}</td>
                  <td className="rp-pt2"><PoolStatusChip pool={row}/></td>
                  <td className="td-action"><span className="rp-row-actions">
                    <button type="button" className="rp-btn-add-liquidity" onClick={() => setAddPool(row)} aria-label={`Add liquidity to ${row.baseSymbol} / ${row.quoteSymbol}`}><Plus size={13} className="rp-add-icon" aria-hidden/><span className="rp-add-label">Add liquidity</span></button>
                    <Link className="rp-action-link" href={`/launchpad/token/${row.token}`}>Trade</Link>
                  </span></td>
                </tr>)}
                {!filtered.length && <tr><td colSpan={6}><div className="rp-empty-pools">{live && q.isPending ? 'Loading pools…' : `No pools matching “${search}”`}</div></td></tr>}
              </tbody>
            </table>
          </div>
          <p className="rp-note rp-pools-footnote">Fee and yield statistics (fees 24h, pool APR) are not shown: no verified source exists. Base and quote inventory are shown separately — inventory does not guarantee execution for a particular order size.</p>
        </div>
        {live && !q.isError && q.data && <PageLinks cursor={cursor} next={q.data.nextCursor} onCursor={setCursor}/>}
      </>}
    </section>

    {addPool && <AddLiquidityModal pool={addPool} currentPrice={currentPriceFor(addPool)} isOpen onClose={() => setAddPool(null)}/>}
    {vaultPool && <VaultDetailModal pool={vaultPool} isOpen onClose={() => setVaultPool(null)}/>}
  </>;
}

function PoolDetails({ token }: { token: string }) {
  const params = useSearchParams();
  const valid = live ? addressValid(token) : token === demoPool.token;
  const q = useQuery({ queryKey: launchKeys.resource(token, 'liquidity-pool'), enabled: live && valid && !!INDEXER_URL, queryFn: ({ signal }) => fetchPool(INDEXER_URL!, token, signal), refetchInterval: 15_000 });
  if (!valid) return <ErrorState title="Invalid pool" text={live ? 'A pool route must identify a RetroPick token address.' : 'This pool is not part of the demo fixture.'}/>;
  const pool = live ? q.data?.data : demoPool;
  return <><Link href="/liquidity" className="rp-back">← All pools</Link>
    {live && q.isError && <ErrorState title="Indexed pool details unavailable" text={q.error.message} onRetry={() => void q.refetch()}/>}
    {live ? <LiveMarketLiquidity token={token} baseSymbol={pool?.baseSymbol ?? 'BASE'} quoteSymbol={pool?.quoteSymbol ?? 'QUOTE'}/> : <MarketLiquidity view={demoLiquidityView(token, params.get('scenario') ?? '')} baseSymbol={demoPool.baseSymbol} quoteSymbol={demoPool.quoteSymbol}/>}
    <p className="rp-note">Graduation LP shares are permanently protected. This page provides read-only LP information. Public LP deposits, minting and withdrawals are not enabled.</p>
    <PoolHistory token={token} pool={pool}/>
  </>;
}

function PoolHistory({ token, pool }: { token: string; pool?: IndexedLiquidityPool }) {
  const [cursor, setCursor] = useState<string>();
  const q = useQuery({ queryKey: launchKeys.resource(token, 'liquidity-events', { cursor }), enabled: live && !!INDEXER_URL, queryFn: ({ signal }) => fetchPoolEvents(INDEXER_URL!, token, cursor, signal), refetchInterval: cursor ? false : 15_000 });
  const rows = live ? q.data?.data ?? [] : demoPoolEvents;
  return <section className="rp-liquidity-card" aria-label="Vault history"><div className="rp-liquidity-header"><h2>Vault history</h2>{live && <LiquidityFreshness freshness={q.data?.freshness}/>}</div>
    {pool && !pool.historyComplete && <p className="rp-note" role="status">Vault history backfill is pending. An empty page cannot establish a zero position.</p>}
    {live && q.isError ? <ErrorState title="Vault history unavailable" text="The indexer may still be backfilling this vault. Current chain liquidity is read independently." onRetry={() => void q.refetch()}/> : <DataTable caption="Vault deposit withdrawal and share transfer history" rows={rows} rowKey={row => row.id} empty={<EmptyState title={live && q.isPending ? 'Loading vault history…' : 'No vault events on this page'}/>} columns={[
      { key: 'kind', header: 'Event', cell: row => row.kind.toLowerCase() },
      { key: 'shares', header: 'Shares (atomic units)', align: 'right', cell: row => row.sharesRaw },
      { key: 'base', header: 'Base assets', align: 'right', cell: row => row.baseRaw !== undefined && pool ? `${formatRaw(row.baseRaw, pool.baseDecimals)} ${pool.baseSymbol}` : '—' },
      { key: 'quote', header: 'Quote assets', align: 'right', cell: row => row.quoteRaw !== undefined && pool ? `${formatRaw(row.quoteRaw, pool.quoteDecimals)} ${pool.quoteSymbol}` : '—' },
      { key: 'receipt', header: 'Receipt', cell: row => <AddressChip value={row.transactionHash} kind="tx" label="vault event transaction"/> },
    ]}/>}
    {live && !q.isError && q.data && <PageLinks cursor={cursor} next={q.data.nextCursor} onCursor={setCursor}/>}
  </section>;
}

function LPPositions() {
  const wallet = useWallet(), account = wallet.account;
  const [cursor, setCursor] = useState<string>();
  const q = useQuery({ queryKey: launchKeys.wallet(account ?? 'disconnected', `lp-positions:${cursor ?? ''}`), enabled: live && !!account && !!INDEXER_URL, queryFn: ({ signal }) => fetchLPPositions(INDEXER_URL!, account!, cursor, signal), refetchInterval: cursor ? false : 15_000 });
  if (live && !account) return <EmptyState title="Connect a wallet to see LP positions" text="LP shares are distinct from Kuru trading margin." action={<button className="rp-btn rp-btn-primary" onClick={() => void wallet.connect().catch(() => {})}>Connect wallet</button>}/>;
  const rows: IndexedLPPosition[] = live ? q.data?.data ?? [] : [];
  return <div>
    <p className="rp-note">Read-only wallet-owned LP shares. Protected graduation shares belong to the protocol lock. Trading capital and open orders remain separate.</p>
    {live && q.isError ? <ErrorState title="LP positions unavailable" text="Position history is unavailable or still syncing. This does not establish a zero share balance." onRetry={() => void q.refetch()}/> : rows.length ? <div className="rp-positions-list">{rows.map(row => <VerifiedPosition key={`${row.vault}:${row.wallet}`} row={row} account={account!}/>)}</div> : <div className="rp-positions-empty">
      <p className="rp-empty-title">{live && q.isPending ? 'Loading LP positions…' : 'No indexed LP positions on this page'}</p>
      <p className="rp-note">{live ? 'Only verified, indexed Kuru vault positions appear here.' : 'The demo wallet has no LP shares. Demo margin balances are trading capital, not LP ownership.'}</p>
    </div>}
    {live && !q.isError && q.data && <PageLinks cursor={cursor} next={q.data.nextCursor} onCursor={setCursor}/>}
  </div>;
}

const ROLE_TAG: Record<IndexedLPPosition['role'], string> = { PROTECTED: 'Protected protocol', INFRASTRUCTURE: 'Infrastructure', WALLET: 'Wallet' };

function VerifiedPosition({ row, account }: { row: IndexedLPPosition; account: Address }) {
  const q = useKuruLiquidity(row.token, account);
  const view = liquidityView(row.token, q.data, { loading: q.isPending, error: q.isError ? q.error.message : null, stale: !!q.data && (q.isError || Date.now() - q.dataUpdatedAt >= 20_000) });
  const poolShares = view.vaultState.sharesRaw;
  const sharePct = poolShares && BigInt(poolShares) > 0n && view.position.sharesRaw ? BigInt(view.position.sharesRaw) * 10_000n / BigInt(poolShares) : null;
  return <article className="rp-position-card" aria-label={`LP position in ${row.token}`}>
    <header className="rp-pos-header">
      <span className="rp-pos-title-wrap">
        <h3><Link className="rp-link" href={`/liquidity/pools/${row.token}`}>{ROLE_TAG[row.role]} position</Link></h3>
        <span className={`rp-pos-type-tag${row.role === 'WALLET' ? '' : ' is-protocol'}`}>{ROLE_TAG[row.role]}</span>
        <span className="rp-pos-status-badge" title={view.block ? `Verified on-chain at block ${view.block}` : 'Chain confirmation unavailable'}><span className="dot" aria-hidden="true"/>{view.block ? `Block ${view.block}` : 'Unverified'}</span>
      </span>
      <span className="rp-pos-actions"><AddressChip value={row.token} label="position token"/></span>
    </header>
    <dl className="rp-pos-stats-grid">
      <div><dt>Current shares</dt><dd><StateValue status={view.position.status}>{view.shareDecimals === null ? `${view.position.sharesRaw ?? '—'} atomic shares` : formatRaw(view.position.sharesRaw, view.shareDecimals)}</StateValue></dd></div>
      <div><dt>Share of pool</dt><dd><StateValue status={view.position.status}>{sharePct !== null ? `${Number(sharePct) / 100}%` : '—'}</StateValue></dd></div>
      <div><dt>Underlying preview · base / quote</dt><dd><StateValue status={view.position.status}>{formatRaw(view.position.baseRaw, view.baseDecimals)} / {formatRaw(view.position.quoteRaw, view.quoteDecimals)}</StateValue></dd></div>
      <div><dt>Earned fees</dt><dd title="No fee-earnings source exists: Kuru trade events carry no fee field and the indexer aggregates none."><span className="rp-muted">—</span></dd></div>
    </dl>
    <footer className="rp-pos-foot">
      <button className="rp-btn-withdraw" disabled title="LP withdrawals are not enabled on RetroPick. Graduation LP shares are permanently protocol-protected.">Withdraw</button>
      <p className="rp-note">Underlying values are the current vault withdrawal preview; they are not guaranteed withdrawal proceeds.</p>
    </footer>
  </article>;
}
