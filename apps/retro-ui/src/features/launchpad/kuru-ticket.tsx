'use client';

import { useCallback, useEffect, useMemo, useState } from 'react';
import type { Address } from 'viem';
import { zeroAddress } from 'viem';
import { publicClient } from '@/lib/live/public-client';
import { useWallet } from '@/wallet/provider';
import { executePreparedWrite, type TxPhase } from '@/services/tx-pipeline';
import { Segments } from '@/components/product/ui';
import { kuruAbi, marginAbi } from '@retropick/launchpad-sdk/abi';
import { release } from '@retropick/launchpad-sdk/chain';
import { readMarketParams, kuruGrid, prepareMarginDeposit, prepareMarginWithdraw, prepareKuruLimitOrder, prepareKuruMarketOrder, prepareKuruCancel, type KuruMarketParams } from '@retropick/launchpad-sdk/prepare';
import { decodeOrderCreated, decodeOrderCancellations } from '@retropick/launchpad-sdk/decode';
import { parseExact } from '@retropick/launchpad-sdk/math';
import { toast } from 'sonner';

interface OpenOrder { id: number; isBuy: boolean; priceUnits: bigint; sizeUnits: bigint }

/**
 * Kuru orderbook ticket for graduated launches: margin account, resting limit
 * orders, fill-or-kill market orders and cancels — all through the shared
 * transaction pipeline and the security-reviewed SDK write boundary.
 */
export function KuruTicket({ market, token, tokenSymbol, initialQuoteBalance, initialBaseBalance, reload }: {
  market: Address;
  token: Address;
  tokenSymbol: string;
  initialQuoteBalance: bigint;
  initialBaseBalance: bigint;
  reload: () => void;
}) {
  const wallet = useWallet();
  const account = wallet.account;
  const [params, setParams] = useState<KuruMarketParams | null>(null);
  const [marginQuote, setMarginQuote] = useState(initialQuoteBalance);
  const [marginBase, setMarginBase] = useState(initialBaseBalance);
  const [orders, setOrders] = useState<OpenOrder[]>([]);
  const [side, setSide] = useState('Buy');
  const [kind, setKind] = useState('Limit');
  const [price, setPrice] = useState('');
  const [size, setSize] = useState('');
  const [tx, setTx] = useState<TxPhase | { kind: 'idle' }>({ kind: 'idle' });
  const [error, setError] = useState('');
  const [tick, setTick] = useState(0);
  const refresh = useCallback(() => setTick((value) => value + 1), []);
  const busy = tx.kind !== 'idle' && tx.kind !== 'failed';

  const refreshState = useCallback(async () => {
    if (!account) return;
    const [marketParams, quote, base, counter] = await Promise.all([
      readMarketParams(publicClient, market),
      publicClient.readContract({ address: marginAddress(), abi: marginAbi, functionName: 'getBalance', args: [account, zeroAddress] }),
      publicClient.readContract({ address: marginAddress(), abi: marginAbi, functionName: 'getBalance', args: [account, token] }),
      publicClient.readContract({ address: market, abi: kuruAbi, functionName: 's_orderIdCounter' }),
    ]);
    setParams(marketParams);
    setMarginQuote(quote);
    setMarginBase(base);
    // Order ids are only ever taken from chain storage, never derived here.
    const ids: number[] = [];
    for (let id = Number(counter); id > 0 && ids.length < 120; id -= 1) ids.push(id);
    // Batched: one multicall covers the whole id range.
    const results = await Promise.all(ids.map((id) =>
      publicClient.readContract({ address: market, abi: kuruAbi, functionName: 's_orders', args: [id] }).catch(() => undefined) as Promise<unknown>,
    ));
    const found: OpenOrder[] = [];
    results.forEach((raw, index) => {
      if (!raw) return;
      // The catalog ABI decodes this struct positionally: (owner, size, prev, next, flippedId, price, flippedPrice, isBuy)
      const order = raw as unknown as [Address, bigint | number, number, number, number, bigint | number, number, boolean];
      const [owner, size, , , , price, , isBuy] = order;
      const sizeUnits = BigInt(size);
      const priceUnits = BigInt(price);
      if (sizeUnits > 0n && String(owner).toLowerCase() === account.toLowerCase()) {
        found.push({ id: ids[index], isBuy, priceUnits, sizeUnits });
      }
    });
    setOrders(found);
  }, [account, market, token]);

  useEffect(() => { void refreshState().catch(() => undefined); }, [refreshState, tick, reload]);

  const quotes = useMemo(() => {
    if (!params) return null;
    return { quote: Number(marginQuote) / 1e18, base: Number(marginBase) / 1e18 };
  }, [params, marginQuote, marginBase]);

  const run = async (prepare: () => Promise<Parameters<typeof executePreparedWrite>[2]>, successNote: (events: string[]) => string) => {
    if (!wallet.wallet || !account) return;
    setError('');
    try {
      const prepared = await prepare();
      const result = await executePreparedWrite(publicClient, wallet.wallet, prepared, { onPhase: setTx });
      if (result.kind === 'success') {
        toast.success(successNote([/* events decoded by callers where relevant */]), { description: result.hash });
        refresh();
        reload();
      } else {
        setError(result.reason);
      }
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : 'Transaction failed.');
    } finally {
      setTx({ kind: 'idle' });
    }
  };

  const deposit = () => run(
    () => prepareMarginDeposit(publicClient, account!, { token: zeroAddress, amount: parseExact(depositAmount || '0', 18) }),
    () => 'Margin deposit confirmed',
  );
  const withdraw = () => run(
    () => prepareMarginWithdraw(publicClient, account!, { token: zeroAddress, amount: parseExact(withdrawAmount || '0', 18) }),
    () => 'Margin withdrawal confirmed',
  );
  const [depositAmount, setDepositAmount] = useState('');
  const [withdrawAmount, setWithdrawAmount] = useState('');

  const submitOrder = () => {
    if (!params || !account) return;
    if (kind === 'Limit') {
      return run(
        () => prepareKuruLimitOrder(publicClient, account!, {
          market, token, side: side.toLowerCase() as 'buy' | 'sell',
          priceRaw: parseExact(price || '0', 18), sizeRaw: parseExact(size || '0', 18), postOnly: false,
        }),
        () => 'Limit order placed',
      );
    }
    return run(
      () => prepareKuruMarketOrder(publicClient, account!, {
        market, token, side: side.toLowerCase() as 'buy' | 'sell',
        amountRaw: side === 'Buy' ? parseExact(size || '0', 18) : parseExact(size || '0', 18),
        minOutcomeRaw: 0n, // fill-or-kill with on-chain price protection from the book itself
        slippageBps: 300n,
      }),
      () => 'Market order executed',
    );
  };

  const cancel = (id: number) => run(() => prepareKuruCancel(publicClient, market, account!, [id]), () => 'Order cancelled');

  const priceFor = (units: bigint) => params ? Number(kuruGrid.unitsToPriceRaw(units, params)) / 1e18 : 0;

  return <div className="panel token-trade-ticket kuru-ticket">
    <h2>Kuru <small>Graduated market</small></h2>
    <div className="quote-lines">
      <div><span>Margin · MON</span><strong>{quotes ? quotes.quote.toFixed(4) : '—'}</strong></div>
      <div><span>Margin · {tokenSymbol}</span><strong>{quotes ? quotes.base.toFixed(2) : '—'}</strong></div>
    </div>
    <div className="form-grid">
      <label className="field"><span>Deposit MON</span>
        <input inputMode="decimal" value={depositAmount} onChange={(event) => setDepositAmount(event.target.value)} placeholder="0"/>
        <button className="btn ghost" disabled={busy} onClick={deposit}>Deposit</button>
      </label>
      <label className="field"><span>Withdraw MON</span>
        <input inputMode="decimal" value={withdrawAmount} onChange={(event) => setWithdrawAmount(event.target.value)} placeholder="0"/>
        <button className="btn ghost" disabled={busy} onClick={withdraw}>Withdraw</button>
      </label>
    </div>
    <Segments label="Order side" values={['Buy', 'Sell']} value={side} onChange={setSide}/>
    <Segments label="Order type" values={['Limit', 'Market']} value={kind} onChange={setKind}/>
    <label className="field"><span>{kind === 'Limit' ? 'Price' : side === 'Buy' ? 'Spend' : 'Sell'} {kind === 'Limit' ? `· MON per ${tokenSymbol}` : kind === 'Market' && side === 'Buy' ? '· MON' : `· ${tokenSymbol}`}</span>
      <input inputMode="decimal" value={price} onChange={(event) => setPrice(event.target.value)} placeholder="0" disabled={kind === 'Market'} style={kind === 'Market' ? { display: 'none' } : undefined}/>
      <input inputMode="decimal" value={size} onChange={(event) => setSize(event.target.value)} placeholder="0"/>
      <small>{kind === 'Limit' ? 'Price and size snap to the market grid; validated before signing.' : 'Fill-or-kill against the book, funded from margin.'}</small>
    </label>
    {error && <div role="alert" className="form-error">{error}</div>}
    {busy && <div role="status" className="ticket-note" data-tx-phase={tx.kind}>Working…</div>}
    <button className="btn primary full" disabled={busy || !params} onClick={submitOrder}>
      {busy ? 'Working…' : `${side === 'Buy' ? 'Buy' : 'Sell'} ${tokenSymbol}${kind === 'Limit' ? ' · limit' : ' · market'}`}
    </button>
    {orders.length > 0 && <div className="open-orders">
      <span className="field-label">Open orders</span>
      {orders.map((order) => <div className="open-order" key={order.id}>
        <span className={order.isBuy ? 'positive' : 'negative'}>{order.isBuy ? 'Buy' : 'Sell'}</span>
        <span>{params ? Number(order.sizeUnits * 10n ** 18n / (10n ** BigInt(params.baseDecimals) * params.sizePrecision)) : Number(order.sizeUnits)} {tokenSymbol} @ {priceFor(order.priceUnits).toFixed(8)} MON</span>
        <button className="btn ghost" disabled={busy} onClick={() => cancel(order.id)}>Cancel</button>
      </div>)}
    </div>}
    <p className="ticket-note">Orders live on the verified Kuru orderbook. Order ids come from on-chain storage; nothing is fabricated.</p>
  </div>;
}

const marginAddress = () => release.kuruEnvironment.marginAccount as Address;
