'use client';

import { useCallback, useEffect, useState } from 'react';
import type { Address } from 'viem';
import { publicClient } from '@/lib/live/public-client';
import { useWallet } from '@/wallet/provider';
import { executePreparedWrite, type TxPhase } from '@/services/tx-pipeline';
import { readFeeEscrowCredit, readBuybackReleasable } from '@retropick/launchpad-sdk/registry';
import { prepareFeeClaim, prepareFeeClaimToken, prepareBuybackRelease } from '@retropick/launchpad-sdk/prepare';
import { fetchLaunches } from '@/lib/live/indexer-client';
import { INDEXER_URL } from '@/lib/live/env';
import { shortAddress } from '@/lib/live/format';
import { toast } from 'sonner';

interface BuybackRow { token: Address; symbol: string; releasable: bigint }

/** Live Earn surface: real FeeEscrow credit and BuybackVault release for the
 * connected creator, executed through the shared transaction pipeline. */
export function LiveEarn() {
  const wallet = useWallet();
  const account = wallet.account;
  const [credit, setCredit] = useState<bigint | null>(null);
  const [buybacks, setBuybacks] = useState<BuybackRow[]>([]);
  const [tx, setTx] = useState<TxPhase | { kind: 'idle' }>({ kind: 'idle' });
  const [error, setError] = useState('');
  const [tick, setTick] = useState(0);
  const refresh = useCallback(() => setTick((value) => value + 1), []);
  const busy = tx.kind !== 'idle' && tx.kind !== 'failed';

  const refreshState = useCallback(async () => {
    if (!account) return;
    const [escrow, launches] = await Promise.all([
      readFeeEscrowCredit(publicClient, account),
      INDEXER_URL ? fetchLaunches(INDEXER_URL).then((envelope) => envelope.data).catch(() => []) : Promise.resolve([]),
    ]);
    setCredit(escrow);
    const mine = launches.filter((launch) => launch.creator.toLowerCase() === account.toLowerCase());
    const rows: BuybackRow[] = [];
    for (const launch of mine) {
      const releasable = await readBuybackReleasable(publicClient, launch.token as Address).catch(() => 0n);
      if (releasable > 0n) rows.push({ token: launch.token as Address, symbol: launch.symbol, releasable });
    }
    setBuybacks(rows);
  }, [account]);

  useEffect(() => { void refreshState().catch(() => undefined); }, [refreshState, tick]);

  const run = async (prepare: () => Promise<Parameters<typeof executePreparedWrite>[2]>, label: string) => {
    if (!wallet.wallet || !account) return;
    setError('');
    try {
      const prepared = await prepare();
      const result = await executePreparedWrite(publicClient, wallet.wallet, prepared, { onPhase: setTx });
      if (result.kind === 'success') {
        toast.success(`${label} confirmed`, { description: result.hash });
        setTx({ kind: 'idle' });
        refresh();
      } else {
        setError(result.reason);
        setTx({ kind: 'idle' });
      }
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : 'Transaction failed.');
      setTx({ kind: 'idle' });
    }
  };

  if (!account) {
    return <section className="earn-panel panel"><h2>Creator earnings</h2><p className="earn-empty">Connect your wallet to see claimable creator fees and vested buyback proceeds on Monad Testnet.</p></section>;
  }

  return <section className="earn-panel panel" aria-label="Live creator earnings">
    <div className="earn-panel-head"><h2>Creator fees · live</h2><span className="addr-chip">{shortAddress(account)}</span></div>
    <div className="earn-amount-row"><strong>{credit === null ? '…' : `${Number(credit) / 1e18}`}</strong><span>MON available in the fee escrow</span></div>
    <div className="earn-actions">
      <button className="btn primary" disabled={busy || !credit} onClick={() => run(() => prepareFeeClaim(publicClient, account), 'Fee claim')}>
        {busy ? 'Working…' : 'Claim MON fees'}
      </button>
    </div>
    {buybacks.length > 0 && <div className="earn-row-group">
      <span className="field-label">Vested buyback proceeds</span>
      {buybacks.map((row) => <div className="earn-row" key={row.token}>
        <span>{row.symbol} · releasable {Number(row.releasable) / 1e18}</span>
        <span>
          <button className="btn ghost" disabled={busy} onClick={() => run(() => prepareBuybackRelease(publicClient, row.token, account), `Buyback release ${row.symbol}`)}>Release</button>
          <button className="btn ghost" disabled={busy} onClick={() => run(() => prepareFeeClaimToken(publicClient, account, row.token), `Token claim ${row.symbol}`)} title="Released buyback credit arrives as escrowed tokens; claim them here after releasing.">Claim tokens</button>
        </span>
      </div>)}
    </div>}
    {error && <div role="alert" className="form-error">{error}</div>}
    <p className="earn-empty">Claims settle directly from the deployed FeeEscrow and BuybackVault contracts.</p>
  </section>;
}
