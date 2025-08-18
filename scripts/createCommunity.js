const { ethers } = require("hardhat");

async function main() {
  const accounts = await ethers.getSigners();

  const contractAddress = "0xF7BC434A3ADD3a82C652542f5c45e1323F45d8DB";
  const manager = accounts[0];

  const PASS_URI = "ipfs://QmPassMetadata";
  const Vendor1 = {
    vendorId: 1,
    metadata: "ipfs://QmVendor1Metadata",
    price: 50,
    share: 5000,
  };

  const Vendor2 = {
    vendorId: 2,
    metadata: "ipfs://QmVendor2Metadata",
    price: 50,
    share: 5000,
  };

  const contractArtifact = await artifacts.readArtifact("FlexableCommunity");
  const flexableCommunity = new ethers.Contract(
    contractAddress,
    contractArtifact.abi,
    manager
  );

  await flexableCommunity.createCommunity(
    "Bangalore Diaries",
    PASS_URI,
    100,
    [Vendor1, Vendor2],
    100
  );

  console.log("Community created successfully");
}

// main
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
