'use client';
import { useCallback, useEffect, useState } from 'react';
import { formatEther, isAddress } from 'viem';
import { toast } from 'sonner';
import { errorText, addresses, chain } from '@/lib/live/client';
import { coordinatorAbi, curveAbi, factoryAbi, tokenAbi } from '@/lib/live/abi';
import { readLaunch, type LiveLaunch } from '@/lib/live/model';
import { buyQuote, minOutput, sellQuote, parseExact } from '@/lib/live/math';
import { useWallet } from '@/lib/live/wallet';
export const liveValue = (n: bigint) => formatEther(n).replace(/(\.\d{6})\d+$/, '$1');
export function useLiveToken(token: string) {
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
  const phase = data ? data.ledger.phase === 0 && data.remaining === 0n ? 'READY TO SECURE' : ['BONDING', 'GRADUATING', 'GRADUATED'][data.ledger.phase] : 'LOADING';
  const allocation = data ? data.supply - data.reserved : 0n;
  const progress = data ? data.ledger.phase > 0 ? 100 : allocation > 0n ? Number((allocation - data.remaining) * 10000n / allocation) / 100 : 0 : 0;
  const stale = !!error || !!data && now - data.observedAt > 15000;
  const protectedVerified = !!data?.custody && data.custody.lp >= data.ledger.protectedLPAmount && data.custody.excess >= data.ledger.protectedExcessAmount;
  const disabled = busy || wallet.pending || stale || !wallet.account;
  let estimated = 0n;
  try { if(data && data.ledger.phase === 0 && data.remaining > 0n) {const input=parseExact(amount);estimated=side==='buy' ? buyQuote(input,data.reserves[0],data.reserves[1],data.remaining,data.fee,data.tax) : sellQuote(input,data.reserves[1],data.reserves[0],data.fee,data.tax);} } catch { /* Invalid input stays unavailable until submission validation. */ }
  return {wallet,data,error,amount,setAmount,side,setSide,busy,refresh,transact,phase,progress,stale,protectedVerified,disabled,estimated};
}
