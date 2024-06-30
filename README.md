# FlexableNFT Smart Contract

Smart contract deployed to Polygon Network

### Base Sepolia Testnet
[Explorer](https://sepolia.basescan.org/address/0x900eeDD8F96c1623Fe9125531ea3a90e1318f9bB#code)
```
FlexableNFT deployed to 0x900eeDD8F96c1623Fe9125531ea3a90e1318f9bB
```
### Mainnet

[Explorer](https://polygonscan.com/address/0x0B6bf4A1769Cc286269Ca4954c638eb0D323161c#code)
```
FlexableNFT deployed to 0x0B6bf4A1769Cc286269Ca4954c638eb0D323161c
```

# Testing and development

- Install Packages - `yarn install`
- Run tests - `yarn test`
- After chaging contract write tests(if required) in `test/FlexableNFT.ts` and run `yarn test` again
- Coverage - `yarn coverage`
- Deploy - `yarn hardhat run scripts/deploy.ts --network matic`
- Verify - `yarn hardhat verify --network matic 0x0B6bf4A1769Cc286269Ca4954c638eb0D323161c "FlexableNFT" "FLEX"`

# TheGraph Deployment

```
graph init --product hosted-service weareflexable/flexablenft
graph codegen && graph build
graph auth --product hosted-service $GRAPH_TOKEN
graph deploy --product hosted-service weareflexable/flexablenft
```

Build completed: QmPSBigtJhXK72PnCMVFDm7aLVkzWK6o7NS5Z2qX9E2q4q

Deployed to https://thegraph.com/explorer/subgraph/weareflexable/flexablenft

Subgraph endpoints:
Queries (HTTP):     https://api.thegraph.com/subgraphs/name/weareflexable/flexablenft
