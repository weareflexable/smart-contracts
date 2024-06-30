# FlexableNFT Smart Contract

Smart contract deployed to Polygon Network

### Mumbai Testnet
[Explorer](https://mumbai.polygonscan.com/address/0xDC34c09270bFe7316854E6B58647d63616dEFD6d#code)
```
FlexableNFT deployed to 0xDC34c09270bFe7316854E6B58647d63616dEFD6d
```
### Mainnet

[Explorer](https://polygonscan.com/address/0x0B6bf4A1769Cc286269Ca4954c638eb0D323161c#code)
```
FlexableNFT deployed to 0x0B6bf4A1769Cc286269Ca4954c638eb0D323161c
```

### Base Sepolia Testnet
[Explorer](https://mumbai.polygonscan.com/address/0xDC34c09270bFe7316854E6B58647d63616dEFD6d#code)
```
FlexableNFT deployed to 0xDC34c09270bFe7316854E6B58647d63616dEFD6d

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


## The Base Graph Endpoint

Subgraph endpoints:
Queries (HTTP):  https://api.studio.thegraph.com/query/45177/flexable_nft/v0.0.1