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
