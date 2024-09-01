const fs = require("fs")
const { ethers, run, network } = require("hardhat")

async function main() {
    const FlexableFactory = await hre.ethers.getContractFactory("FlexableNFTV2")
    const Flexable = await FlexableFactory.deploy("Flexable", "FLX")

    await Flexable.deployed()

    console.log("Flexable Contract Deployed to:", Flexable.address)
    contractAddress = Flexable.address
    blockNumber = Flexable.provider._maxInternalBlockNumber

    /// VERIFY
    if (hre.network.name != "hardhat") {
        await Flexable.deployTransaction.wait(6)
        await verify(Flexable.address, ["Flexable", "FLX"])
    }
}

// async function verify(contractAddress, args) {
const verify = async (contractAddress, args) => {
    console.log("Verifying contract...")
    try {
        await run("verify:verify", {
            address: contractAddress,
            constructorArguments: args,
        })
        Verified = true
    } catch (e) {
        if (e.message.toLowerCase().includes("already verified")) {
            console.log("Already Verified!")
        } else {
            console.log(e)
        }
    }
}

// main
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
