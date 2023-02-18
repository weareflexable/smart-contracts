# Tests

This folder contains tests which will executed after running `yarn test`
Before running test make sure you have installed packages using `yarn install`

We use default test suite which is provided by mocha. With it you can have multiple `it` covering each test case

Proper use of await should be done to make sure test works as they are intended

For example, for testing reverts, it is observed that using await in except will not check the revert properly.