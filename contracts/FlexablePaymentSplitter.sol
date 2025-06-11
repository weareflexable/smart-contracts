// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Interface for the NFT contract that will mint passes
interface IFlexablePassNFT {
    function mintPass(
        address to,
        uint256 communityId,
        uint256 vendorId
    ) external returns (uint256);
}

/**
 * @title FlexablePaymentSplitter
 * @dev Manages communities, vendors, and automated USDC payment splitting
 * @author Your DeFi Mentor 🚀
 */
contract FlexablePaymentSplitter is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ===== STATE VARIABLES =====

    // Core contracts
    IERC20 public immutable usdc;
    IFlexablePassNFT public passNFT;

    // Platform settings
    address public platformWallet;
    uint256 public platformFeeBP = 1000; // 10% default platform fee
    uint256 public constant MAX_BP = 10000; // 100%

    enum PaymentType {
        FIXED, // Vendor gets fixed USDC amount
        PERCENTAGE // Vendor gets % of remaining funds
    }

    // ===== STRUCTS =====

    /**
     * @dev Vendor = someone who provides services in a community
     * wallet: Where to send their payment
     * price: How much their service costs in USDC
     * share: How much % they get if using percentage payment (basis points)
     * fixedAmount: Fixed USDC amount they get if using fixed payment
     * paymentType: FIXED or PERCENTAGE
     * active: Can they receive payments?
     * serviceName: What service they provide
     */
    struct Vendor {
        address wallet;
        uint256 price; // NEW: Service price in USDC (6 decimals)
        uint256 share; // Basis points (100 = 1%) - only used if PERCENTAGE
        uint256 fixedAmount; // Fixed USDC amount - only used if FIXED
        bool active;
        string serviceName;
    }

    /**
     * @dev Community = group of vendors managed by one person
     * manager: Person who created and manages this community
     * managerFeeBP: Manager's cut in basis points
     * paymentType: All vendors in community use same payment type
     * totalSharesBP: Sum of all vendor shares (for PERCENTAGE type)
     * exists: Is this community active?
     * name: Community name for identification
     * vendors: Mapping of vendorId to Vendor details
     */
    struct Community {
        address manager;
        uint256 managerFeeBP;
        PaymentType paymentType; // NEW: Community-wide payment type
        uint256 totalSharesBP; // Only used for PERCENTAGE type
        bool exists;
        string name;
        mapping(uint256 => Vendor) vendors; // Store vendors directly in the struct
        uint256 vendorCount; // Track number of vendors for iteration
    }

    // ===== STORAGE MAPPINGS =====

    mapping(uint256 => Community) public communities;

    // Tracking
    uint256 public nextCommunityId = 1;
    mapping(address => uint256[]) public managerCommunities; // Manager => their community IDs
    mapping(uint256 => uint256) public communityEarnings; // Community => earnings
    mapping(address => uint256) public totalEarnings; // Track lifetime earnings per address
    mapping(address => uint256) public pendingBalances; // Track claimable balances per address

    // ===== EVENTS =====

    event CommunityCreated(
        uint256 indexed communityId,
        address indexed manager,
        string name,
        uint256 managerFeeBP,
        PaymentType paymentType
    );

    event VendorAdded(
        uint256 indexed communityId,
        uint256 vendorId,
        address wallet,
        string serviceName,
        uint256 price
    );

    event PassPurchased(
        uint256 indexed communityId,
        uint256 indexed vendorId,
        address indexed buyer,
        uint256 price,
        uint256 nftTokenId
    );

    event PaymentSplit(
        address indexed recipient,
        uint256 amount,
        string recipientType // "platform", "manager", "vendor"
    );

    event FundsClaimed(address indexed recipient, uint256 amount);

    event PlatformFeeUpdated(uint256 newFeeBP);
    event VendorUpdated(uint256 indexed communityId, uint256 vendorId);

    // ===== MODIFIERS =====

    modifier onlyManager(uint256 communityId) {
        require(
            communities[communityId].manager == msg.sender,
            "Not community manager"
        );
        _;
    }

    modifier communityExists(uint256 communityId) {
        require(communities[communityId].exists, "Community does not exist");
        _;
    }

    modifier validVendor(uint256 communityId, uint256 vendorId) {
        require(
            vendorId < communities[communityId].vendorCount,
            "Invalid vendor ID"
        );
        require(
            communities[communityId].vendors[vendorId].active,
            "Vendor not active"
        );
        _;
    }

    // ===== CONSTRUCTOR =====

    /**
     * @param _usdc USDC token address
     * @param _platformWallet Where platform fees go
     */
    constructor(address _usdc, address _platformWallet) Ownable(msg.sender) {
        require(_usdc != address(0), "Invalid USDC address");
        require(_platformWallet != address(0), "Invalid platform wallet");

        usdc = IERC20(_usdc);
        platformWallet = _platformWallet;
    }

    // ===== MAIN FUNCTIONS =====

    function createCommunity(
        string memory name,
        uint256 managerFeeBP,
        PaymentType paymentType
    ) external returns (uint256) {
        require(bytes(name).length > 0, "Name cannot be empty");
        require(managerFeeBP <= 5000, "Manager fee too high (max 50%)");

        uint256 communityId = nextCommunityId++;

        // Create community
        Community storage community = communities[communityId];
        community.manager = msg.sender;
        community.managerFeeBP = managerFeeBP;
        community.paymentType = paymentType;
        community.totalSharesBP = 0;
        community.exists = true;
        community.name = name;
        community.vendorCount = 0;

        managerCommunities[msg.sender].push(communityId);

        emit CommunityCreated(
            communityId,
            msg.sender,
            name,
            managerFeeBP,
            paymentType
        );

        return communityId;
    }

    /**
     * @dev Purchase from a specific vendor - this is where the magic happens! 💰
     * @param communityId Which community to buy from
     * @param vendorId Which vendor to buy from
     */
    function purchaseFromVendor(
        uint256 communityId,
        uint256 vendorId
    )
        external
        nonReentrant
        communityExists(communityId)
        validVendor(communityId, vendorId)
    {
        Vendor memory vendor = communities[communityId].vendors[vendorId];

        // Transfer USDC from buyer
        usdc.safeTransferFrom(msg.sender, address(this), vendor.price);

        // Split the payment
        communityEarnings[communityId] += vendor.price;

        // Mint NFT pass to buyer
        uint256 tokenId = 0;
        if (address(passNFT) != address(0)) {
            tokenId = passNFT.mintPass(msg.sender, communityId, vendorId);
        }

        emit PassPurchased(
            communityId,
            vendorId,
            msg.sender,
            vendor.price,
            tokenId
        );
    }

    /**
     * @dev Internal function to split payments 🔥
     * Order: Platform fee → Manager fee → Vendors (based on community payment type)
     */
    function splitPayment(uint256 communityId) external nonReentrant {
        Community storage community = communities[communityId];
        uint256 totalAmount = communityEarnings[communityId];

        // 1. Platform fee
        uint256 platformAmount = (totalAmount * platformFeeBP) / MAX_BP;
        if (platformAmount > 0) {
            usdc.safeTransfer(platformWallet, platformAmount);
            totalEarnings[platformWallet] += platformAmount;
            emit PaymentSplit(platformWallet, platformAmount, "platform");
        }

        // 2. Manager fee
        uint256 managerAmount = (totalAmount * community.managerFeeBP) / MAX_BP;
        if (managerAmount > 0) {
            usdc.safeTransfer(community.manager, managerAmount);
            totalEarnings[community.manager] += managerAmount;
            emit PaymentSplit(community.manager, managerAmount, "manager");
        }

        // 3. Vendors get remaining amount
        uint256 remainingAmount = totalAmount - platformAmount - managerAmount;

        if (community.paymentType == PaymentType.FIXED) {
            _distributeFixedPayments(communityId, remainingAmount);
        } else {
            _distributePercentagePayments(communityId, remainingAmount);
        }
    }

    /**
     * @dev Distribute remaining funds to vendors using fixed amounts
     */
    function _distributeFixedPayments(
        uint256 communityId,
        uint256 remainingAmount
    ) private {
        Community storage community = communities[communityId];
        uint256 totalPaid = 0;

        for (uint256 i = 0; i < community.vendorCount; i++) {
            Vendor memory vendor = communities[communityId].vendors[i];
            if (!vendor.active) continue;

            uint256 vendorPayment = vendor.fixedAmount;

            // Ensure we don't exceed remaining amount
            if (totalPaid + vendorPayment > remainingAmount) {
                vendorPayment = remainingAmount - totalPaid;
            }

            if (vendorPayment > 0) {
                pendingBalances[vendor.wallet] += vendorPayment;
                totalEarnings[vendor.wallet] += vendorPayment;
                totalPaid += vendorPayment;
                emit PaymentSplit(vendor.wallet, vendorPayment, "vendor");
            }

            if (totalPaid >= remainingAmount) break;
        }
    }

    /**
     * @dev Distribute remaining funds to vendors using percentage shares
     */
    function _distributePercentagePayments(
        uint256 communityId,
        uint256 remainingAmount
    ) private {
        Community storage community = communities[communityId];

        if (community.totalSharesBP == 0) return;

        for (uint256 i = 0; i < community.vendorCount; i++) {
            Vendor memory vendor = communities[communityId].vendors[i];
            if (!vendor.active || vendor.share == 0) continue;

            uint256 vendorPayment = (remainingAmount * vendor.share) /
                community.totalSharesBP;

            if (vendorPayment > 0) {
                pendingBalances[vendor.wallet] += vendorPayment;
                totalEarnings[vendor.wallet] += vendorPayment;
                emit PaymentSplit(vendor.wallet, vendorPayment, "vendor");
            }
        }
    }

    // ===== MANAGER FUNCTIONS =====

    /**
     * @dev Add a new vendor to existing community
     */
    function addVendor(
        uint256 communityId,
        Vendor memory vendorData
    ) external onlyManager(communityId) {
        Community storage community = communities[communityId];
        require(community.vendorCount < 100, "Max vendors reached");

        uint256 vendorId = community.vendorCount;
        community.vendors[vendorId] = vendorData;
        community.vendorCount++;

        // Update total shares if percentage type
        if (community.paymentType == PaymentType.PERCENTAGE) {
            community.totalSharesBP += vendorData.share;

            uint256 availableForVendorsBP = MAX_BP -
                platformFeeBP -
                community.managerFeeBP;
            require(
                community.totalSharesBP <= availableForVendorsBP,
                "Total shares exceed available amount"
            );
        }

        emit VendorAdded(
            communityId,
            vendorId,
            vendorData.wallet,
            vendorData.serviceName,
            vendorData.price
        );
    }

    /**
     * @dev Update vendor details
     */
    function updateVendor(
        uint256 communityId,
        uint256 vendorId,
        uint256 newPrice,
        bool active
    ) external onlyManager(communityId) {
        require(
            vendorId < communities[communityId].vendorCount,
            "Invalid vendor ID"
        );
        require(newPrice > 0, "Price must be greater than 0");

        communities[communityId].vendors[vendorId].price = newPrice;
        communities[communityId].vendors[vendorId].active = active;

        emit VendorUpdated(communityId, vendorId);
    }

    // ===== CLAIM FUNCTIONS =====

    /**
     * @dev Claim accumulated earnings
     */
    function claimFunds() external nonReentrant {
        uint256 amount = pendingBalances[msg.sender];
        require(amount > 0, "No funds to claim");

        pendingBalances[msg.sender] = 0;
        usdc.safeTransfer(msg.sender, amount);

        emit FundsClaimed(msg.sender, amount);
    }

    /**
     * @dev Claim funds on behalf of another address (useful for contracts)
     */
    function claimFundsFor(address recipient) external nonReentrant {
        uint256 amount = pendingBalances[recipient];
        require(amount > 0, "No funds to claim");

        pendingBalances[recipient] = 0;
        usdc.safeTransfer(recipient, amount);

        emit FundsClaimed(recipient, amount);
    }

    // ===== ADMIN FUNCTIONS =====

    /**
     * @dev Update platform fee (only owner)
     */
    function updatePlatformFee(uint256 newFeeBP) external onlyOwner {
        require(newFeeBP <= 2000, "Platform fee too high (max 20%)");
        platformFeeBP = newFeeBP;
        emit PlatformFeeUpdated(newFeeBP);
    }

    /**
     * @dev Update platform wallet
     */
    function updatePlatformWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0), "Invalid wallet address");
        platformWallet = newWallet;
    }

    /**
     * @dev Set NFT contract address
     */
    function setPassNFT(address _passNFT) external onlyOwner {
        passNFT = IFlexablePassNFT(_passNFT);
    }

    // ===== VIEW FUNCTIONS =====

    /**
     * @dev Calculate payment distribution preview
     */
    function calculatePaymentSplit(
        uint256 communityId,
        uint256 amount
    )
        external
        view
        returns (uint256 platformCut, uint256 managerCut, uint256 vendorTotal)
    {
        Community storage community = communities[communityId];
        platformCut = (amount * platformFeeBP) / MAX_BP;
        managerCut = (amount * community.managerFeeBP) / MAX_BP;
        vendorTotal = amount - platformCut - managerCut;
    }

    /**
     * @dev Get contract's total USDC balance
     */
    function getContractBalance() external view returns (uint256) {
        return usdc.balanceOf(address(this));
    }
}
