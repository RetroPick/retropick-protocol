'use client';

import Link from '@/components/product/safe-link';
import { Check, ChevronRight, ImagePlus, ShieldCheck } from 'lucide-react';
import { useEffect, useMemo, useState, type ChangeEvent } from 'react';
import { approvedPairAssets } from '@/lib/domain/launchpad-fixtures';
import type { LaunchpadType } from '@/lib/domain/launchpad-types';
import { useDemo } from '@/components/product/provider';
import { useWallet } from '@/wallet/provider';
import { DATA_MODE } from '@/lib/live/env';
import { publicClient } from '@/lib/live/public-client';
import { rawToDisplay } from '@/lib/live/format';
import { readLaunchPreconditions, type LaunchPreconditions } from '@retropick/launchpad-sdk/registry';
import { prepareLaunchToken } from '@retropick/launchpad-sdk/prepare';
import { decodeTokenLaunched } from '@retropick/launchpad-sdk/decode';
import { parseExact } from '@retropick/launchpad-sdk/math';
import { executePreparedWrite, type TxPhase } from '@/services/tx-pipeline';
import type { Address, Hash } from 'viem';
import CreateMarket from '@/features/create-market/wizard';

type CreationType = Exclude<LaunchpadType, 'all'>;
type FeeDestination = 'feeWallet' | 'buybackVest' | 'holders';

const LAUNCH_FEE = '0.0005 ETH';
const GRADUATES_AT = '4.20 ETH';
const CURVE_FEE = '1.0%';
const SUPPLY = '1,000,000,000';

const feeDestinations: { id: FeeDestination; title: string; body: string; supportedLive: boolean }[] = [
  { id: 'feeWallet', title: 'Your fee wallet', body: 'Fees accrue to your fee wallet to claim.', supportedLive: true },
  { id: 'buybackVest', title: 'Buyback & vest', body: 'Part of each creator fee buys the token back; bought tokens lock and release to your fee escrow over time, with a protocol share on release.', supportedLive: true },
  { id: 'holders', title: 'Holders', body: 'Fee distribution to holders is not supported by the deployed V2 contracts.', supportedLive: false },
];

function LaunchStepper({ active }: { active: number }) {
  const steps = ['Identity', 'Economics'];
  return <div className="stepper token-stepper" aria-label="Token launch progress">{steps.map((step, index) => <div className={index === active ? 'current' : index < active ? 'done' : ''} key={step} aria-current={index === active ? 'step' : undefined}><b>{index < active ? <Check size={13}/> : index + 1}</b>{step}</div>)}</div>;
}

type LivePhase = { kind: 'idle' } | TxPhase;

function TokenLaunchWizard({ type }: { type: 'crypto' | 'stocks' }) {
  const isStock = type === 'stocks';
  const demo = useDemo();
  const wallet = useWallet();
  const live = DATA_MODE === 'live';
  const [step, setStep] = useState(0);
  const [done, setDone] = useState<null | { token: string; hash: Hash }>(null);
  const [error, setError] = useState('');
  const [image, setImage] = useState('');
  const [imageName, setImageName] = useState('');
  const [feeDestination, setFeeDestination] = useState<FeeDestination>('feeWallet');
  const [showVestDetail, setShowVestDetail] = useState(false);
  const [venue, setVenue] = useState<'KURU' | 'UNISWAP_V4'>('KURU');
  const [form, setForm] = useState({ name: '', ticker: '', description: '', x: '', telegram: '', website: '', pair: 'MON', feeWallet: '', creatorFee: '0', openingBuy: '0' });
  const [preconditions, setPreconditions] = useState<LaunchPreconditions | null>(null);
  const [preconditionsError, setPreconditionsError] = useState<string | null>(null);
  const [phase, setPhase] = useState<LivePhase>({ kind: 'idle' });
  const fixturePairs = approvedPairAssets.filter((asset) => isStock ? asset.assetClass === 'STOCK_QUOTE' : asset.assetClass === 'CRYPTO');
  const pairOptions = live ? [] : [{ id: 'ETH', symbol: 'ETH', name: 'Ether' }, ...fixturePairs];
  const set = (key: keyof typeof form, value: string) => setForm((current) => ({ ...current, [key]: value }));

  // Live launch terms come from the deployed factory/registry, never constants.
  useEffect(() => {
    if (!live) return;
    let active = true;
    void readLaunchPreconditions(publicClient, wallet.account ?? undefined)
      .then((value) => { if (active) { setPreconditions(value); setPreconditionsError(null); } })
      .catch((cause) => { if (active) setPreconditionsError(cause instanceof Error ? cause.message : 'Could not read launch terms.'); });
    return () => { active = false; };
  }, [live, wallet.account]);

  const config = useMemo(() => preconditions?.configs.find((entry) => entry.enabled) ?? preconditions?.configs[0] ?? null, [preconditions]);
  const admittedQuotes = useMemo(() => {
    if (!preconditions) return [] as { id: string; symbol: string; name: string; venues: ('KURU' | 'UNISWAP_V4')[]; thresholdRaw: bigint; decimals: number }[];
    const byAddress = new Map<string, { id: string; symbol: string; name: string; venues: ('KURU' | 'UNISWAP_V4')[]; thresholdRaw: bigint; decimals: number }>();
    for (const quote of preconditions.quotes) {
      const key = quote.address.toLowerCase();
      const venueName = quote.venue === 1 ? 'KURU' : 'UNISWAP_V4';
      const existing = byAddress.get(key);
      if (existing) existing.venues.push(venueName);
      else byAddress.set(key, { id: quote.address, symbol: quote.symbol, name: quote.address === '0x0000000000000000000000000000000000000000' ? 'Native Monad' : quote.address, venues: [venueName], thresholdRaw: quote.graduationThreshold, decimals: quote.decimals });
    }
    return [...byAddress.values()];
  }, [preconditions]);
  const livePair = admittedQuotes.find((quote) => quote.id.toLowerCase() === form.pair.toLowerCase()) ?? admittedQuotes[0];
  const venuesForPair = livePair?.venues ?? [];
  const activeVenue = venuesForPair.includes(venue) ? venue : venuesForPair[0] ?? 'KURU';
  const launchFeeMon = preconditions ? rawToDisplay(preconditions.launchFee.toString(), 18) : null;
  const thresholdDisplay = livePair && preconditions ? rawToDisplay(livePair.thresholdRaw.toString(), livePair.decimals) : null;
  const maxCreatorFeePercent = preconditions ? Number(preconditions.maxCreatorTaxBps) / 100 : 10;
  const pair = live ? { symbol: livePair?.symbol ?? 'MON', name: livePair?.name ?? 'Native Monad' } : (pairOptions.find((asset) => asset.id === form.pair) ?? pairOptions[0]);

  const onImage = (event: ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;
    if (file.size > 5 * 1024 * 1024 || !['image/png', 'image/jpeg', 'image/webp'].includes(file.type)) {
      setError('Use a square PNG, JPEG or WebP image up to 5 MB.');
      return;
    }
    setError('');
    const reader = new FileReader();
    reader.onload = () => { setImage(String(reader.result)); setImageName(file.name); };
    reader.readAsDataURL(file);
  };

  const canContinue = () => {
    if (!form.name.trim()) return 'Give your token a name.';
    if (!/^[A-Z0-9]{2,10}$/.test(form.ticker)) return 'Ticker needs 2\u201310 uppercase letters or digits.';
    if (form.description.length > 256) return 'Keep the description within 256 characters.';
    return '';
  };
  const canLaunch = () => {
    const fee = Number(form.creatorFee);
    if (!Number.isFinite(fee) || fee < 0) return 'Creator fee must be zero or greater.';
    if (live) {
      if (fee > maxCreatorFeePercent) return `Creator fee must be at most ${maxCreatorFeePercent}% (factory limit).`;
      if (preconditions?.canLaunch === false) return 'This wallet is not authorized to launch right now.';
      if (!config?.enabled) return 'No enabled launch configuration is live on the factory.';
      if (!livePair) return 'No admitted quote asset is available for this venue.';
      if (feeDestination === 'holders') return 'Holder fee distribution is not supported by the deployed contracts.';
    } else {
      if (fee > 10) return 'Creator fee must be between 0 and 10.0%.';
      const buy = Number(form.openingBuy);
      if (!Number.isFinite(buy) || buy < 0) return 'Opening buy must be zero or greater.';
    }
    if (form.feeWallet.trim() && !/^0x[a-fA-F0-9]{40}$/.test(form.feeWallet.trim())) return 'Creator fee wallet must be a 0x address, or leave it empty to default to your wallet.';
    return '';
  };
  const next = () => { const issue = canContinue(); setError(issue); if (!issue) setStep(1); };

  const launchDemo = () => {
    try {
      localStorage.setItem('retropick-token-launch-draft', JSON.stringify({
        name: form.name, symbol: form.ticker, description: form.description,
        x: form.x, telegram: form.telegram, website: form.website,
        launchKind: isStock ? 'STOCK_PAIRED_TOKEN' : 'CRYPTO_TOKEN',
        quoteAsset: pair.symbol, feeWallet: form.feeWallet.trim() || null,
        creatorFee: Number(form.creatorFee), openingBuy: Number(form.openingBuy),
        feeDestination, supply: 1_000_000_000,
        provenance: 'DEMO',
      }));
      setError('');
      setDoneDemo(true);
    } catch { setError('This browser could not save the local demo draft.'); }
  };
  const [doneDemo, setDoneDemo] = useState(false);

  const launchLive = async () => {
    if (!wallet.wallet || !wallet.account || !config || !livePair) return;
    setPhase({ kind: 'idle' });
    try {
      const prepared = await prepareLaunchToken(publicClient, wallet.account, {
        name: form.name,
        symbol: form.ticker,
        logo: imageName,
        description: form.description,
        socials: { twitter: form.x, telegram: form.telegram, website: form.website },
        creatorFeeRecipient: (form.feeWallet.trim() || undefined) as Address | undefined,
        // hundredths of a percent are exactly basis points at two decimals
        creatorTaxBps: parseExact(form.creatorFee || '0', 2),
        buybackEnabled: feeDestination === 'buybackVest',
        launchConfigId: config.id,
        pairToken: livePair.id as Address,
        venue: activeVenue === 'KURU' ? 1 : 0,
      });
      const result = await executePreparedWrite(publicClient, wallet.wallet, prepared, { onPhase: setPhase });
      if (result.kind === 'success') {
        const launched = decodeTokenLaunched(result.receipt.logs);
        const token = launched ? String(launched.args.token) : '';
        if (!token) throw Error('TokenLaunched event not found in the receipt.');
        setDone({ token, hash: result.hash });
      } else {
        setError(result.reason);
        setPhase({ kind: 'idle' });
      }
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : 'Launch failed.');
      setPhase({ kind: 'idle' });
    }
  };

  if (done) return <div className="guide"><div className="panel success-page"><Check size={46} className="positive"/><h1>{form.name} is live.</h1><p>Deployed on Monad Testnet (chain 10143). Transaction <code className="tx-hash">{done.hash}</code></p><div className="notice">The bonding curve is open. Discovery updates as the indexer observes the launch.</div><div className="prism-actions"><Link href={`/launchpad/token/${done.token}`} className="btn primary">Open {form.ticker} <ChevronRight size={15}/></Link><Link href="/launchpad" className="btn">Explore Launchpad</Link></div></div></div>;
  if (doneDemo) return <div className="guide"><div className="panel success-page"><Check size={46} className="positive"/><h1>Your token launch draft is ready.</h1><p>{form.name || 'Your token'} remains a local DEMO draft. No token, pool, pair, contract address or onchain market was created — the curve does not open from this interface.</p><div className="notice">A real launch must use reviewed deployment configuration, an admitted quote-asset registry and a wallet-signed transaction.</div><div className="prism-actions"><Link href="/launchpad" className="btn primary">Explore Launchpad</Link><button className="btn" onClick={() => setDoneDemo(false)}>Edit draft</button></div></div></div>;

  const counter = (value: string, max: number) => <span className="char-counter">{value.length}/{max}</span>;
  const fieldWithCounter = (label: string, key: keyof typeof form, placeholder: string, max: number) => <label className="field"><span className="field-head"><span>{label}</span>{counter(form[key], max)}</span><input maxLength={max} value={form[key]} onChange={(event) => set(key, event.target.value)} placeholder={placeholder}/></label>;
  const phaseLabel = (value: LivePhase): string => {
    switch (value.kind) {
      case 'approving': return 'Approving quote asset…';
      case 'simulating': return 'Simulating launch…';
      case 'awaiting-signature': return 'Confirm in your wallet…';
      case 'broadcasting': return 'Broadcasting…';
      case 'confirming': return 'Waiting for receipt…';
      case 'preparing': return 'Preparing…';
      default: return '';
    }
  };
  const busy = phase.kind !== 'idle' && phase.kind !== 'failed';

  return <><div className="page-heading"><div><div className="eyebrow">{live ? 'CREATE LAUNCH · MONAD TESTNET' : 'CREATE LAUNCH · DEMO DRAFT'}</div><h1>Launch a token.</h1><p>Two steps. Give it a name and a face, choose what it trades against{live ? ', and the curve opens when your launch transaction confirms.' : ', and the curve opens the moment you sign.'}</p></div><span className="tag">{live ? 'LIVE · 10143' : 'NOT DEPLOYED'}</span></div><LaunchStepper active={step}/><div className="workspace token-create-workspace"><section className="panel">{step === 0 && <><div className="form-title"><h2>1 · Identity</h2><p>Give it a name and a face.</p></div><div className="image-picker"><span className="field-label">Image</span><div className="image-picker-row">{image ? <img src={image} alt="Token image preview" className="image-preview"/> : <span className="image-empty"><ImagePlus size={22}/></span>}<div><label className="btn image-choose"><input type="file" accept="image/png,image/jpeg,image/webp" onChange={onImage} aria-label="Choose token image"/>Choose image</label><small>{imageName || 'No file chosen'}</small><small>Square, up to 5 MB</small></div></div></div>{fieldWithCounter('Name', 'name', 'Retro Coin', 32)}<div className="form-grid">{fieldWithCounter('Ticker', 'ticker', 'RETRO', 10)}<div/></div><label className="field"><span className="field-head"><span>Description</span>{counter(form.description, 256)}</span><textarea maxLength={256} value={form.description} onChange={(event) => set('description', event.target.value)} placeholder="What is it, in a sentence or two. No links."/></label><div className="form-grid"><label className="field"><span>X</span><input value={form.x} onChange={(event) => set('x', event.target.value)} placeholder="handle or URL"/></label><label className="field"><span>Telegram</span><input value={form.telegram} onChange={(event) => set('telegram', event.target.value)} placeholder="username or t.me"/></label></div><label className="field"><span>Website</span><input value={form.website} onChange={(event) => set('website', event.target.value)} placeholder="https://"/></label></>}{step === 1 && <>{live ? <>
    <div className="form-title"><h2>2 · Economics</h2><p>Terms read live from the deployed factory.</p></div>
    {preconditionsError && <div role="alert" className="form-error">{preconditionsError}</div>}
    {!preconditions && !preconditionsError && <p className="empty-copy">Loading launch terms from the factory…</p>}
    {preconditions && <><label className="field"><span>Paired with</span><select value={livePair?.id ?? ''} onChange={(event) => set('pair', event.target.value)}>{admittedQuotes.map((quote) => <option value={quote.id} key={quote.id}>{quote.symbol} · {quote.name}</option>)}</select><small>Admitted by the on-chain quote registry. Buyers pay {livePair?.symbol} on the curve.</small></label>
    <div className="form-grid"><label className="field"><span>Graduates to</span><select value={activeVenue} onChange={(event) => setVenue(event.target.value === 'UNISWAP_V4' ? 'UNISWAP_V4' : 'KURU')}>{venuesForPair.map((name) => <option value={name} key={name}>{name === 'KURU' ? 'Kuru orderbook' : 'Uniswap V4'}</option>)}</select><small>Fixed by the venue you choose; {livePair?.venues.length === 2 ? 'both venues are admitted for this pair.' : 'only this venue is admitted for this pair.'}</small></label>
    <label className="field"><span>Creator fee wallet</span><input value={form.feeWallet} onChange={(event) => set('feeWallet', event.target.value)} placeholder="0x…"/><small>Defaults to your wallet.</small></label></div>
    <div className="form-grid"><label className="field"><span>Creator fee</span><input inputMode="decimal" value={form.creatorFee} onChange={(event) => set('creatorFee', event.target.value)} placeholder="0"/><small>Up to {maxCreatorFeePercent}% of each trade, on top of the {(config ? Number(config.curveFeeBps) / 100 : 0)}% curve fee. Unit: %.</small></label><div/></div>
    <div className="fee-section"><span className="field-label">Where your creator fees go</span><div className="fee-options">{feeDestinations.map((option) => <label key={option.id} className={`fee-option${feeDestination === option.id ? ' selected' : ''}${option.supportedLive ? '' : ' disabled'}`}><input type="radio" name="feeDestination" value={option.id} disabled={!option.supportedLive} checked={feeDestination === option.id} onChange={() => option.supportedLive && setFeeDestination(option.id)}/><strong>{option.title}</strong><p>{option.body}</p></label>)}</div></div>
    <p className="launch-info-line">Launch fee {launchFeeMon !== null ? `${launchFeeMon} MON` : '—'}. Graduates at {thresholdDisplay !== null ? `${thresholdDisplay} ${livePair?.symbol}` : '—'}. Curve fee {config ? `${Number(config.curveFeeBps) / 100}%` : '—'}.</p>
    <p className="launch-info-line">No bundled opening buy: the deployed launch flow creates the curve; you can buy immediately after in a separate, visible transaction.</p>
  </>}</> : <><div className="form-title"><h2>2 · Economics</h2><p>Choose what it trades against.</p></div><label className="field"><span>Paired with</span><select value={form.pair} onChange={(event) => set('pair', event.target.value)}>{pairOptions.map((asset) => <option value={asset.id} key={asset.id}>{asset.symbol} · {asset.name}</option>)}</select><small>Buyers pay in {pair.symbol} on the curve and in the pool after graduation.</small></label><label className="field"><span>Creator fee wallet</span><input value={form.feeWallet} onChange={(event) => set('feeWallet', event.target.value)} placeholder="0x…"/><small>Defaults to your wallet.</small></label><div className="form-grid"><label className="field"><span>Creator fee</span><input inputMode="decimal" value={form.creatorFee} onChange={(event) => set('creatorFee', event.target.value)} placeholder="0"/><small>Up to 10.0% of each trade. Unit: %.</small></label><label className="field"><span>Opening buy</span><input inputMode="decimal" value={form.openingBuy} onChange={(event) => set('openingBuy', event.target.value)} placeholder="0"/><small>Optional. Buys first, in the same transaction as the launch. Unit: {pair.symbol}.</small></label></div><div className="fee-section"><span className="field-label">Where your creator fees go</span><div className="fee-options">{feeDestinations.map((option) => <label key={option.id} className={`fee-option${feeDestination === option.id ? ' selected' : ''}`}><input type="radio" name="feeDestination" value={option.id} checked={feeDestination === option.id} onChange={() => setFeeDestination(option.id)}/><strong>{option.title}</strong><p>{option.body}</p>{option.id === 'buybackVest' && <button type="button" className="text-link" onClick={() => setShowVestDetail((open) => !open)}>How buyback &amp; vest works</button>}</label>)}</div>{showVestDetail && <div className="notice" style={{ marginTop: 14 }}>Buyback spend repurchases your own token on the open market. Repurchased tokens lock in the vesting contract and release to your fee escrow linearly over 5 years; each release keeps a protocol share. Illustrative description for this demo draft — no such contracts are deployed.</div>}</div><p className="launch-info-line">Launch fee {LAUNCH_FEE}. Graduates at {GRADUATES_AT}. Curve fee {CURVE_FEE}.</p></>}</>}{error && <div role="alert" className="form-error">{error}</div>}{busy && <div role="status" className="launch-info-line" data-tx-phase={phase.kind}>{phaseLabel(phase)}</div>}<div className="form-actions"><button className="btn ghost" disabled={step === 0} onClick={() => { setError(''); setStep(0); }}>Back</button>{step === 0 ? <button className="btn primary" onClick={next}>Continue <ChevronRight size={15}/></button>
    : live
      ? (wallet.status === 'connected' ? <button className="btn primary" disabled={busy || !preconditions} onClick={launchLive}>{busy ? 'Launching…' : `Launch · ${launchFeeMon ?? ''} MON fee`}</button>
        : wallet.status === 'wrong-chain' ? <button className="btn primary" onClick={() => void wallet.switchChain()}>Switch to Monad Testnet</button>
        : <button className="btn primary" onClick={() => void wallet.connect().catch(() => {})}>Connect wallet to launch</button>)
      : demo.connected ? <button className="btn primary" onClick={launchDemo}>Launch</button> : <button className="btn primary" onClick={() => demo.setConnected(true)}>Sign in to launch</button>}</div></section><aside className="rail"><div className="panel creation-preview token-preview"><div className="preview-label">ON THE BOARD</div>{image ? <img src={image} alt="" className="image-preview large"/> : <span className="token-icon" style={{ color: '#8df0b5', background: '#12241a' }}>{form.ticker.slice(0, 1) || 'T'}</span>}<h3>{form.name || 'Your token'}</h3><span className="tag">{isStock ? 'STOCK-PAIRED' : 'CRYPTO'}</span><p>{form.ticker || 'TOKEN'} · {pair.symbol} pair</p><dl className="detail-list"><dt>Supply</dt><dd>{live && config ? rawToDisplay(config.supply.toString(), 18)?.toLocaleString() : SUPPLY}</dd><dt>Graduates at</dt><dd>{live && thresholdDisplay !== null ? `${thresholdDisplay} ${livePair?.symbol}` : GRADUATES_AT}</dd><dt>Creator fee</dt><dd>{Number.isFinite(Number(form.creatorFee)) ? `${Number(form.creatorFee)}%` : '—'}</dd><dt>Launch fee</dt><dd>{live ? (launchFeeMon !== null ? `${launchFeeMon} MON` : '—') : LAUNCH_FEE}</dd></dl></div><div className="notice create-boundary" style={{ marginTop: 20 }}><ShieldCheck size={17}/><span>{live ? 'A real launch on Monad Testnet: your wallet signs one factory transaction that deploys the token and its bonding curve.' : 'Local DEMO draft only. No asset is minted, deployed, or submitted to any venue from this interface.'}</span></div></aside></div></>;
}

export default function CreateLaunch({ initialType }: { initialType?: string }) {
  if (initialType === 'prediction') return <CreateMarket/>;
  const type: CreationType = initialType === 'stocks' ? 'stocks' : 'crypto';
  return <TokenLaunchWizard type={type}/>;
}
