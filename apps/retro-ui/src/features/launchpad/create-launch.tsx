'use client';

import Link from '@/components/product/safe-link';
import { Check, ChevronRight, ImagePlus, ShieldCheck } from 'lucide-react';
import { useState, type ChangeEvent } from 'react';
import { approvedPairAssets } from '@/lib/domain/launchpad-fixtures';
import type { LaunchpadType } from '@/lib/domain/launchpad-types';
import { useDemo } from '@/components/product/provider';
import CreateMarket from '@/features/create-market/wizard';

type CreationType = Exclude<LaunchpadType, 'all'>;
type FeeDestination = 'feeWallet' | 'buybackVest' | 'holders';

const LAUNCH_FEE = '0.0005 ETH';
const GRADUATES_AT = '4.20 ETH';
const CURVE_FEE = '1.0%';
const SUPPLY = '1,000,000,000';

const feeDestinations: { id: FeeDestination; title: string; body: string }[] = [
  { id: 'feeWallet', title: 'Your fee wallet', body: 'Fees accrue to your fee wallet to claim, as today.' },
  { id: 'buybackVest', title: 'Buyback & vest', body: 'Spend part of your creator fees buying the token back: bought tokens lock and your share releases to your fee escrow to claim, gradually over 5 years; the protocol keeps part of every release.' },
  { id: 'holders', title: 'Holders', body: 'Every creator fee is paid out to the token\u2019s holders, split by how much each holds and for how long. Two more confirmations after the launch. This is permanent: the fees can never be routed back to you.' },
];

function LaunchStepper({ active }: { active: number }) {
  const steps = ['Identity', 'Economics'];
  return <div className="stepper token-stepper" aria-label="Token launch progress">{steps.map((step, index) => <div className={index === active ? 'current' : index < active ? 'done' : ''} key={step} aria-current={index === active ? 'step' : undefined}><b>{index < active ? <Check size={13}/> : index + 1}</b>{step}</div>)}</div>;
}

function TokenLaunchWizard({ type }: { type: 'crypto' | 'stocks' }) {
  const isStock = type === 'stocks';
  const demo = useDemo();
  const [step, setStep] = useState(0);
  const [done, setDone] = useState(false);
  const [error, setError] = useState('');
  const [image, setImage] = useState('');
  const [imageName, setImageName] = useState('');
  const [feeDestination, setFeeDestination] = useState<FeeDestination>('feeWallet');
  const [showVestDetail, setShowVestDetail] = useState(false);
  const [form, setForm] = useState({ name: '', ticker: '', description: '', x: '', telegram: '', website: '', pair: 'ETH', feeWallet: '', creatorFee: '0', openingBuy: '0' });
  const fixturePairs = approvedPairAssets.filter((asset) => isStock ? asset.assetClass === 'STOCK_QUOTE' : asset.assetClass === 'CRYPTO');
  const pairOptions = [{ id: 'ETH', symbol: 'ETH', name: 'Ether' }, ...fixturePairs];
  const pair = pairOptions.find((asset) => asset.id === form.pair) ?? pairOptions[0];
  const set = (key: keyof typeof form, value: string) => setForm((current) => ({ ...current, [key]: value }));

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
    const buy = Number(form.openingBuy);
    if (!Number.isFinite(fee) || fee < 0 || fee > 10) return 'Creator fee must be between 0 and 10.0%.';
    if (form.feeWallet.trim() && !/^0x[a-fA-F0-9]{4,40}$/.test(form.feeWallet.trim())) return 'Creator fee wallet must be a 0x address, or leave it empty to default to your wallet.';
    if (!Number.isFinite(buy) || buy < 0) return 'Opening buy must be zero or greater.';
    return '';
  };
  const next = () => { const issue = canContinue(); setError(issue); if (!issue) setStep(1); };
  const launch = () => {
    const issue = canLaunch();
    setError(issue);
    if (issue) return;
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
      setDone(true);
    } catch { setError('This browser could not save the local demo draft.'); }
  };

  if (done) return <div className="guide"><div className="panel success-page"><Check size={46} className="positive"/><h1>Your token launch draft is ready.</h1><p>{form.name || 'Your token'} remains a local DEMO draft. No token, pool, pair, contract address or onchain market was created \u2014 the curve does not open from this interface.</p><div className="notice">A real launch must use reviewed deployment configuration, an admitted quote-asset registry and a wallet-signed transaction.</div><div className="prism-actions"><Link href="/launchpad" className="btn primary">Explore Launchpad</Link><button className="btn" onClick={() => setDone(false)}>Edit draft</button></div></div></div>;

  const counter = (value: string, max: number) => <span className="char-counter">{value.length}/{max}</span>;
  const fieldWithCounter = (label: string, key: keyof typeof form, placeholder: string, max: number) => <label className="field"><span className="field-head"><span>{label}</span>{counter(form[key], max)}</span><input maxLength={max} value={form[key]} onChange={(event) => set(key, event.target.value)} placeholder={placeholder}/></label>;

  return <><div className="page-heading"><div><div className="eyebrow">CREATE LAUNCH · DEMO DRAFT</div><h1>Launch a token on Pons.</h1><p>Two steps on Robinhood Chain. Give it a name and a face, choose what it trades against, and the curve opens the moment you sign.</p></div><span className="tag">NOT DEPLOYED</span></div><LaunchStepper active={step}/><div className="workspace token-create-workspace"><section className="panel">{step === 0 && <><div className="form-title"><h2>1 · Identity</h2><p>Give it a name and a face.</p></div><div className="image-picker"><span className="field-label">Image</span><div className="image-picker-row">{image ? <img src={image} alt="Token image preview" className="image-preview"/> : <span className="image-empty"><ImagePlus size={22}/></span>}<div><label className="btn image-choose"><input type="file" accept="image/png,image/jpeg,image/webp" onChange={onImage} aria-label="Choose token image"/>Choose image</label><small>{imageName || 'No file chosen'}</small><small>Square, up to 5 MB</small></div></div></div>{fieldWithCounter('Name', 'name', 'Pons Coin', 32)}<div className="form-grid">{fieldWithCounter('Ticker', 'ticker', 'PONS', 10)}<div/></div><label className="field"><span className="field-head"><span>Description</span>{counter(form.description, 256)}</span><textarea maxLength={256} value={form.description} onChange={(event) => set('description', event.target.value)} placeholder="What is it, in a sentence or two. No links."/></label><div className="form-grid"><label className="field"><span>X</span><input value={form.x} onChange={(event) => set('x', event.target.value)} placeholder="handle or URL"/></label><label className="field"><span>Telegram</span><input value={form.telegram} onChange={(event) => set('telegram', event.target.value)} placeholder="username or t.me"/></label></div><label className="field"><span>Website</span><input value={form.website} onChange={(event) => set('website', event.target.value)} placeholder="https://"/></label></>}{step === 1 && <><div className="form-title"><h2>2 · Economics</h2><p>Choose what it trades against.</p></div><label className="field"><span>Paired with</span><select value={form.pair} onChange={(event) => set('pair', event.target.value)}>{pairOptions.map((asset) => <option value={asset.id} key={asset.id}>{asset.symbol} · {asset.name}</option>)}</select><small>Buyers pay in {pair.symbol} on the curve and in the pool after graduation.</small></label><label className="field"><span>Creator fee wallet</span><input value={form.feeWallet} onChange={(event) => set('feeWallet', event.target.value)} placeholder="0x\u2026"/><small>Defaults to your wallet.</small></label><div className="form-grid"><label className="field"><span>Creator fee</span><input inputMode="decimal" value={form.creatorFee} onChange={(event) => set('creatorFee', event.target.value)} placeholder="0"/><small>Up to 10.0% of each trade. Unit: %.</small></label><label className="field"><span>Opening buy</span><input inputMode="decimal" value={form.openingBuy} onChange={(event) => set('openingBuy', event.target.value)} placeholder="0"/><small>Optional. Buys first, in the same transaction as the launch. Unit: {pair.symbol}.</small></label></div><div className="fee-section"><span className="field-label">Where your creator fees go</span><div className="fee-options">{feeDestinations.map((option) => <label key={option.id} className={`fee-option${feeDestination === option.id ? ' selected' : ''}`}><input type="radio" name="feeDestination" value={option.id} checked={feeDestination === option.id} onChange={() => setFeeDestination(option.id)}/><strong>{option.title}</strong><p>{option.body}</p>{option.id === 'buybackVest' && <button type="button" className="text-link" onClick={() => setShowVestDetail((open) => !open)}>How buyback &amp; vest works</button>}</label>)}</div>{showVestDetail && <div className="notice" style={{ marginTop: 14 }}>Buyback spend repurchases your own token on the open market. Repurchased tokens lock in the vesting contract and release to your fee escrow linearly over 5 years; each release keeps a protocol share. Illustrative description for this demo draft \u2014 no such contracts are deployed.</div>}</div><p className="launch-info-line">Launch fee {LAUNCH_FEE}. Graduates at {GRADUATES_AT}. Curve fee {CURVE_FEE}.</p></>}{error && <div role="alert" className="form-error">{error}</div>}<div className="form-actions"><button className="btn ghost" disabled={step === 0} onClick={() => { setError(''); setStep(0); }}>Back</button>{step === 0 ? <button className="btn primary" onClick={next}>Continue <ChevronRight size={15}/></button> : demo.connected ? <button className="btn primary" onClick={launch}>Launch</button> : <button className="btn primary" onClick={() => demo.setConnected(true)}>Sign in to launch</button>}</div></section><aside className="rail"><div className="panel creation-preview token-preview"><div className="preview-label">ON THE BOARD</div>{image ? <img src={image} alt="" className="image-preview large"/> : <span className="token-icon" style={{ color: '#8df0b5', background: '#12241a' }}>{form.ticker.slice(0, 1) || 'T'}</span>}<h3>{form.name || 'Your token'}</h3><span className="tag">{isStock ? 'STOCK-PAIRED' : 'CRYPTO'}</span><p>{form.ticker || 'TOKEN'} · {pair.symbol} pair</p><dl className="detail-list"><dt>Supply</dt><dd>{SUPPLY}</dd><dt>Graduates at</dt><dd>{GRADUATES_AT}</dd><dt>Creator fee</dt><dd>{Number.isFinite(Number(form.creatorFee)) ? `${Number(form.creatorFee)}%` : '\u2014'}</dd><dt>Launch fee</dt><dd>{LAUNCH_FEE}</dd></dl></div><div className="notice create-boundary" style={{ marginTop: 20 }}><ShieldCheck size={17}/><span>Local DEMO draft only. No asset is minted, deployed, or submitted to any venue from this interface.</span></div></aside></div></>;
}

export default function CreateLaunch({ initialType }: { initialType?: string }) {
  if (initialType === 'prediction') return <CreateMarket/>;
  const type: CreationType = initialType === 'stocks' ? 'stocks' : 'crypto';
  return <TokenLaunchWizard type={type}/>;
}
