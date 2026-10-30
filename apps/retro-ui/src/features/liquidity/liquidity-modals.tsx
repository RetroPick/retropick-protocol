'use client';
// Honest rebuild of the example-ui-ux liquidity modals. The donor's visuals
// (2-step add-liquidity flow, vault detail sheet) are preserved, but every
// number is real: balances are chain reads, vault parameters come from the
// block-pinned SDK liquidity read, and there is NO deposit execution — public
// LP deposits/mints/withdrawals are not enabled on RetroPick (graduation LP
// is permanently protocol-locked). The confirm affordance states that reason
// and routes to Market Making, the real two-sided liquidity flow.
import { useEffect, useMemo, useRef, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { zeroAddress, type Address } from 'viem';
import { CheckCircle2, ChevronRight, Droplets, Shield, TrendingUp, X } from 'lucide-react';
import Link from '@/components/product/safe-link';
import { tokenAbi } from '@retropick/launchpad-sdk/abis/tokenAbi';
import { publicClient } from '@/lib/live/public-client';
import { launchKeys } from '@/lib/live/queries';
import { DATA_MODE } from '@/lib/live/env';
import { useWallet } from '@/wallet/provider';
import { useKuruLiquidity } from '@/hooks/use-kuru-liquidity';
import { liquidityView } from '@/lib/view-models/liquidity';
import { formatPriceX18, formatRaw, formatRawCompact } from '@/lib/view-models/token-terminal';
import type { IndexedLiquidityPool } from '@retropick/launchpad-sdk/read-model';
import { AddressChip, DemoBadge, SkeletonLine } from '@/components/trading/primitives';
import { calculateDefaultPriceRange, calculateDepositAmounts, generateDistributionBars, type VolatilityStrategy } from './liquidity-math';
import './liquidity.css';

const LP_DISABLED_REASON = 'Public LP deposits, minting and withdrawals are not enabled on RetroPick. Graduation LP shares are permanently protocol-protected.';

function useEscape(isOpen: boolean, onClose: () => void) {
  useEffect(() => {
    if (!isOpen) return;
    const onKey = (e: KeyboardEvent) => { if (e.key === 'Escape') onClose(); };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [isOpen, onClose]);
}

/** Real wallet balance for one asset (native MON via getBalance, ERC-20 via balanceOf). */
function useAssetBalance(address: string | null) {
  const wallet = useWallet();
  const account = DATA_MODE === 'live' ? wallet.account : null;
  const enabled = !!account && !!address;
  const q = useQuery({
    queryKey: launchKeys.wallet(account ?? 'disconnected', `asset-balance:${address ?? 'none'}`),
    enabled,
    queryFn: async () => address === zeroAddress
      ? await publicClient.getBalance({ address: account! })
      : BigInt(await publicClient.readContract({ address: address as Address, abi: tokenAbi, functionName: 'balanceOf', args: [account!] })),
    refetchInterval: 15_000, structuralSharing: false, retry: 0,
  });
  return { raw: q.data ?? null, status: !enabled ? 'off' : q.isError ? 'error' : q.data === null ? 'loading' : 'ready' as const };
}

const STRATEGIES: Array<{ id: VolatilityStrategy; name: string; tagline: string; desc: string }> = [
  { id: 'spot', name: 'Spot Strategy', tagline: 'Standard CLOB distribution', desc: 'Balanced limit orders spread evenly across the price range. The general shape for two-sided markets.' },
  { id: 'curve', name: 'Curve Strategy', tagline: 'Concentrated around mid-price', desc: 'Tighter clustering near the current price for volume efficiency on quieter markets.' },
  { id: 'bidask', name: 'Bid / Ask Skew', tagline: 'Wide perimeter bounds', desc: 'Depth toward the range edges — suited to mean-reverting, volatile assets.' },
];

export function AddLiquidityModal({ pool, currentPrice, isOpen, onClose }: {
  pool: IndexedLiquidityPool; currentPrice: number | null; isOpen: boolean; onClose: () => void;
}) {
  const [step, setStep] = useState<1 | 2>(1);
  const [strategy, setStrategy] = useState<VolatilityStrategy>('spot');
  const [feeTier, setFeeTier] = useState(0.05);
  const [minPrice, setMinPrice] = useState('');
  const [maxPrice, setMaxPrice] = useState('');
  const [baseInput, setBaseInput] = useState('');
  const [quoteInput, setQuoteInput] = useState('');
  const closeRef = useRef<HTMLButtonElement>(null);
  useEscape(isOpen, onClose);
  const base = pool.baseSymbol, quote = pool.quoteSymbol;
  const mmHref = `/liquidity/market-making?token=${pool.token}`;

  // Auto-range from the REAL market price when one exists (launch join / best
  // ask). No price → user enters the range manually; nothing is invented.
  useEffect(() => {
    if (!isOpen || currentPrice === null) return;
    const r = calculateDefaultPriceRange(currentPrice, strategy, feeTier);
    setMinPrice(String(r.minPrice)); setMaxPrice(String(r.maxPrice));
  }, [isOpen, strategy, feeTier, currentPrice]);

  useEffect(() => { if (isOpen) { setStep(1); closeRef.current?.focus(); } }, [isOpen]);

  const bars = useMemo(() => {
    const lo = Number(minPrice), hi = Number(maxPrice);
    if (!Number.isFinite(lo) || !Number.isFinite(hi) || hi <= lo) return [];
    return generateDistributionBars(lo, hi, currentPrice ?? (lo + hi) / 2, strategy, 20);
  }, [minPrice, maxPrice, currentPrice, strategy]);

  const sync = (side: 'base' | 'quote', value: string) => {
    const lo = Number(minPrice), hi = Number(maxPrice);
    if (!Number.isFinite(lo) || !Number.isFinite(hi) || hi <= lo || currentPrice === null) {
      side === 'base' ? setBaseInput(value) : setQuoteInput(value);
      return;
    }
    const baseNum = Number((side === 'base' ? value : baseInput) || 0);
    const quoteNum = Number((side === 'quote' ? value : quoteInput) || 0);
    const out = calculateDepositAmounts(baseNum, quoteNum, currentPrice, lo, hi, side);
    setBaseInput(side === 'base' ? value : out.baseRequired.toFixed(6));
    setQuoteInput(side === 'quote' ? value : out.quoteRequired.toFixed(4));
  };

  if (!isOpen) return null;
  return <div className="rp-modal-overlay" onClick={onClose} role="presentation">
    <div className="rp-modal-box" role="dialog" aria-modal="true" aria-label={`Add liquidity to ${base} / ${quote}`} onClick={(e) => e.stopPropagation()}>
      <div className="rp-modal-header">
        <div className="rp-modal-title-row">
          <span className="rp-pair-icons" aria-hidden="true">
            <span className="rp-token-dot">{base[0]}</span><span className="rp-token-dot">{quote[0]}</span>
          </span>
          <div><h3>Add liquidity · {base}/{quote}</h3><p className="rp-modal-subtitle">Kuru vault market · preview only</p></div>
        </div>
        <button ref={closeRef} className="rp-modal-close" onClick={onClose} aria-label="Close modal"><X size={18} aria-hidden/></button>
      </div>

      <div className="rp-modal-steps" role="tablist" aria-label="Add liquidity steps">
        <button className={`rp-step-btn${step === 1 ? ' active' : ''}`} role="tab" aria-selected={step === 1} onClick={() => setStep(1)}><span>1</span>Strategy</button>
        <button className={`rp-step-btn${step === 2 ? ' active' : ''}`} role="tab" aria-selected={step === 2} onClick={() => setStep(2)}><span>2</span>Range &amp; deposit</button>
      </div>

      {step === 1 ? <div className="rp-modal-content">
        <p className="rp-section-label">Order distribution preview <small className="rp-modal-hint">(illustrative — shapes how two-sided maker orders could be spread)</small></p>
        <div className="rp-strategy-grid" role="group" aria-label="Distribution strategy preview">
          {STRATEGIES.map((s) => (
            <button key={s.id} type="button" className={`rp-strategy-card${strategy === s.id ? ' selected' : ''}`} onClick={() => setStrategy(s.id)} aria-pressed={strategy === s.id}>
              <span className="rp-strategy-head"><span className="rp-strategy-name">{s.name}</span>{strategy === s.id && <CheckCircle2 size={15} aria-hidden/>}</span>
              <span className="rp-strategy-tagline">{s.tagline}</span>
              <span className="rp-strategy-desc">{s.desc}</span>
            </button>
          ))}
        </div>
        <p className="rp-modal-note">Fee tiers are fixed per market by Kuru market parameters — they are not user-selectable here. Live maker/taker fees are shown on the Market Making desk.</p>
        <div className="rp-modal-actions">
          <button className="rp-mbtn-secondary" onClick={onClose}>Cancel</button>
          <button className="rp-mbtn-primary" onClick={() => setStep(2)}>Next: range &amp; deposit<ChevronRight size={14} aria-hidden/></button>
        </div>
      </div> : <div className="rp-modal-content">
        <p className="rp-price-banner">Current price:{' '}
          {currentPrice !== null ? <strong className="rp-text-pos">{currentPrice.toFixed(4)}</strong> : <strong>—</strong>}
          <span className="rp-dim"> ({quote} per {base}{currentPrice === null ? ' · unavailable until a qualified market read or indexed trade exists' : ''})</span>
        </p>
        <div className="rp-dist-box" aria-label="Illustrative order distribution preview">
          <div className="rp-dist-head"><span>Order distribution preview ({strategy})</span>
            <span className="rp-dist-legend"><span className="dot bid"/>Bids <span className="dot ask"/>Asks</span></div>
          <div className="rp-dist-bars" aria-hidden="true">
            {bars.length ? bars.map((b, i) => <span key={i} className={`rp-bar ${b.type}`} style={{ height: `${b.heightPercent}%` }} title={`Price: ${b.label}`}/>)
              : <span className="rp-dim rp-dist-empty">Enter a price range to preview the distribution.</span>}
          </div>
          <div className="rp-dist-range-labels"><span>Min {minPrice || '—'}</span><span>Max {maxPrice || '—'}</span></div>
        </div>
        <div className="rp-range-inputs">
          <label>Min price ({quote})<input type="number" step="0.0001" min="0" value={minPrice} onChange={(e) => setMinPrice(e.target.value)} aria-label={`Minimum price in ${quote}`}/></label>
          <label>Max price ({quote})<input type="number" step="0.0001" min="0" value={maxPrice} onChange={(e) => setMaxPrice(e.target.value)} aria-label={`Maximum price in ${quote}`}/></label>
        </div>
        <div className="rp-deposit-inputs">
          <BalanceField label={`Deposit ${base}`} symbol={base} address={pool.baseAsset} value={baseInput} onChange={(v) => sync('base', v)}/>
          <BalanceField label={`Deposit ${quote}`} symbol={quote} address={pool.quoteAsset} value={quoteInput} onChange={(v) => sync('quote', v)}/>
        </div>
        <div className="rp-modal-actions">
          <button className="rp-mbtn-secondary" onClick={() => setStep(1)}>Back</button>
          <div className="rp-modal-cta-wrap">
            <button className="rp-mbtn-primary" disabled title={LP_DISABLED_REASON}>Public LP deposits not enabled</button>
            <Link className="rp-mm-route" href={mmHref} onClick={onClose}>Provide liquidity via Market Making →</Link>
          </div>
        </div>
        <p className="rp-modal-note">{LP_DISABLED_REASON}</p>
      </div>}
    </div>
  </div>;
}

function BalanceField({ label, symbol, address, value, onChange }: { label: string; symbol: string; address: string; value: string; onChange: (v: string) => void }) {
  const { raw, status } = useAssetBalance(address);
  return <label className="rp-input-group">{label}
    <span className="rp-input-label-row"><span className="rp-balance">{status === 'ready' && raw !== null ? `Bal: ${formatRaw(raw.toString(), 18, 4)} ${symbol}` : status === 'off' ? 'Bal: connect a wallet' : status === 'error' ? 'Bal: unavailable' : 'Bal: reading…'}</span></span>
    <span className="rp-input-wrap"><input type="number" min="0" step="any" value={value} onChange={(e) => onChange(e.target.value)} aria-label={label}/><span className="rp-input-token" aria-hidden="true">{symbol}</span></span>
  </label>;
}

/** Vault detail sheet: every value from the block-pinned SDK liquidity read. */
export function VaultDetailModal({ pool, isOpen, onClose }: { pool: IndexedLiquidityPool; isOpen: boolean; onClose: () => void }) {
  const closeRef = useRef<HTMLButtonElement>(null);
  useEscape(isOpen, onClose);
  useEffect(() => { if (isOpen) closeRef.current?.focus(); }, [isOpen]);
  const live = DATA_MODE === 'live' && /^0x[\da-f]{40}$/i.test(pool.token);
  const q = useKuruLiquidity(pool.token, undefined, live);
  const view = live ? liquidityView(pool.token, q.data, { loading: q.isPending, error: q.isError ? (q.error as Error).message : null, stale: !!q.data && (q.isError || Date.now() - q.dataUpdatedAt >= 20_000) }) : null;
  if (!isOpen) return null;
  const base = pool.baseSymbol, quote = pool.quoteSymbol;
  return <div className="rp-modal-overlay" onClick={onClose} role="presentation">
    <div className="rp-modal-box rp-modal-vault" role="dialog" aria-modal="true" aria-label={`${base} / ${quote} vault details`} onClick={(e) => e.stopPropagation()}>
      <div className="rp-modal-header">
        <div className="rp-modal-title-row">
          <span className="rp-pair-icons" aria-hidden="true">
            <span className="rp-token-dot">{base[0]}</span><span className="rp-token-dot">{quote[0]}</span>
          </span>
          <div><h3>{base}/{quote} vault</h3><p className="rp-modal-subtitle">Automated Kuru order-book vault · Monad Testnet</p></div>
        </div>
        <button ref={closeRef} className="rp-modal-close" onClick={onClose} aria-label="Close modal"><X size={18} aria-hidden/></button>
      </div>
      <div className="rp-modal-content">
        {!live ? <p className="rp-modal-note"><DemoBadge/> Demo fixture vault — switch to live mode for on-chain vault reads.</p>
        : !view || view.status === 'loading' ? <div role="status" aria-label="Reading vault state">{Array.from({ length: 4 }, (_, i) => <SkeletonLine key={i} height={18}/>)}</div>
        : view.status === 'unavailable' ? <p className="rp-modal-note" role="alert">Vault read unavailable{view.error ? `: ${view.error}` : ''}. This does not establish zero balances.</p>
        : <>
          <div className="rp-vault-banner">
            <div><span className="rp-vault-apr-label">Vault quoting band</span>
              <span className="rp-vault-apr-num">{view.vaultState.bidX18 !== null && view.vaultState.askX18 !== null ? `${formatPriceX18(view.vaultState.bidX18)} / ${formatPriceX18(view.vaultState.askX18)}` : '—'} <small>{quote}</small></span>
            </div>
            <div className="rp-vault-banner-stats">
              <span>Chain block <strong>{view.block ? `#${view.block}` : '—'}</strong></span>
              <span>{view.status === 'stale' ? 'Snapshot stale' : 'Snapshot live'}</span>
            </div>
          </div>
          <dl className="rp-vault-facts">
            <div><dt>AMM {base} inventory</dt><dd>{pool.baseAssetsRaw !== null ? `${formatRawCompact(pool.baseAssetsRaw, pool.baseDecimals)} ${base}` : 'Unavailable'}</dd></div>
            <div><dt>AMM {quote} inventory</dt><dd>{pool.quoteAssetsRaw !== null ? `${formatRawCompact(pool.quoteAssetsRaw, pool.quoteDecimals)} ${quote}` : 'Unavailable'}</dd></div>
            <div><dt>Total LP shares</dt><dd>{pool.totalSharesRaw !== null ? formatRawCompact(pool.totalSharesRaw, view.shareDecimals ?? 18) : '—'}</dd></div>
            <div><dt>Protected shares <Shield size={12} aria-label="protocol lock"/></dt><dd>{pool.protectedSharesRaw !== null ? formatRawCompact(pool.protectedSharesRaw, view.shareDecimals ?? 18) : '—'}</dd></div>
            <div><dt>Infrastructure shares</dt><dd>{pool.infrastructureSharesRaw !== null ? formatRawCompact(pool.infrastructureSharesRaw, view.shareDecimals ?? 18) : '—'}</dd></div>
            <div><dt>Best combined bid / ask <TrendingUp size={12} aria-label="market"/></dt><dd>{view.best.bidX18 !== null ? formatPriceX18(view.best.bidX18) : 'No bid'} / {view.best.askX18 !== null ? formatPriceX18(view.best.askX18) : 'No ask'} {quote}</dd></div>
            <div><dt>Market state <Droplets size={12} aria-label="state"/></dt><dd>{view.best.paused === null ? 'Unknown' : view.best.paused ? 'Paused' : 'Active'}</dd></div>
          </dl>
          <div className="rp-vault-chips">
            <span>Market <AddressChip value={pool.market} label="market"/></span>
            <span>Vault <AddressChip value={pool.vault} label="vault"/></span>
            {pool.lpLock && <span>Lock <AddressChip value={pool.lpLock} label="liquidity lock"/></span>}
          </div>
          <p className="rp-modal-note">Graduation LP shares are held by the permanent protocol lock — they are not tradeable or withdrawable through this interface. No APR or fee-yield is displayed: no verified source exists.</p>
          <div className="rp-modal-actions">
            <button className="rp-mbtn-secondary" onClick={onClose}>Close</button>
            <Link className="rp-mm-route" href={`/liquidity/market-making?token=${pool.token}`} onClick={onClose}>Provide liquidity via Market Making →</Link>
          </div>
        </>}
      </div>
    </div>
  </div>;
}
