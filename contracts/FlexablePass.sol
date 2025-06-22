// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IFlexableAuth.sol";

/**
 * @title FlexablePassNFT
 * @dev NFT contract for community passes - minted when users purchase services
 */
contract FlexablePass is ERC721, ERC721URIStorage {
    IFlexableAuth private flexableAuth;
    // Token tracking
    uint256 private _tokenIdCounter;

    enum PassType {
        GENERAL,
        EXCLUSIVE_ACCESS,
        COMMUNITY_ACCESS,
        EVENT_ACCESS
    }

    struct Pass {
        PassType passType;
        uint256 passId;
        string passURI;
    }

    mapping(uint256 => Pass) public pass;

    // Events
    event PassMinted(uint256 indexed tokenId, address indexed recipient);

    constructor(address _flexableAuth) ERC721("Flexable Pass", "FLEXPASS") {
        _tokenIdCounter = 1;
        flexableAuth = IFlexableAuth(_flexableAuth);
    }

    function mintPass(
        address to,
        uint8 passtype,
        uint256 passId,
        string memory _uri
    ) external returns (uint256) {
        require(flexableAuth.isMinter(_msgSender()), "Not a minter");
        require(passtype < 4, "Invalid pass type");
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;

        _safeMint(to, tokenId);

        // Set token URI (you can customize this)
        string memory uri = string(
            abi.encodePacked(_uri, Strings.toString(tokenId))
        );
        _setTokenURI(tokenId, uri);

        PassType _passType = PassType(passtype);

        pass[tokenId] = Pass({
            passType: _passType,
            passId: passId,
            passURI: uri
        });

        return tokenId;
    }

    /**
     * @dev Update token URI (admin only)
     */
    function updateTokenURI(uint256 tokenId, string memory newURI) external {
        require(flexableAuth.isOperator(_msgSender()), "Not an operator");
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
    ) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
