'use client';

import Link from '@/components/product/safe-link';
import { Empty, Segments, Spark, Stat, TokenIcon } from '@/components/product/ui';
import { compact, money } from '@/lib/domain/fixtures';
import { getLaunchInstrument } from '@/lib/domain/launchpad-repository';
import { DATA_MODE } from '@/lib/live/env';
import { useLaunchDetail } from '@/hooks/use-launch-detail';
import { bpsToPercent, priceToDisplay, rawToDisplay, shortAddress } from '@/lib/live/format';
import { buyQuote, minOutput, parseExact, sellQuote } from '@retropick/launchpad-sdk/math';
import { prepareCurveBuy, prepareCurveSell, prepareFactoryGraduate, prepareCoordinatorComplete } from '@retropick/launchpad-sdk/prepare';
import { decodeCurveTrade, decodeGraduation } from '@retropick/launchpad-sdk/decode';
import { executePreparedWrite, type TxPhase } from '@/services/tx-pipeline';
import { useWallet } from '@/wallet/provider';
import { publicClient } from '@/lib/live/public-client';
import { toast } from 'sonner';
import { ArrowLeft, CandlestickChart, Info, Landmark } from 'lucide-react';
import { useMemo, useState } from 'react';

function lifecycleCopy(state: string, live: boolean) {
  if (state === 'GRADUATED') return live
    ? 'Graduated to the Kuru orderbook. Bonding-curve trading is closed; trade on Kuru.'
    : 'Graduated · Kuru is the intended mature venue in this demo. Execution is not connected.';
  if (state === 'GRADUATION_READY') return live
    ? 'Graduation threshold reached. Trigger the graduation transaction to move liquidity to the mature venue.'
    : 'Graduation threshold reached. Destination setup is pending; this is not a successful migration.';
  if (state === 'GRADUATING') return live
    ? 'Graduation is in progress. If it stalled, completing the transition is a permissionless retry.'
    : 'Destination setup is pending. Trading remains a demo fixture.';
  return 'Trading on the RetroPick bonding curve. Graduation moves only after the configured threshold is met.';
}
function tokenPrice(value: number) {
  return value < 0.1 ? `$${value.toFixed(5)}` : money(value);
}

function LiveSparkline({ points }: { points: number[] }) {
  if (points.length < 2) return <Spark seed={11} large />;
  const min = Math.min(...points);
  const max = Math.max(...points);
  const span = max - min || 1;
  const path = points.map((value, index) => `${(index / (points.length - 1)) * 100},${28 - ((value - min) / span) * 26}`).join(' ');
  const positive = points[points.length - 1] >= points[0];
  return <svg viewBox="0 0 100 30" preserveAspectRatio="none" className="live-sparkline" role="img" aria-label="Price history"><polyline points={path} fill="none" stroke={positive ? '#3ddc97' : '#ff6b81'} strokeWidth="1.4" vectorEffect="non-scaling-stroke"/></svg>;
}

/** Live bonding-curve ticket: real quote math, exact amounts, pipeline execution. */
function LiveTicket({ onchain, quoteSymbol, reload, graduateReady, phase }: {
  onchain: NonNullable<ReturnType<typeof useLaunchDetail>['launch']>;
  quoteSymbol: string;
  reload: () => void;
  graduateReady: boolean;
  phase: string;
}) {
  const wallet = useWallet();
  const [side, setSide] = useState('Buy');
  const [amount, setAmount] = useState('');
  const [slippageBps, setSlippageBps] = useState('50');
  const [tx, setTx] = useState<TxPhase | { kind: 'idle' }>({ kind: 'idle' });
  const [error, setError] = useState('');
  const decimals = onchain.packet.quoteDecimals ?? 18;
  const busy = tx.kind !== 'idle' && tx.kind !== 'failed';
  const bonding = Number(onchain.ledger.phase) === 0;

  const quote = useMemo(() => {
    if (!amount || !bonding) return null;
    try {
      const [quoteReserve, tokenReserve] = onchain.reserves;
      if (side === 'Buy') {
        const quoteIn = parseExact(amount, decimals);
        const out = buyQuote(quoteIn, quoteReserve, tokenReserve, onchain.remaining, onchain.fee, onchain.tax);
        return out > 0n ? { expected: out, min: minOutput(out, BigInt(slippageBps)), unit: onchain.symbol, scaled: 18 } : null;
      }
      const tokensIn = parseExact(amount, 18);
      if (tokensIn > onchain.balance) return null;
      const out = sellQuote(tokensIn, tokenReserve, quoteReserve, onchain.fee, onchain.tax);
      return out > 0n ? { expected: out, min: minOutput(out, BigInt(slippageBps)), unit: quoteSymbol, scaled: decimals } : null;
    } catch {
      return null;
    }
  }, [amount, side, onchain, bonding, slippageBps, decimals, quoteSymbol]);

  const submit = async () => {
    if (!wallet.wallet || !wallet.account) return;
    setError('');
    try {
      const prepared = side === 'Buy'
        ? await prepareCurveBuy(publicClient, onchain.token, wallet.account, { quoteIn: parseExact(amount, decimals), slippageBps: BigInt(slippageBps) })
        : await prepareCurveSell(publicClient, onchain.token, wallet.account, { tokensIn: parseExact(amount, 18), slippageBps: BigInt(slippageBps) });
      const result = await executePreparedWrite(publicClient, wallet.wallet, prepared, { onPhase: setTx });
      if (result.kind === 'success') {
        const events = decodeCurveTrade(result.receipt.logs);
        toast.success(`${side} confirmed`, { description: events.map((event) => event.eventName).join(', ') || result.hash });
        setAmount('');
        setTx({ kind: 'idle' });
        reload();
      } else {
        setError(result.reason);
        setTx({ kind: 'idle' });
      }
    } catch (cause) {
      console.error('[live-ticket] trade failed', cause);
      setError(cause instanceof Error ? cause.message : 'Trade failed.');
      setTx({ kind: 'idle' });
    }
  };

  const graduate = async () => {
    if (!wallet.wallet || !wallet.account) return;
    setError('');
    try {
      const prepared = Number(onchain.ledger.phase) === 0
        ? await prepareFactoryGraduate(publicClient, onchain.token, wallet.account)
        : await prepareCoordinatorComplete(publicClient, onchain.token, wallet.account);
      const result = await executePreparedWrite(publicClient, wallet.wallet, prepared, { onPhase: setTx });
      if (result.kind === 'success') {
        toast.success('Graduation transaction confirmed', { description: decodeGraduation(result.receipt.logs).map((event) => event.eventName).join(' → ') || result.hash });
        setTx({ kind: 'idle' });
        reload();
      } else {
        setError(result.reason);
        setTx({ kind: 'idle' });
      }
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : 'Graduation failed.');
      setTx({ kind: 'idle' });
    }
  };

  const phaseLabel = tx.kind === 'approving' ? 'Approving…' : tx.kind === 'simulating' ? 'Simulating…' : tx.kind === 'awaiting-signature' ? 'Confirm in wallet…' : tx.kind === 'broadcasting' ? 'Broadcasting…' : tx.kind === 'confirming' ? 'Confirming…' : '';

  return <div className="panel token-trade-ticket">
    <h2>Trade <small>Live · Monad 10143</small></h2>
    {bonding && <Segments label="Trade side" values={['Buy', 'Sell']} value={side} onChange={setSide}/>}
    {bonding ? <>
      <label className="field"><span>You {side === 'Buy' ? 'pay' : 'sell'}</span><input inputMode="decimal" value={amount} onChange={(event) => setAmount(event.target.value)} placeholder="0"/><small>{side === 'Buy' ? quoteSymbol : onchain.symbol}</small></label>
      <label className="field"><span>Slippage tolerance</span>
        <select value={slippageBps} onChange={(event) => setSlippageBps(event.target.value)} aria-label="Slippage tolerance">
          <option value="10">0.1%</option><option value="50">0.5%</option><option value="200">2.0%</option>
        </select>
        <small>Applied as an exact minimum on the signed transaction.</small>
      </label>
      <dl className="quote-lines">
        <div><span>Estimated receive</span><strong>{quote ? `${Number(quote.expected) / 10 ** quote.scaled} ${quote.unit}` : '—'}</strong></div>
        <div><span>Minimum received</span><strong>{quote ? `${Number(quote.min) / 10 ** quote.scaled} ${quote.unit}` : '—'}</strong></div>
        <div><span>Fees</span><strong>{Number(onchain.fee) / 100}% + {Number(onchain.tax) / 100}% creator</strong></div>
        <div><span>Your balance</span><strong>{side === 'Buy' ? 'wallet MON' : `${Number(onchain.balance) / 1e18} ${onchain.symbol}`}</strong></div>
      </dl>
    </> : <p className="ticket-note">The bonding curve has closed. Graduated tokens trade on the Kuru orderbook.</p>}
    {error && <div role="alert" className="form-error">{error}</div>}
    {busy && phaseLabel && <div role="status" className="ticket-note" data-tx-phase={tx.kind}>{phaseLabel}</div>}
    {wallet.status !== 'connected'
      ? <button className="btn primary full" onClick={() => void wallet.connect().catch(() => {})}>{wallet.status === 'wrong-chain' ? 'Wrong chain — switch' : 'Connect wallet'}</button>
      : wallet.status === 'connected' && wallet.chainId !== 10143
        ? <button className="btn primary full" onClick={() => void wallet.switchChain()}>Switch to Monad Testnet</button>
        : bonding
          ? <button className="btn primary full" disabled={busy || !quote} onClick={submit}>{busy ? 'Working…' : `${side} ${onchain.symbol}`}</button>
          : null}
    {wallet.status === 'connected' && wallet.chainId === 10143 && (graduateReady || phase === 'GRADUATING') && (
      <button className="btn full" disabled={busy} onClick={graduate} style={{ marginTop: 10 }}>
        {phase === 'GRADUATING' ? 'Complete graduation (retry)' : 'Graduate to Kuru'}
      </button>
    )}
    <p className="ticket-note">Signed through your wallet after an on-chain simulation. Partial fills and refunds follow the deployed curve rules.</p>
  </div>;
}

export default function TokenDetail({ id }: { id: string }) {
  const liveAddress = DATA_MODE === 'live' && /^0x[0-9a-fA-F]{40}$/.test(id);
  const wallet = useWallet();
  const detail = useLaunchDetail(liveAddress ? id : null, liveAddress ? (wallet.account ?? undefined) : undefined);
  const reload = detail.reload;
  const fixture = liveAddress ? undefined : getLaunchInstrument(id);
  const [side, setSide] = useState('Buy');
  const [amount, setAmount] = useState('');
  const [tab, setTab] = useState('Overview');

  const view = useMemo(() => {
    if (!liveAddress) {
      if (!fixture || fixture.kind !== 'token') return null;
      const stock = fixture.referenceClass === 'stock';
      return {
        live: false as const, name: fixture.name, symbol: fixture.symbol ?? '', description: fixture.description ?? '',
        icon: fixture.icon ?? '◇', color: fixture.color ?? '#b09cfa', creator: fixture.creator ?? '—', stock,
        quoteAsset: fixture.pair?.symbol ?? '—', price: Number(fixture.price ?? 0), change: fixture.change24h ?? 0,
        lifecycle: fixture.status as string, progress: Math.round((fixture.token?.curveProgressBps ?? 0) / 100),
        marketCap: fixture.marketCap === null ? null : Number(fixture.marketCap), liquidity: fixture.liquidity === null ? null : Number(fixture.liquidity),
        volume24h: fixture.volume24h === null ? null : Number(fixture.volume24h), trades24h: fixture.trades24h,
        candles: [] as number[], trades: [] as { side: string; price: string; size: string; time: string }[], holders: null as number | null,
        address: null as string | null, market: null as string | null, feeBps: null as number | null, taxBps: null as number | null,
        primaryVenue: fixture.token?.primaryVenue ?? '', matureVenue: fixture.token?.matureVenue ?? '',
      };
    }
    const indexed = detail.indexed;
    const onchain = detail.launch;
    if (!onchain) return null;
    const decimals = indexed?.quoteDecimals ?? 18;
    const lifecycle = Number(onchain.ledger.phase) === 2 ? 'GRADUATED' : Number(onchain.ledger.phase) === 1 ? 'GRADUATING' : 'GRADUATION_READY' as string;
    const phase = Number(onchain.ledger.phase) === 2 ? 'GRADUATED' : Number(onchain.ledger.phase) === 1 ? 'GRADUATING' : (indexed?.phase ?? 'ACTIVE') === 'ACTIVE' ? 'CURVE' : 'GRADUATION_READY';
    const [quoteReserve, tokenReserve] = onchain.reserves;
    const terminal = onchain.completion[0] ?? 0n;
    const progress = phase === 'CURVE' && terminal > 0n ? Math.min(100, Number(quoteReserve * 10_000n / terminal)) : phase === 'CURVE' ? (indexed?.bondingProgressBps ?? 0) / 100 : 100;
    return {
      live: true as const, name: onchain.name, symbol: onchain.symbol, description: indexed?.description ?? '',
      icon: '◈', color: '#7ef0c0', creator: indexed?.creator ?? shortAddress(onchain.packet.token), stock: false,
      quoteAsset: indexed?.quoteSymbol ?? 'MON', price: priceToDisplay(indexed?.priceRaw ?? null) ?? 0,
      change: bpsToPercent(indexed?.change24hBps ?? null) ?? 0, lifecycle: phase, progress,
      marketCap: rawToDisplay(indexed?.marketCapRaw ?? null, decimals), liquidity: rawToDisplay(indexed?.quoteReserveRaw ?? null, decimals),
      volume24h: rawToDisplay(indexed?.volume24hRaw ?? null, decimals), trades24h: indexed?.trades24h ?? null,
      candles: detail.candles.map((candle) => Number(candle.close)).filter((value) => Number.isFinite(value)),
      trades: detail.trades.slice(0, 30).map((trade) => ({
        side: trade.side, price: (Number(trade.priceRaw) / 1e18).toPrecision(4),
        size: compact(Number(trade.tokensRaw) / 1e18), time: new Date(trade.timestamp * 1000).toLocaleTimeString(),
      })),
      holders: indexed?.holderCount ?? null, address: onchain.token, market: detail.kuru ? (indexed?.market ?? null) : null,
      feeBps: Number(onchain.fee), taxBps: Number(onchain.tax),
      primaryVenue: 'RetroPick bonding market', matureVenue: (indexed?.venue ?? 'KURU') === 'KURU' ? 'Kuru orderbook' : 'Uniswap V4',
      onchain,
    };
  }, [liveAddress, fixture, detail]);

  // Read-only live quote preview from real curve state (SDK bigint math); the
  // button stays disabled until the wallet/transaction engine ships. Must stay
  // above every early return to keep hook order stable across render phases.
  const preview = useMemo(() => {
    const onchain = detail.launch;
    if (!liveAddress || !onchain || !amount || Number(onchain.ledger.phase) !== 0) return null;
    try {
      const [quoteReserve, tokenReserve] = onchain.reserves;
      if (side === 'Buy') {
        const quoteIn = parseExact(amount, 18);
        return `${Number(buyQuote(quoteIn, quoteReserve, tokenReserve, onchain.remaining, onchain.fee, onchain.tax)) / 1e18} ${onchain.symbol}`;
      }
      const tokensIn = parseExact(amount, 18);
      return `${Number(sellQuote(tokensIn, tokenReserve, quoteReserve, onchain.fee, onchain.tax)) / 1e18} MON`;
    } catch {
      return null;
    }
  }, [liveAddress, detail.launch, amount, side]);

  if (liveAddress && detail.status === 'loading') return <Empty title="Loading launch…" text="Reading the RetroPick V2 contracts on Monad Testnet."/>;
  if (!view) return liveAddress
    ? <Empty title="Launch not found on-chain" text={detail.error ?? 'This address is not a RetroPick V2 launch token on Monad Testnet (chain 10143).'}/>
    : <Empty title="Token launch not found" text="This demo token may have been removed from the Launchpad fixture."/>;

  const stock = view.stock;
  const quoteAsset = view.quoteAsset;
  const tokenValue = (value: number | null) => value === null ? '—' : compact(value);
  const currentPrice = view.price;
  const change = view.change;
  const lifecycle = view.lifecycle;
  const progress = Math.round(view.progress);
  return <div className="token-detail-page"><Link className="back-link" href={`/launchpad?type=${stock ? 'stocks' : 'crypto'}`}><ArrowLeft size={14}/>Back to Launchpad</Link><section className="token-detail-heading"><TokenIcon market={{ icon: view.icon, color: view.color }}/><div><div className="card-top"><span className={`launch-kind-badge ${(stock ? 'stock_paired_token' : 'crypto_token')}`}>{stock ? 'Stock-paired' : 'Crypto token'}</span><span className="demo-pill">{view.live ? 'LIVE · 10143' : 'DEMO'}</span></div><h1>{view.name} <span>{view.symbol}</span></h1><p>{view.description || 'No description provided.'}</p><div className="meta-row"><span>Pair {quoteAsset}</span><span>Creator {view.creator}</span><span>{view.live ? `Address ${shortAddress(view.address ?? '')}` : 'Address not deployed'}</span><span>{lifecycle.replaceAll('_', ' ')}</span></div></div></section>{stock && <div className="notice stock-disclosure"><Landmark size={17}/><span>Paired against a tokenized stock asset. The launched token is not itself equity in {fixture?.token?.stockReference}.</span></div>}<section className="token-detail-stats"><Stat label="Price" value={tokenPrice(currentPrice)} note={`${change >= 0 ? '+' : ''}${change.toFixed(1)}% · 24h`}/><Stat label="Market cap" value={tokenValue(view.marketCap)} note={view.live ? 'Last trade · onchain' : 'DEMO snapshot'}/><Stat label="Liquidity" value={tokenValue(view.liquidity)} note={view.live ? (lifecycle === 'GRADUATED' ? 'Seeded quote' : 'Curve quote reserve') : 'Curve reserve · demo'}/><Stat label="24h volume" value={tokenValue(view.volume24h)} note={`${view.trades24h ?? 0} ${view.live ? 'indexed trades' : 'demo trades'}`}/></section><div className="workspace token-terminal"><section><div className="panel token-chart-panel"><div className="chart-top"><div><span className="eyebrow">{view.live ? 'INDEXED PRICE HISTORY' : 'ILLUSTRATIVE PRICE HISTORY'}</span><h2>{view.symbol} / {quoteAsset}</h2></div><span className="chart-price">{tokenPrice(currentPrice)} <span className={change >= 0 ? 'positive' : 'negative'}>{change >= 0 ? '+' : ''}{change.toFixed(1)}%</span></span></div><div className="token-chart"><CandlestickChart size={32}/>{view.live ? <LiveSparkline points={view.candles}/> : <Spark seed={view.name.length} large/>}</div><p className="chart-caption">{view.live ? (detail.freshness ? `Indexed through block ${detail.freshness.indexedBlock} (lag ${detail.freshness.lagBlocks}).` : 'Indexer history temporarily unavailable; on-chain state is live.') : 'Illustrative fixture only. No indexed price feed or live Kuru market is connected.'}</p></div><div className="panel launch-progress"><div className="section-title"><h2>Launch progress</h2><span>{lifecycle.replaceAll('_', ' ')}</span></div><div className="progress-track"><span style={{ width: `${progress}%` }}/></div><div className="progress-values"><strong>{progress}%</strong><span>{tokenValue(view.liquidity)} quote {view.live ? 'reserve' : `/ ${compact(43_000)} target`}</span></div><p>{lifecycleCopy(lifecycle, view.live)}</p></div><div className="panel token-tabs"><Segments label="Token detail sections" values={['Overview', 'Trades', 'Holders', 'Protocol']} value={tab} onChange={setTab}/>{tab === 'Overview' && <dl className="detail-list"><dt>Launch kind</dt><dd>{stock ? 'Stock-paired normal token' : 'Crypto normal token'}</dd><dt>Primary venue</dt><dd>{view.primaryVenue}{view.live ? '' : ' · DEMO'}</dd><dt>Mature venue</dt><dd>{view.matureVenue} · {view.live ? (view.market ? `market ${shortAddress(view.market)}` : lifecycle === 'GRADUATED' ? 'see coordinator receipt' : 'after graduation') : 'planned / no adapter'}</dd><dt>Pair asset</dt><dd>{quoteAsset} · {view.live ? 'quote registry admitted' : 'DEMO'}</dd><dt>Lifecycle</dt><dd>{lifecycle}</dd></dl>}{tab === 'Trades' && (view.live ? (view.trades.length ? <table className="detail-trades"><thead><tr><th>Side</th><th>Price</th><th>Size</th><th>Time</th></tr></thead><tbody>{view.trades.map((trade, index) => <tr key={index}><td className={trade.side === 'buy' ? 'positive' : 'negative'}>{trade.side}</td><td>{trade.price}</td><td>{trade.size}</td><td>{trade.time}</td></tr>)}</tbody></table> : <p className="empty-copy">No indexed trades for this launch yet.</p>) : <p className="empty-copy">No live trades are available. The 24h count above is illustrative fixture data.</p>)}{tab === 'Holders' && (view.live ? <p className="empty-copy">{view.holders === null ? 'Holder count is not indexed yet.' : `${view.holders} indexed holders (from Transfer events).`}</p> : <p className="empty-copy">Holder data requires an admitted indexer; no holders are fabricated in this demo.</p>)}{tab === 'Protocol' && <div className="notice"><Info size={16}/><span>{view.live ? `Curve fee ${view.feeBps ?? '—'} bps · creator tax ${view.taxBps ?? '—'} bps · sellable ${(Number('remaining' in view.onchain ? view.onchain.remaining : 0n) / 1e18).toLocaleString()} tokens. State read directly from the deployed contracts.` : 'Token deployment, curve parameters, fees and any Kuru listing must come from reviewed configuration. This screen does not provide execution.'}</span></div>}</div></section><aside className="rail desktop-ticket">{view.live && detail.launch ? <LiveTicket onchain={detail.launch} quoteSymbol={quoteAsset} reload={reload} graduateReady={detail.readyToGraduate} phase={lifecycle}/> : <div className="panel token-trade-ticket"><h2>Trade <small>Demo only</small></h2><Segments label="Trade side" values={['Buy', 'Sell']} value={side} onChange={setSide}/><label className="field"><span>You {side === 'Buy' ? 'pay' : 'sell'}</span><input inputMode="decimal" value={amount} onChange={(event) => setAmount(event.target.value)} placeholder="0"/><small>{side === 'Buy' ? quoteAsset : view.symbol}</small></label><dl className="quote-lines"><div><span>Estimated receive</span><strong>{preview ?? '—'}</strong></div><div><span>Price</span><strong>{tokenPrice(currentPrice)}</strong></div><div><span>Fees</span><strong>Protocol configured</strong></div><div><span>Slippage / price impact</span><strong>Unavailable</strong></div></dl><button className="btn primary full" disabled>{side} unavailable</button><p className="ticket-note">A verified wallet and venue adapter are required before any real trade can be shown.</p></div>}</aside></div><div className="mobile-trade"><span>{tokenPrice(currentPrice)} · {quoteAsset}</span>{view.live && detail.launch && Number(detail.launch.ledger.phase) === 0 ? <span>Open the trade panel above</span> : <button className="btn primary" disabled>Trade unavailable</button>}</div></div>;
}
