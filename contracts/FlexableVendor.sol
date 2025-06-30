// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "./IFlexableAuth.sol";

contract FlexableVendor is ERC721 {
    IFlexableAuth private flexableAuth;
    uint256 private counter = 1;

    struct VendorInfo {
        address payoutWallet;
        string name;
        string serviceMetadata;
        bool isActive;
        bool isVerified;
    }

    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => VendorInfo) private _vendorInfo;

    event VendorCreated(
        address indexed to,
        uint256 indexed tokenId,
        string name,
        string serviceMetadata
    );

    constructor(
        address _flexableAuthAddr
    ) ERC721("FlexableVendor", "FLEXVENDOR") {
        flexableAuth = IFlexableAuth(_flexableAuthAddr);
    }

    // ===== MAIN FUNCTIONS =====
    //Changes -
    //  Give an Array of VendorInfo , and create vendors for each of them.
    function createVendor(
        address to,
        string memory _name,
        string memory _uri
    ) public {
        require(balanceOf(to) == 0, "Vendor already created");
        uint256 tokenId = counter;

        _safeMint(to, tokenId);
        _tokenURIs[tokenId] = _uri;
        _vendorInfo[tokenId] = VendorInfo({
            payoutWallet: to,
            name: _name,
            serviceMetadata: _uri,
            isActive: true,
            isVerified: false
        });
        counter++;
        emit VendorCreated(to, tokenId, _name, _uri);
    }

    function setTokenURI(uint256 tokenId, string memory _uri) public {
        require(flexableAuth.isOperator(_msgSender()), "Not an operator");
        _tokenURIs[tokenId] = _uri;
    }

    function burnVendor(uint256 tokenId) public {
        require(ownerOf(tokenId) == _msgSender(), "Not the owner");
        _burn(tokenId);
    }

    function updateVendorWallet(uint256 tokenId, address _wallet) public {
        require(ownerOf(tokenId) == _msgSender(), "Not the Owner");
        _vendorInfo[tokenId].payoutWallet = _wallet;
    }

    function tokenIdToVendorWallet(
        uint256 tokenId
    ) public view returns (address) {
        return _vendorInfo[tokenId].payoutWallet;
    }

    function isVendorActive(uint256 tokenId) external view returns (bool) {
        return _vendorInfo[tokenId].isActive;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        return _tokenURIs[tokenId];
    }
}
