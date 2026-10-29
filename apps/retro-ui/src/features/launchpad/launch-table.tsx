// Shared launch discovery table/grid. Consumes DiscoveryRow from live indexer
// or demo fixtures. Visual system from the example-ui-ux donor (o1-style
// hierarchy, trending rail, richer cards) rebuilt on canonical rules: every
// value is quote-denominated bigint-exact or an honest em-dash — never `$`,
// never a fabricated fallback (goal RETROPICK-RETRO-UI-EXAMPLE-INTEGRATION-V1).
import { useState } from 'react';
import { ArrowRight, Flame, Plus, Star } from 'lucide-react';
import Link from '@/components/product/safe-link';
import { DemoBadge, EmptyState, LifecycleBadge, SegmentedControl, TokenIdentity, cx } from '@/components/trading/primitives';
import { DiscoveryBondingProgress } from '@/components/trading/bonding-progress';
import { ageFrom, changeDirection, formatBps, formatPriceX18, formatRawCompact } from '@/lib/view-models/token-terminal';
import { LIFECYCLE_FILTERS, type DiscoveryRow, type LifecycleFilter } from '@/lib/view-models/discovery';
import '@/components/trading/trading.css';
import './launch-table.css';

/** Sparkline from REAL bucket closes only (bigint → relative position). Fewer than 2 points → "—". */
export function Sparkline({ closes, label, width = 96, height = 28 }: { closes: string[]; label: string; width?: number; height?: number }) {
  if (closes.length < 2) return <span className="rp-muted" aria-label="No price history">—</span>;
  const values = closes.map((c) => BigInt(c));
  const lo = values.reduce((a, b) => (b < a ? b : a)), hi = values.reduce((a, b) => (b > a ? b : a));
  const span = hi - lo || 1n;
  const pts = values.map((v, i) => `${((i * width) / (values.length - 1)).toFixed(1)},${(height - 2 - Number(((v - lo) * BigInt((height - 4) * 1000)) / span) / 1000).toFixed(1)}`).join(' ');
  const up = values[values.length - 1] >= values[0];
  return <svg className={cx('rp-spark', up ? 'rp-up' : 'rp-down')} width={width} height={height} viewBox={`0 0 ${width} ${height}`} role="img" aria-label={label}><polyline points={pts} fill="none" stroke="currentColor" strokeWidth="1.5" vectorEffect="non-scaling-stroke"/></svg>;
}

const rawBig = (v: string | null) => (v ? BigInt(v) : -1n);

/** Top movers ranked by REAL 24h volume (bigint), tie-broken by market cap. Mixed-quote sums are never computed. */
function trendingRows(rows: DiscoveryRow[], n = 5): DiscoveryRow[] {
  return [...rows].sort((a, b) => {
    const d = rawBig(b.volume24hRaw) - rawBig(a.volume24hRaw);
    if (d !== 0n) return d > 0n ? 1 : -1;
    return rawBig(b.marketCapRaw) > rawBig(a.marketCapRaw) ? 1 : -1;
  }).slice(0, n);
}

/**
 * Discovery hero. Protocol stats are COUNTS derived from the actual snapshot —
 * never invented aggregates. Aggregated volumes/TVL across launches are
 * impossible to state honestly (mixed quote denominations, no USD oracle), so
 * they are not shown at all.
 */
export function LaunchpadHeader({ rows, subtitle }: { rows: DiscoveryRow[]; subtitle: string }) {
  const bonding = rows.filter((r) => r.lifecycle === 'ACTIVE').length;
  const graduated = rows.filter((r) => r.lifecycle === 'GRADUATED').length;
  const quotes = new Set(rows.map((r) => r.quote.symbol)).size;
  const demo = rows.some((r) => r.dataMode === 'demo');
  const trending = trendingRows(rows);
  return <section className="rp-disc-hero" aria-label="Launchpad overview">
    <div className="rp-disc-hero-main">
      <div className="rp-disc-hero-title">
        <h1>Launchpad</h1>
        {demo ? <DemoBadge/> : <span className="rp-disc-chain">Monad Testnet</span>}
      </div>
      <p>{subtitle}</p>
      <div className="rp-disc-hero-actions">
        <Link className="rp-btn rp-btn-primary" href="/launchpad/create"><Plus size={15} aria-hidden/>Launch token</Link>
        <a className="rp-btn rp-btn-ghost" href="#launches">Explore feed<ArrowRight size={14} aria-hidden/></a>
      </div>
      <dl className="rp-disc-stats">
        <div><dt>Launches indexed</dt><dd>{rows.length || '—'}</dd></div>
        <div><dt>Bonding now</dt><dd>{bonding || '—'}</dd></div>
        <div><dt>Graduated</dt><dd>{graduated || '—'}</dd></div>
        <div><dt>Quote assets</dt><dd>{quotes || '—'}</dd></div>
      </dl>
    </div>
    {trending.length > 0 && <aside className="rp-trending" aria-label="Most active launches by 24h volume">
      <div className="rp-trending-head"><h2><Flame size={15} aria-hidden/>Most active</h2><span className="rp-trending-sub">by 24h volume</span></div>
      <ol>
        {trending.map((r, i) => {
          const dir = changeDirection(r.change24hBps);
          return <li key={r.id}>
            <Link href={r.href} className="rp-trending-row">
              <span className="rp-trending-rank" aria-hidden="true">{i + 1}</span>
              <TokenIdentity name={r.name} symbol={r.symbol} icon={r.icon} logo={r.logo} quote={r.quote} size="sm"/>
              <span className="rp-trending-nums">
                <span className="rp-trending-cap">{r.marketCapRaw ? <>{formatRawCompact(r.marketCapRaw, r.quote.decimals)} <span className="rp-unit">{r.quote.symbol}</span></> : '—'}</span>
                <span className="rp-trending-vol">Vol {r.volume24hRaw ? <>{formatRawCompact(r.volume24hRaw, r.quote.decimals)} <span className="rp-unit">{r.quote.symbol}</span></> : '—'}</span>
              </span>
              <span className={cx('rp-trending-chg', `rp-${dir}`)}>{dir === 'none' ? '—' : formatBps(r.change24hBps, true)}</span>
            </Link>
          </li>;
        })}
      </ol>
    </aside>}
  </section>;
}

export function DiscoveryControls({ filter, onFilter, pairs, pair, onPair, view, onView }: {
  filter: LifecycleFilter; onFilter: (f: LifecycleFilter) => void; pairs: Array<{ value: string; label: string }>; pair: string; onPair: (p: string) => void; view: 'list' | 'grid'; onView: (v: 'list' | 'grid') => void;
}) {
  return <div className="rp-disc-controls">
    <SegmentedControl label="Launch lifecycle" value={filter} onChange={onFilter} options={LIFECYCLE_FILTERS.map(([value, label]) => ({ value, label }))}/>
    <div className="rp-disc-right">
      <label className="rp-select"><span className="rp-sr">Pair filter</span>
        <select aria-label="Pair filter" value={pair} onChange={(e) => onPair(e.target.value)}><option value="">Any pair</option>{pairs.map((p) => <option key={p.value} value={p.value}>{p.label}</option>)}</select>
      </label>
      <SegmentedControl label="Layout" size="sm" value={view} onChange={onView} options={[{ value: 'list', label: <><span className="rp-sr">List view</span><span aria-hidden>List</span></> }, { value: 'grid', label: <><span className="rp-sr">Grid view</span><span aria-hidden>Grid</span></> }]}/>
    </div>
  </div>;
}

const value = (raw: string | null, r: DiscoveryRow) => raw ? <>{formatRawCompact(raw, r.quote.decimals)} <span className="rp-unit">{r.quote.symbol}</span></> : <span className="rp-muted">—</span>;

/** Session-local watch stars — a viewing aid only, never persisted or economic. */
function useWatched() {
  const [watched, setWatched] = useState<Record<string, boolean>>({});
  return [watched, (id: string) => setWatched((prev) => ({ ...prev, [id]: !prev[id] }))] as const;
}

export function LaunchTable({ rows, view, now, onHover, empty }: { rows: DiscoveryRow[]; view: 'list' | 'grid'; now: number; onHover?: (r: DiscoveryRow) => void; empty?: string }) {
  const [watched, toggleWatch] = useWatched();
  if (!rows.length) return <EmptyState title="No launches match these filters" text={empty ?? 'Try another lifecycle or pair.'}/>;
  if (view === 'grid') return <ul className="rp-grid-cards" aria-label="Launches">{rows.map((r) => {
    const dir = changeDirection(r.change24hBps);
    const isWatched = !!watched[r.id];
    return <li key={r.id}><Link href={r.href} className="rp-card" onMouseEnter={() => onHover?.(r)} onFocus={() => onHover?.(r)} data-testid="launch-card">
      <div className="rp-card-top">
        <TokenIdentity name={r.symbol} symbol={r.name} icon={r.icon} logo={r.logo} quote={r.quote} size="sm"/>
        <span className="rp-card-side">
          {r.dataMode === 'demo' && <DemoBadge/>}
          <button type="button" className={cx('rp-watch', isWatched && 'is-watched')} aria-pressed={isWatched} aria-label={isWatched ? `Unwatch ${r.symbol}` : `Watch ${r.symbol}`} onClick={(e) => { e.preventDefault(); e.stopPropagation(); toggleWatch(r.id); }}><Star size={14} aria-hidden/></button>
        </span>
      </div>
      <div className="rp-card-mid">
        <div><small>Price</small><strong>{r.priceX18 ? <>{formatPriceX18(r.priceX18)} <span className="rp-unit">{r.quote.symbol}</span></> : '—'}</strong>
          <small className={`rp-${dir}`}>{dir === 'none' ? '—' : formatBps(r.change24hBps, true)}</small></div>
        <Sparkline closes={r.closes} label={`${r.symbol} price history${r.dataMode === 'demo' ? ' (simulated)' : ''}`}/>
      </div>
      <DiscoveryBondingProgress row={r}/>
      <div className="rp-card-foot"><span>MCap {value(r.marketCapRaw, r)}</span><span>Vol {value(r.volume24hRaw, r)}</span></div>
    </Link></li>;
  })}</ul>;
  return <div className="rp-table-wrap"><table className="rp-table rp-launch-table" aria-label="Launches">
    <thead><tr>
      <th scope="col">Token</th><th scope="col" className="rp-p1">Pair & bonding</th><th scope="col" className="rp-p2">Graph</th>
      <th scope="col" className="rp-right">Price</th><th scope="col" className="rp-right">Market cap</th>
      <th scope="col" className="rp-right rp-p2">Liquidity</th><th scope="col" className="rp-right">Volume 24h</th>
      <th scope="col" className="rp-right rp-p3">Lifetime volume</th><th scope="col" className="rp-right rp-p3">Trades 24h</th>
    </tr></thead>
    <tbody>{rows.map((r) => {
      const dir = changeDirection(r.change24hBps);
      const isWatched = !!watched[r.id];
      return <tr key={r.id} onMouseEnter={() => onHover?.(r)} data-testid="launch-row">
        <td data-label="Token"><div className="rp-row-token"><Link href={r.href} className="rp-row-link" onFocus={() => onHover?.(r)}><TokenIdentity name={r.name} symbol={r.symbol} icon={r.icon} logo={r.logo} quote={r.quote} size="sm"><div className="rp-row-meta"><LifecycleBadge lifecycle={r.lifecycle}/>{r.dataMode === 'demo' && <DemoBadge/>}<span>{ageFrom(r.createdAt, now)}</span></div></TokenIdentity></Link><button type="button" className={cx('rp-watch', isWatched && 'is-watched')} aria-pressed={isWatched} aria-label={isWatched ? `Unwatch ${r.symbol}` : `Watch ${r.symbol}`} onClick={() => toggleWatch(r.id)}><Star size={13} aria-hidden/></button></div></td>
        <td data-label="Pair" className="rp-p1"><span className="rp-badge rp-pair">{r.symbol}/{r.quote.symbol}</span><DiscoveryBondingProgress row={r}/></td>
        <td data-label="Graph" className="rp-p2"><Sparkline closes={r.closes} label={`${r.symbol} price history${r.dataMode === 'demo' ? ' (simulated)' : ''}`}/></td>
        <td data-label="Price" className="rp-right"><div>{r.priceX18 ? <>{formatPriceX18(r.priceX18)} <span className="rp-unit">{r.quote.symbol}</span></> : '—'}</div><small className={`rp-${dir}`}>{dir === 'none' ? '' : formatBps(r.change24hBps, true)}</small></td>
        <td data-label="Market cap" className="rp-right">{value(r.marketCapRaw, r)}</td>
        <td data-label="Liquidity" className="rp-right rp-p2">{value(r.liquidityRaw, r)}</td>
        <td data-label="Volume 24h" className="rp-right">{value(r.volume24hRaw, r)}</td>
        <td data-label="Lifetime volume" className="rp-right rp-p3">{value(r.lifetimeVolumeRaw, r)}</td>
        <td data-label="Trades 24h" className="rp-right rp-p3">{r.trades24h ?? '—'}</td>
      </tr>;
    })}</tbody>
  </table></div>;
}
