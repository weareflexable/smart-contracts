const fs = require("fs");
const { ethers, run, network } = require("hardhat");

async function main() {
  // Replace these with actual contract addresses after deployment
  const FlexableAuthAddress = "0xc9D415bB5Bc285116a3f40C74048f40928218Ae3"; // Replace with actual FlexableAuth address
  /// DEPLOY FlexableVendor
  console.log("Deploying FlexableVendor...");
  const FlexableVendorFactory = await hre.ethers.getContractFactory(
    "FlexableVendor"
  );
  const FlexableVendor = await FlexableVendorFactory.deploy(
    FlexableAuthAddress
  );

  await FlexableVendor.deployed();

  console.log("FlexableVendor Contract Deployed to:", FlexableVendor.address);

  /// VERIFY FlexableVendor
  if (hre.network.name != "hardhat") {
    await FlexableVendor.deployTransaction.wait(6);
    await verify(FlexableVendor.address, [FlexableAuthAddress]);
  }
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
