export type FiatAsset = { symbol: string; tokenAddress?: string };
export type FiatRequest = { chainId: number; asset: FiatAsset; country?: string };
export type FiatCapability = { provider: string; buy: false; sell: false; reason: string; documentationUrl: string };
export interface FiatProvider {
  capabilities(request: FiatRequest): Promise<FiatCapability>;
  buy(request: FiatRequest): Promise<never>;
  sell(request: FiatRequest): Promise<never>;
}

/** Fail closed: mainnet asset availability never qualifies Testnet 10143 delivery. */
function unavailable(provider:string,reason:string,documentationUrl:string):FiatProvider {
  const capability=(request:FiatRequest):FiatCapability=>({provider,buy:false,sell:false,reason:request.chainId===10143?reason:'This network has not been qualified for RetroPick funding.',documentationUrl});
  return {capabilities:async request=>capability(request),buy:async request=>{throw Error(capability(request).reason);},sell:async request=>{throw Error(capability(request).reason);}};
}
export const fiatProviders:ReadonlyArray<FiatProvider>=[
  unavailable('MoonPay','MoonPay sandbox does not support MON or USDC on Monad Testnet.','https://dev.moonpay.com/widget/sandbox-testing'),
  unavailable('Transak','Transak sandbox does not deliver MON or USDC on Monad Testnet.','https://docs.transak.com/guides/sandbox-credentials'),
  unavailable('Ramp','Ramp demo assets do not include MON or USDC on Monad Testnet.','https://docs.rampnetwork.com/testing-environment'),
  unavailable('Coinbase Onramp','Coinbase has not confirmed MON or USDC delivery on Monad Testnet for this integration.','https://docs.cdp.coinbase.com/onramp/additional-resources/sandbox-testing'),
];

/** Listed by official Monad network information, verified 2026-10-10. */
export const MONAD_TESTNET_FAUCET='https://faucet.monad.xyz';
export const MONAD_TESTNET_FAUCET_SOURCE='https://docs.monad.xyz/developer-essentials/testnet';
