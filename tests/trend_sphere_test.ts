import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can create a new collection",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const items = [types.uint(1), types.uint(2)];
        
        let block = chain.mineBlock([
            Tx.contractCall('trend-sphere', 'create-collection', [
                types.ascii("Summer Collection"),
                types.ascii("Hot trends for summer 2024"),
                types.list(items)
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectOk().expectUint(0);
        
        // Verify collection was created
        let getCollection = chain.mineBlock([
            Tx.contractCall('trend-sphere', 'get-collection', [
                types.uint(0)
            ], deployer.address)
        ]);
        
        const collection = getCollection.receipts[0].result.expectOk().expectSome();
        assertEquals(collection['title'], "Summer Collection");
    }
});

Clarinet.test({
    name: "Can vote for a collection",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const voter = accounts.get('wallet_1')!;
        const items = [types.uint(1), types.uint(2)];
        
        // First create a collection
        let block = chain.mineBlock([
            Tx.contractCall('trend-sphere', 'create-collection', [
                types.ascii("Summer Collection"),
                types.ascii("Hot trends for summer 2024"),
                types.list(items)
            ], deployer.address)
        ]);
        
        // Then vote for it
        let voteBlock = chain.mineBlock([
            Tx.contractCall('trend-sphere', 'vote-for-collection', [
                types.uint(0)
            ], voter.address)
        ]);
        
        voteBlock.receipts[0].result.expectOk().expectBool(true);
        
        // Verify vote was counted
        let getCollection = chain.mineBlock([
            Tx.contractCall('trend-sphere', 'get-collection', [
                types.uint(0)
            ], deployer.address)
        ]);
        
        const collection = getCollection.receipts[0].result.expectOk().expectSome();
        assertEquals(collection['votes'], types.uint(1));
    }
});

Clarinet.test({
    name: "Can list item for sale",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const seller = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('trend-sphere', 'list-item', [
                types.ascii("Vintage Jacket"),
                types.ascii("Classic denim jacket from the 90s"),
                types.uint(100)
            ], seller.address)
        ]);
        
        block.receipts[0].result.expectOk().expectUint(0);
    }
});