import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can create a new collection with category",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const items = [types.uint(1), types.uint(2)];
        
        let block = chain.mineBlock([
            Tx.contractCall('trend-sphere', 'create-collection', [
                types.ascii("Summer Collection"),
                types.ascii("Hot trends for summer 2024"),
                types.ascii("streetwear"),
                types.list(items)
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectOk().expectUint(0);
        
        let getCollection = chain.mineBlock([
            Tx.contractCall('trend-sphere', 'get-collection', [
                types.uint(0)
            ], deployer.address)
        ]);
        
        const collection = getCollection.receipts[0].result.expectOk().expectSome();
        assertEquals(collection['category'], "streetwear");
    }
});

Clarinet.test({
    name: "Can vote and earn rewards",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const voter = accounts.get('wallet_1')!;
        const items = [types.uint(1), types.uint(2)];
        
        // Create collection
        let block = chain.mineBlock([
            Tx.contractCall('trend-sphere', 'create-collection', [
                types.ascii("Summer Collection"),
                types.ascii("Hot trends for summer 2024"),
                types.ascii("streetwear"),
                types.list(items)
            ], deployer.address)
        ]);
        
        // Vote for collection
        let voteBlock = chain.mineBlock([
            Tx.contractCall('trend-sphere', 'vote-for-collection', [
                types.uint(0)
            ], voter.address)
        ]);
        
        voteBlock.receipts[0].result.expectOk().expectBool(true);
        
        // Check reward pool
        let rewardPool = chain.mineBlock([
            Tx.contractCall('trend-sphere', 'get-reward-pool', [], deployer.address)
        ]);
        
        assertEquals(rewardPool.receipts[0].result.expectOk(), types.uint(10));
        
        // Claim rewards
        let claimBlock = chain.mineBlock([
            Tx.contractCall('trend-sphere', 'claim-collection-rewards', [
                types.uint(0)
            ], deployer.address)
        ]);
        
        claimBlock.receipts[0].result.expectOk().expectUint(5);
    }
});
