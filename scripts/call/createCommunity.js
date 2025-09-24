const { ethers } = require("hardhat");
const { artifacts } = require("hardhat");

async function main() {
  const accounts = await ethers.getSigners();

  // Replace with your deployed LandAssetManager contract address
  const contractAddress = "0x584B604Dec9E12e74c0750B11379703295b3d881";

  // Fetching the ABI
  const contractArtifact = await artifacts.readArtifact("FlexableCommunity");
  const contract = new ethers.Contract(
    contractAddress,
    contractArtifact.abi,
    accounts[0]
  );

  const mockUSDCAddress = "0x47c8134211cC8714e2971f556065D0BEAde7B11d";

  const mockUSDC = await artifacts.readArtifact("MockERC20");
  const mockUSDCContract = new ethers.Contract(
    mockUSDCAddress,
    mockUSDC.abi,
    accounts[0]
  );

  const price = ethers.utils.parseEther("100000");

  await mockUSDCContract.mint(accounts[0].address, price);

  await mockUSDCContract.approve(
    contractAddress,
    ethers.utils.parseEther("100000")
  );

  const community = await contract.communities(1);
  console.log("Community:", community.passPrice);

  try {
    const transaction = await contract.buyCommunityPass(1, "www.xyz.com", {
      value: ethers.utils.parseEther("100000"),
    });
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
