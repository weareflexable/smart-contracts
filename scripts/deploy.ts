import { ethers } from "hardhat";

async function main() {

  const nftData = {
    name: "FlexableNFT",
    symbol: "FLEX",
  }
  const FlexableNFT = await ethers.getContractFactory("FlexableNFT");
  const flexableNFT = await FlexableNFT.deploy(nftData.name, nftData.symbol);

  await flexableNFT.deployed();

  console.log(`FlexableNFT deployed to ${flexableNFT.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
