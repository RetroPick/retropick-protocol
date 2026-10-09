export type NativeState = 'DRAFT' | 'OPEN' | 'LOCKED' | 'RESOLUTION_PENDING' | 'RESOLVED' | 'REDEEMABLE' | 'ARCHIVED';
export type SeriesState = 'DRAFT' | 'ACTIVE' | 'MINT_PAUSED' | 'RESOLUTION_PENDING' | 'RESOLVED' | 'REDEEMABLE' | 'ARCHIVED';
export type Outcome = 'YES' | 'NO';
// Presentation draft from canonical workflow §9.3; hashes/IDs are not manufactured.
export interface ResolutionSpec { sourceType: string; sourceIdentifier: string; condition: string; observationWindow: string; resolutionTimestamp: string; deadline: string; validValues: readonly ['YES','NO']; invalidCancelPolicy: string; fallbackPolicy: string; adapterVersion: string | null; evidenceSchemaHash: string | null; questionHash: string | null; }
export interface EventMarket { id:string; question:string; description:string; category:'Crypto'|'Macro'|'Technology'|'Sports'; symbol:string; icon:string; color:string; state:NativeState; yes:number; no:number; change:number; volume:number; collateral:number; depth:number; expires:string; created:string; creator:string; resolution:ResolutionSpec; provenance:'DEMO'; }
export interface Position { id:string; marketId:string; side:Outcome|'PRISM'; quantity:number; entry:number; state:NativeState|SeriesState; payout?:number; funded?:boolean; }
export interface DemoOrder { id:string; marketId:string; side:Outcome|'PRISM'; price:number; quantity:number; status:'OPEN'|'CANCELLED'; reservedCash:number; }
export interface Activity { id:string; action:'Buy'|'Sell'|'Market created'|'Mint'|'Redemption'|'Resolution'; marketId:string; label:string; amount:number; value:number; time:string; }
