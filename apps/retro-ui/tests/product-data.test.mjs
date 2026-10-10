import test from 'node:test';
import assert from 'node:assert/strict';
import {chartData} from '../src/features/launchpad/chart-data.ts';
import {exactAmount} from '../src/lib/live/format.ts';
test('chart shares sorted unique canonical OHLC timestamps and quote volume units',()=>{
 const candle=(timestamp,close='2000000000000000000')=>({timestamp,open:'1000000000000000000',high:'3000000000000000000',low:'1000000000000000000',close,quoteVolumeRaw:'123000000',tradeCount:1});
 const data=chartData([candle(120),candle(60),candle(120,'3000000000000000000')],6);
 assert.deepEqual(data.line,[{time:60,value:2},{time:120,value:3}]);
 assert.equal(data.volume[0].value,123);assert.equal(data.candles[1].close,3);
});
test('chart never manufactures missing trades or accepts invalid OHLC',()=>{
 assert.deepEqual(chartData([],18),{line:[],candles:[],volume:[]});
 assert.equal(chartData([{timestamp:1,open:'5',high:'1',low:'0',close:'5',quoteVolumeRaw:'0',tradeCount:1}],18).line.length,0);
});
test('exact formatting retains integer digits beyond Number precision',()=>{
 assert.equal(exactAmount('123456789012345678901234567890',18),'123456789012.345678');
 assert.equal(exactAmount('123456789',6,4),'123.4567');assert.equal(exactAmount(null),'—');
});
