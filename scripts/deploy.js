const fs = require("fs");
const { ethers, run, network } = require("hardhat");

async function main() {
  let owner = await ethers.getSigner();
  console.log("Owner address:", owner.address);

  /**************************** DEPLOY AUTH ****************************/
  console.log("Deploying FlexableAuth...");
  const FlexableAuthFactory = await hre.ethers.getContractFactory(
    "FlexableAuth"
  );
  const FlexableAuth = await FlexableAuthFactory.deploy();

  await FlexableAuth.deployed();

  console.log("FlexableAuth Contract Deployed to:", FlexableAuth.address);
  contractAddress = FlexableAuth.address;
  blockNumber = FlexableAuth.provider._maxInternalBlockNumber;

  /// VERIFY

  if (hre.network.name != "hardhat") {
    await FlexableAuth.deployTransaction.wait(6);
    await verify(FlexableAuth.address, []);
  }

  /**************************** DEPLOY FlexablePassNFT ****************************/
  console.log("Deploying MockERC20...");
  const RCFactory = await hre.ethers.getContractFactory("MockERC20");
  const MockERC20 = await RCFactory.deploy();

  await MockERC20.deployed();

  console.log("MockERC20 Contract Deployed to:", MockERC20.address);
  contractAddress = MockERC20.address;

  /// VERIFY
  if (hre.network.name != "hardhat") {
    await MockERC20.deployTransaction.wait(6);
    await verify(MockERC20.address, []);
  }

  /**************************** DEPLOY FlexableVendor ****************************/
  console.log("Deploying FlexableVendor...");
  const FlexableVendorFactory = await hre.ethers.getContractFactory(
    "FlexableVendor"
  );
  const FlexableVendor = await FlexableVendorFactory.deploy(
    FlexableAuth.address
  );

  await FlexableVendor.deployed();

  console.log("FlexableVendor Contract Deployed to:", FlexableVendor.address);
  contractAddress = FlexableVendor.address;
  blockNumber = FlexableVendor.provider._maxInternalBlockNumber;

  /// VERIFY
  if (hre.network.name != "hardhat") {
    await FlexableVendor.deployTransaction.wait(6);
    await verify(FlexableVendor.address, [FlexableAuth.address]);
  }

  /**************************** DEPLOY FlexablePassNFT ****************************/
  console.log("Deploying FlexablePassNFT...");
  const FlexablePassNFTFactory = await hre.ethers.getContractFactory(
    "FlexablePass"
  );
  const FlexablePassNFT = await FlexablePassNFTFactory.deploy(
    FlexableAuth.address
  );

  await FlexablePassNFT.deployed();

  console.log("FlexablePassNFT Contract Deployed to:", FlexablePassNFT.address);
  contractAddress = FlexablePassNFT.address;
  blockNumber = FlexablePassNFT.provider._maxInternalBlockNumber;

  /// VERIFY
  if (hre.network.name != "hardhat") {
    await FlexablePassNFT.deployTransaction.wait(6);
    await verify(FlexablePassNFT.address, [FlexableAuth.address]);
  }

  /**************************** DEPLOY Community ****************************/
  console.log("Deploying FlexableCommunity...");
  const FlexableCommunityFactory = await hre.ethers.getContractFactory(
    "FlexableCommunity"
  );
  const FlexableCommunity = await FlexableCommunityFactory.deploy(
    MockERC20.address,
    owner.address,
    FlexableAuth.address,
    FlexableVendor.address,
    FlexablePassNFT.address
  );

  await FlexableCommunity.deployed();

  console.log(
    "FlexableCommunity Contract Deployed to:",
    FlexableCommunity.address
  );
  contractAddress = FlexableCommunity.address;
  blockNumber = FlexableCommunity.provider._maxInternalBlockNumber;

  /// VERIFY
  if (hre.network.name != "hardhat") {
    await FlexableCommunity.deployTransaction.wait(6);
    await verify(FlexableCommunity.address, [
      MockERC20.address,
      owner.address,
      FlexableAuth.address,
      FlexableVendor.address,
      FlexablePassNFT.address,
    ]);
  }
}

// async function verify(contractAddress, args) {
const verify = async (contractAddress, args) => {
  console.log("Verifying contract...");
  try {
    await run("verify:verify", {
      address: contractAddress,
      constructorArguments: args,
    });
    Verified = true;
  } catch (e) {
    if (e.message.toLowerCase().includes("already verified")) {
      console.log("Already Verified!");
    } else {
      console.log(e);
    }
  }
};

// main
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
