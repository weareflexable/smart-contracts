# Flexable - Decentralized Community Marketplace

A decentralized marketplace platform enabling anyone to create and manage communities of vendors, with built-in payment splitting and NFT-based access passes.

## What is Flexable?

Flexable is a permissionless platform where:

- Anyone can become a community manager and create vendor networks
- Vendors can join multiple communities to expand their reach
- Users can purchase, trade, and utilize service passes as NFTs
- Payments are automatically split between platform, managers and vendors

## Use Cases

### 🍷 Nightlife Communities

- Managers can curate networks of bars, clubs and venues
- Users purchase passes for entry, drinks or VIP access
- Venues get instant payouts based on usage

### 🍽️ Restaurant Collectives

- Restaurant groups can offer combined dining passes
- Users access multiple venues with a single NFT
- Revenue sharing between participating restaurants

### 🏪 Retail Networks

- Shopping districts can create joint loyalty programs
- Store owners receive proportional revenue share
- Customers unlock perks across multiple shops

### 🎨 Creator Communities

- Artists/creators can form collaborative networks
- Fans purchase passes for content/experiences
- Fair profit distribution to contributing creators

## Key Benefits

### For Managers

- Zero upfront costs to create communities
- Automated revenue collection and distribution
- Tools to curate and grow vendor networks

### For Vendors

- Access to wider customer base
- Flexible participation in multiple communities
- Transparent and instant payments

### For Users

- Single pass for multiple services
- Trade/resell passes on NFT marketplaces
- Verifiable proof of purchase on chain

## Future Roadmap

- Cross-chain community bridging
- Advanced tokenomics and staking
- Mobile app for pass management
- Expanded vendor integration tools

## Overview

Flexable consists of two main smart contracts that work together to create a comprehensive community marketplace:

1. **FlexablePaymentSplitter** - Manages communities, payment splitting, and service purchases
2. **FlexablePassNFT** - Mints NFT passes as proof of service purchases

## Architecture

```
┌─────────────────────┐    ┌──────────────────────┐
│ FlexablePaymentSplitter │◄──┤ FlexablePassNFT     │
│                     │    │                      │
│ • Community Mgmt    │    │ • ERC721 NFTs        │
│ • Payment Splitting │    │ • Pass Metadata      │
│ • USDC Distribution │    │ • Minting Logic      │
│ • Access Control    │    │ • URI Management     │
└─────────────────────┘    └──────────────────────┘
```

## Core Features

### 🏘️ Community Management

- **Community Creation**: Managers can create communities with custom fee structures
- **Vendor Management**: Add/update vendors with individual pricing and shares
- **Access Control**: Role-based permissions with admin and manager roles

### 💰 Payment Splitting

- **Multi-tier Fee Structure**: Platform → Manager → Vendors
- **Flexible Distribution**: Percentage-based vendor profit sharing
- **USDC Integration**: Native USDC token support with SafeERC20
- **Claim System**: Pending balances with secure withdrawal mechanism

### 🎫 NFT Passes

- **Automatic Minting**: NFT passes minted on every purchase
- **Rich Metadata**: Community ID, purchase date, and buyer information
- **Customizable URIs**: Flexible metadata and image hosting
- **ERC721 Standard**: Full compatibility with NFT marketplaces

## Contract Details

### FlexablePaymentSplitter

**Key Components:**

```solidity
struct Community {
  string name;
  address manager;
  uint256 managerFeeBP; // Manager fee in basis points
  bool isActive;
  string serviceName;
  mapping(uint256 => Vendor) vendors;
  uint256 vendorCount;
  uint256 totalSharesBP; // Total vendor shares
}

struct Vendor {
  address wallet;
  string name;
  uint256 price; // Service price in USDC
  uint256 share; // Percentage share (basis points)
  bool active;
  string description;
}
```

**Main Functions:**

- `createCommunity()` - Create new community with vendors
- `purchaseFromVendor()` - Buy services and trigger payment split
- `claimFunds()` - Withdraw accumulated earnings
- `updateManagerFee()` - Adjust manager fee structure
- `communityActivation()` - Enable/disable communities

**Fee Structure:**

1. **Platform Fee**: 10% (1000 basis points) - configurable up to 10%
2. **Manager Fee**: Up to 50% (5000 basis points) - set per community
3. **Vendor Shares**: Remaining amount distributed by percentage shares

### FlexablePassNFT

**Key Components:**

```solidity
struct PassMetadata {
  uint256 communityId;
  uint256 purchaseDate;
  address originalBuyer;
}
```

**Main Functions:**

- `mintPass()` - Mint NFT pass (called by PaymentSplitter)
- `updateTokenURI()` - Update metadata URI (admin only)
- Standard ERC721 functions (transfer, approve, etc.)

**Roles:**

- `ADMIN_ROLE` - Full contract administration
- `MINTER_ROLE` - Can mint new passes (typically the PaymentSplitter)

## Usage Examples

### 1. Deploy Contracts

```solidity
// Deploy NFT contract first
FlexablePassNFT passNFT = new FlexablePassNFT();

// Deploy payment splitter
FlexablePaymentSplitter splitter = new FlexablePaymentSplitter(
    USDC_ADDRESS,
    PLATFORM_WALLET
);

// Connect contracts
splitter.setPassNFT(address(passNFT));
passNFT.grantRole(MINTER_ROLE, address(splitter));
```

### 2. Create Community

```solidity
// Define vendors
Vendor[] memory vendors = new Vendor[](2);
vendors[0] = Vendor({
    wallet: 0x123...,
    name: "Design Service",
    price: 100 * 10**6,  // 100 USDC
    share: 6000,         // 60%
    active: true,
    description: "UI/UX Design"
});

// Create community
uint256 communityId = splitter.createCommunity(
    "Web3 Designers",
    1000,        // 10% manager fee
    vendors,
    200 * 10**6  // 200 USDC total price
);
```

### 3. Purchase Service

```solidity
// Approve USDC spending
usdc.approve(address(splitter), 200 * 10**6);

// Purchase and get NFT pass
splitter.purchaseFromVendor(
    communityId,
    "https://metadata.example.com/pass/"
);
```

## Security Features

- **ReentrancyGuard**: Protection against reentrancy attacks
- **SafeERC20**: Safe token transfers with proper error handling
- **Access Control**: Role-based permissions for sensitive functions
- **Input Validation**: Comprehensive requirement checks
- **Overflow Protection**: Solidity 0.8.25 built-in overflow protection

## Events

### FlexablePaymentSplitter

- `CommunityCreated` - New community registered
- `PassPurchased` - Service purchased and NFT minted
- `PaymentSplit` - Payment distributed to recipient
- `FundsClaimed` - User withdrew earnings
- `PlatformFeeUpdated` - Platform fee changed

### FlexablePassNFT

- `PassMinted` - New NFT pass created
- Standard ERC721 events (Transfer, Approval, etc.)

## Gas Optimization

- **Packed Structs**: Efficient storage layout
- **Batch Operations**: Multiple vendors processed in single transaction
- **Minimal External Calls**: Reduced contract interactions
- **Storage vs Memory**: Optimal data location choices

## Deployment Requirements

- **Solidity Version**: 0.8.25
- **OpenZeppelin**: ^5.0.0
- **Network**: Ethereum, Polygon, or other EVM-compatible chains
- **Token**: USDC contract address for payments

## License

MIT License - see LICENSE file for details.

## Contributing

1. Fork the repository
2. Create feature branch
3. Add comprehensive tests
4. Submit pull request with detailed description

---
