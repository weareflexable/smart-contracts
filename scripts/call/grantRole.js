const { ethers } = require("hardhat");
const { artifacts } = require("hardhat");

async function main() {
  const accounts = await ethers.getSigners();

  // Replace with your deployed LandAssetManager contract address
  const contractAddress = "0xc9D415bB5Bc285116a3f40C74048f40928218Ae3";
  const communityAddress = "0x584B604Dec9E12e74c0750B11379703295b3d881";

  // Fetching the ABI
  const contractArtifact = await artifacts.readArtifact("FlexableAuth");
  const flexableCommunity = new ethers.Contract(
    contractAddress,
    contractArtifact.abi,
    accounts[0]
  );

  try {
    console.log("Granting MINTER_ROLE to", communityAddress);

    const transaction = await flexableCommunity.grantRole(
      await flexableCommunity.MINTER_ROLE(),
      communityAddress
    );

    await transaction.wait();

    if (transaction.status === 1) {
      console.log("Transaction successful");
    } else {
      console.log("Transaction failed");
    }
    console.log("Transaction:", transaction);
  } catch (error) {
    console.error("Error fetching data:");
    console.error(error.message);
  }
}

// Run the main function
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
