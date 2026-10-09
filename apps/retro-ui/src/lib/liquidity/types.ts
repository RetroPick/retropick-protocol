import type { Outcome } from '../domain/types';
export type VenueId='kuru'|'uniswap-v4'|'polymarket';
export interface LiquiditySource {venue:VenueId;network:'Monad'|'Polygon';instrument:'NATIVE_OUTCOME'|'EXTERNAL_PREDICTION';structure:'CLOB'|'AMM';status:'DEMO'|'PLANNED';executable:boolean;quoteAsset:string;supportsLimit:boolean;}
export interface Quote {marketId:string;outcome:Outcome|'PRISM';venue:VenueId;network:string;quoteAsset:string;spend:number;quantity:number;averagePrice:number;fee:number;minimumReceived:number;expiresAt:number;provenance:'DEMO';}
export interface LiquidityVenueAdapter {source:LiquiditySource;quote(input:{marketId:string;outcome:Outcome|'PRISM';spend:number;price:number}):Quote;prepareTrade(quote:Quote):never;}
