// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title FlexablePassNFT
 * @dev NFT contract for community passes - minted when users purchase services
 */
contract FlexablePassNFT is
    ERC721,
    ERC721URIStorage,
    ERC721Enumerable,
    AccessControl
{
    // Roles
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    // Token tracking
    uint256 private _tokenIdCounter;
    // Metadata
    struct PassMetadata {
        uint256 communityId;
        string serviceType;
        uint256 purchaseDate;
        address originalBuyer;
    }

    mapping(uint256 => PassMetadata) public passMetadata;

    // Events
    event PassMinted(
        uint256 indexed tokenId,
        address indexed recipient,
        uint256 communityId,
        string serviceType
    );

    constructor() ERC721("Flexable Community Pass", "FLEX") {
        _grantRole(ADMIN_ROLE, msg.sender);
        _tokenIdCounter = 1; // Start token IDs at 1
    }

    /**
     * @dev Mint a new pass NFT
     * @param to Recipient address
     * @param communityId Which community this pass is for
     * @param serviceType What service was purchased
     */
    function mintPass(
        address to,
        uint256 communityId,
        string memory serviceType,
        string memory _uri
    ) external onlyRole(MINTER_ROLE) returns (uint256) {
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;

        _safeMint(to, tokenId);

        // Store metadata
        passMetadata[tokenId] = PassMetadata({
            communityId: communityId,
            serviceType: serviceType,
            purchaseDate: block.timestamp,
            originalBuyer: to
        });

        // Set token URI (you can customize this)
        string memory uri = string(
            abi.encodePacked(_uri, Strings.toString(tokenId))
        );
        _setTokenURI(tokenId, uri);

        emit PassMinted(tokenId, to, communityId, serviceType);

        return tokenId;
    }

    /**
     * @dev Update token URI (admin only)
     */
    function updateTokenURI(
        uint256 tokenId,
        string memory newURI
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        _setTokenURI(tokenId, newURI);
    }

    /**
     * @dev Check if address has a pass for specific community
     */
    function hasPassForCommunity(
        address user,
        uint256 communityId
    ) external view returns (bool) {
        uint256 balance = balanceOf(user);
        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(user, i);
            if (passMetadata[tokenId].communityId == communityId) {
                return true;
            }
        }
        return false;
    }

    // Required overrides for multiple inheritance
    function _increaseBalance(
        address account,
        uint128 value
    ) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
