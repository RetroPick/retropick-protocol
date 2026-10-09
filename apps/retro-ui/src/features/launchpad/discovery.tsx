'use client';

import './feed.css';

import Link from '@/components/product/safe-link';
import { Empty, Segments, Spark, TokenIcon } from '@/components/product/ui';
import { useDemo } from '@/components/product/provider';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { compact, date, money, SNAPSHOT } from '@/lib/domain/fixtures';
import { getInstrumentRoute } from '@/lib/domain/launchpad-adapters';
import { launchInstruments, queryLaunchInstruments, type InstrumentSort } from '@/lib/domain/launchpad-repository';
import { useLaunchInstruments } from '@/hooks/use-launch-instruments';
import type { LaunchInstrument } from '@/lib/domain/instruments';
import type { LaunchpadType } from '@/lib/domain/launchpad-types';
import { ArrowRight, ArrowUpRight, Bolt, Droplets, Flame, Layers, LayoutGrid, List, Plus, ShieldCheck, Sprout, Star } from 'lucide-react';
import { usePathname, useRouter, useSearchParams } from '@/lib/next-compat';
import { type ReactNode, useState } from 'react';

const launchTypes: { value: LaunchpadType; label: string }[] = [
  { value: 'all', label: 'All' },
  { value: 'prediction', label: 'Prediction' },
  { value: 'crypto', label: 'Crypto' },
  { value: 'stocks', label: 'Stocks' },
];
const predictionTopics = ['all', 'Crypto', 'Macro', 'Technology', 'Sports', 'Watchlist'];
const sortOptions = [
  { value: 'trending', label: 'Trending', Icon: Flame },
  { value: 'volume', label: 'Vol 24h', Icon: Bolt },
  { value: 'new', label: 'New', Icon: Sprout },
  { value: 'liquidity', label: 'Liquidity', Icon: Droplets },
] as const;

const kindLabel = (item: LaunchInstrument) => item.kind === 'prediction' ? 'Prediction' : item.kind === 'prism' ? 'PRISM' : item.referenceClass === 'stock' ? 'Stock paired' : 'Crypto';
const kindClass = (item: LaunchInstrument) => item.kind === 'prediction' ? 'prediction' : item.referenceClass === 'stock' ? 'stocks' : 'crypto';
const iconFor = (item: LaunchInstrument) => ({ icon: item.icon ?? '◇', color: item.color ?? '#b09cfa' });
const tokenPrice = (value: number) => value < 0.1 ? `$${value.toFixed(5)}` : money(value);
const amount = (value: number | bigint | null) => value === null ? '—' : compact(Number(value));
const price = (item: LaunchInstrument) => item.price === null ? '—' : tokenPrice(Number(item.price));
const metaFor = (item: LaunchInstrument) => item.kind === 'prediction' ? `${item.prediction?.topic} · ${item.symbol}` : `${item.pair?.symbol ?? '—'} pair · ${item.symbol}`;

function ageLabel(createdAt: string | null) {
  if (!createdAt) return 'demo';
  const ageHours = Math.max(0, Math.floor((Date.parse(SNAPSHOT) - Date.parse(createdAt)) / 3_600_000));
  if (ageHours < 24) return ageHours ? `${ageHours}h ago` : 'just now';
  const ageDays = Math.floor(ageHours / 24);
  return ageDays === 1 ? 'yesterday' : `${ageDays}d ago`;
}
function Snapshot({ item }: { item: LaunchInstrument }) {
  if (item.kind === 'prediction' && item.prediction) return <div className="price-pair"><span className="yes-price">Y {(item.prediction.yesPrice * 100).toFixed(0)}¢</span><span className="no-price">N {(item.prediction.noPrice * 100).toFixed(1)}¢</span></div>;
  return <strong>{price(item)}</strong>;
}
function FeedMetric({ value, note }: { value: string; note?: ReactNode }) {
  return <div className="feed-metric"><strong>{value}</strong>{note && <small>{note}</small>}</div>;
}
function changeLabel(item: LaunchInstrument) {
  if (item.change24h === null) return '—';
  return `${item.change24h >= 0 ? '+' : ''}${item.change24h.toFixed(1)}${item.prediction?.priceChangeUnit === 'cents' ? '¢' : '%'}`;
}

/** One compact feed for every kind: token, prediction market and PRISM. */
function TokenFeedTable({ items, watch, toggleWatch }: { items: LaunchInstrument[]; watch: string[]; toggleWatch: (id: string) => void }) {
  return <Table className="market-table o1-feed-table token-feed-table"><TableHeader><TableRow><TableHead>Token</TableHead><TableHead>Price</TableHead><TableHead>24h change</TableHead><TableHead>Volume 24h</TableHead><TableHead>Liquidity</TableHead><TableHead className="feed-action-head">Trade</TableHead></TableRow></TableHeader><TableBody>{items.map((item, index) => <TableRow key={item.id}><TableCell><div className="feed-token-with-watch"><Link href={getInstrumentRoute(item)} className="market-cell feed-token-cell"><TokenIcon market={iconFor(item)} small/><span><strong>{item.name} <em>{item.kind === 'prediction' ? '' : item.symbol}</em></strong><small><span className={`listing-type ${kindClass(item)}`}>{kindLabel(item)}</span>{item.kind === 'prediction' ? `resolves ${item.prediction ? date(item.prediction.resolutionDate) : '—'}` : `${item.pair?.symbol ?? '—'} · ${ageLabel(item.createdAt)}`}</small></span></Link>{item.kind === 'prediction' && <button className={`icon-button ${watch.includes(item.id) ? 'saved' : ''}`} aria-label={`Watch ${item.symbol}`} aria-pressed={watch.includes(item.id)} onClick={() => toggleWatch(item.id)}><Star size={15} fill={watch.includes(item.id) ? 'currentColor' : 'none'}/></button>}</div></TableCell><TableCell><Snapshot item={item}/></TableCell><TableCell><div className="feed-change"><span className={item.change24h === null ? '' : item.change24h >= 0 ? 'positive' : 'negative'}>{changeLabel(item)}</span>{item.change24h !== null && <Spark seed={index + 7} negative={item.change24h < 0}/>}</div></TableCell><TableCell><FeedMetric value={amount(item.volume24h)}/></TableCell><TableCell><FeedMetric value={amount(item.liquidity)}/></TableCell><TableCell><Link href={getInstrumentRoute(item)} className="feed-trade" aria-label={`Trade ${item.symbol ?? item.name}`}>Trade <Bolt size={14}/></Link></TableCell></TableRow>)}</TableBody></Table>;
}

function FeaturedCard({ item, watch, toggleWatch }: { item: LaunchInstrument; watch: string[]; toggleWatch: (id: string) => void }) {
  const prediction = item.kind === 'prediction';
  const change = item.change24h ?? 0;
  const quote = item.pair?.symbol ?? '—';
  return <article className="featured-card"><div className="card-top"><span className="category-tag">{kindLabel(item)}</span>{prediction ? <button aria-label={`Watch ${item.symbol}`} aria-pressed={watch.includes(item.id)} className={`icon-button ${watch.includes(item.id) ? 'saved' : ''}`} onClick={() => toggleWatch(item.id)}><Star size={16} fill={watch.includes(item.id) ? 'currentColor' : 'none'}/></button> : <span className="tag">{quote} PAIR</span>}</div><div className="featured-title"><TokenIcon market={iconFor(item)}/><Link href={getInstrumentRoute(item)}><h3>{item.name}</h3></Link></div><div className="featured-chart"><div>{prediction ? <><span className="big-price">{Math.round((item.prediction?.yesPrice ?? 0) * 100)}<small>¢</small></span><span className={change >= 0 ? 'positive' : 'negative'}>{changeLabel(item)} <small>24h</small></span><span className="muted small-label">Outcome market price</span></> : <><span className="big-price">{price(item)}</span><span className={change >= 0 ? 'positive' : 'negative'}>{changeLabel(item)} <small>24h</small></span><span className="muted small-label">Launch token price</span></>}</div><Spark seed={item.id.length} large negative={change < 0}/></div>{prediction ? <div className="outcome-buttons"><Link href={`${getInstrumentRoute(item)}?outcome=YES`} className="yes">Buy YES <strong>{((item.prediction?.yesPrice ?? 0) * 100).toFixed(0)}¢</strong></Link><Link href={`${getInstrumentRoute(item)}?outcome=NO`} className="no">Buy NO <strong>{((item.prediction?.noPrice ?? 0) * 100).toFixed(1)}¢</strong></Link></div> : <div className="outcome-buttons"><Link href={getInstrumentRoute(item)} className="yes">Open token <strong>{quote}</strong></Link><Link href="/docs" className="no">Read disclosure <ArrowUpRight size={14}/></Link></div>}<div className="card-footer"><span>{amount(item.volume24h)} vol.</span><span>{prediction ? item.prediction ? date(item.prediction.resolutionDate) : '—' : item.token?.stockReference ?? `Curve ${Math.round((item.token?.curveProgressBps ?? 0) / 100)}%`} <ArrowUpRight size={13}/></span></div></article>;
}

export default function LaunchpadDiscovery() {
  const params = useSearchParams(); const router = useRouter(); const pathname = usePathname(); const { watch, toggleWatch } = useDemo(); const [view, setView] = useState<'list' | 'grid'>('list');
  const rawType = params.get('type'); const type: LaunchpadType = rawType === 'prediction' || rawType === 'crypto' || rawType === 'stocks' ? rawType : 'all'; const topic = params.get('predictionTopic') || 'all'; const rawSort = params.get('sort'); const sort: InstrumentSort = rawSort === 'volume' || rawSort === 'new' || rawSort === 'liquidity' ? rawSort : 'trending';
  const setParam = (key: string, value: string) => { const next = new URLSearchParams(params.toString()); next.set(key, value); router.replace(`${pathname}?${next.toString()}`, { scroll: false }); };
  const setType = (value: string) => { const next = new URLSearchParams(params.toString()); if (value === 'all') next.delete('type'); else next.set('type', value); next.delete('predictionTopic'); router.replace(`${pathname}${next.size ? `?${next.toString()}` : ''}`, { scroll: false }); };
  const filtered = useLaunchInstruments({ type, predictionTopic: type === 'prediction' && topic !== 'Watchlist' ? topic : undefined, watchlist: type === 'prediction' && topic === 'Watchlist' ? watch : undefined, sort });
  const crypto = queryLaunchInstruments({ type: 'crypto' }).filter((item) => item.kind === 'token'); const stocks = queryLaunchInstruments({ type: 'stocks' }).filter((item) => item.kind === 'token'); const predictions = queryLaunchInstruments({ type: 'prediction' });
  const spotlight = type === 'prediction' ? predictions.slice(0, 2) : type === 'crypto' ? crypto.slice(0, 2) : type === 'stocks' ? stocks.slice(0, 2) : [crypto[0], stocks[0]].filter((item): item is LaunchInstrument => Boolean(item));
  const prism = launchInstruments.find((item) => item.kind === 'prism');
  const featureLabel = type === 'prediction' ? 'Prediction launches' : type === 'all' ? 'Featured launches' : type === 'stocks' ? 'Stock-paired launches' : 'Crypto launches';
  return <><section className="page-heading"><div><h1>Launch tokens.<br/><span>Trade what&apos;s next.</span></h1><p>Crypto, stock-paired and prediction launches.</p></div><Link className="btn primary" href="/launchpad/create"><Plus size={17}/>Launch token</Link></section><section className="featured-section"><div className="section-title"><h2><Flame size={17}/> {featureLabel}</h2></div><div className="featured-grid">{spotlight.map((item) => <FeaturedCard key={item.id} item={item} watch={watch} toggleWatch={toggleWatch}/>)}<article className="prism-feature"><div className="card-top"><span className="prism-word"><Layers size={17}/> PRISM</span><span className="tag purple">STRUCTURED</span></div><h3>One position.<br/>More possibilities.</h3><p>Combine event outcomes into a fully backed basket.</p><div className="composition-mini"><div><span>FED <b>YES</b></span><strong>{(prism?.prism?.components[0]?.unitsPerShare ?? 0) * 100}%</strong></div><div><span>BTC <b>NO</b></span><strong>{(prism?.prism?.components[1]?.unitsPerShare ?? 0) * 100}%</strong></div><div className="composition-track"><span/></div></div><Link href={prism ? getInstrumentRoute(prism) : '/prism'} className="prism-link">Explore PRISM <ArrowUpRight size={18}/></Link></article></div></section><section className="explorer"><div className="explorer-heading"><h2>Explore <span className="count">{filtered.length}</span></h2><div className="view-switch"><button className={view === 'list' ? 'active' : ''} aria-label="Table view" aria-pressed={view === 'list'} onClick={() => setView('list')}><List size={17}/></button><button className={view === 'grid' ? 'active' : ''} aria-label="Card view" aria-pressed={view === 'grid'} onClick={() => setView('grid')}><LayoutGrid size={16}/></button></div></div><div className="feed-controls"><div className="type-filter"><Segments label="Launchpad type" values={launchTypes.map((entry) => entry.value)} value={type} onChange={setType} labels={Object.fromEntries(launchTypes.map((entry) => [entry.value, entry.label]))}/></div><div className="sort-buttons o1-sort-buttons" aria-label="Sort launchpad feed">{sortOptions.map(({ value, label, Icon }) => <button className={sort === value ? 'selected' : ''} key={value} onClick={() => setParam('sort', value)}><Icon size={13}/> {label}</button>)}</div></div>{type === 'prediction' && <div className="category-row"><Segments label="Prediction event topics" values={predictionTopics} value={topic} onChange={(value) => setParam('predictionTopic', value)} labels={{ all: 'All topics' }}/></div>}{!filtered.length ? <Empty title="No launchpad listings found" text="Try another category or topic."/> : view === 'grid' ? <div className="market-grid">{filtered.map((item) => <Link className="market-grid-card" href={getInstrumentRoute(item)} key={item.id}><TokenIcon market={iconFor(item)}/><span className={`listing-type ${kindClass(item)}`}>{kindLabel(item)}</span><h3>{item.name}</h3><Snapshot item={item}/><small>{amount(item.volume24h)} volume · {metaFor(item)}</small></Link>)}</div> : <div className="feed-stacks"><div className="feed-block"><TokenFeedTable items={filtered} watch={watch} toggleWatch={toggleWatch}/></div></div>}<div className="table-footer"><span>Showing {filtered.length} of {launchInstruments.length} demo listings</span></div></section><div className="bottom-note"><ShieldCheck size={15}/><span>All listings are illustrative demo data.</span><Link href="/docs">How it works <ArrowRight size={14}/></Link></div></>;
}
