import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { expect } from "chai"
import { ethers } from "hardhat"
import { FlexableNFT } from "../typechain-types"

describe("NFT contract", () => {
  let [owner, creator, creator2, buyer, operator]: SignerWithAddress[] = new Array(5)
  let flexableNFT: FlexableNFT
  const nftData = {
    name: "FlexableNFT",
    symbol: "FLEX",
  }
  before(async () => {
    [owner, operator, creator, creator2, buyer, operator] = await ethers.getSigners()
  })

  before(async () => {
    let flexableNFTFactory = await ethers.getContractFactory("FlexableNFT")

    flexableNFT = await flexableNFTFactory.deploy(nftData.name, nftData.symbol)
  })
  it("Should return the right name and symbol of the token once FlexableNFT is deployed", async () => {
    expect(await flexableNFT.name()).to.equal(nftData.name)
    expect(await flexableNFT.symbol()).to.equal(nftData.symbol)
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
    const Ticket = await flexableNFT.TicketStatus(1)

    expect(Ticket.redeemCount).to.be.equal(0)

    expect(
      await flexableNFT.connect(operator).
        redeemTicket(1, status)
    ).to.emit(flexableNFT, "TicketRedeemed")
      .withArgs(1, Ticket.redeemCount + 1, status)

    const Ticket2 = await flexableNFT.TicketStatus(1)
    expect(Ticket2.redeemCount).to.be.equal(1)
  })

  it("Should fail to set status if not operator", async () => {
    const FLEXABLENFT_OPERATOR_ROLE = await flexableNFT.FLEXABLENFT_OPERATOR_ROLE()
    const status = "test status"
    await expect(
      flexableNFT.connect(creator).
        redeemTicket(1, status)
    ).to.be.revertedWith(`AccessControl: account ${creator.address.toLowerCase()} is missing role ${FLEXABLENFT_OPERATOR_ROLE}`)
  })
  it("should set the  custom royallty by CREATOR ROLE", async () => {
  
    const FLEXABLENFT_CREATOR_ROLE = await flexableNFT.FLEXABLENFT_CREATOR_ROLE()

    await flexableNFT.connect(operator).grantRole(FLEXABLENFT_CREATOR_ROLE, buyer.address)

    await flexableNFT.connect(buyer).createTicketWithCustomRoyalty("www.xyz.con", 500);

    const value = await ethers.utils.parseEther("1")

    const royalty = await flexableNFT.royaltyInfo(2, value)

    const recivedAmount = (value.mul(500)).div(10000);

    expect(royalty[1]).to.be.equal(recivedAmount)

    expect(royalty[0]).to.be.equal(buyer.address)

  })
  it("should set the  custom royallty for delegateTicket ", async () => {

    const FLEXABLENFT_CREATOR_ROLE = await flexableNFT.FLEXABLENFT_CREATOR_ROLE()


    await flexableNFT.connect(operator).delegateTicketCreationWithCustomRoyalty(creator.address, "www.abc.con", owner.address, 500);

    const value = await ethers.utils.parseEther("1")

    const royalty = await flexableNFT.royaltyInfo(3, value)

    const recivedAmount = (value.mul(500)).div(10000);

    expect(await flexableNFT.ownerOf(3)).to.be.equal(creator.address);

    expect(royalty[1]).to.be.equal(recivedAmount)

    expect(royalty[0]).to.be.equal(owner.address)

  })
  it("should check Create Ticket", async () =>{
        const metaData = "www.abc.com"
        expect(await flexableNFT.connect(buyer).createTicket(metaData)).to.emit(flexableNFT,"TicketCreated")
        expect(await flexableNFT.ownerOf(2)).to.be.equal(buyer.address)
  })
  it("Burn Nft",async () => {
      await flexableNFT.connect(buyer).burnTicket(2)
      expect(flexableNFT.ownerOf(2)).to.not.equal(buyer.address)
  })
  it("Update the Royalty",async () => {
        expect(await flexableNFT.updateDefaultRoyalty(buyer.address , 1000)).to.emit(flexableNFT , "RoyaltyUpdated")
        const royalty = await flexableNFT.royaltyInfo(4 , 1)
        expect(royalty[0]).to.be.equal(buyer.address)
  })
  it("pause and Unpause",async () => {
    await flexableNFT.connect(operator).pause()
    expect(await flexableNFT.ownerOf(4)).to.be.equal(buyer.address)
    expect(flexableNFT.transferFrom(buyer.address,owner.address,4)).to.be.reverted
    await flexableNFT.connect(operator).unpause()
    await flexableNFT.connect(buyer).transferFrom(buyer.address,owner.address,4)
    expect(await flexableNFT.ownerOf(4)).to.be.equal(owner.address)

  })
})