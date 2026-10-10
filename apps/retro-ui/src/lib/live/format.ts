import { formatUnits } from 'viem';

/**
 * The single display boundary: exact bigint/string raws become human numbers
 * only here, for rendering and ordering. User-signed amounts never round-trip
 * through these values — they use the SDK's bigint parseExact/minOutput path.
 */
export function rawToDisplay(raw: string | null | undefined, decimals: number): number | null {
  if (raw === null || raw === undefined || raw === '') return null;
  try {
    return Number(formatUnits(BigInt(raw), decimals));
  } catch {
    return null;
  }
}

/** Indexer prices are 1e18-scaled fixed-point (quote per token). */
export function priceToDisplay(priceRaw: string | null | undefined): number | null {
  return rawToDisplay(priceRaw, 18);
}

export function bpsToPercent(bps: string | null | undefined): number | null {
  if (bps === null || bps === undefined || bps === '') return null;
  const value = Number(bps);
  return Number.isFinite(value) ? value / 100 : null;
}

export function shortAddress(address: string | undefined): string {
  return address ? `${address.slice(0, 6)}…${address.slice(-4)}` : '—';
}

/** Exact display formatting: truncates insignificant digits without floating point. */
export function exactAmount(raw: string | bigint | null | undefined, decimals = 18, digits = 6): string {
  if (raw == null) return '—';
  try {
    const text = formatUnits(BigInt(raw), decimals);
    const [whole, fraction = ''] = text.split('.');
    const clipped = fraction.slice(0, digits).replace(/0+$/, '');
    return whole + (clipped ? '.' + clipped : (BigInt(raw) !== 0n && whole === '0' ? '…' : ''));
  } catch { return '—'; }
}
export function age(timestamp: number): string {
  const seconds = Math.max(0, Math.floor(Date.now()/1000 - timestamp));
  return seconds < 60 ? 'just now' : seconds < 3600 ? Math.floor(seconds/60)+'m' : seconds < 86400 ? Math.floor(seconds/3600)+'h' : Math.floor(seconds/86400)+'d';
}
