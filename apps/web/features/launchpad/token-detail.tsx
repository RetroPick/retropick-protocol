'use client';

import Link from '@/components/product/safe-link';
import { Empty, Segments, Spark, Stat, TokenIcon } from '@/components/product/ui';
import { compact, money } from '@/lib/domain/fixtures';
import { getLaunchInstrument } from '@/lib/domain/launchpad-repository';
import { ArrowLeft, CandlestickChart, Info, Landmark } from 'lucide-react';
import { useState } from 'react';

function lifecycleCopy(state: string) {
  if (state === 'GRADUATED') return 'Graduated · Kuru is the intended mature venue in this demo. Execution is not connected.';
  if (state === 'GRADUATION_READY') return 'Graduation threshold reached. Destination setup is pending; this is not a successful migration.';
  if (state === 'GRADUATING') return 'Destination setup is pending. Trading remains a demo fixture.';
  return 'Trading on the RetroPick bonding curve. Graduation moves only after the configured threshold is met.';
}
function tokenPrice(value: number) {
  return value < 0.1 ? `$${value.toFixed(5)}` : money(value);
}

export default function TokenDetail({ id }: { id: string }) {
  const token = getLaunchInstrument(id);
  const [side, setSide] = useState('Buy');
  const [amount, setAmount] = useState('');
  const [tab, setTab] = useState('Overview');
  if (!token || token.kind !== 'token') return <Empty title="Token launch not found" text="This demo token may have been removed from the Launchpad fixture."/>;
  const stock = token.referenceClass === 'stock';
  const quoteAsset = token.pair?.symbol ?? '—';
  const tokenValue = (value: number | bigint | null) => value === null ? '—' : compact(Number(value));
  const currentPrice = Number(token.price ?? 0);
  const change = token.change24h ?? 0;
  const lifecycle = token.status;
  const progress = Math.round((token.token?.curveProgressBps ?? 0) / 100);
  return <div className="token-detail-page"><Link className="back-link" href={`/launchpad?type=${stock ? 'stocks' : 'crypto'}`}><ArrowLeft size={14}/>Back to Launchpad</Link><section className="token-detail-heading"><TokenIcon market={{ icon: token.icon ?? '◇', color: token.color ?? '#b09cfa' }}/><div><div className="card-top"><span className={`launch-kind-badge ${(stock ? 'stock_paired_token' : 'crypto_token')}`}>{stock ? 'Stock-paired' : 'Crypto token'}</span><span className="demo-pill">DEMO</span></div><h1>{token.name} <span>{token.symbol}</span></h1><p>{token.description}</p><div className="meta-row"><span>Pair {quoteAsset}</span><span>Creator {token.creator}</span><span>Address not deployed</span><span>{lifecycle.replaceAll('_', ' ')}</span></div></div></section>{stock && <div className="notice stock-disclosure"><Landmark size={17}/><span>Paired against a tokenized stock asset. The launched token is not itself equity in {token.token?.stockReference}.</span></div>}<section className="token-detail-stats"><Stat label="Price" value={tokenPrice(currentPrice)} note={`${change >= 0 ? '+' : ''}${change.toFixed(1)}% · 24h`}/><Stat label="Market cap" value={tokenValue(token.marketCap)} note="DEMO snapshot"/><Stat label="Liquidity" value={tokenValue(token.liquidity)} note="Curve reserve · demo"/><Stat label="24h volume" value={tokenValue(token.volume24h)} note={`${token.trades24h} demo trades`}/></section><div className="workspace token-terminal"><section><div className="panel token-chart-panel"><div className="chart-top"><div><span className="eyebrow">ILLUSTRATIVE PRICE HISTORY</span><h2>{token.symbol} / {quoteAsset}</h2></div><span className="chart-price">{tokenPrice(currentPrice)} <span className={change >= 0 ? 'positive' : 'negative'}>{change >= 0 ? '+' : ''}{change.toFixed(1)}%</span></span></div><div className="token-chart"><CandlestickChart size={32}/><Spark seed={token.id.length} large/></div><p className="chart-caption">Illustrative fixture only. No indexed price feed or live Kuru market is connected.</p></div><div className="panel launch-progress"><div className="section-title"><h2>Launch progress</h2><span>{lifecycle.replaceAll('_', ' ')}</span></div><div className="progress-track"><span style={{ width: `${progress}%` }}/></div><div className="progress-values"><strong>{progress}%</strong><span>{tokenValue(token.liquidity)} / {compact(43_000)} target</span></div><p>{lifecycleCopy(lifecycle)}</p></div><div className="panel token-tabs"><Segments label="Token detail sections" values={['Overview', 'Trades', 'Holders', 'Protocol']} value={tab} onChange={setTab}/>{tab === 'Overview' && <dl className="detail-list"><dt>Launch kind</dt><dd>{stock ? 'Stock-paired normal token' : 'Crypto normal token'}</dd><dt>Primary venue</dt><dd>{token.token?.primaryVenue} · DEMO</dd><dt>Mature venue</dt><dd>{token.token?.matureVenue} · planned / no adapter</dd><dt>Pair asset</dt><dd>{quoteAsset} · DEMO</dd><dt>Lifecycle</dt><dd>{lifecycle}</dd></dl>}{tab === 'Trades' && <p className="empty-copy">No live trades are available. The 24h count above is illustrative fixture data.</p>}{tab === 'Holders' && <p className="empty-copy">Holder data requires an admitted indexer; no holders are fabricated in this demo.</p>}{tab === 'Protocol' && <div className="notice"><Info size={16}/><span>Token deployment, curve parameters, fees and any Kuru listing must come from reviewed configuration. This screen does not provide execution.</span></div>}</div></section><aside className="rail desktop-ticket"><div className="panel token-trade-ticket"><h2>Trade <small>Demo only</small></h2><Segments label="Trade side" values={['Buy', 'Sell']} value={side} onChange={setSide}/><label className="field"><span>You {side === 'Buy' ? 'pay' : 'sell'}</span><input inputMode="decimal" value={amount} onChange={(event) => setAmount(event.target.value)} placeholder="0"/><small>{side === 'Buy' ? quoteAsset : token.symbol}</small></label><dl className="quote-lines"><div><span>Estimated receive</span><strong>{amount ? `${(Number(amount) / currentPrice).toLocaleString(undefined, { maximumFractionDigits: 2 })} ${side === 'Buy' ? token.symbol : quoteAsset}` : '—'}</strong></div><div><span>Price</span><strong>{tokenPrice(currentPrice)}</strong></div><div><span>Fees</span><strong>Protocol configured</strong></div><div><span>Slippage / price impact</span><strong>Unavailable</strong></div></dl><button className="btn primary full" disabled>{side} unavailable</button><p className="ticket-note">A verified wallet and venue adapter are required before any real trade can be shown.</p></div></aside></div><div className="mobile-trade"><span>{tokenPrice(currentPrice)} · {quoteAsset}</span><button className="btn primary" disabled>Trade unavailable</button></div></div>;
}
