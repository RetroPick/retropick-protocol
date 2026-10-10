export const CHAIN_ID = 10143 as const;
export const REFERRAL_PAYOUT_REQUIRES_PROTOCOL_CHANGE = true as const;
export const SESSION_MS = 60 * 60 * 1000;
export const CHALLENGE_MS = 5 * 60 * 1000;
export const FIRST_TOUCH_MS = 30 * 24 * 60 * 60 * 1000;
export const PURPOSE = 'Associate a RetroPick referral and view referral attribution. No transaction or payout is authorized.';

export class ApiError extends Error {
  status: number;
  code: string;
  constructor(status: number, code: string) { super(code); this.status=status; this.code=code; }
}

export function address(value: unknown): string {
  if (typeof value !== 'string' || !/^0x[\da-fA-F]{40}$/.test(value) || /^0x0{40}$/i.test(value)) throw new ApiError(400, 'INVALID_WALLET');
  return value.toLowerCase();
}

export type Challenge = {
  id: string; wallet: string; referrer: string | null; nonce: string;
  message: string; createdAt: number; expiresAt: number; firstSeenAt: number;
};
export type Association = { referredWallet: string; referrerWallet: string; firstSeenAt: number; associatedAt: number; associationBlock: number };
export type QualifyingEvent = {
  id: string; chainId: 10143; blockNumber: number; blockHash: string; txHash: string;
  logIndex: number; transactionIndex: number; timestamp: number;
  eventName: 'TokenLaunched' | 'CurveBuy' | 'CurveSell' | 'KuruTrade';
  actor: string; token: string; quote: string; quoteAmountRaw: string;
};
export type IndexFreshness = {
  chainId: 10143; indexedBlock: number; headBlock: number; confirmations: number;
  lagBlocks: number; indexedAt: string | null; syncing: boolean; error: string | null;
  source: 'MONAD_EVENT_INDEXER'; indexedBlockHash: string; reorgRevision: number; projectionVersion: number;
};
export type ActivityEnvelope = {
  data: { events: QualifyingEvent[]; nextCursor: string | null; canonicalFromBlock: number; canonicalToBlock: number };
  freshness: IndexFreshness;
};
export type ReferralSummary = {
  wallet: string; referralCode: string; earningsEnabled: false; referralPayoutRequiresProtocolChange: true;
  referredBy: string | null; referredWallets: number; qualifiedWallets: number; createdLaunches: number;
  volumeByQuote: { quote: string; volumeRaw: string }[];
  referrals: { wallet: string; firstSeenAt: string; status: 'ASSOCIATED' | 'QUALIFIED'; qualifyingAction: string | null; qualifyingTxHash: string | null; createdLaunch: string | null }[];
  freshness: IndexFreshness | null;
};

export function validateEvent(value: unknown): QualifyingEvent {
  if (!value || typeof value !== 'object') throw new ApiError(502, 'INVALID_INDEXER_EVENT');
  const event = value as QualifyingEvent;
  if (event.chainId !== CHAIN_ID || !['TokenLaunched', 'CurveBuy', 'CurveSell', 'KuruTrade'].includes(event.eventName)
    || typeof event.id !== 'string' || event.id.length > 180 || !event.id.length
    || !/^0x[\da-fA-F]{64}$/.test(event.blockHash) || !/^0x[\da-fA-F]{64}$/.test(event.txHash)
    || ![event.blockNumber, event.logIndex, event.transactionIndex, event.timestamp].every(n => Number.isSafeInteger(n) && n >= 0)
    || typeof event.quoteAmountRaw !== 'string' || !/^\d{1,100}$/.test(event.quoteAmountRaw)
    || !/^0x[\da-fA-F]{40}$/.test(event.quote)) throw new ApiError(502, 'INVALID_INDEXER_EVENT');
  try { return { ...event, actor: address(event.actor), token: address(event.token), quote: event.quote.toLowerCase(), txHash: event.txHash.toLowerCase(), blockHash: event.blockHash.toLowerCase() }; }
  catch { throw new ApiError(502, 'INVALID_INDEXER_EVENT'); }
}
