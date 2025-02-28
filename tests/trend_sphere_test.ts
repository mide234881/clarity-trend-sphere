// [Previous imports remain unchanged]

Clarinet.test({
    name: "Validates items properly and enforces reward caps",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const voter = accounts.get('wallet_1')!;
        
        // First create some items
        let itemBlock = chain.mineBlock([
            Tx.contractCall('trend-sphere', 'list-item', [
                types.ascii("Item 1"),
                types.ascii("Description"),
                types.uint(100),
                types.ascii("streetwear")
            ], deployer.address)
        ]);
        
        itemBlock.receipts[0].result.expectOk().expectUint(0);
        
        // Try to create collection with invalid item
        let invalidBlock = chain.mineBlock([
            Tx.contractCall('trend-sphere', 'create-collection', [
                types.ascii("Invalid Collection"),
                types.ascii("Description"),
                types.ascii("streetwear"),
                types.list([types.uint(999)]) // Invalid item ID
            ], deployer.address)
        ]);
        
        invalidBlock.receipts[0].result.expectErr(105); // err-invalid-item
        
        // Create valid collection and test reward caps
        let validBlock = chain.mineBlock([
            Tx.contractCall('trend-sphere', 'create-collection', [
                types.ascii("Valid Collection"),
                types.ascii("Description"),
                types.ascii("streetwear"),
                types.list([types.uint(0)])
            ], deployer.address)
        ]);
        
        validBlock.receipts[0].result.expectOk().expectUint(0);
        
        // Add many votes to test reward cap
        for(let i = 0; i < 200; i++) {
            chain.mineBlock([
                Tx.contractCall('trend-sphere', 'vote-for-collection', [
                    types.uint(0)
                ], voter.address)
            ]);
        }
        
        let claimBlock = chain.mineBlock([
            Tx.contractCall('trend-sphere', 'claim-collection-rewards', [
                types.uint(0)
            ], deployer.address)
        ]);
        
        // Should be capped at max-reward (1000)
        claimBlock.receipts[0].result.expectOk().expectUint(1000);
    }
});

// [Previous tests remain unchanged]
