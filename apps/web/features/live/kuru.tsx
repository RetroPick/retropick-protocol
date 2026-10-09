'use client';
import { useCallback, useEffect, useState } from 'react';
import { decodeEventLog, formatEther, formatUnits, parseEther, parseUnits, zeroAddress } from 'viem';
import { toast } from 'sonner';
import { readKuru, kuruAbi, marginAbi, type KuruState } from '@/lib/live/kuru';
import { tokenAbi } from '@/lib/live/abi';
import { errorText, chain } from '@/lib/live/client';
import type { LiveLaunch } from '@/lib/live/model';
import { useWallet } from '@/lib/live/wallet';
export default function KuruMarket({ launch }: { launch: LiveLaunch }) {
  const wallet = useWallet(); const [state, setState] = useState<KuruState>(); const [now,setNow]=useState(0); const [error, setError] = useState('');
  const [deposit, setDeposit] = useState('0.01'); const [asset, setAsset] = useState<'quote' | 'base'>('quote');
  const [price, setPrice] = useState('0.004'); const [size, setSize] = useState('1'); const [side, setSide] = useState<'buy' | 'sell'>('buy'); const [postOnly, setPostOnly] = useState(true); const [orderId, setOrderId] = useState(''); const [busy, setBusy] = useState(false);
  const refresh = useCallback(async () => { try { setState(await readKuru(launch.receipt.market, launch.token, launch.receipt.vault, wallet.account)); setError(''); } catch (e) { setError(errorText(e)); } }, [launch.receipt.market, launch.receipt.vault, launch.token, wallet.account]);
  useEffect(() => { const initial = setTimeout(refresh, 0); const timer = setInterval(refresh, 5000); return () => {clearTimeout(initial);clearInterval(timer);}; }, [refresh]);
  useEffect(() => {const timer=setInterval(() => setNow(Date.now()),1000);return () => clearInterval(timer);}, []);
  async function act(action: 'deposit' | 'withdraw' | 'order' | 'cancel') {
    setBusy(true);
    try {
      if (!wallet.account) throw Error('Connect your wallet first.');
      const fresh = await readKuru(launch.receipt.market, launch.token, launch.receipt.vault, wallet.account);
      if (action === 'deposit' || action === 'withdraw') {
        const amount = parseEther(deposit); if (amount <= 0n) throw Error('Enter a positive amount.');
        const token = asset === 'quote' ? zeroAddress : launch.token;
        if (action === 'deposit' && asset === 'base') {
          const allowance = await chain.readContract({ address: token, abi: tokenAbi, functionName: 'allowance', args: [wallet.account, fresh.margin] });
          if (allowance < amount) await wallet.send({ address: token, abi: tokenAbi, functionName: 'approve', args: [fresh.margin, amount] });
        }
        await wallet.send({ address: fresh.margin, abi: marginAbi, functionName: action, args: action === 'deposit' ? [wallet.account, token, amount] : [amount, token], value: action === 'deposit' && asset === 'quote' ? amount : 0n });
      } else if (action === 'order') {
        // Qualified testnet markets use decimal precisions of 1e8. Fail closed on drift.
        if (fresh.params[0] !== 100000000 || fresh.params[1] !== 100000000n) throw Error('Unsupported market precision.');
        const p = parseUnits(price, 8), s = parseUnits(size, 8);
        if (p <= 0n || p > 0xffffffffn || p % BigInt(fresh.params[6]) !== 0n || s < fresh.params[7] || s > fresh.params[8]) throw Error('Price/tick or order size outside market limits.');
        const hash = await wallet.send({ address: launch.receipt.market, abi: kuruAbi, functionName: side === 'buy' ? 'addBuyOrder' : 'addSellOrder', args: [Number(p), s, postOnly] });
        const receipt = await chain.getTransactionReceipt({hash});
        for(const log of receipt.logs) { if(log.address.toLowerCase() !== launch.receipt.market.toLowerCase()) continue; try { const event=decodeEventLog({abi:kuruAbi,data:log.data,topics:log.topics}); if(event.eventName==='OrderCreated' && event.args.owner.toLowerCase()===wallet.account.toLowerCase()) setOrderId(String(event.args.orderId)); } catch { /* Other market event. */ } }
      } else {
        const id = BigInt(orderId); if (id <= 0n || id >= 2n ** 40n) throw Error('Invalid order ID.');
        const order = await chain.readContract({ address: launch.receipt.market, abi: kuruAbi, functionName: 's_orders', args: [Number(id)] });
        if (order[0].toLowerCase() !== wallet.account.toLowerCase() || order[1] === 0n) throw Error('No active order owned by this wallet at that ID.');
        await wallet.send({ address: launch.receipt.market, abi: kuruAbi, functionName: 'batchCancelOrders', args: [[id]] });
      }
      await refresh();
    } catch (e) { toast.error(errorText(e)); } finally { setBusy(false); }
  }
  const disabled = busy || wallet.pending || !wallet.account || !state || !!error || now - state.observedAt > 15000;
  return <section className="live-panel"><div className="live-heading"><div><span className="eyebrow">SECONDARY EXECUTION</span><h2>Kuru orderbook</h2></div><button className="btn" onClick={refresh}>Refresh</button></div>{error && <p className="notice" role="alert">{error}</p>}{state ? <><div className="live-grid"><div><small>Best bid</small><strong>{formatEther(state.best[0])} MON</strong></div><div><small>Best ask</small><strong>{formatEther(state.best[1])} MON</strong></div><div><small>Your Kuru MON balance</small><strong>{formatEther(state.quoteBalance)}</strong></div><div><small>Your Kuru {launch.symbol} balance</small><strong>{formatEther(state.baseBalance)}</strong></div></div><div className="live-grid"><div><h3>Bids</h3>{state.book.bids.length ? state.book.bids.map((l, i) => <p key={i}>{formatUnits(l.price, 8)} MON · {formatUnits(l.size, 8)} {launch.symbol}</p>) : <p>No resting limit bids</p>}</div><div><h3>Asks</h3>{state.book.asks.length ? state.book.asks.map((l, i) => <p key={i}>{formatUnits(l.price, 8)} MON · {formatUnits(l.size, 8)} {launch.symbol}</p>) : <p>No resting limit asks</p>}</div></div><h3>Recent trades · last 100 blocks</h3>{state.trades?.length ? state.trades.slice(-8).reverse().map(trade => <p key={`${trade.transactionHash}:${trade.logIndex}`}>{formatEther(trade.args.price || 0n)} MON · {formatUnits(trade.args.filledSize || 0n, 8)} {launch.symbol}</p>) : <p>{state.trades ? 'No trade events in this observed window.' : 'Recent trade feed unavailable; market state remains verified.'}</p>}<p>Best prices may include Kuru AMM liquidity; the depth above shows resting limit orders. Limit orders can partially fill. Post-only orders revert if they would immediately match.</p></> : <p>Reading market parameters and balances…</p>}<div className="live-grid"><div><h3>Trading funds</h3><label>Asset<select value={asset} onChange={e => setAsset(e.target.value as 'quote' | 'base')}><option value="quote">MON</option><option value="base">{launch.symbol}</option></select></label><label>Amount<input inputMode="decimal" value={deposit} onChange={e => setDeposit(e.target.value)}/></label><div className="live-actions"><button className="btn" disabled={disabled} onClick={() => act('deposit')}>Deposit</button><button className="btn" disabled={disabled} onClick={() => act('withdraw')}>Withdraw trading funds</button></div><small>Trading deposits are separate from permanently protected graduation liquidity.</small></div><div><h3>Place limit order</h3><label>Side<select value={side} onChange={e => setSide(e.target.value as 'buy' | 'sell')}><option value="buy">Buy</option><option value="sell">Sell</option></select></label><label>Limit price (MON)<input inputMode="decimal" value={price} onChange={e => setPrice(e.target.value)}/></label><label>Size ({launch.symbol})<input inputMode="decimal" value={size} onChange={e => setSize(e.target.value)}/></label><label className="live-check"><input type="checkbox" checked={postOnly} onChange={e => setPostOnly(e.target.checked)}/>Post only</label><button className="btn primary" disabled={disabled} onClick={() => act('order')}>Place order</button></div><div><h3>Cancel your order</h3><label>Order ID<input inputMode="numeric" value={orderId} onChange={e => setOrderId(e.target.value)}/></label><button className="btn" disabled={disabled || !orderId} onClick={() => act('cancel')}>Cancel order</button><p>Only active orders owned by your wallet can be cancelled.</p></div></div></section>;
}
