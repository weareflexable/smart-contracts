const fs = require("fs");
const { ethers, run, network } = require("hardhat");

async function main() {
  /// DEPLOY FlexableAuth
  console.log("Deploying FlexableAuth...");
  const FlexableAuthFactory = await hre.ethers.getContractFactory(
    "FlexableAuth"
  );
  const FlexableAuth = await FlexableAuthFactory.deploy();

  await FlexableAuth.deployed();

  console.log("FlexableAuth Contract Deployed to:", FlexableAuth.address);

  /// VERIFY FlexableAuth
  if (hre.network.name != "hardhat") {
    await FlexableAuth.deployTransaction.wait(6);
    await verify(FlexableAuth.address, []);
  }

  /// DEPLOY FlexableVendor
  console.log("Deploying FlexableVendor...");
  const FlexableVendorFactory = await hre.ethers.getContractFactory(
    "FlexableVendor"
  );
  const FlexableVendor = await FlexableVendorFactory.deploy(
    FlexableAuth.address
  );

  await FlexableVendor.deployed();

  console.log("FlexableVendor Contract Deployed to:", FlexableVendor.address);

  /// VERIFY FlexableVendor
  if (hre.network.name != "hardhat") {
    await FlexableVendor.deployTransaction.wait(6);
    await verify(FlexableVendor.address, [FlexableAuth.address]);
  }

  /// LOG DEPLOYMENT SUMMARY
  console.log("\n=== DEPLOYMENT SUMMARY ===");
  console.log(`FlexableAuth: ${FlexableAuth.address}`);
  console.log(`FlexableVendor: ${FlexableVendor.address}`);
}

const verify = async (contractAddress, args) => {
  console.log("Verifying contract...");
  try {
    await run("verify:verify", {
      address: contractAddress,
      constructorArguments: args,
    });
    console.log("Contract verified successfully!");
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
