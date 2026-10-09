'use client';
import { useCallback, useEffect, useState } from 'react';
import { formatEther, isAddress } from 'viem';
import { toast } from 'sonner';
import { errorText, addresses, chain, explorer, short } from '@/lib/live/client';
import { coordinatorAbi, curveAbi, factoryAbi, tokenAbi } from '@/lib/live/abi';
import { readLaunch, type LiveLaunch } from '@/lib/live/model';
import { buyQuote, minOutput, sellQuote, parseExact } from '@/lib/live/math';
import { useWallet } from '@/lib/live/wallet';
import KuruMarket from './kuru';
const value = (n: bigint) => formatEther(n).replace(/(\.\d{6})\d+$/, '$1');
export default function LiveToken({ token }: { token: string }) {
  const wallet = useWallet(); const [data, setData] = useState<LiveLaunch>(); const [now,setNow]=useState(0); const [error, setError] = useState('');
  const [amount, setAmount] = useState('0.1'); const [side, setSide] = useState<'buy' | 'sell'>('buy'); const [busy, setBusy] = useState(false);
  const refresh = useCallback(async () => { try { if (!isAddress(token)) throw Error('Enter a valid token address.'); setData(await readLaunch(token, wallet.account)); setError(''); } catch (e) { setError(errorText(e)); } }, [token, wallet.account]);
  useEffect(() => { let stopped = false; async function poll() { if (!stopped) await refresh(); } void poll(); const timer = setInterval(poll, 5000); return () => { stopped = true; clearInterval(timer); }; }, [refresh]);
  useEffect(() => {const timer=setInterval(() => setNow(Date.now()),1000);return () => clearInterval(timer);}, []);
  async function transact(action: 'buy' | 'sell' | 'secure' | 'complete') {
    setBusy(true);
    try {
      if (!wallet.account || !isAddress(token)) throw Error('Connect your wallet first.');
      const fresh = await readLaunch(token, wallet.account);
      if (action === 'complete') {
        if (fresh.ledger.phase !== 1) throw Error('Launch is not GRADUATING.');
        await wallet.send({ address: addresses.coordinator, abi: coordinatorAbi, functionName: 'complete', args: [token] });
      } else if (action === 'secure') {
        if (fresh.ledger.phase !== 0 || fresh.remaining !== 0n) throw Error('Bonding allocation is not complete.');
        await wallet.send({ address: addresses.factory, abi: factoryAbi, functionName: 'graduate', args: [token] });
      } else {
        if (fresh.ledger.phase !== 0 || fresh.remaining === 0n) throw Error('Bonding trading is closed.');
        const input = parseExact(amount);
        if (input <= 0n) throw Error('Enter a positive amount.');
        const output = action === 'buy' ? buyQuote(input, fresh.reserves[0], fresh.reserves[1], fresh.remaining, fresh.fee, fresh.tax) : sellQuote(input, fresh.reserves[1], fresh.reserves[0], fresh.fee, fresh.tax);
        const minimum = minOutput(output);
        if (minimum === 0n) throw Error('Amount is too small.');
        if (action === 'sell') {
          const allowance = await chain.readContract({ address: token, abi: tokenAbi, functionName: 'allowance', args: [wallet.account, fresh.packet.curve] });
          if (allowance < input) await wallet.send({ address: token, abi: tokenAbi, functionName: 'approve', args: [fresh.packet.curve, input] });
        }
        await wallet.send({ address: fresh.packet.curve, abi: curveAbi, functionName: action, args: [input, minimum, wallet.account], ...(action === 'buy' ? { value: input } : {}) });
      }
      await refresh();
    } catch (e) { toast.error(errorText(e)); } finally { setBusy(false); }
  }
  if (!data) return <section className="live-panel"><h1>{error ? 'Market unavailable' : 'Reading Monad…'}</h1><p role="status">{error || 'Loading the launch packet and graduation ledger.'}</p><button className="btn" onClick={refresh}>Refresh</button></section>;
  const phase = data.ledger.phase === 0 && data.remaining === 0n ? 'READY TO SECURE' : ['BONDING', 'GRADUATING', 'GRADUATED'][data.ledger.phase];
  const allocation = data.supply - data.reserved;
  const progress = data.ledger.phase > 0 ? 100 : allocation > 0n ? Number((allocation - data.remaining) * 10000n / allocation) / 100 : 0;
  const stale = !!error || now - data.observedAt > 15000;
  const protectedVerified = !!data.custody && data.custody.lp >= data.ledger.protectedLPAmount && data.custody.excess >= data.ledger.protectedExcessAmount;
  const disabled = busy || wallet.pending || stale || !wallet.account;
  return <><div className="live-heading"><div><span className="eyebrow">MON → KURU</span><h1>{data.name} <small>{data.symbol}</small></h1><p>Two stages. One market lifecycle.</p></div><span className="demo-pill">{phase}</span></div>{stale && <div className="notice" role="alert">Live data is stale. Trading is disabled until refreshed. {error}</div>}<div className="live-grid"><section className="live-panel"><h2>Price discovery</h2><div className="live-grid"><div><small>{data.ledger.phase === 2 ? 'Quote seeded at graduation' : 'Curve quote reserve'}</small><strong>{value(data.ledger.phase === 2 ? data.receipt.seededQuote : data.realQuote)} MON</strong></div><div><small>Your tokens</small><strong>{value(data.balance)} {data.symbol}</strong></div><div><small>Curve spot price</small><strong>{data.ledger.phase === 0 && data.reserves[1] > 0n ? value(data.reserves[0] * 10n ** 18n / data.reserves[1]) : 'Bonding closed'} {data.ledger.phase === 0 ? 'MON' : ''}</strong></div><div><small>Completion ceiling</small><strong>{value(data.packet.graduationQuoteCeiling)} MON</strong></div></div><label htmlFor="graduation-progress">Bonding allocation sold · {progress.toFixed(2)}%</label><progress id="graduation-progress" max="100" value={progress}/><p>Graduation follows exhaustion of the sellable allocation. The threshold alone does not determine completion.</p>{data.ledger.phase === 0 && data.remaining > 0n && <><div className="live-actions"><button className={`btn ${side === 'buy' ? 'primary' : ''}`} onClick={() => setSide('buy')}>Buy</button><button className={`btn ${side === 'sell' ? 'primary' : ''}`} onClick={() => setSide('sell')}>Sell</button></div><label>Amount ({side === 'buy' ? 'MON' : data.symbol})<input inputMode="decimal" value={amount} onChange={e => setAmount(e.target.value)}/></label><p>Slippage tolerance: 0.5%. Final buys may partially fill and refund unused MON.</p><button className="btn primary full" disabled={disabled} onClick={() => transact(side)}>{disabled && busy ? 'Awaiting confirmation…' : `${side === 'buy' ? 'Buy' : 'Sell'} on curve`}</button><button className="btn full" onClick={() => { setSide('buy'); setAmount(formatEther(data.completion[1])); }}>Use remaining completion input · {value(data.completion[1])} MON</button></>}{data.ledger.phase === 0 && data.remaining === 0n && <><p>Bonding is closed. Anyone can secure the launch to the Coordinator.</p><button className="btn primary" disabled={disabled} onClick={() => transact('secure')}>Secure graduation</button></>}{data.ledger.phase === 1 && <><p>Assets are secured. Completion is permissionless; a failed venue transaction leaves the launch retryable.</p><button className="btn primary" disabled={disabled} onClick={() => transact('complete')}>{busy ? 'Completing…' : 'Complete Kuru graduation'}</button></>}{data.ledger.phase === 2 && <p>Graduation verified by the Coordinator. Continue trading on the Kuru orderbook below.</p>}</section><section className="live-panel" aria-labelledby="launch-proof"><span className="eyebrow">ONCHAIN EVIDENCE</span><h2 id="launch-proof">Launch Proof</h2><dl className="live-proof"><dt>Network</dt><dd>Monad Testnet · 10143</dd><dt>Quote</dt><dd>MON</dd><dt>Venue</dt><dd>Kuru · immutable</dd><dt>Policy</dt><dd>TESTNET_POLICY_V1 · version {data.packet.quotePolicyVersion}</dd><dt>Graduation</dt><dd>{phase}</dd><dt>Liquidity custody</dt><dd>{protectedVerified ? 'Permanently protected · balances verified' : data.ledger.phase === 2 ? 'Verification mismatch' : 'Permanent custody on completion'}</dd>{[['Token', token], ['Curve', data.packet.curve], ['Factory', addresses.factory], ['Coordinator', addresses.coordinator], ...(data.ledger.phase === 2 ? [['Market', data.receipt.market], ['Vault', data.receipt.vault], ['LP lock', data.ledger.protectedLPReceiver]] : [])].map(([label, address]) => <div className="live-proof-row" key={label}><dt>{label}</dt><dd><a href={explorer(address)} target="_blank" rel="noreferrer" title={address}>{short(address)} ↗</a></dd></div>)}{data.custody && <><dt>Locked LP shares</dt><dd>{data.custody.lp.toString()} raw</dd><dt>Locked excess tokens</dt><dd>{value(data.custody.excess)}</dd></>}<dt>Observed block</dt><dd>{data.blockNumber.toString()}</dd></dl><button className="btn" onClick={refresh}>Refresh proof</button></section></div>{data.ledger.phase === 2 && <KuruMarket launch={data}/>}</>;
}
