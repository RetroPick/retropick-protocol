import { test, expect } from './protected-test';
// Routed error/empty envelopes only. These tests never add illustrative markets to the live feed.
test('indexer failures remain explicit, and unavailable category counts are not reported as zero',async({page})=>{
 await page.route(/\/v1\/launches(?:\?|$)/,route=>route.fulfill({status:502,body:'{"error":"TEST_ROUTED_UPSTREAM_FAILURE"}',contentType:'application/json'}));
 await page.goto('/launchpad');await expect(page.getByTestId('indexer-unavailable')).toHaveAttribute('data-failure-kind','http',{timeout:30000});await expect(page.getByText('No launches match these filters')).toHaveCount(0);await expect(page.getByRole('group',{name:'Market quote categories'})).toContainText('—');
});
test('wrong-chain envelopes fail closed',async({page})=>{
 await page.route(/\/v1\/launches(?:\?|$)/,route=>route.fulfill({body:JSON.stringify({data:[],freshness:{chainId:1,source:'MONAD_EVENT_INDEXER'}}),contentType:'application/json'}));
 await page.goto('/launchpad');await expect(page.getByTestId('indexer-unavailable')).toHaveAttribute('data-failure-kind','wrong-chain',{timeout:30000});
});
test('a complete empty snapshot produces an honest empty category',async({page})=>{
 await page.route(/\/v1\/launches(?:\?|$)/,route=>route.fulfill({body:JSON.stringify({data:[],nextCursor:null,freshness:{chainId:10143,indexedBlock:100,indexedBlockHash:'test-routed-empty',projectionVersion:2,reorgRevision:0,lagBlocks:0,error:null,source:'MONAD_EVENT_INDEXER'}}),contentType:'application/json'}));
 await page.goto('/launchpad?category=STOCKS');await expect(page.getByText('No launches match these filters')).toBeVisible();await expect(page.getByTestId('indexer-unavailable')).toHaveCount(0);await expect(page.getByText('0 of 0 matching launches · 0 indexed in total')).toBeVisible();
});
