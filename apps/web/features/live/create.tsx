'use client';
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { decodeEventLog, formatEther, toHex, zeroAddress } from 'viem';
import { toast } from 'sonner';
import { errorText, addresses, chain } from '@/lib/live/client';
import { factoryAbi } from '@/lib/live/abi';
import { useWallet } from '@/lib/live/wallet';
export default function LiveCreate() {
  const wallet = useWallet(); const router = useRouter();
  const [name, setName] = useState(''); const [symbol, setSymbol] = useState(''); const [description, setDescription] = useState('');
  const [fee, setFee] = useState<bigint>();
  const [busy, setBusy] = useState(false);
  async function launch(event: React.FormEvent) {
    event.preventDefault(); setBusy(true);
    try {
      if (!wallet.account) throw Error('Connect your wallet first.');
      const [economics, currentFee, allowed] = await Promise.all([
        chain.readContract({ address: addresses.factory, abi: factoryAbi, functionName: 'previewVenueEconomics', args: [0n, zeroAddress, 1] }),
        chain.readContract({ address: addresses.factory, abi: factoryAbi, functionName: 'launchFee' }),
        chain.readContract({ address: addresses.factory, abi: factoryAbi, functionName: 'canLaunch', args: [wallet.account] }),
      ]);
      setFee(currentFee);
      if (!allowed) throw Error('This wallet is not currently permitted to launch by the Factory.');
      const hash = await wallet.send({ address: addresses.factory, abi: factoryAbi, functionName: 'launchToken', args: [{ name: name.trim(), symbol: symbol.trim(), logo: '', description: description.trim(), socials: { twitter: '', telegram: '', discord: '', website: '', farcaster: '' }, creatorFeeRecipient: wallet.account, creatorTaxBps: 0, buybackEnabled: false, expectedEconomics: economics, salt: toHex(crypto.getRandomValues(new Uint8Array(32))) }, 0n, zeroAddress, 1], value: currentFee });
      const receipt = await chain.getTransactionReceipt({ hash });
      for (const log of receipt.logs) {
        if (log.address.toLowerCase() !== addresses.factory.toLowerCase()) continue;
        try { const event = decodeEventLog({ abi: factoryAbi, data: log.data, topics: log.topics }); if (event.eventName === 'TokenLaunched') { router.push(`/launchpad/token/${event.args.token}`); return; } } catch { /* Other Factory event. */ }
      }
      throw Error('Launch confirmed; token event was not decoded. Open the transaction in the explorer.');
    } catch (error) { toast.error(errorText(error)); } finally { setBusy(false); }
  }
  return <section className="live-panel live-form"><span className="eyebrow">MARKET ORIGINATION</span><h1>Create your market</h1><p>Issue a token, discover its price on a bonding curve, then graduate to Kuru.</p><form onSubmit={launch}><label>Token name<input required maxLength={64} value={name} onChange={e => setName(e.target.value)} placeholder="Your community token"/></label><label>Symbol<input required maxLength={12} value={symbol} onChange={e => setSymbol(e.target.value)} placeholder="TOKEN"/></label><label>Description<textarea maxLength={1000} value={description} onChange={e => setDescription(e.target.value)}/></label><div className="live-grid"><div><small>Quote</small><strong>MON</strong></div><div><small>Graduation venue</small><strong>Kuru · immutable</strong></div><div><small>Policy</small><strong>TESTNET_POLICY_V1</strong></div><div><small>Supply / curve fee</small><strong>1,000 tokens / 1%</strong></div></div><p className="notice">Graduation LP and excess tokens enter permanent custody. Creator tax: 0%. Buyback: off. This is a testnet candidate.</p>{fee !== undefined && <p>Factory launch fee: {formatEther(fee)} MON</p>}<button className="btn primary full" type="submit" disabled={busy || wallet.pending || !wallet.account}>{busy || wallet.pending ? 'Awaiting confirmation…' : wallet.account ? 'Launch on Monad Testnet' : 'Connect wallet to launch'}</button></form></section>;
}
