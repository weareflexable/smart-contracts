import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { expect } from "chai"
import { ethers } from "hardhat"
import { WeareFlex } from "../typechain-types"

describe("NFT contract", () => {
  let [owner, creator, creator2, buyer, operator]: SignerWithAddress[] = new Array(5)
  before(async () => {
    [owner, operator, creator, creator2, buyer] = await ethers.getSigners()
  })
  let weareFlex: WeareFlex
  const metadata = {
    name: "WeareFlex",
    symbol: "WRFX",
  }
  before(async () => {
    let weareFlexFactory = await ethers.getContractFactory("WeareFlex")
    weareFlex = await weareFlexFactory.deploy(metadata.name, metadata.symbol)
  })
  it("Should return the right name and symbol of the token once WeareFlex is deployed", async () => {
    expect(await weareFlex.name()).to.equal(metadata.name)
    expect(await weareFlex.symbol()).to.equal(metadata.symbol)
  })

  it("Should get the right owner", async () => {
    const WEAREFLEX_ADMIN_ROLE = await weareFlex.WEAREFLEX_ADMIN_ROLE()
    expect(await weareFlex.getRoleMember(WEAREFLEX_ADMIN_ROLE, 0)).to.be.equal(owner.address)
  })

  it("Should grant role", async () => {
    const WEAREFLEX_OPERATOR_ROLE = await weareFlex.WEARFLEX_OPERATOR_ROLE()
    expect(
      await weareFlex.grantRole(WEAREFLEX_OPERATOR_ROLE, operator.address)
    )
      .to.emit(weareFlex, "RoleGranted")
      .withArgs(WEAREFLEX_OPERATOR_ROLE, operator.address, owner.address)
    let hasRole = await weareFlex.hasRole(WEAREFLEX_OPERATOR_ROLE, operator.address)
    expect(hasRole).to.be.true

    const WEAREFLEX_CREATOR_ROLE = await weareFlex.WEARFLEX_CREATOR_ROLE()

    expect(
      await weareFlex.connect(operator).grantRole(WEAREFLEX_CREATOR_ROLE, creator.address)
    )
      .to.emit(weareFlex, "RoleGranted")
      .withArgs(WEAREFLEX_CREATOR_ROLE, creator.address, operator.address)

    hasRole = await weareFlex.hasRole(WEAREFLEX_CREATOR_ROLE, creator.address)
    expect(hasRole).to.be.true

  })
  const metaDataHash = "ipfs://QmbXvKra8Re7sxCMAEpquWJEq5qmSqis5VPCvo9uTA7AcF"

  it("Should delegate artifact creation", async () => {
    expect(
      await weareFlex.connect(operator).delegateArtifactCreation(creator2.address, metaDataHash)
    )
      .to.emit(weareFlex, "ArtifactCreated")
      .withArgs(1, creator2.address, metaDataHash)

    const tokenURI = await weareFlex.tokenURI(1)
    expect(tokenURI).to.equal(metaDataHash)
  })

  it("Should update status if owner of token", async () => {
    const status = "test status"
    expect(
      await weareFlex.connect(creator2).
        setStatus(1, status)
    ).to.emit(weareFlex, "StatusUpdated")
      .withArgs(1, status)
  })

  it("Should fail to set status if not owner of token", async () => {
    const status = "test status"
    await expect(
      weareFlex.connect(creator).
        setStatus(1, status)
    ).to.be.revertedWith("Weareflex: caller is not owner nor approved to set status of NFT")
  })

})