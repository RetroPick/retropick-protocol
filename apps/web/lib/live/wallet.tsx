'use client';
import { createContext, useCallback, useContext, useEffect, useState, type ReactNode } from 'react';
import { createWalletClient, custom, getAddress, type Address, type EIP1193Provider, type Hash, type Abi } from 'viem';
import { chain, monad } from './client';
import { toast } from 'sonner';

type Provider = EIP1193Provider & { on?: (event: string, fn: (...args: unknown[]) => void) => void; removeListener?: (event: string, fn: (...args: unknown[]) => void) => void };
declare global { interface Window { ethereum?: Provider } }
type Write = { address: Address; abi: Abi; functionName: string; args?: readonly unknown[]; value?: bigint };
const Context = createContext<{ account?: Address; pending: boolean; connect: () => Promise<void>; disconnect: () => void; send: (write: Write) => Promise<Hash> } | null>(null);
export function WalletProvider({ children }: { children: ReactNode }) {
  const [account, setAccount] = useState<Address>();
  const [pending, setPending] = useState(false);
  const connect = useCallback(async () => {
    try {
      if (!window.ethereum) throw Error('Install an EVM wallet to connect to Monad Testnet.');
      const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' }) as string[];
      setAccount(accounts[0] ? getAddress(accounts[0]) : undefined);
    } catch (error) { toast.error(error instanceof Error ? error.message : 'Wallet connection failed'); }
  }, []);
  useEffect(() => {
    const provider = window.ethereum;
    const changed = (...args: unknown[]) => { const accounts = args[0] as string[]; setAccount(accounts?.[0] ? getAddress(accounts[0]) : undefined); };
    provider?.on?.('accountsChanged', changed);
    return () => provider?.removeListener?.('accountsChanged', changed);
  }, []);
  const send = async (write: Write) => {
    if (!window.ethereum || !account) throw Error('Connect your wallet first.');
    if (pending) throw Error('Wait for the current transaction.');
    setPending(true);
    try {
      const provider = window.ethereum;
      const id = await provider.request({ method: 'eth_chainId' });
      if (id !== '0x279f') {
        try { await provider.request({ method: 'wallet_switchEthereumChain', params: [{ chainId: '0x279f' }] }); }
        catch (error) {
          if ((error as { code?: number }).code !== 4902) throw error;
          await provider.request({ method: 'wallet_addEthereumChain', params: [{ chainId: '0x279f', chainName: monad.name, nativeCurrency: monad.nativeCurrency, rpcUrls: monad.rpcUrls.default.http, blockExplorerUrls: [monad.blockExplorers.default.url] }] });
          await provider.request({ method: 'wallet_switchEthereumChain', params: [{ chainId: '0x279f' }] });
        }
      }
      if (await provider.request({ method: 'eth_chainId' }) !== '0x279f') throw Error('Monad Testnet is required.');
      // Simulation is refreshed immediately before every signature.
      const { request } = await chain.simulateContract({ ...write, account });
      const wallet = createWalletClient({ account, chain: monad, transport: custom(provider) });
      const hash = await wallet.writeContract(request);
      toast.message('Transaction sent', { description: hash });
      const receipt = await chain.waitForTransactionReceipt({ hash });
      if (receipt.status !== 'success') throw Error('Transaction reverted.');
      toast.success('Confirmed on Monad Testnet');
      return hash;
    } finally { setPending(false); }
  };
  return <Context.Provider value={{ account, pending, connect, disconnect: () => setAccount(undefined), send }}>{children}</Context.Provider>;
}
export function useWallet() { const context = useContext(Context); if (!context) throw Error('WalletProvider required'); return context; }
