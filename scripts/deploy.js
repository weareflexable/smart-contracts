const fs = require("fs");
const { ethers, run, network } = require("hardhat");

async function main() {
  /// DEPLOY FlexablePassNFT
  console.log("Deploying FlexablePassNFT...");
  const FlexablePassNFTFactory = await hre.ethers.getContractFactory(
    "FlexablePassNFT"
  );
  const FlexablePassNFT = await FlexablePassNFTFactory.deploy();

  await FlexablePassNFT.deployed();

  console.log("FlexablePassNFT Contract Deployed to:", FlexablePassNFT.address);
  contractAddress = FlexablePassNFT.address;
  blockNumber = FlexablePassNFT.provider._maxInternalBlockNumber;

  /// VERIFY
  if (hre.network.name != "hardhat") {
    await FlexablePassNFT.deployTransaction.wait(6);
    await verify(FlexablePassNFT.address, []);
  }

  /// DEPLOY FlexablePaymentSplitter
  const USDC_ADDRESS = "0x214f178D9b1a888C48a1E8f329065Fba011d17F2";
  console.log("Deploying FlexablePaymentSplitter...");
  const FlexablePaymentSplitterFactory = await hre.ethers.getContractFactory(
    "FlexablePaymentSplitter"
  );
  const FlexablePaymentSplitter = await FlexablePaymentSplitterFactory.deploy(
    USDC_ADDRESS,
    FlexablePassNFT.address
  );

  await FlexablePaymentSplitter.deployed();

  console.log("FlexablePassNFT Contract Deployed to:", FlexablePassNFT.address);
  contractAddress = FlexablePassNFT.address;
  blockNumber = FlexablePassNFT.provider._maxInternalBlockNumber;

  /// VERIFY
  if (hre.network.name != "hardhat") {
    await FlexablePaymentSplitter.deployTransaction.wait(6);
    await verify(FlexablePaymentSplitter.address, [
      USDC_ADDRESS,
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
