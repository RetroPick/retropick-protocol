import { type Abi, type Address, type Hex, type Log, decodeErrorResult, decodeEventLog, toFunctionSelector } from 'viem';
import { coordinatorAbi, curveAbi, factoryAbi, kuruAbi, marginAbi, tokenAbi } from './abi.ts';
import { retroPickBuybackVaultV2Abi, retroPickFeeEscrowV2Abi } from '@retropick/abi/abi';

/** ABIs whose events/errors the application decodes from receipts. */
export const decodeAbis = [
  factoryAbi,
  coordinatorAbi,
  curveAbi,
  tokenAbi,
  kuruAbi,
  marginAbi,
  retroPickFeeEscrowV2Abi,
  retroPickBuybackVaultV2Abi,
] as unknown as readonly Abi[];

export type DecodedEvent = { eventName: string; args: Record<string, unknown>; logIndex: number; address: Address };

/** Decode receipt logs against a set of ABIs, optionally filtering by event name. */
export function decodeEvents(logs: Pick<Log, 'address' | 'topics' | 'data' | 'logIndex'>[], abis: readonly Abi[] = decodeAbis, names?: readonly string[]): DecodedEvent[] {
  const found: DecodedEvent[] = [];
  for (const log of logs) {
    for (const abi of abis) {
      try {
        const parsed = decodeEventLog({ abi, data: log.data, topics: log.topics as [Hex, ...Hex[]], strict: false });
        if (parsed.eventName && (!names || names.includes(parsed.eventName))) {
          found.push({ eventName: parsed.eventName, args: parsed.args as unknown as Record<string, unknown>, logIndex: Number(log.logIndex), address: log.address as Address });
          break;
        }
      } catch {
        // not from this abi
      }
    }
  }
  return found.sort((a, b) => a.logIndex - b.logIndex);
}

export function firstEvent(logs: Parameters<typeof decodeEvents>[0], eventName: string): DecodedEvent | undefined {
  return decodeEvents(logs, decodeAbis, [eventName])[0];
}

// --- Flow-specific decoders ------------------------------------------------

export function decodeTokenLaunched(logs: Parameters<typeof decodeEvents>[0]) {
  return firstEvent(logs, 'TokenLaunched');
}

/** Curve trade lifecycle: buy/sell/refund/terminal completion. */
export function decodeCurveTrade(logs: Parameters<typeof decodeEvents>[0]) {
  return decodeEvents(logs, decodeAbis, ['CurveBuy', 'CurveSell', 'CurveBuyRefunded', 'CurveCompleted']);
}

export function decodeGraduation(logs: Parameters<typeof decodeEvents>[0]) {
  return decodeEvents(logs, decodeAbis, ['LaunchCommitted', 'GraduationSecured', 'GraduationCompleted', 'PoolGraduated']);
}

/** Order ids must come from confirmed OrderCreated logs, never counters. */
export function decodeOrderCreated(logs: Parameters<typeof decodeEvents>[0]) {
  return decodeEvents(logs, [kuruAbi as unknown as Abi], ['OrderCreated']).map((event) => ({
    orderId: Number(event.args.orderId),
    owner: event.args.owner as Address,
    size: event.args.size as bigint,
    price: event.args.price as bigint,
    isBuy: Boolean(event.args.isBuy),
  }));
}

export function decodeOrderCancellations(logs: Parameters<typeof decodeEvents>[0]) {
  return decodeEvents(logs, [kuruAbi as unknown as Abi], ['OrderCanceled', 'OrdersCanceled', 'FlipOrdersCanceled']);
}

export function decodeKuruFills(logs: Parameters<typeof decodeEvents>[0]) {
  return decodeEvents(logs, [kuruAbi as unknown as Abi], ['Trade']);
}

export function decodeEscrowClaim(logs: Parameters<typeof decodeEvents>[0]) {
  return decodeEvents(logs, [retroPickFeeEscrowV2Abi as unknown as Abi], ['FeesClaimed', 'Claimed', 'TokenFeesClaimed']);
}

export function decodeBuybackRelease(logs: Parameters<typeof decodeEvents>[0]) {
  return firstEvent(logs, 'Released');
}

// --- Custom error decoding --------------------------------------------------

export type ErrorCatalogEntry = { abi: Abi; name: string; args: Record<string, unknown> };
type ErrorSelectorMap = Map<Hex, { abi: Abi; definition: unknown }>;

const errorMapCache = new WeakMap<readonly Abi[], ErrorSelectorMap>();

/** Build (and cache) a 4-byte selector map over every custom error in the ABIs. */
export function buildErrorSelectorMap(abis: readonly Abi[] = decodeAbis): ErrorSelectorMap {
  const cached = errorMapCache.get(abis);
  if (cached) return cached;
  const map: ErrorSelectorMap = new Map();
  for (const abi of abis) {
    for (const item of abi as unknown as { type: string; name?: string; inputs?: { type: string }[] }[]) {
      if (item.type !== 'error' || !item.name) continue;
      const signature = `${item.name}(${(item.inputs ?? []).map((input) => input.type).join(',')})`;
      map.set(toFunctionSelector(signature), { abi, definition: item });
    }
  }
  errorMapCache.set(abis, map);
  return map;
}

/** Decode revert payload data against the error selector map. */
export function decodeRevertData(data: Hex | undefined, map: ErrorSelectorMap = buildErrorSelectorMap()): ErrorCatalogEntry | undefined {
  if (!data || data.length < 10) return undefined;
  const selector = data.slice(0, 10) as Hex;
  const entry = map.get(selector);
  if (!entry) return undefined;
  try {
    const decoded = decodeErrorResult({ abi: entry.abi, data });
    return { abi: entry.abi, name: decoded.errorName, args: decoded.args as unknown as Record<string, unknown> };
  } catch {
    return { abi: entry.abi, name: String((entry.definition as { name: string }).name), args: {} };
  }
}

export type RevertClassification =
  | { kind: 'user-rejected'; decoded?: never }
  | { kind: 'revert'; message: string; decoded?: ErrorCatalogEntry }
  | { kind: 'rpc'; message: string }
  | { kind: 'unknown'; message: string };

/** Classify a wallet/RPC error: rejection vs decoded revert vs transport failure. */
export function classifyError(error: unknown, map: ErrorSelectorMap = buildErrorSelectorMap()): RevertClassification {
  const seen = new Set<unknown>();
  let cause: unknown = error;
  while (cause && typeof cause === 'object' && !seen.has(cause)) {
    seen.add(cause);
    const e = cause as { name?: string; shortMessage?: string; message?: string; data?: Hex; cause?: unknown };
    if (e.name === 'UserRejectedRequestError' || e.name === 'TransactionRejectedRpcError') {
      return { kind: 'user-rejected' };
    }
    if (e.data && /^0x[0-9a-fA-F]+$/.test(e.data)) {
      const decoded = decodeRevertData(e.data, map);
      if (decoded) return { kind: 'revert', message: `${decoded.name}(${Object.values(decoded.args ?? {}).join(', ')})`, decoded };
    }
    if (e.name === 'ContractFunctionRevertedError' && e.message) {
      return { kind: 'revert', message: e.message };
    }
    if (e.name === 'HttpRequestError' || e.name === 'TimeoutError' || e.name === 'RpcError' || e.name === 'TransactionExecutionError') {
      return { kind: 'rpc', message: e.shortMessage ?? e.message ?? 'Network request failed.' };
    }
    cause = e.cause;
  }
  const shaped = error as { shortMessage?: string; message?: string } | undefined;
  const message = shaped?.shortMessage ?? shaped?.message ?? (error instanceof Error ? error.message : String(error));
  return { kind: 'unknown', message: message || 'Transaction failed.' };
}
