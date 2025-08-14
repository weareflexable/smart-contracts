import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";
import {
  FlexableCommunity,
  FlexableVendor,
  FlexablePass,
  FlexableAuth,
  MockERC20,
} from "../typechain-types";

describe("Flexable Contracts Tests", () => {
  let owner: SignerWithAddress;
  let admin: SignerWithAddress;
  let operator: SignerWithAddress;
  let manager: SignerWithAddress;
  let vendor1: SignerWithAddress;
  let vendor2: SignerWithAddress;
  let buyer: SignerWithAddress;
  let user1: SignerWithAddress;
  let user2: SignerWithAddress;

  let flexableCommunity: FlexableCommunity;
  let flexableVendor: FlexableVendor;
  let flexablePass: FlexablePass;
  let flexableAuth: FlexableAuth;
  let mockUSDC: MockERC20;

  const VENDOR_METADATA_1 = "ipfs://QmVendor1Metadata";
  const VENDOR_METADATA_2 = "ipfs://QmVendor2Metadata";
  const Vendor1 = {
    vendorId: 1,
    metadata: VENDOR_METADATA_1,
    price: 50,
    share: 5000,
  };

  const Vendor2 = {
    vendorId: 2,
    metadata: VENDOR_METADATA_2,
    price: 50,
    share: 5000,
  };

  const COMMUNITY_URI = "ipfs://QmCommunityMetadata";
  const PASS_URI = "ipfs://QmPassMetadata";

  before(async () => {
    [owner, admin, operator, manager, vendor1, vendor2, buyer, user1, user2] =
      await ethers.getSigners();
    // Deploy MockUSDC
    const MockERC20Factory = await ethers.getContractFactory("MockERC20");
    mockUSDC = (await MockERC20Factory.deploy()) as MockERC20;

    // Deploy FlexableAuth
    const FlexableAuthFactory = await ethers.getContractFactory("FlexableAuth");
    flexableAuth = (await FlexableAuthFactory.deploy()) as FlexableAuth;

    // Deploy FlexableVendor
    const FlexableVendorFactory = await ethers.getContractFactory(
      "FlexableVendor"
    );
    flexableVendor = (await FlexableVendorFactory.deploy(
      flexableAuth.address
    )) as FlexableVendor;

    // Deploy FlexablePass
    const FlexablePassFactory = await ethers.getContractFactory("FlexablePass");
    flexablePass = (await FlexablePassFactory.deploy(
      flexableAuth.address
    )) as FlexablePass;

    // Deploy FlexableCommunity
    const FlexableCommunityFactory = await ethers.getContractFactory(
      "FlexableCommunity"
    );
    flexableCommunity = (await FlexableCommunityFactory.deploy(
      mockUSDC.address,
      owner.address,
      flexableAuth.address,
      flexableVendor.address,
      flexablePass.address
    )) as FlexableCommunity;

    // Setup roles in FlexableAuth
    await flexableAuth.grantRole(
      await flexableAuth.ADMIN_ROLE(),
      admin.address
    );
    await flexableAuth.grantRole(
      await flexableAuth.OPERATOR_ROLE(),
      operator.address
    );
    await flexableAuth.grantRole(
      await flexableAuth.MINTER_ROLE(),
      flexableCommunity.address
    );
  });

  it("Should Create Vendor", async () => {
    console.log("Test1");

    const expectedId = await flexableVendor.callStatic.createVendor(
      vendor1.address,
      "Test Vendor",
      VENDOR_METADATA_1
    );
    await flexableVendor.createVendor(
      vendor1.address,
      "Test Vendor 1",
      VENDOR_METADATA_1
    );
    console.log("expectedId", expectedId);
    expect(expectedId).to.be.equal(1);

    await flexableVendor.createVendor(
      vendor2.address,
      "Test Vendor 2",
      VENDOR_METADATA_2
    );
  });
  it("Should set Vendor active", async () => {
    let expectedId = await flexableVendor.callStatic.createVendor(
      vendor1.address,
      "Test Vendor 1",
      VENDOR_METADATA_1
    );
    await flexableVendor
      .connect(vendor1)
      .createVendor(vendor1.address, "Test Vendor 1", VENDOR_METADATA_1);

    expect(await flexableVendor.isVendorActive(expectedId)).to.be.true;
    await flexableVendor.connect(operator).setVendorActive(expectedId, false);
    expect(await flexableVendor.isVendorActive(expectedId)).to.be.false;
  });
  it("Should Create a Community", async () => {
    await flexableCommunity
      .connect(manager)
      .createCommunity(
        "Bangalore Diaries",
        PASS_URI,
        100,
        [Vendor1, Vendor2],
        100
      );

    const community = await flexableCommunity.communities(1);
    expect(community.name).to.equal("Bangalore Diaries");
    expect(community.managerFeeBP).to.equal(100);
    expect(community.passPrice).to.equal(100);
    expect(community.baseURI).to.equal(PASS_URI);
    expect(community.managerFeeBP).to.equal(100);

    expect(community.managerWallet).to.equal(manager.address);
    expect(community.status).to.equal(1); // 1 is ACTIVE status
  });
  it("Should buy a Pass", async () => {
    await mockUSDC.mint(buyer.address, ethers.utils.parseEther("100000"));
    const community = await flexableCommunity.communities(1);

    const decimals = await mockUSDC.decimals();
    const actualPrice = ethers.utils.parseUnits(
      community.passPrice.toString(),
      decimals
    );
    console.log("actualPrice", ethers.utils.formatEther(actualPrice));
    await mockUSDC
      .connect(buyer)
      .approve(flexableCommunity.address, actualPrice);

    await flexableCommunity.connect(buyer).buyCommunityPass(1, "www.xyz.com");
    const pass = await flexablePass.ownerOf(1);
    expect(pass).to.equal(buyer.address);

    const ownerBalance = await mockUSDC.balanceOf(owner.address);
    const managerBalance = await mockUSDC.balanceOf(manager.address);
    const ownerTotalEarnings = await flexableCommunity.totalEarnings(
      owner.address
    );
    const managerTotalEarnings = await flexableCommunity.totalEarnings(
      manager.address
    );

    console.log(
      "ownerTotalEarnings",
      ethers.utils.formatEther(ownerTotalEarnings)
    );
    console.log(
      "managerTotalEarnings",
      ethers.utils.formatEther(managerTotalEarnings)
    );

    const vendor1Balance = await mockUSDC.balanceOf(vendor1.address);
    const vendor2Balance = await mockUSDC.balanceOf(vendor2.address);
    console.log("vendor1Balance", ethers.utils.formatEther(vendor1Balance));
    console.log("vendor2Balance", ethers.utils.formatEther(vendor2Balance));
  });
});
