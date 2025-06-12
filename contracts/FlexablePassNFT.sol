// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title FlexablePassNFT
 * @dev NFT contract for community passes - minted when users purchase services
 */
contract FlexablePassNFT is ERC721, ERC721URIStorage, AccessControl {
    // Roles
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    // Token tracking
    uint256 private _tokenIdCounter;
    // Metadata
    struct PassMetadata {
        uint256 communityId;
        uint256 purchaseDate;
        address originalBuyer;
    }

    mapping(uint256 => PassMetadata) public passMetadata;

    // Events
    event PassMinted(
        uint256 indexed tokenId,
        address indexed recipient,
        uint256 communityId
    );

    constructor() ERC721("Flexable Community Pass", "FLEX") {
        _grantRole(ADMIN_ROLE, msg.sender);
        _tokenIdCounter = 1; // Start token IDs at 1
    }

    function mintPass(
        address to,
        uint256 communityId,
        string memory _uri
    ) external onlyRole(MINTER_ROLE) returns (uint256) {
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;

        _safeMint(to, tokenId);

        // Store metadata
        passMetadata[tokenId] = PassMetadata({
            communityId: communityId,
            purchaseDate: block.timestamp,
            originalBuyer: to
        });

        // Set token URI (you can customize this)
        string memory uri = string(
            abi.encodePacked(_uri, Strings.toString(tokenId))
        );
        _setTokenURI(tokenId, uri);

        emit PassMinted(tokenId, to, communityId);

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

    // Required overrides for multiple inheritance
    function _increaseBalance(
        address account,
        uint128 value
    ) internal override(ERC721) {
        super._increaseBalance(account, value);
    }

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721) returns (address) {
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
        override(ERC721, ERC721URIStorage, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
