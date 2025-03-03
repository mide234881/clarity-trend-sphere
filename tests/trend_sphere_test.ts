Clarinet.test({
    name: "Validates items properly and enforces reward caps",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const voter = accounts.get('wallet_1')!;
        
        // Create test item
        let itemBlock = chain.mineBlock([
            Tx.contractCall('trend-sphere', 'list-item', [
                types.ascii("Item 1"),
                types.ascii("Description"),
                types.uint(100),
                types.ascii("streetwear")
            ], deployer.address)
        ]);
        
        itemBlock.receipts[0].result.expectOk().expectUint(0);
        
        // Test invalid item collection
        let invalidBlock = chain.mineBlock([
            Tx.contractCall('trend-sphere', 'create-collection', [
                types.ascii("Invalid Collection"),
                types.ascii("Description"),
                types.ascii("streetwear"),
                types.list([types.uint(999)])
            ], deployer.address)
        ]);
        
        invalidBlock.receipts[0].result.expectErr(105);
        
        // Test reward calculation
        let validBlock = chain.mineBlock([
            Tx.contractCall('trend-sphere', 'create-collection', [
                types.ascii("Valid Collection"),
                types.ascii("Description"),
                types.ascii("streetwear"),
                types.list([types.uint(0)])
            ], deployer.address)
        ]);
        
        validBlock.receipts[0].result.expectOk().expectUint(0);
        
        // Test progressive rewards
        let expectedReward = 100; // base-reward
        for(let i = 0; i < 10; i++) {
            chain.mineBlock([
                Tx.contractCall('trend-sphere', 'vote-for-collection', [
                    types.uint(0)
                ], voter.address)
            ]);
            expectedReward = Math.min(1000, expectedReward + 5); // vote-multiplier
        }
        
        let claimBlock = chain.mineBlock([
            Tx.contractCall('trend-sphere', 'claim-collection-rewards', [
                types.uint(0)
            ], deployer.address)
        ]);
        
        claimBlock.receipts[0].result.expectOk().expectUint(expectedReward);
    }
});
