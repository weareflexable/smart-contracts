const fs = require("fs");
const { ethers, run, network } = require("hardhat");

async function main() {
  console.log("Deploying FlexableCommunity...");
  const owner = await ethers.getSigner();
  console.log("Owner address:", owner.address);

  /// ======================== ADDRESSES ========================= ///
  // Replace these with actual contract addresses after deployment
  // These are placeholders and should be updated with real addresses
  const MockERC20Address = "0x47c8134211cC8714e2971f556065D0BEAde7B11d"; // Replace with actual MockERC20 address
  const FlexableAuthAddress = "0xc9D415bB5Bc285116a3f40C74048f40928218Ae3"; // Replace with actual FlexableAuth address
  const FlexableVendorAddress = "0xEB9F0ced17f5d43854ba469BeEDa088B5F3ca0a1"; // Replace with actual FlexableVendor address
  const FlexablePassNFTAddress = "0x43BfB82BC4A90260b2E6C78aDD33959453f88d84"; // Replace with actual FlexablePassNFT address

  const FlexableCommunityFactory = await hre.ethers.getContractFactory(
    "FlexableCommunity"
  );
  const FlexableCommunity = await FlexableCommunityFactory.deploy(
    MockERC20Address,
    owner.address,
    FlexableAuthAddress,
    FlexableVendorAddress,
    FlexablePassNFTAddress
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
      MockERC20Address,
      owner.address,
      FlexableAuthAddress,
      FlexableVendorAddress,
      FlexablePassNFTAddress,
    ]);
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
