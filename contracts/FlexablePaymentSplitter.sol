// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Interface for the NFT contract that will mint passes
interface IFlexablePassNFT {
    function mintPass(
        address to,
        uint256 communityId,
        string memory serviceName,
        string memory _uri
    ) external returns (uint256);
}

/**
 * @title FlexablePaymentSplitter
 * @dev Manages communities, vendors, and automated USDC payment splitting
 */
contract FlexablePaymentSplitter is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ===== STATE VARIABLES =====

    // Core contracts
    IERC20 public immutable usdc;
    IFlexablePassNFT public passNFT;

    // Platform settings
    address public platformWallet;
    uint256 public platformFeeBP = 1000; // 10% default platform fee
    uint256 public constant MAX_BP = 10000; // 100%
    uint256 public nextCommunityId = 1;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

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
        string name;
        uint256 price; // NEW: Service price in USDC (6 decimals)
        uint256 share; // Basis points (100 = 1%) - only used if PERCENTAGE
        bool active;
        string description;
    }

    /**
     * @dev Community = group of vendors managed by one person
     * manager: Person who created and manages this community
     * managerFeeBP: Manager's cut in basis points
     * totalSharesBP: Sum of all vendor shares (for PERCENTAGE type)
     * isActive: Is this community active?
     * name: Community name for identification
     * vendors: Mapping of vendorId to Vendor details
     */
    struct Community {
        string name;
        address manager;
        uint256 managerFeeBP;
        bool isActive;
        string serviceName;
        mapping(uint256 => Vendor) vendors; // Store vendors directly in the struct
        uint256 vendorCount; // Track number of vendors for iteration
        uint256 totalSharesBP; // Sum of all vendor shares
    }

    mapping(uint256 => Community) public communities;

    mapping(address => bool) public vendorPaymentPaused;
    mapping(uint256 => uint256) public communityTotalPrice;
    mapping(address => uint256[]) public managerCommunities; // Manager => their community IDs
    mapping(address => uint256) public totalEarnings; // Track lifetime earnings per address
    mapping(address => uint256) public pendingBalances; // Track claimable balances per address

    // ===== EVENTS =====

    event CommunityCreated(
        uint256 indexed communityId,
        address indexed manager,
        string name,
        uint256 managerFeeBP,
        uint256 totalPrice
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
        string recipientType
    );

    event FundsClaimed(address indexed recipient, uint256 amount);

    event PlatformFeeUpdated(uint256 newFeeBP);
    event VendorUpdated(uint256 indexed communityId, uint256 vendorId);

    // ===== MODIFIERS =====

    modifier onlyManager(uint256 communityId) {
        require(
            communities[communityId].manager == _msgSender(),
            "Not community manager"
        );
        _;
    }

    // ===== CONSTRUCTOR =====

    /**
     * @param _usdc USDC token address
     * @param _platformWallet Where platform fees go
     */
    constructor(address _usdc, address _platformWallet) {
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _grantRole(ADMIN_ROLE, _msgSender());
        require(_usdc != address(0), "Invalid USDC address");
        require(_platformWallet != address(0), "Invalid platform wallet");

        usdc = IERC20(_usdc);
        platformWallet = _platformWallet;
    }

    // ===== MAIN FUNCTIONS =====

    function communityActivation(
        uint256 communityId,
        bool status
    ) external onlyRole(ADMIN_ROLE) {
        Community storage community = communities[communityId];
        community.isActive = status;
    }

    function createCommunity(
        string memory name,
        uint256 managerFeeBP,
        Vendor[] memory vendors,
        uint256 totalPrice
    ) external returns (uint256) {
        require(bytes(name).length > 0, "Name cannot be empty");
        require(managerFeeBP <= 5000, "Manager fee too high (max 50%)");

        uint256 communityId = nextCommunityId++;

        // Create community
        Community storage community = communities[communityId];
        community.name = name;
        community.manager = _msgSender();
        community.managerFeeBP = managerFeeBP;
        community.totalSharesBP = 0;
        community.isActive = false;
        community.name = name;
        community.vendorCount = 0;

        for (uint256 i = 0; i < vendors.length; i++) {
            community.vendors[i] = vendors[i];
            community.vendorCount++;
        }

        managerCommunities[_msgSender()].push(communityId);
        communityTotalPrice[communityId] = totalPrice;

        emit CommunityCreated(
            communityId,
            _msgSender(),
            name,
            managerFeeBP,
            totalPrice
        );

        return communityId;
    }

    /**
     * @dev Purchase from a community - this is where the magic happens! 💰
     * @param communityId Which community to buy from
     * @param _uri URI for the NFT pass
     */
    function purchaseFromVendor(
        uint256 communityId,
        string memory _uri
    ) external nonReentrant {
        require(communities[communityId].isActive, "Community is not active");
        require(
            usdc.balanceOf(_msgSender()) >= communityTotalPrice[communityId],
            "Insufficient balance"
        );

        uint256 totalPrice = communityTotalPrice[communityId];

        // Transfer USDC from buyer
        usdc.safeTransferFrom(_msgSender(), address(this), totalPrice);

        // Split the payment
        _splitPayment(communityId, totalPrice);

        // Mint NFT pass to buyer
        uint256 tokenId = 0;
        if (address(passNFT) != address(0)) {
            tokenId = passNFT.mintPass(
                _msgSender(),
                communityId,
                communities[communityId].name,
                _uri
            );
        }
        emit PassPurchased(
            communityId,
            0, // vendorId not used in this simplified version
            _msgSender(),
            totalPrice,
            tokenId
        );
    }

    /**
     * @dev Internal function to split payments 🔥
     * Order: Platform fee → Manager fee → Vendors (based on community payment type)
     */
    function _splitPayment(
        uint256 communityId,
        uint256 amount
    ) internal nonReentrant {
        Community storage community = communities[communityId];
        uint256 totalAmount = amount;

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

        // 4. Distribute remaining amount to vendors
        _distributePercentagePayments(communityId, remainingAmount);
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
     * @dev Update manager fee
     * @param communityId The ID of the community
     * @param share The new manager fee in basis points
     */
    function updateManagerFee(
        uint256 communityId,
        uint256 share
    ) external onlyManager(communityId) {
        require(share <= 1000, "Manager fee too high (max 10%)");
        communities[communityId].managerFeeBP = share;
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
        uint256 amount = pendingBalances[_msgSender()];
        require(amount > 0, "No funds to claim");

        pendingBalances[_msgSender()] = 0;
        usdc.safeTransfer(_msgSender(), amount);

        emit FundsClaimed(_msgSender(), amount);
    }

    // ===== ADMIN FUNCTIONS =====

    /**
     * @dev Update platform fee (only owner)
     */
    function updatePlatformFee(uint256 newFeeBP) external onlyRole(ADMIN_ROLE) {
        require(newFeeBP <= 1000, "Platform fee too high (max 10%)");
        platformFeeBP = newFeeBP;
        emit PlatformFeeUpdated(newFeeBP);
    }

    /**
     * @dev Update platform wallet
     */
    function updatePlatformWallet(
        address newWallet
    ) external onlyRole(ADMIN_ROLE) {
        require(newWallet != address(0), "Invalid wallet address");
        platformWallet = newWallet;
    }

    /**
     * @dev Set NFT contract address
     */
    function setPassNFT(address _passNFT) external onlyRole(ADMIN_ROLE) {
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
