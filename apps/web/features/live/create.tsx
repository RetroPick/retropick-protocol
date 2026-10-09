'use client';
import { useState,useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { decodeEventLog, toHex, zeroAddress } from 'viem';
import { toast } from 'sonner';
import { errorText, addresses, chain } from '@/lib/live/client';
import { factoryAbi } from '@/lib/live/abi';
import { useWallet } from '@/lib/live/wallet';
export function useCreateLaunch() {
  const wallet = useWallet(); const router = useRouter();
  const [fee, setFee] = useState<bigint>();
  const [config,setConfig]=useState<{supply:bigint;curveFeeBps:bigint}>();
  useEffect(()=>{let active=true;chain.readContract({address:addresses.factory,abi:factoryAbi,functionName:'getLaunchConfig',args:[0n]}).then(c=>{if(active&&c.enabled)setConfig(c);}).catch(()=>{});return()=>{active=false;};},[]);
  const [busy, setBusy] = useState(false);
  async function launch(form: {name:string;symbol:string;description:string;website:string;x:string;telegram:string}) {
    setBusy(true);
    try {
      if (!wallet.account) throw Error('Connect your wallet first.');
      const [economics, currentFee, allowed,currentConfig] = await Promise.all([
        chain.readContract({ address: addresses.factory, abi: factoryAbi, functionName: 'previewVenueEconomics', args: [0n, zeroAddress, 1] }),
        chain.readContract({ address: addresses.factory, abi: factoryAbi, functionName: 'launchFee' }),
        chain.readContract({ address: addresses.factory, abi: factoryAbi, functionName: 'canLaunch', args: [wallet.account] }),
        chain.readContract({address:addresses.factory,abi:factoryAbi,functionName:'getLaunchConfig',args:[0n]}),
      ]);
      setFee(currentFee);
      if(!config || !currentConfig.enabled || currentConfig.supply!==config.supply || currentConfig.curveFeeBps!==config.curveFeeBps){setConfig(currentConfig.enabled?currentConfig:undefined);throw Error('Launch configuration changed. Review the refreshed terms before signing.');}
      if (!allowed) throw Error('This wallet is not currently permitted to launch by the Factory.');
      const hash = await wallet.send({ address: addresses.factory, abi: factoryAbi, functionName: 'launchToken', args: [{ name: form.name.trim(), symbol: form.symbol.trim(), logo: '', description: form.description.trim(), socials: { twitter: form.x.trim(), telegram: form.telegram.trim(), discord: '', website: form.website.trim(), farcaster: '' }, creatorFeeRecipient: wallet.account, creatorTaxBps: 0, buybackEnabled: false, expectedEconomics: economics, salt: toHex(crypto.getRandomValues(new Uint8Array(32))) }, 0n, zeroAddress, 1], value: currentFee });
      const receipt = await chain.getTransactionReceipt({ hash });
      for (const log of receipt.logs) {
        if (log.address.toLowerCase() !== addresses.factory.toLowerCase()) continue;
        try { const event = decodeEventLog({ abi: factoryAbi, data: log.data, topics: log.topics }); if (event.eventName === 'TokenLaunched') { router.push(`/launchpad/token/${event.args.token}`); return; } } catch { /* Other Factory event. */ }
      }
      throw Error('Launch confirmed; token event was not decoded. Open the transaction in the explorer.');
    } catch (error) { toast.error(errorText(error)); } finally { setBusy(false); }
  }
  return {wallet,fee,config,busy,launch};
}
