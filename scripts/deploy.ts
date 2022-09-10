import { ethers } from "hardhat";

async function main() {

  const metadata = {
    name: "FlexableNFT",
    symbol: "FLEX",
  }
  const FlexableNFT = await ethers.getContractFactory("FlexableNFT");
  const flexableNFT = await FlexableNFT.deploy(metadata.name, metadata.symbol);

  await flexableNFT.deployed();

  console.log(`FlexableNFT deployed to ${flexableNFT.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
