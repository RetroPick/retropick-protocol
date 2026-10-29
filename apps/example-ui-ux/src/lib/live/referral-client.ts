import type { EvmWallet } from '@retropick/launchpad-sdk/wallet';

const FIRST_TOUCH_KEY = 'retropick-referral-first-touch-v1';
const FIRST_TOUCH_MS = 30 * 24 * 60 * 60 * 1000;
const validWallet = (value: string) => /^0x[\da-fA-F]{40}$/.test(value) && !/^0x0{40}$/i.test(value);
export type PendingReferral = { referrer: string; firstSeenAt: number; expiresAt: number };
export type ReferralSummary = {
  wallet: string; referralCode: string; earningsEnabled: false; referralPayoutRequiresProtocolChange: true;
  referredBy: string | null; referredWallets: number; qualifiedWallets: number; createdLaunches: number;
  volumeByQuote: { quote: string; volumeRaw: string }[];
  referrals: { wallet: string; firstSeenAt: string; status: 'ASSOCIATED' | 'QUALIFIED'; qualifyingAction: string | null; qualifyingTxHash: string | null; createdLaunch: string | null }[];
  freshness: { indexedBlock: number; indexedAt: string | null; lagBlocks: number } | null;
  syncError: string | null;
};

export function pendingReferral(): PendingReferral | null {
  try {
    const raw=localStorage.getItem(FIRST_TOUCH_KEY);if(!raw)return null;
    const value=JSON.parse(raw) as PendingReferral;
    const now=Date.now();
    if(!validWallet(value.referrer)||!Number.isSafeInteger(value.firstSeenAt)||value.firstSeenAt>now||value.firstSeenAt<now-FIRST_TOUCH_MS
      ||value.expiresAt!==value.firstSeenAt+FIRST_TOUCH_MS||value.expiresAt<=now){localStorage.removeItem(FIRST_TOUCH_KEY);return null;}
    return value;
  } catch{return null;}
}

/** First touch is a local attribution hint; only a signed server association establishes ownership. */
export function captureReferral(walletOrCode: string): boolean {
  if(!validWallet(walletOrCode))return false;
  if(pendingReferral())return true;
  const firstSeenAt=Date.now();
  try {localStorage.setItem(FIRST_TOUCH_KEY,JSON.stringify({referrer:walletOrCode.toLowerCase(),firstSeenAt,expiresAt:firstSeenAt+FIRST_TOUCH_MS}));return true;}
  catch{return false;}
}

export function clearPendingReferral() { try {localStorage.removeItem(FIRST_TOUCH_KEY);}catch{/* Storage can be unavailable. */} }
export function referralLink(wallet: string, origin=window.location.origin): string {
  if(!validWallet(wallet))throw Error('Invalid referral wallet');
  return `${origin}/r/${wallet.toLowerCase()}`;
}

async function request<T>(path: string,body?:unknown,signal?:AbortSignal): Promise<T> {
  const response=await fetch(`/api/referrals/${path}`,{method:body===undefined?'GET':'POST',credentials:'same-origin',
    headers:body===undefined?undefined:{'Content-Type':'application/json'},body:body===undefined?undefined:JSON.stringify(body),signal:signal??AbortSignal.timeout(8000)});
  if(response.status===401 && path==='summary')return null as T;
  const data=await response.json() as {error?:string};
  if(!response.ok)throw Error(data.error??'Referral attribution is temporarily unavailable.');
  return data as T;
}
export const getReferralSummary=(signal?:AbortSignal)=>request<ReferralSummary|null>('summary',undefined,signal);
export const logoutReferralSession=()=>request<{loggedOut:boolean}>('logout',{});

export async function verifyReferralAssociation(wallet:EvmWallet,account:string,pending:PendingReferral|null,stillCurrent:()=>boolean) {
  const referrer=pending?.referrer===account.toLowerCase()?undefined:pending?.referrer;
  const challenge=await request<{challengeId:string;message:string;expiresAt:string;chainId:number}>('challenge',{wallet:account,...(referrer?{referrer,firstSeenAt:pending!.firstSeenAt}:{})});
  if(challenge.chainId!==10143 || !stillCurrent())throw Error('Wallet changed. Please try again.');
  const signature=await wallet.signMessage({message:challenge.message});
  if(!stillCurrent())throw Error('Wallet changed. Please try again.');
  const result=await request<{wallet:string}>('verify',{challengeId:challenge.challengeId,signature});
  if(result.wallet.toLowerCase()!==account.toLowerCase()||!stillCurrent()){await logoutReferralSession();throw Error('Wallet changed. Please try again.');}
  if(referrer)clearPendingReferral();
}
