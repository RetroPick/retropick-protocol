'use client';

import { useCallback, useEffect, useState } from 'react';
import type { Address } from 'viem';
import { zeroAddress } from 'viem';
import { publicClient } from '@/lib/live/public-client';
import { useWallet } from '@/wallet/provider';
import { fetchLaunches } from '@/lib/live/indexer-client';
import { INDEXER_URL } from '@/lib/live/env';
import { shortAddress } from '@/lib/live/format';
import { release } from '@retropick/launchpad-sdk/chain';
import { tokenAbi, marginAbi } from '@retropick/launchpad-sdk/abi';
import { readFeeEscrowCredit } from '@retropick/launchpad-sdk/registry';

interface LivePosition { token: Address; symbol: string; name: string; phase: string; balanceRaw: bigint; priceRaw: string | null }

/** Live portfolio for the connected wallet: real balances across the wallet,
 * Kuru margin custody and the fee escrow — no fabricated PnL. */
export function LivePortfolio() {
  const wallet = useWallet();
  const account = wallet.account;
  const [monBalance, setMonBalance] = useState<bigint | null>(null);
  const [positions, setPositions] = useState<LivePosition[]>([]);
  const [marginMon, setMarginMon] = useState<bigint | null>(null);
  const [escrowCredit, setEscrowCredit] = useState<bigint | null>(null);
  const [status, setStatus] = useState<'loading' | 'ready' | 'error'>('loading');

  const refresh = useCallback(async () => {
    if (!account) return;
    try {
      const launches = INDEXER_URL ? await fetchLaunches(INDEXER_URL).then((envelope) => envelope.data).catch(() => []) : [];
      const [mon, escrow, marginQuote, ...tokenBalances] = await Promise.all([
        publicClient.getBalance({ address: account }),
        readFeeEscrowCredit(publicClient, account),
        publicClient.readContract({ address: release.kuruEnvironment.marginAccount as Address, abi: marginAbi, functionName: 'getBalance', args: [account, zeroAddress] }),
        ...launches.map((launch) => publicClient.readContract({ address: launch.token as Address, abi: tokenAbi, functionName: 'balanceOf', args: [account] }).catch(() => 0n)),
      ]);
      setMonBalance(mon);
      setEscrowCredit(escrow);
      setMarginMon(marginQuote);
      setPositions(launches.map((launch, index) => ({
        token: launch.token as Address,
        symbol: launch.symbol,
        name: launch.name,
        phase: launch.phase,
        balanceRaw: tokenBalances[index] ?? 0n,
        priceRaw: launch.priceRaw,
      })).filter((position) => position.balanceRaw > 0n));
      setStatus('ready');
    } catch {
      setStatus('error');
    }
  }, [account]);

  useEffect(() => { void refresh(); }, [refresh]);

  if (!account) return <section className="panel"><h2>Portfolio</h2><p className="empty-copy">Connect your wallet to see live positions on Monad Testnet.</p></section>;
  if (status === 'loading') return <section className="panel"><h2>Portfolio</h2><p className="empty-copy">Reading balances from the deployed contracts…</p></section>;
  if (status === 'error') return <section className="panel"><h2>Portfolio</h2><p className="empty-copy">Balances are temporarily unavailable. Retry shortly.</p></section>;

  const valueOf = (balanceRaw: bigint, priceRaw: string | null) => priceRaw ? balanceRaw * BigInt(priceRaw) / 10n ** 18n : null;

  return <section className="panel" aria-label="Live portfolio">
    <div className="earn-panel-head"><h2>Portfolio · live · {shortAddress(account)}</h2></div>
    <div className="earn-amount-row"><strong>{monBalance === null ? '—' : `${Number(monBalance) / 1e18}`}</strong><span>MON in wallet</span></div>
    {positions.length > 0 && <table className="detail-trades"><thead><tr><th>Token</th><th>Balance</th><th>Phase</th><th>Value (MON)</th></tr></thead><tbody>
      {positions.map((position) => <tr key={position.token}>
        <td>{position.symbol}</td>
        <td>{Number(position.balanceRaw) / 1e18}</td>
        <td>{position.phase.replaceAll('_', ' ')}</td>
        <td>{valueOf(position.balanceRaw, position.priceRaw) === null ? 'unavailable' : `${Number(valueOf(position.balanceRaw, position.priceRaw)) / 1e18}`}</td>
      </tr>)}
    </tbody></table>}
    <div className="earn-row-group">
      <div className="earn-row"><span>Kuru margin · MON</span><strong>{marginMon === null ? '—' : `${Number(marginMon) / 1e18}`}</strong></div>
      <div className="earn-row"><span>Claimable creator fees · MON</span><strong>{escrowCredit === null ? '—' : `${Number(escrowCredit) / 1e18}`}</strong></div>
    </div>
    <p className="earn-empty">Values are last-trade estimates from the indexer; cost basis and PnL are not fabricated — they show as unavailable.</p>
  </section>;
}
