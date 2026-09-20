// Bounded UI arithmetic only. Never a contract admission engine.
export function basketPreview(fedBps:number, btcBps:number, supply:number){
 if(!Number.isInteger(fedBps)||!Number.isInteger(btcBps)||fedBps<0||btcBps<0||fedBps+btcBps!==10000||!Number.isInteger(supply)||supply<1||supply>1000000) return null;
 return {payoffs:[btcBps,0,fedBps+btcBps,fedBps].map(x=>x/10000),backing:[supply*fedBps/10000,supply*btcBps/10000]};
}
export function canRedeem(state:string,funded:boolean,payout:number|undefined){return state==='REDEEMABLE'&&funded&&payout!==undefined&&payout>0;}
export function validAmount(s:string){return /^\d+(\.\d{1,2})?$/.test(s)&&Number(s)>0&&Number(s)<=10000;}
export function settlementCovered(balance:number,supply:number,payout:number){return [balance,supply,payout].every(n=>Number.isFinite(n)&&n>=0)&&balance>=supply*payout;}
