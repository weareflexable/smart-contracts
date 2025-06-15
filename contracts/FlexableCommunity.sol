// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./IFlexableAuth.sol";

interface IFlexablePassNFT {
    function mintPass(
        address to,
        uint8 passtype,
        uint256 passId,
        string memory _uri
    ) external returns (uint256);
}

// Changes
// Contract Name -> FlexableCommunity
/**
 * @title FlexablePaymentSplitter
 * @dev Manages communities, vendors, and automated USDC payment splitting
 */
contract FlexableCommunity is ReentrancyGuard, Context {
    using SafeERC20 for IERC20;

    // ===== STATE VARIABLES =====

    // Core contracts
    //Changes variable name to currency
    // Make setter function where we can set the currency address.
    IERC20 public currency;
    IFlexablePassNFT public passNFT;

    // Platform settings
    address public flexableWallet;
    /// change to flexableFeeBP
    uint256 public platformFeeBP = 1000; // 10% default platform fee
    uint256 public constant MAX_BP = 10000; // 100%
    uint256 private counter = 1;
    uint256 private decimals;
    address flexableAuthAddr;
    IFlexableAuth private flexableAuth;
    // Add a operator Role for operations which are not priority

    enum Status {
        PAUSED,
        ACTIVE,
        DEACTIVATED
    }

    struct Vendor {
        address wallet;
        string name;
        string service; // We will take in metadata
        uint256 price; // NEW: Service price in USD without Decimals
        uint256 share; // Basis points (100 = 1%) - only used if PERCENTAGE
    }

    //Changes add an status ENUM Status - PAUSED, ACTIVE ,DEACTIVATED.
    // Both Manager and Flexable can be deactivat , if once deactivated cannot be active again.
    // Both Manager and Flexable can Pause , but activation can only be done Flexable.
    // By default community will be Active
    struct Community {
        string name;
        string baseURI; // Metadata URI for the community
        address managerWallet;
        address flexableWallet; // Flexable wallet address
        Status status;
        mapping(uint256 => Vendor) vendors; // Store vendors directly in the struct
        uint8 vendorCount; // Track number of vendors for iteration
        uint256 managerFeeBP;
        uint256 flexableFeeBP; // Flexable fee in basis points
        uint256 passPrice; // Price of the pass in USDC without Decimals
    }

    mapping(uint256 => Community) public communities;

    mapping(address => bool) public vendorPaymentPaused;
    mapping(address => uint256) public totalEarnings; // Track lifetime earnings per address
    mapping(address => uint256) public pendingBalances; // Track claimable balances per address

    // ===== EVENTS =====

    //Change- Add more parameters
    event CommunityCreated(
        uint256 indexed communityId,
        address indexed manager,
        string name,
        uint256 managerFeeBP,
        uint256 totalPrice
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
            communities[communityId].managerWallet == _msgSender(),
            "Not community manager"
        );
        _;
    }

    modifier onlyManagerOrOperator(uint256 communityId) {
        require(
            communities[communityId].managerWallet == _msgSender() ||
                flexableAuth.isOperator(_msgSender()),
            "Not community manager or operator"
        );
        _;
    }

    modifier onlyAdmin() {
        require(flexableAuth.isAdmin(_msgSender()), "Not admin");
        _;
    }

    modifier onlyOperator() {
        require(flexableAuth.isOperator(_msgSender()), "Not operator");
        _;
    }

    // ===== CONSTRUCTOR =====

    // ADDITION OF OPERATOR ROLE
    constructor(
        uint256 _decimals,
        address stablecoin,
        address _platformWallet,
        address _flexableAuth
    ) {
        require(stablecoin != address(0), "Invalid stablecoin address");
        require(_platformWallet != address(0), "Invalid platform wallet");
        require(_flexableAuth != address(0), "Invalid flexable auth address");
        decimals = _decimals;
        currency = IERC20(stablecoin);
        flexableWallet = _platformWallet;
        flexableAuthAddr = _flexableAuth;
        flexableAuth = IFlexableAuth(_flexableAuth);
    }

    // ===== MAIN FUNCTIONS =====

    //Add Community  BaseURi for the community metadata in the params
    function createCommunity(
        string memory name,
        string memory baseURI,
        uint256 managerFeeBP,
        Vendor[] memory vendors,
        uint256 totalPrice
    ) external returns (uint256) {
        require(bytes(name).length > 0, "Name cannot be empty");
        require(managerFeeBP <= 1000, "Manager fee too high (max 10%)");

        uint256 communityId = counter++;

        // Create community
        Community storage community = communities[communityId];
        community.name = name;
        community.baseURI = baseURI;
        community.managerWallet = _msgSender();
        community.managerFeeBP = managerFeeBP;
        community.status = Status.ACTIVE;
        community.vendorCount = uint8(vendors.length);

        //Add the vendors and calculate the total shares and each vendor share
        for (
            uint256 i = 0;
            i < vendors.length &&
                ((totalPrice * vendors[i].share) / MAX_BP == vendors[i].price);
            i++
        ) {
            community.vendors[i] = vendors[i];
        }

        community.passPrice = totalPrice;

        // change the event
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

    //Changes , the uri will be take from community struct itself and nft should be minted.
    function buyCommunityPass(
        uint256 communityId,
        string memory _uri
    ) external nonReentrant {
        uint256 actualPrice = communities[communityId].passPrice *
            10 ** decimals;

        require(
            communities[communityId].status == Status.ACTIVE,
            "Community is not active"
        );
        require(
            currency.balanceOf(_msgSender()) >= actualPrice,
            "Insufficient balance"
        );

        // Transfer USDC from buyer
        currency.safeTransferFrom(_msgSender(), address(this), actualPrice);

        // Split the payment
        _splitPayment(communityId, actualPrice);

        // Mint NFT pass to buyer
        uint256 tokenId = 0;
        if (address(passNFT) != address(0)) {
            tokenId = passNFT.mintPass(_msgSender(), 1, communityId, _uri);
        }
        emit PassPurchased(
            communityId,
            0, // vendorId not used in this simplified version
            _msgSender(),
            actualPrice,
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
        uint256 platformCommission = (totalAmount * platformFeeBP) / MAX_BP;
        if (platformCommission > 0) {
            currency.safeTransfer(flexableWallet, platformCommission);
            totalEarnings[flexableWallet] += platformCommission;
            emit PaymentSplit(flexableWallet, platformCommission, "platform");
        }

        // 2. Manager fee
        uint256 managerCommission = (totalAmount * community.managerFeeBP) /
            MAX_BP;
        if (managerCommission > 0) {
            currency.safeTransfer(community.managerWallet, managerCommission);
            totalEarnings[community.managerWallet] += managerCommission;
            emit PaymentSplit(
                community.managerWallet,
                managerCommission,
                "manager"
            );
        }

        // 3. Vendors get remaining amount
        uint256 remainingAmount = totalAmount -
            platformCommission -
            managerCommission;

        // 4. Distribute remaining amount to vendors
        _distributeVendorPayments(communityId, remainingAmount);
    }

    /**
     * @dev Distribute remaining funds to vendors using percentage shares
     */
    function _distributeVendorPayments(
        uint256 communityId,
        uint256 remainingAmount
    ) private {
        Community storage community = communities[communityId];

        for (uint256 i = 0; i < community.vendorCount; i++) {
            Vendor memory vendor = communities[communityId].vendors[i];
            if (vendor.share == 0) continue;

            uint256 vendorPayment = (remainingAmount * vendor.share) / MAX_BP;

            if (vendorPayment > 0) {
                currency.safeTransfer(vendor.wallet, vendorPayment);
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

    // ===== PLATFORM FUNCTIONS =====
    //changes - it will be called by operator role ✅
    function activateCommunity(uint256 communityId) external onlyOperator {
        Community storage community = communities[communityId];
        community.status = Status.ACTIVE;
    }

    //changes - it will be called by manager or operator role ✅
    function deactivateCommunity(
        uint256 communityId
    ) external onlyManagerOrOperator(communityId) {
        communities[communityId].status = Status.DEACTIVATED;
    }

    //changes - it will be called by manager or operator role ✅
    function pauseCommunity(
        uint256 communityId
    ) external onlyManagerOrOperator(communityId) {
        communities[communityId].status = Status.PAUSED;
    }

    //  ===== ADMIN FUNCTIONS =====

    /**
     * @dev Update platform fee (only owner)
     */
    function updatePlatformFee(uint256 newFeeBP) external onlyAdmin {
        require(newFeeBP <= 1000, "Platform fee too high (max 10%)");
        platformFeeBP = newFeeBP;
        emit PlatformFeeUpdated(newFeeBP);
    }

    /**
     * @dev Update platform wallet
     */
    function updatePlatformWallet(address newWallet) external onlyAdmin {
        require(
            newWallet != address(0) || newWallet != flexableWallet,
            "Invalid wallet address"
        );
        flexableWallet = newWallet;
    }

    // make setter function for currency
    function updateCurrency(
        address _currency,
        uint256 _decimals
    ) external onlyAdmin {
        require(_currency != address(0), "Invalid currency address");
        currency = IERC20(_currency);
        decimals = _decimals;
    }

    function setFlexableAuthContract(address _flexableAuth) external onlyAdmin {
        require(_flexableAuth != address(0), "Invalid flexable auth address");
        flexableAuthAddr = _flexableAuth;
        flexableAuth = IFlexableAuth(_flexableAuth);
    }

    /**
     *
     * @dev Set NFT contract address
     */
    function setPassNFT(address _passNFT) external onlyAdmin {
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

    function getDecimals() external view returns (uint256) {
        return decimals;
    }

    /**
     * @dev Get contract's total USDC balance
     */
    function getContractBalance() external view returns (uint256) {
        return currency.balanceOf(address(this));
    }

    function getFlexableAuth() external view onlyOperator returns (address) {
        return flexableAuthAddr;
    }
}
