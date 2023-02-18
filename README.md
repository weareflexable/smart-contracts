# FlexableNFT Smart Contract

Smart contract deployed to Polygon Network

### Mumbai Testnet
[Explorer](https://mumbai.polygonscan.com/address/0xDC34c09270bFe7316854E6B58647d63616dEFD6d#code)
```
FlexableNFT deployed to 0xDC34c09270bFe7316854E6B58647d63616dEFD6d
```
### Mainnet

[IN TESTING]()
```
```

# Testing and development

- Install Packages - `yarn install`
- Run tests - `yarn test`
- After chaging contract write tests(if required) in `test/FlexableNFT.ts` and run `yarn test` again
- Coverage - `yarn coverage`

# TheGraph Deployment

```
graph init --index-events
graph codegen && graph build
graph auth --product hosted-service $GRAPH_TOKEN
graph deploy --product hosted-service weareflexable/flexablenft-mumbai
```

Build completed: QmY3bCFm9vEMzqh5M1Ya9Fc9nUVgNstMFGzn8XVhQSgceW

Deployed to https://thegraph.com/explorer/subgraph/weareflexable/flexablenft-mumbai

Subgraph endpoints:
Queries (HTTP):     https://api.thegraph.com/subgraphs/name/weareflexable/flexablenft-mumbai