import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { expect } from "chai"
import { ethers } from "hardhat"
import { FlexableNFT } from "../typechain-types"

describe("NFT contract", () => {
  let [owner, creator, creator2, buyer, operator]: SignerWithAddress[] = new Array(5)
  before(async () => {
    [owner, operator, creator, creator2, buyer] = await ethers.getSigners()
  })
  let flexableNFT: FlexableNFT
  const metadata = {
    name: "FlexableNFT",
    symbol: "FLEX",
  }
  before(async () => {
    let flexableNFTFactory = await ethers.getContractFactory("FlexableNFT")
    flexableNFT = await flexableNFTFactory.deploy(metadata.name, metadata.symbol)
  })
  it("Should return the right name and symbol of the token once FlexableNFT is deployed", async () => {
    expect(await flexableNFT.name()).to.equal(metadata.name)
    expect(await flexableNFT.symbol()).to.equal(metadata.symbol)
  })

  it("Should get the right owner", async () => {
    const FLEXABLENFT_ADMIN_ROLE = await flexableNFT.FLEXABLENFT_ADMIN_ROLE()
    expect(await flexableNFT.getRoleMember(FLEXABLENFT_ADMIN_ROLE, 0)).to.be.equal(owner.address)
  })

  it("Should grant role", async () => {
    const FLEXABLENFT_OPERATOR_ROLE = await flexableNFT.FLEXABLENFT_OPERATOR_ROLE()
    expect(
      await flexableNFT.grantRole(FLEXABLENFT_OPERATOR_ROLE, operator.address)
    )
      .to.emit(flexableNFT, "RoleGranted")
      .withArgs(FLEXABLENFT_OPERATOR_ROLE, operator.address, owner.address)
    let hasRole = await flexableNFT.hasRole(FLEXABLENFT_OPERATOR_ROLE, operator.address)
    expect(hasRole).to.be.true

    const FLEXABLENFT_CREATOR_ROLE = await flexableNFT.FLEXABLENFT_CREATOR_ROLE()

    expect(
      await flexableNFT.connect(operator).grantRole(FLEXABLENFT_CREATOR_ROLE, creator.address)
    )
      .to.emit(flexableNFT, "RoleGranted")
      .withArgs(FLEXABLENFT_CREATOR_ROLE, creator.address, operator.address)

    hasRole = await flexableNFT.hasRole(FLEXABLENFT_CREATOR_ROLE, creator.address)
    expect(hasRole).to.be.true

  })
  const metaDataHash = "ipfs://QmbXvKra8Re7sxCMAEpquWJEq5qmSqis5VPCvo9uTA7AcF"

  it("Should delegate ticket creation", async () => {
    expect(
      await flexableNFT.connect(operator).delegateTicketCreation(creator2.address, metaDataHash)
    )
      .to.emit(flexableNFT, "TicketCreated")
      .withArgs(1, creator2.address, metaDataHash)

    const tokenURI = await flexableNFT.tokenURI(1)
    expect(tokenURI).to.equal(metaDataHash)
  })

  it("Should update status if operator", async () => {
    const status = "test status"
    expect(
      await flexableNFT.connect(operator).
        setStatus(1, status)
    ).to.emit(flexableNFT, "StatusUpdated")
      .withArgs(1, status)
  })

  it("Should fail to set status if not operator", async () => {
    const FLEXABLENFT_OPERATOR_ROLE = await flexableNFT.FLEXABLENFT_OPERATOR_ROLE()
    const status = "test status"
    await expect(
      flexableNFT.connect(creator).
        setStatus(1, status)
    ).to.be.revertedWith(`AccessControl: account ${creator.address.toLowerCase()} is missing role ${FLEXABLENFT_OPERATOR_ROLE}`)
  })

})