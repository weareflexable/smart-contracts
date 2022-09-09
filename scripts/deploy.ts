import { ethers } from "hardhat";

async function main() {

  const metadata = {
    name: "WeareFlex",
    symbol: "WRFX",
  }
  const WeareFlex = await ethers.getContractFactory("WeareFlex");
  const weareFlex = await WeareFlex.deploy(metadata.name, metadata.symbol);

  await weareFlex.deployed();

  console.log(`WeareFlex deployed to ${weareFlex.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
